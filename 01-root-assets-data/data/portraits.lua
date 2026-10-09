-- Purpose: frontend-only portrait roles; domain/customer identities remain unchanged.
local Portraits={roles={'nanay_bayong','tricycle_driver','school_kid','tambay','lola_rosary','teacher','nurse','delivery_rider','vendor_basket','tanod','office_worker','suki_aunt'}}
function Portraits.role(id)
    if type(id)=='string' then for _,role in ipairs(Portraits.roles) do if role==id then return role end end end
    if type(id)=='number' then return Portraits.roles[(id-1)%#Portraits.roles+1] end
    local n=tonumber(tostring(id):match('(%d+)$'))
    if n then return Portraits.roles[(n-1)%#Portraits.roles+1] end
    local hash=0; for byte in tostring(id):gmatch('.') do hash=(hash*31+byte:byte())%997 end
    return Portraits.roles[hash%#Portraits.roles+1]
end
function Portraits.assetId(id,expression)
    if expression==nil or expression=='neutral' then expression='waiting' end
    if expression~='happy' and expression~='waiting' and expression~='impatient' and expression~='angry' then expression='waiting' end
    return 'char_'..Portraits.role(id)..'_'..expression
end
return Portraits
