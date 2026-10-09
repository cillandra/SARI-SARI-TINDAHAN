-- Fictional verified wallet services staged inside the atomic retail basket.
local Cash=require('src.systems.cash');local State=require('src.model.state');local V=require('src.model.validate');local Order=require('src.systems.order')
local Progress=require('src.systems.line_progress')
local T={}
function T.receipt_matches(request)
 local receipt=request.receipt;if receipt==nil then receipt=request.transfer end;local transfer=request.transfer
 if type(receipt)~='table' or type(transfer)~='table' then return false end
 for _,field in ipairs({'amount','reference','recipient','status'}) do if receipt[field]~=transfer[field] then return false end end
 return true
end
function T.valid_evidence(request,day)
 local store=request.transfer;local receipt=request.receipt;if receipt==nil then receipt=store end
 if not V.string(request.reference) or not V.string(request.recipient) then return false end
 if type(store)~='table' or store.status~='confirmed' or store.amount~=request.principal or store.reference~=request.reference or store.recipient~=request.recipient then return false end
 if type(receipt)~='table' or not V.positive(receipt.amount) or not V.string(receipt.reference) or not V.string(receipt.recipient) or (receipt.status~='confirmed' and receipt.status~='pending') then return false end
 local differences=0
 for _,field in ipairs({'amount','reference','recipient','status'}) do if receipt[field]~=store[field] then differences=differences+1 end end
 return differences==0 or day>=6 and differences==1
end
function T.summary(sale)
 local m={payout=0,fees=0,walletDelta=0,retailRevenue=0}
 for _,line in ipairs(sale and sale.lines or {}) do
  if line.type=='cash_in' then m.fees=m.fees+line.fee;m.walletDelta=m.walletDelta-line.principal
  elseif line.type=='cash_out' then m.fees=m.fees+line.fee;m.walletDelta=m.walletDelta+line.principal;m.payout=m.payout+line.principal
  else m.retailRevenue=m.retailRevenue+line.amount end
 end
 return m
end
function T.offer(state,customer)
 local incoming,outgoing=0,0
 for _,line in ipairs(customer.lines) do
  if line.type=='cash_in' then incoming=incoming+line.principal elseif line.type=='cash_out' then outgoing=outgoing+line.principal end
 end
 if not V.nonnegative(incoming) or not V.nonnegative(outgoing) then return nil,'Invalid wallet principal' end
 if incoming>state.wallet.balance then return nil,'Kulang ang wallet balance' end
 if outgoing>0 and not Cash.plan(state,outgoing) then return nil,'Kulang ang cash sa drawer' end
 return true
end
function T.match(line,request)
 return line.type==request.type and line.reference==request.reference and line.principal==request.principal and line.fee==request.fee and line.amount==request.amount and line.confirmed==true
end
function T.add(state,id,index,receipt)
 local sale=state.retail;local customer=state.queue[1]
 if not sale or sale.id~=id or not customer or customer.id~=id or sale.tender then return nil,'No editable current order' end
 local request=customer.lines[index]
 if not request or (request.type~='cash_in' and request.type~='cash_out') or not Order.allowed(state.day,request.type) then return nil,'Wallet service is not unlocked' end
 for _,line in ipairs(sale.lines) do if line.requestIndex==index then return true end end
 if not V.positive(request.principal) or not V.positive(request.fee) or not V.string(request.reference) or not V.string(request.recipient) or request.amount~=(request.type=='cash_in' and request.principal+request.fee or request.fee) then return nil,'Invalid wallet request' end
 if type(receipt)~='table' or receipt.status~='confirmed' or receipt.reference~=request.reference or receipt.recipient~=request.recipient or receipt.amount~=request.principal then return nil,'Verify recipient, reference, amount and confirmed store status' end
 for _,record in ipairs(state.histories.wallet) do if record.reference==request.reference then return nil,'Transfer reference already used' end end
 for _,line in ipairs(sale.lines) do if line.reference==request.reference then return nil,'Transfer reference already staged' end end
 local ok,err=T.offer(state,customer);if not ok then return nil,err end
 if not V.nonnegative(sale.total+request.amount) then return nil,'Invalid basket total' end
 local line=State.clone(request);line.transfer=nil;line.receipt=nil;line.confirmed=true;line.requestIndex=index
 sale.lines[#sale.lines+1]=line;sale.total=sale.total+line.amount
 Progress.complete(state,id,index)
 return true
end
return T
