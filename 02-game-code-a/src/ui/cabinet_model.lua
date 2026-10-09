-- Cabinet queries and pointer dwell only, no economic mutations.
local Products=require('data.products')
local Inventory=require('src.systems.inventory')
local Tuning=require('data.tuning')
local M={slots={}}
for section=1,6 do M.slots[section]={} end
for _,p in ipairs(Products.list) do M.slots[p.cabinet.section][p.cabinet.slot]=p end
function M.model(a)
 local picked={};local quote=a:quote()
 if quote then for _,line in ipairs(quote.lines) do if line.productId then picked[line.productId]=line end end end
 return {picked=picked,items=quote and quote.lines or {},count=quote and #quote.lines or 0,requested=a.state.queue[1] and #a.state.queue[1].lines or 0}
end
function M.stock(state,p)
 local stock=Inventory.available(state,p.id)
 local baseline=Tuning.startingStock[p.id] or (p.saleUnit=='piece' and 10 or 1000)
 return stock,math.max(0,math.min(1,stock/baseline))
end
function M.hover(a,id,clock)
 if not id then a.cabinetHover=nil;return false end
 if not a.cabinetHover or a.cabinetHover.id~=id then a.cabinetHover={id=id,at=clock};return false end
 return clock-a.cabinetHover.at>=Tuning.ui.cabinetTooltipSeconds
end
return M
