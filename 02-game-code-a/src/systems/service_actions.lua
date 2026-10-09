-- Gameplay mistakes and wallet decisions; raw staging and settlement APIs stay strict.
local State=require('src.model.state')
local Retail=require('src.systems.retail')
local Wallet=require('src.systems.tindapay')
local Customers=require('src.systems.customers')
local Reputation=require('src.systems.reputation')
local Cash=require('src.systems.cash')
local Products=require('data.products')
local Order=require('src.systems.order')
local Config=require('data.config')
local Validate=require('src.model.validate')
local Actions={}
local function publish(live,staged)
 for key in pairs(live) do live[key]=nil end
 for key,value in pairs(staged) do live[key]=value end
end
local function current(state,id)
 if state.reputation<=0 or state.paused or state.phase~='service' or not state.queue[1] or state.queue[1].id~=id then return nil,'No editable current customer' end
 return state.queue[1]
end
local function request(state,id,index)
 local c,err=current(state,id);if not c then return nil,err end
 local sale=state.retail;local line=c.lines[index]
 if not sale or sale.id~=id or sale.tender or not line or not Order.is_wallet(line) or not Order.allowed(state.day,line.type) then return nil,'No editable wallet request' end
 if not Validate.positive(line.principal) or not Validate.positive(line.fee) or line.amount~=(line.type=='cash_in' and line.principal+line.fee or line.fee) or not Wallet.valid_evidence(line,state.day) then return nil,'Invalid wallet evidence' end
 return line
end
local function finish(state,id,penalty,scam)
 local ok,err=Retail.cancel(state,id);if not ok then return nil,err end
 table.remove(state.queue,1);state.serviceOutcomes.timedOut=state.serviceOutcomes.timedOut+1
 if penalty>0 then state.serviceOutcomes.mistakes=(state.serviceOutcomes.mistakes or 0)+1 end
 if scam then state.serviceOutcomes.scams=(state.serviceOutcomes.scams or 0)+1 end
 Reputation.adjust(state,-penalty)
 if state.reputation==0 then
  local lost,why=Customers.lose(state);if not lost then return nil,why end
  return true,'lose'
 end
 return true,'closed'
end
local function unavailable(state,id,why)
 local staged=State.clone(state);local ok,outcome=finish(staged,id,0,false)
 if not ok then return nil,outcome end
 publish(state,staged)
 return true,why=='Kulang ang cash sa drawer' and 'cash_shortage' or 'wallet_shortage'
end
function Actions.wrong_item(state,id,product_id)
 local customer,err=current(state,id);if not customer then return nil,err end
 if not Products.byId[product_id] or state.retail and state.retail.tender then return nil,'Selection is unavailable' end
 for _,line in ipairs(customer.lines) do if line.productId==product_id then return nil,'Requested item is not a mistake' end end
 local staged=State.clone(state);staged.queue[1].mistake=true
 staged.serviceOutcomes.mistakes=(staged.serviceOutcomes.mistakes or 0)+1
 Reputation.adjust(staged,-Config.wrong_item_penalty)
 local outcome='mistake'
 if staged.reputation==0 then local ok,why=Customers.lose(staged);if not ok then return nil,why end;outcome='lose' end
 publish(state,staged);return true,outcome
end
function Actions.reject(state,id,index)
 local line,err=request(state,id,index);if not line then return nil,err end
 for _,item in ipairs(state.retail.lines) do if item.requestIndex==index then return nil,'Wallet line already verified' end end
 local available,why=Wallet.offer(state,state.queue[1]);if not available then return unavailable(state,id,why) end
 local penalty=Wallet.receipt_matches(line) and Config.valid_reject_penalty or 0
 local staged=State.clone(state);local ok,outcome=finish(staged,id,penalty,false)
 if not ok then return nil,outcome end
 publish(state,staged);return true,outcome
end
function Actions.accept(state,id,index)
 local line,err=request(state,id,index);if not line then return nil,err end
 for _,item in ipairs(state.retail.lines) do if item.requestIndex==index then return true,'accepted' end end
 local available,why=Wallet.offer(state,state.queue[1]);if not available then return unavailable(state,id,why) end
 if Wallet.receipt_matches(line) then
  local ok,why=Wallet.add(state,id,index,line.transfer);if not ok then return nil,why end
  return true,'accepted'
 end
 -- Fraud forfeits outgoing principal; no unconfirmed incoming credit is booked.
 local payout
 if line.type=='cash_out' then payout,why=Cash.plan(state,line.principal);if not payout then return nil,why end end
 local staged=State.clone(state);local ok,outcome=finish(staged,id,Config.scam_penalty,true)
 if not ok then return nil,outcome end
 if payout then
  for d,n in pairs(payout) do staged.drawer[d]=staged.drawer[d]-n end
  staged.ledger.cashFlow=staged.ledger.cashFlow-line.principal
 else
  staged.wallet.balance=staged.wallet.balance-line.principal
  staged.ledger.walletTransfers=staged.ledger.walletTransfers-line.principal
 end
 staged.ledger.scamLosses=(staged.ledger.scamLosses or 0)+line.principal
 local cash,error=Cash.value(staged.drawer);if not cash then return nil,error end
 local valid,reason=Validate.monetaryTotals(staged.ledger,cash,staged.wallet.balance);if not valid then return nil,reason end
 publish(state,staged);return true,outcome
end
return Actions
