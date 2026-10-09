-- Click/hold/drag coordinator. Fulfilment uses existing App.pick only.
local Products=require('data.products')
local Inventory=require('src.systems.inventory')
local Tuning=require('data.tuning').ui
local L=require('src.ui.cabinet_layout')
local C={}
local function enabled(a) return a.view=='shelves' and a.state.phase=='service' and not a.state.paused and not a.ticketOpen and not a.portionSwitch end
function C.begin(a,pid,x,y)
 if not enabled(a) or not Products.byId[pid] then return nil end
 if Inventory.available(a.state,pid)<=0 and not require('src.ui.cabinet_model').model(a).picked[pid] then return nil end
 if a.state.retail and a.state.retail.tender then a:notify('Payment is already staged.');return nil end
 if type(x)~='number' or type(y)~='number' then return nil end
 a.cabinetDrag={productId=pid,startX=x,startY=y,x=x,y=y,at=a.uiClock,moved=false}
 return true
end
function C.move(a,x,y)
 local d=a.cabinetDrag;if not d then return end
 d.x=x;d.y=y
 if (x-d.startX)^2+(y-d.startY)^2>=Tuning.cabinetDragDistance^2 then d.moved=true end
end
function C.release(a,x,y)
 local d=a.cabinetDrag;if not d then return nil end
 C.move(a,x,y);a.cabinetDrag=nil
 if not enabled(a) then return nil end
 if not d.moved or L.contains(L.basket,x,y) then a:pick(d.productId);return true end
 a:notify('Return the item to the cabinet, or drop it in the counter basket.')
 return nil
end
function C.update(a)
 local d=a.cabinetDrag
 if not d then return end
 if not enabled(a) then a.cabinetDrag=nil;return end
 if not d.moved and a.uiClock-d.at>=Tuning.cabinetHoldSeconds then a.cabinetDrag=nil;a:pick(d.productId) end
end
return C
