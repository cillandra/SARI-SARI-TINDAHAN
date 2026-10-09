-- Workbench orchestration: all stock mutations go through existing app commands.
local Products=require('data.products')
local Customers=require('src.systems.customers')
local Tuning=require('data.tuning')
local M=require('src.ui.timbangan_model')
local Requests=require('src.systems.measured_requests')
local C={}
local function requested_mode(a,pid)
 local p=Products.byId[pid]
 if a.state.phase~='preparation' then
  local customer=Customers.current(a.state)
  if customer then for _,request in ipairs(customer.lines) do
   if request.productId==pid and (request.type=='weigh' or request.type=='repack' or request.type=='pour') then return request.type end
  end end
 end
 return p.timbangan.mode
end
local function choose(a,pid,mode)
 local p=Products.byId[pid]
 if a.state.phase=='preparation' then
  a.prepackProduct=pid;a.packSize=(p.requestSizes or p.portionSizes)[1];a.packQuantity=0
  a.packChoiceMode=nil;a.packChoiceValue=nil
 else
  local c=Customers.current(a.state)
  local requested
  if c then for _,r in ipairs(c.lines) do if r.productId==pid then requested=r end end end
  if requested and not M.line(a,pid) then
   if not a.state.retail and not a:command('beginRetail',c.id) then return nil end
   if not a:command('targetPortion',c.id,pid,requested.requestValue or requested.quantity,requested.requestMode or 'quantity') then return nil end
  end
  if a.portionProduct~=pid then
   a.packChoiceMode=nil;a.packChoiceValue=nil
   local line=M.line(a,pid)
   a.packSize=Tuning.mvp.measuredQuantity
   if line then a.packSize=p.portionSizes[#p.portionSizes];for _,size in ipairs(p.portionSizes) do if size>=line.targetQuantity then a.packSize=size;break end end end
  end
  if requested and requested.requestMode=='peso' and a.portionProduct~=pid then
   a.packSize=requested.quantity;a.packChoiceMode='peso';a.packChoiceValue=requested.requestValue
  end
  a.portionProduct=pid
 end
 a.timbanganMode=mode or requested_mode(a,pid)
 a.pouring=false;a.pourElapsed=0;a.pourRemainder=0
 return true
end
function C.open(a)
 if a.state.paused or a.portionSwitch then return nil end
 local open=M.open(a)
 local pid=open and open.productId
 if not pid then
  local c=Customers.current(a.state)
  if c then for _,r in ipairs(c.lines) do
   local line=M.line(a,r.productId)
   if r.measured and Products.byId[r.productId].timbangan and (not line or not line.confirmed) then pid=r.productId;break end
  end end
 end
 if not choose(a,pid or 'sugar') then return nil end
 return a:go('timbangan')
end
function C.select(a,pid)
 local p=Products.byId[pid]
 if a.state.paused or not p or not p.timbangan or a.portionSwitch then return nil end
 local current=a.state.phase=='preparation' and a.prepackProduct or a.portionProduct
 if pid==current then a.timbanganMode=requested_mode(a,pid);return true end
 local open=M.open(a)
 if pid~=current and (open and open.productId~=pid or a.state.phase=='preparation' and a.packQuantity>0) then
  a.portionSwitch={destination=pid,productId=open and open.productId or current,
   saleId=a.state.retail and a.state.retail.id,reference=open and open.reservation,
   prep=a.state.phase=='preparation'}
  a.pouring=false;a.pourElapsed=0;a.pourRemainder=0
  require('src.ui.widgets').items={}
  return nil
 end
 return choose(a,pid)
end
function C.resolve(a,action)
 local pending=a.portionSwitch
 if a.state.paused or not pending then return nil end
 if action=='continue' then a.portionSwitch=nil;require('src.ui.widgets').items={};return true end
 if action~='discard' then return nil end
 if not pending.prep and not a:command('discardPortion',pending.saleId,pending.reference) then return nil end
 a.portionSwitch=nil
 require('src.ui.widgets').items={}
 if choose(a,pending.destination) then return a:go('timbangan') end
 return nil
end
local function select_size(a,p,size,mode,value)
 if a.state.paused or a.portionSwitch then return nil end
 local prep=a.state.phase=='preparation'
 local line=M.line(a,p.id)
 if prep and a.packQuantity>0 then a:notify('Seal or discard this portion before changing the bag.');return nil end
 if not prep and (not line or line.confirmed or a.state.retail.tender or size<line.targetQuantity and not (line.targetQuantity>p.portionSizes[#p.portionSizes] and size==p.portionSizes[#p.portionSizes])) then a:notify('Choose a bag that fits the requested portion.');return nil end
 a.packSize=size;a.packChoiceMode=mode;a.packChoiceValue=value
 return true
end
function C.size(a,size)
 local p=Products.byId[a.state.phase=='preparation' and a.prepackProduct or a.portionProduct]
 if not p then return nil end
 for _,value in ipairs(p.portionSizes) do
  if value==size then return select_size(a,p,size,'quantity',value) end
 end
 return nil
end
function C.option(a,mode,value)
 if mode=='quantity' then return C.size(a,value) end
 if mode~='peso' then return nil end
 local p=Products.byId[a.state.phase=='preparation' and a.prepackProduct or a.portionProduct]
 if not p or not p.timbangan then return nil end
 local allowed=false;for _,amount in ipairs(p.pesoPortions) do if value==amount then allowed=true end end
 if not allowed then return nil end
 local size=Requests.resolve(a.state.prices[p.id],p,value,mode)
 if not size then return nil end
 return select_size(a,p,size,mode,value)
end
function C.confirm(a)
 local m=M.model(a)
 if m.reason then a:notify(m.reason);return nil end
 if m.prep then
  a.packSerial=a.packSerial+1
  if not a:command('prepack','ui:pack:'..a.state.day..':'..a.state.ids.nextBatch..':'..a.packSerial,m.product.id,m.actual) then return nil end
  a.packQuantity=0;a.feedback:place(m.product.id);a:notify(m.actual..'-unit pack sealed.');return true
 end
 local c=Customers.current(a.state)
 if c and a:command('confirmPortion',c.id,m.index) then a.feedback:place(m.product.id);return a:go('counter') end
 return nil
end
return C
