-- Purpose: atomic staged retail sales. API: begin(s,id), add(s,id,productId,q), remove(s,id,lineIndex), stageTender(s,id,bundle), commit(s,id,changeBundle), cancel(s,id) -> true or nil,error; quote(s,id) -> independent quote or nil,error. Dependencies: inventory/cash/products/state/validate.
local I=require('src.systems.inventory'); local C=require('src.systems.cash'); local Products=require('data.products'); local S=require('src.model.state'); local V=require('src.model.validate'); local R={}; local Wallet=require('src.systems.tindapay'); local Order=require('src.systems.order')
local Progress=require('src.systems.line_progress')
local function active(s,id) local t=s.retail; if not t or t.id~=id then return nil,'No active sale with that reference' end; return t end
function R.begin(s,id)
 if s.phase~='service' then return nil,'Retail requires service phase' end
 if not V.string(id) then return nil,'Sale reference required' end
 if s.completedReferences[id] or (s.cancelledRetail and s.cancelledRetail[id]) then return nil,'Sale reference already used' end
 if s.retail then return nil,'Finish or cancel the current sale first' end
 if s.mvp and (not s.queue[1] or s.queue[1].id~=id) then return nil,'Serve the current customer first' end
 s.retail={id=id,lines={},total=0,nextLine=1}; return true
end
function R.add(s,id,productId,q)
 local t,e=active(s,id); if not t then return nil,e end
 if t.tender then return nil,'Tender already staged; cancel to change basket' end
 local requested_line,requested_index
 local p=Products.byId[productId]; if not p or not V.positive(q) then return nil,'Invalid product or quantity' end
  if s.mvp then
  local customer=s.queue[1]
  if not customer or customer.id~=id then return nil,'Serve the current customer first' end
  local requested=false
  for index,request in ipairs(customer.lines) do if request.productId==productId and request.quantity==q and Order.valid_goods(request) then requested=true;requested_line=request;requested_index=index end end
  for _,existing in ipairs(t.lines) do if existing.productId==productId then return nil,'Requested line already added' end end
  if not requested then return nil,'Item or amount was not requested' end
 end
 local price=s.prices[productId]; if not V.positive(price) then return nil,'Invalid sale price' end
 local amount=math.floor(price*q/p.priceQuantity+0.5); if not V.positive(amount) or not V.nonnegative(t.total+amount) then return nil,'Invalid quoted total' end
 local ref='retail:'..id..':'..t.nextLine; local ok,err=I.reserve(s,ref,productId,q); if not ok then return nil,err end
 t.lines[#t.lines+1]={productId=productId,quantity=q,unitPrice=price,priceQuantity=p.priceQuantity,amount=amount,reservation=ref}; local added=t.lines[#t.lines]; if requested_line then added.type=requested_line.type;added.requestIndex=requested_index end; if p.saleUnit~='piece' then added.measured=true; added.confirmed=false; added.targetQuantity=q; added.actualQuantity=0 end
 if s.mvp then for _,request in ipairs(s.queue[1].lines) do if request.productId==productId then added.amount=request.amount; amount=request.amount end end end
 t.nextLine=t.nextLine+1; t.total=t.total+amount
 if not added.measured then Progress.complete(s,id,requested_index) end
 return true
end
function R.remove(s,id,index)
 local t,e=active(s,id); if not t then return nil,e end
 if t.tender or not V.positive(index) or not t.lines[index] then return nil,'Cannot remove that basket line' end
 local l=t.lines[index]; if l.openedSpoilage and l.actualQuantity>0 then return nil,'Cancel sale to discard opened contents' end; if l.reservation then I.release(s,l.reservation) end; t.total=t.total-l.amount; table.remove(t.lines,index); return true
end
function R.quote(s,id) local t,e=active(s,id); if not t then return nil,e end; return S.clone(t) end
function R.stageTender(s,id,bundle)
 local t,e=active(s,id); if not t then return nil,e end
 for _,item in ipairs(t.lines) do if item.measured and not item.confirmed then return nil,'Confirm measured portions before tender' end end
 local amount,err=C.value(bundle); if not amount then return nil,err end
 if #t.lines==0 or amount<t.total then return nil,'Tender must cover a nonempty basket' end
 t.tender=S.clone(bundle); t.tenderAmount=amount; return true
end
function R.changeDue(s,id)
 local t,e=active(s,id);if not t then return nil,e end
 if not t.tender then return nil,'Receive tender first' end
 return t.tenderAmount-t.total+Wallet.summary(t).payout
end
function R.commit(s,id,change)
 if V.string(id) and s.completedReferences[id] then if s.completedReferences[id].kind=='retail' then return true end; return nil,'Reference belongs to another service' end
 local t,e=active(s,id); if not t then return nil,e end
  if s.mvp then
  local customer=s.queue[1]
  if not customer or customer.id~=id or #customer.lines~=#t.lines then return nil,'Complete the current requested basket' end
  for _,request in ipairs(customer.lines) do
   local found=false
   for _,item in ipairs(t.lines) do
    if Order.is_wallet(request) then if Wallet.match(item,request) then found=true end
    elseif Order.matches_goods(item,request) then found=true end
   end
   if not found then return nil,'Complete the current requested basket' end
  end
 end
 if not t.tender then return nil,'Receive tender first' end
 local amount,err=C.value(change); if not amount then return nil,err end
 local expected=R.changeDue(s,id); if amount<expected then return nil,'Short change: add '..(expected-amount)..' centavos' end
 local feasible,why=C.canPay(s,change,t.tender); if not feasible then return nil,why end
 -- Prepare ALL stock changes on a private copy; failures never alter live batches/balances.
 local services=Wallet.summary(t)
 if s.mvp then local ok,err=Wallet.offer(s,s.queue[1]);if not ok then return nil,err end end
 local staged=S.clone(s); local cost=0
 for _,line in ipairs(t.lines) do
  if Order.valid_goods(line) then
   local reservation,why=I.check_reservation(staged,line.reservation,line.productId,line.quantity)
   if not reservation then return nil,why end
   local ok,c=I.consume(staged,line.reservation);if not ok then return nil,c end;cost=cost+c
  elseif Order.is_wallet(line) then
   for _,record in ipairs(staged.histories.wallet) do if record.reference==line.reference then return nil,'Transfer reference already used' end end
   staged.histories.wallet[#staged.histories.wallet+1]={type=line.type,reference=line.reference,customerId=id,day=s.day,principal=line.principal,fee=line.fee,recipient=line.recipient}
  else return nil,'Invalid order line type or product mode' end
 end
 staged.wallet.balance=staged.wallet.balance+services.walletDelta
 local loss=amount-expected; if not V.nonnegative(cost) then return nil,'Invalid cost' end
 for d,n in pairs(t.tender) do staged.drawer[d]=(staged.drawer[d] or 0)+n end
 for d,n in pairs(change) do staged.drawer[d]=staged.drawer[d]-n end
 local l=staged.ledger; l.retailRevenue=l.retailRevenue+services.retailRevenue; l.serviceFees=l.serviceFees+services.fees; l.walletTransfers=l.walletTransfers+services.walletDelta; l.costOfGoods=l.costOfGoods+cost; l.changeLosses=l.changeLosses+loss; l.cashFlow=l.cashFlow+t.tenderAmount-amount
 local drawerTotal,drawerError=C.value(staged.drawer); if not drawerTotal then return nil,drawerError end
 local valid,validationError=V.monetaryTotals(l,drawerTotal,staged.wallet.balance); if not valid then return nil,validationError end
 local record={kind='retail',id=id,day=s.day,total=t.total,cost=cost,changeLoss=loss,tenderAmount=t.tenderAmount,changeAmount=amount,lines=S.clone(t.lines)}
 staged.histories.retail[#staged.histories.retail+1]=record; staged.completedReferences[id]=S.clone(record); staged.ids.nextTransaction=staged.ids.nextTransaction+1
 s.inventory=staged.inventory; s.reservations=staged.reservations; s.drawer=staged.drawer; s.wallet=staged.wallet; s.ledger=staged.ledger; s.histories=staged.histories; s.completedReferences=staged.completedReferences; s.ids=staged.ids; s.retail=nil; if s.mvp then table.remove(s.queue,1); s.serviceOutcomes.served=s.serviceOutcomes.served+1 end; return true
end
function R.cancel(s,id)
 local t,e=active(s,id); if not t then return nil,e end
  local staged=S.clone(s)
 for _,item in ipairs(t.lines) do
  if Order.valid_goods(item) then
   local quantity=item.quantity
   if item.measured then
    if not V.positive(item.targetQuantity) or not V.nonnegative(item.actualQuantity) then return nil,'Measured quantities are inconsistent' end
    quantity=item.confirmed and item.quantity or math.max(item.targetQuantity,item.actualQuantity)
    if item.confirmed and item.quantity~=item.actualQuantity then return nil,'Measured quantities are inconsistent' end
   end
   local reservation,why=I.check_reservation(staged,item.reservation,item.productId,quantity)
   if not reservation then return nil,why end
  elseif not Order.is_wallet(item) then return nil,'Invalid order line type or product mode' end
  if item.openedSpoilage and item.actualQuantity>0 then
   staged.reservations[item.reservation].quantity=item.actualQuantity
   local ok,cost=I.consume(staged,item.reservation)
   if not ok then return nil,cost end
   staged.ledger.spoilage=staged.ledger.spoilage+cost
  elseif item.reservation then I.release(staged,item.reservation) end
 end
 local valid,why=V.monetaryTotals(staged.ledger,C.total(staged),staged.wallet.balance)
 if not valid then return nil,why end
 s.inventory=staged.inventory; s.reservations=staged.reservations; s.ledger=staged.ledger
 s.cancelledRetail=s.cancelledRetail or {}; s.cancelledRetail[id]=true; s.retail=nil; return true
end
return R



