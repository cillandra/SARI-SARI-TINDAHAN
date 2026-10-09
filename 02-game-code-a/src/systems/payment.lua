-- Gameplay payment outcomes layered over the atomic raw retail settlement.
local State=require('src.model.state')
local Retail=require('src.systems.retail')
local Cash=require('src.systems.cash')
local Customers=require('src.systems.customers')
local Reputation=require('src.systems.reputation')
local Order=require('src.systems.order')
local Config=require('data.config')
local Tuning=require('data.tuning')
local Validate=require('src.model.validate')
local Payment={}
local function publish(live,staged)
 for key in pairs(live) do live[key]=nil end
 for key,value in pairs(staged) do live[key]=value end
end
local function reward(state,id,customer)
 if customer.changeMistake or customer.mistake or Customers.mood(customer)~='happy' then return true end
 local tip=(Config.tip_min_pesos+Order.random(state,Config.tip_max_pesos-Config.tip_min_pesos+1)-1)*100
 local remaining=tip
 for i=#Tuning.denominations,1,-1 do
  local d=Tuning.denominations[i];local n=math.floor(remaining/d)
  if n>0 then state.drawer[d]=(state.drawer[d] or 0)+n;remaining=remaining-n*d end
 end
 if remaining~=0 then return nil,'Tip cannot be represented by drawer denominations' end
 state.ledger.tips=(state.ledger.tips or 0)+tip
 state.ledger.cashFlow=state.ledger.cashFlow+tip
 Reputation.adjust(state,Config.perfect_bonus)
 local record=state.histories.retail[#state.histories.retail]
 record.tip=tip;state.completedReferences[id]=State.clone(record)
 local drawer,err=Cash.value(state.drawer);if not drawer then return nil,err end
 return Validate.monetaryTotals(state.ledger,drawer,state.wallet.balance)
end
function Payment.confirm(state,id,selection)
 if state.completedReferences[id] then return Retail.commit(state,id,selection) end
 if state.paused then return nil,'Resume first' end
 if not state.mvp then return Retail.commit(state,id,selection) end
 local customer=state.queue[1];local sale=state.retail
 if state.phase~='service' or not customer or customer.id~=id or not sale or sale.id~=id then return nil,'No active current payment' end
 local selected,err=Cash.value(selection);if not selected then return nil,err end
 local feasible,why=Cash.canPay(state,selection,sale.tender);if not feasible then return nil,why end
 local due,message=Retail.changeDue(state,id);if not due then return nil,message end
 local wrong=selected~=due;local payout=selection
 if wrong then
  -- Second error completes with correct feasible change; never short-pay a wallet payout.
  payout,err=Cash.plan(state,due,sale.tender);if not payout then return nil,err end
 end
 local staged=State.clone(state);local c=staged.queue[1]
 if wrong and not c.changeMistake then
  -- Validate the whole settlement before charging a retry on a corrupt basket.
  local preview=State.clone(staged);local valid,error=Retail.commit(preview,id,payout)
  if not valid then return nil,error end
  c.changeMistake=true;staged.serviceOutcomes.mistakes=(staged.serviceOutcomes.mistakes or 0)+1;Reputation.adjust(staged,-Config.change_penalty)
  if staged.reputation==0 then
   local ok,reason=Customers.lose(staged);if not ok then return nil,reason end
   publish(state,staged);return true,'lose'
  end
  publish(state,staged);return true,'retry'
 end
 local ok,reason=Retail.commit(staged,id,payout);if not ok then return nil,reason end
 local rewarded,rewardError=reward(staged,id,c);if not rewarded then return nil,rewardError end
 publish(state,staged);return true,'completed'
end
return Payment
