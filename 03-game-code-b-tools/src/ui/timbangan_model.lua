-- Read-only workbench queries. No inventory or cash mutations.
local Products=require('data.products')
local Tuning=require('data.tuning')
local Inventory=require('src.systems.inventory')
local Portions=require('src.systems.portions')
local Requests=require('src.systems.measured_requests')
local F=require('src.ui.format')
local M={}
M.bins={}
for _,p in ipairs(Products.list) do if p.timbangan then M.bins[p.timbangan.slot]=p end end
function M.line(a,pid)
 local q=a:quote()
 if q then for i,line in ipairs(q.lines) do if line.productId==pid then return line,i end end end
end
function M.open(a)
 local q=a:quote()
 if q then for _,line in ipairs(q.lines) do if line.measured and not line.confirmed and Products.byId[line.productId].timbangan then return line end end end
end
function M.model(a)
 local prep=a.state.phase=='preparation'
 local p=Products.byId[prep and a.prepackProduct or a.portionProduct] or Products.byId.sugar
 local line,index=M.line(a,p.id)
 local target=prep and (a.packSize or Tuning.mvp.measuredQuantity) or line and line.targetQuantity or 0
 local actual=prep and a.packQuantity or line and line.actualQuantity or 0
 local lower,upper=Portions.bounds(a.state,target)
 if prep then lower=target;upper=target end
 local reason
 if a.state.paused then reason='Resume first.'
 elseif a.portionSwitch then reason='Finish the bin choice first.'
 elseif not prep and not line then reason='This bin is not in the current order.'
 elseif line and line.spillLocked then reason='Spilled: press Ulitin before pouring.'
 elseif line and line.confirmed then reason='This portion is already sealed.'
 elseif not prep and a.state.retail and a.state.retail.tender then reason='Payment is already staged.'
 elseif target<=0 then reason='Choose a requested portion first.'
 elseif actual<lower then reason='Underfilled: add more before sealing.'
 elseif actual>upper then reason='Overfilled: remove some before sealing.' end
 local stock=Inventory.available(a.state,p.id)
 local ready=0
 for _,b in ipairs(a.state.inventory[p.id] or {}) do if b.prepared and b.expiresDay>a.state.day then ready=ready+b.quantity end end
 local mode=a.timbanganMode or p.timbangan and p.timbangan.mode or 'repack'
 local choices={}
 if mode=='weigh' then
  for _,size in ipairs(p.portionSizes) do choices[#choices+1]={requestMode='quantity',requestValue=size,quantity=size,label=size..' '..p.saleUnit} end
 else
  for _,option in ipairs(Requests.options(a.state,p,mode)) do
   option.label=option.requestMode=='peso' and F.money(option.requestValue)
    or p.saleUnit=='g' and (option.quantity==250 and '1/4 kg' or '1/2 kg')
    or option.quantity..' '..p.saleUnit
   choices[#choices+1]=option
  end
 end
 local requestLabel=line and line.requestMode=='peso' and F.money(line.requestValue)..' • ' or ''
 return {product=p,line=line,index=index,prep=prep,target=target,actual=actual,reason=reason,choices=choices,requestLabel=requestLabel,
  bagCount=math.max(1,math.ceil(target/(a.packSize or Tuning.mvp.measuredQuantity))),bagSize=a.packSize or Tuning.mvp.measuredQuantity,
  mode=mode,stock=stock,ready=ready,lower=lower,upper=upper,tolerance=upper-target}
end
return M
