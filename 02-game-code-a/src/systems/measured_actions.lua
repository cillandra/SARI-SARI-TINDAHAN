-- Internal helpers require Portions to validate the editable line/reservation first.
-- Atomic opened-content reset and whole-fill oil spill; no staged cash is used.
local State=require('src.model.state')
local Inventory=require('src.systems.inventory')
local Cash=require('src.systems.cash')
local Validate=require('src.model.validate')
local Config=require('data.config')
local Actions={}
local function fee(state)
 local amount=Config.pouring.spill_penalty
 local before,err=Cash.value(state.drawer);if not before then return nil,err end
 local pay=Cash.plan(state,amount)
 if not pay then
  local denomination
  for d,n in pairs(state.drawer) do if n>0 and d>100 and (not denomination or d<denomination) then denomination=d end end
  if not denomination then return nil,'Not enough cash for spill penalty' end
  -- The cashier exchanges one piece at equal value before paying the configured fee.
  state.drawer[denomination]=state.drawer[denomination]-1
  state.drawer[100]=(state.drawer[100] or 0)+denomination/100
  local changed,why=Cash.value(state.drawer);if not changed then return nil,why end
  if changed~=before then return nil,'Fee change must conserve drawer cash' end
  pay=Cash.plan(state,amount)
 end
 if not pay then return nil,'Not enough cash for spill penalty' end
 for d,n in pairs(pay) do state.drawer[d]=state.drawer[d]-n end
 local after,why=Cash.value(state.drawer);if not after then return nil,why end
 if after~=before-amount then return nil,'Incorrect spill fee' end
 state.ledger.operatingCosts=state.ledger.operatingCosts+amount
 state.ledger.cashFlow=state.ledger.cashFlow-amount
 return true
end
local function waste(state,item,quantity)
 state.reservations[item.reservation].quantity=quantity
 local ok,cost=Inventory.consume(state,item.reservation);if not ok then return nil,cost end
 state.ledger.spoilage=state.ledger.spoilage+cost
 return true
end
local function restart(state,item,index,locked)
 Inventory.release(state,item.reservation)
 local ok=Inventory.reserve(state,item.reservation,item.productId,item.targetQuantity)
 if not ok then
  state.retail.total=state.retail.total-item.amount
  table.remove(state.retail.lines,index)
  return 'removed'
 end
 item.actualQuantity=0;item.openedSpoilage=false;item.spillLocked=locked or false
 return locked and 'spilled' or 'reset'
end
local function publish(live,staged,outcome)
 local total,err=Cash.value(staged.drawer);if not total then return nil,err end
 local valid,why=Validate.monetaryTotals(staged.ledger,total,staged.wallet.balance)
 if not valid then return nil,why end
 if not Validate.nonnegative(staged.retail.total) then return nil,'Invalid remaining basket' end
 live.inventory=staged.inventory;live.reservations=staged.reservations
 live.drawer=staged.drawer;live.ledger=staged.ledger;live.retail=staged.retail
 return true,outcome
end
function Actions.reset(state,id,index)
 local staged=State.clone(state);local item=staged.retail.lines[index]
 if item.openedSpoilage and item.actualQuantity>0 then
  local ok,err=waste(staged,item,item.actualQuantity);if not ok then return nil,err end
 end
 local outcome=restart(staged,item,index,false)
 return publish(state,staged,outcome)
end
function Actions.spill(state,id,index,quantity)
 local staged=State.clone(state);local item=staged.retail.lines[index]
 local ok,err=waste(staged,item,quantity);if not ok then return nil,err end
 ok,err=fee(staged);if not ok then return nil,err end
 local outcome=restart(staged,item,index,true)
 return publish(state,staged,outcome=='removed' and 'spilled_removed' or 'spilled')
end
return Actions
