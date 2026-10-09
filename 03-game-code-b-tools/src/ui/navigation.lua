local Data=require('data.navigation')
local N={}
function N.status(d,state,features)
 if not d then return {enabled=false,reason='Unknown destination.'} end
 if state.paused then return {enabled=false,reason='Resume the shop first.'} end
 if state.phase~='service' then return {enabled=false,reason='Open the store first.'} end
 if state.day<(d.unlock or 1) then return {enabled=false,reason=d.lockedHint or ('Bukas sa Araw '..d.unlock)} end
 if d.feature and not features[d.feature] then return {enabled=false,reason=d.label..' services are coming soon.'} end
 return {enabled=true,reason=d.hint}
end
function N.validate(views,features)
 local order={'cash_drawer','timbangan','shelf_cabinet','phone'}
 if #Data.counter~=4 then return nil,'Expected four counter props' end
 for i,id in ipairs(order) do
  local d=Data.counter[i]
  if d.id~=id or d.order~=i or not d.layoutSlot then return nil,'Counter order mismatch' end
  if not d.feature or features[d.feature] then if not views[d.target] then return nil,'Missing view: '..d.target end end
 end
 for key=1,5 do if not Data.shortcuts[tostring(key)] then return nil,'Missing shortcut '..key end end
 return true
end
return N
