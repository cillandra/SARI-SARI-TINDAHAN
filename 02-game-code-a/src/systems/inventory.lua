-- Purpose: FIFO stock. API: available(s,id), reserve(s,ref,id,q), release/consume(s,ref), purchase(s,id,q,payment). consume -> true,cost,allocations; commands -> true or nil,error. Dependencies: products/days/validate/cash.
local Products=require('data.products'); local Days=require('data.days'); local V=require('src.model.validate'); local C=require('src.systems.cash'); local I={}
function I.available(s,id)
 local t=0; for _,b in ipairs(s.inventory[id] or {}) do if b.expiresDay>s.day then t=t+b.quantity end end
 for _,r in pairs(s.reservations or {}) do if r.productId==id then t=t-r.quantity end end; return t
end
function I.reserve(s,ref,id,q)
 if not V.string(ref) or not Products.byId[id] or not V.positive(q) then return nil,'Invalid stock reservation' end
 if s.reservations and s.reservations[ref] then return nil,'Reservation already exists' end
 if q>I.available(s,id) then return nil,'Not enough stock' end
 s.reservations=s.reservations or {}; s.reservations[ref]={productId=id,quantity=q}; return true
end
function I.release(s,ref) if not V.string(ref) then return nil,'Invalid reference' end; if s.reservations then s.reservations[ref]=nil end; return true end
-- Optional expected product/quantity bind stock to its staged sale line.
function I.check_reservation(s, ref, product_id, quantity)
 if type(s.reservations)~='table' or type(s.inventory)~='table' then return nil,'Stock reservation container is missing or inconsistent' end
 for _,r in pairs(s.reservations) do
  if type(r)~='table' or not Products.byId[r.productId] or not V.positive(r.quantity) then return nil,'Stock reservation is missing or inconsistent' end
 end
 local r=s.reservations[ref]
 if not r or type(s.inventory[r.productId])~='table' then return nil,'Stock reservation is missing or inconsistent' end
 if product_id~=nil and r.productId~=product_id then return nil,'Reservation product does not match the sale' end
 if quantity~=nil and (not V.positive(quantity) or r.quantity~=quantity) then return nil,'Reservation quantity does not match the sale' end
 for _,b in ipairs(s.inventory[r.productId]) do
  if type(b)~='table' or not V.positive(b.quantity) or not V.nonnegative(b.totalCost)
   or not V.positive(b.expiresDay) then return nil,'Reserved stock batch is inconsistent' end
 end
 return r
end
function I.consume(s,ref)
 local r,err=I.check_reservation(s,ref); if not r then return nil,err end
 local left=r.quantity; local a={}; local cost=0
 for _,b in ipairs(s.inventory[r.productId]) do if b.expiresDay>s.day and left>0 then local q=math.min(left,b.quantity); local c=q==b.quantity and b.totalCost or math.floor(b.totalCost*q/b.quantity); a[#a+1]={batch=b,quantity=q,cost=c}; cost=cost+c; left=left-q end end
 if left>0 then return nil,'Reserved stock expired or missing' end
 for _,v in ipairs(a) do v.batch.quantity=v.batch.quantity-v.quantity; v.batch.totalCost=v.batch.totalCost-v.cost end
 local b=s.inventory[r.productId]; for n=#b,1,-1 do if b[n].quantity==0 then table.remove(b,n) end end
 I.release(s,ref); return true,cost,a
end
-- Args: state, product ID, positive base-unit quantity; returns an independent supplier quote or nil,error.
function I.purchaseQuote(s,id,q)
 local p=Products.byId[id]
 if not p or not V.positive(q) or s.day<p.unlock.buyDay then return nil,'Invalid purchase' end
 local day=Days.list[s.day]
 local multiplier=s.dayProfile and s.dayProfile.supplierMultiplierBasisPoints or (day and day.supplierMultiplierBasisPoints or (s.supplierMultiplierBasisPoints or 10000))
 local cost=math.floor(p.cost*q/p.priceQuantity*multiplier/10000+0.5)
 if not V.positive(cost) then return nil,'Invalid purchase amount' end
 return {productId=id,quantity=q,cost=cost}
end
function I.purchase(s,id,q,payment)
 if s.phase~='preparation' then return nil,'Purchases require preparation' end
 local quote,quoteError=I.purchaseQuote(s,id,q)
 if not quote then return nil,quoteError end
 local p=Products.byId[id]
 local cost=quote.cost
 local amount,e=C.value(payment); if not amount then return nil,e end; if amount~=cost then return nil,'Payment must equal supplier cost '..cost end
 local ok,err=C.canPay(s,payment); if not ok then return nil,err end
 local projectedLedger={}; for field,value in pairs(s.ledger) do projectedLedger[field]=value end
 projectedLedger.cashFlow=s.ledger.cashFlow-cost
 local valid,validationError=V.monetaryTotals(projectedLedger,C.total(s)-cost,s.wallet.balance)
 if not valid then return nil,validationError end
 for d,n in pairs(payment) do s.drawer[d]=s.drawer[d]-n end
 local b=s.inventory[id]; b[#b+1]={id='batch:'..s.ids.nextBatch,quantity=q,totalCost=cost,receivedDay=s.day,expiresDay=s.day+p.shelfLifeDays,prepared=false}
 s.ids.nextBatch=s.ids.nextBatch+1; s.ledger.cashFlow=s.ledger.cashFlow-cost; return true
end
return I



