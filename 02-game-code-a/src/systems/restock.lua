-- Equal-value bill/coin exchange and once-only low-coin morning normalization.
local Cash=require('src.systems.cash')
local State=require('src.model.state')
local Config=require('data.config')
local Levels=require('data.levels')
local Inventory=require('src.systems.inventory')
local Products=require('data.products')
local Validate=require('src.model.validate')
local Denominations=require('data.tuning').denominations
local Restock={}
function Restock.prepare(state)
 if not Levels.get(state.day).barya_low or state.dayProfile.baryaPrepared then return true end
 local before,err=Cash.value(state.drawer);if not before then return nil,err end
 local drawer=State.clone(state.drawer)
 for _,pair in ipairs({{100,500},{500,1000}}) do
  local small,large=pair[1],pair[2];local count=drawer[small] or 0;local ratio=large/small
  local excess=math.max(0,count-Config.barya_low_keep[small])
  local groups=math.min(math.floor(count/ratio),math.ceil(excess/ratio))
  drawer[small]=count-groups*ratio;drawer[large]=(drawer[large] or 0)+groups
 end
 local after,why=Cash.value(drawer);if not after then return nil,why end
 if after~=before then return nil,'Coin conversion must conserve cash' end
 state.drawer=drawer;state.dayProfile.baryaPrepared=true;return true
end
local function returned_change(amount)
 local change={}
 for i=#Denominations,1,-1 do
  local d=Denominations[i];local n=math.floor(amount/d)
  if n>0 then change[d]=n;amount=amount-n*d end
 end
 if amount~=0 then return nil,'Cannot represent returned barya payment' end
 return change
end
local function payment(state)
 local cost,err=Cash.value(Config.barya_bundle);if not cost then return nil,err end
 local bills={}
 for d,n in pairs(state.drawer) do if d>=2000 then bills[d]=n end end
 local value,why=Cash.value(bills);if not value then return nil,why,cost end
 local pay=Cash.plan({drawer=bills},cost)
 if pay then return pay,nil,cost,{} end
 if value<cost then return nil,'Not enough bills for the barya bundle',cost end
 -- The coin supplier returns change for larger bills; this never creates cash.
 for _,d in ipairs(Denominations) do
  if d>=cost and d>=2000 and (bills[d] or 0)>0 then
   local change,error=returned_change(d-cost)
   return change and {[d]=1} or nil,error,cost,change
  end
 end
 pay={};local paid=0
 for _,d in ipairs(Denominations) do
  if d>=2000 and (bills[d] or 0)>0 then
   local count=math.min(bills[d],math.ceil((cost-paid)/d))
   if count>0 then pay[d]=count;paid=paid+count*d end
   if paid>=cost then break end
  end
 end
 local change,error=returned_change(paid-cost)
 return change and pay or nil,error,cost,change
end
function Restock.bundle(state)
 local pay,reason,cost=payment(state)
 return {cost=cost,coins=State.clone(Config.barya_bundle),enabled=pay~=nil,reason=reason}
end
function Restock.product_bundle(state,id)
 local product=Products.byId[id];if not product then return nil,'Unknown product' end
 local quantity=product.saleUnit=='piece' and Config.restock_quantities.unit or Config.restock_quantities.loose
 local quote,err=Inventory.purchaseQuote(state,id,quantity)
 if not quote then return nil,err end
 quote.quantity=quantity;return quote
end
function Restock.exchange(state)
 if state.phase~='preparation' or state.paused or state.retail then return nil,'Exchange bills only during morning preparation' end
 local before,err=Cash.value(state.drawer);if not before then return nil,err end
 local pay,reason,_,change=payment(state);if not pay then return nil,reason end
 local drawer=State.clone(state.drawer)
 for d,n in pairs(pay) do drawer[d]=drawer[d]-n end
 for d,n in pairs(Config.barya_bundle) do drawer[d]=(drawer[d] or 0)+n end
 for d,n in pairs(change) do drawer[d]=(drawer[d] or 0)+n end
 local after,why=Cash.value(drawer);if not after then return nil,why end
 if after~=before then return nil,'Barya exchange must conserve cash' end
 local valid,error=Validate.monetaryTotals(state.ledger,after,state.wallet.balance);if not valid then return nil,error end
 state.drawer=drawer;return true
end
return Restock
