-- Purpose: smoke-only check for newly created/reassigned Lua globals. API: capture(),verify(snapshot). Dependencies: Lua standard library only.
local Check={}
function Check.capture()
    local snapshot={}
    for key,value in pairs(_G) do snapshot[key]=value end
    return snapshot
end
function Check.verify(snapshot)
    for key,value in pairs(_G) do
        assert(snapshot[key]~=nil,'Unexpected global: '..tostring(key))
        assert(snapshot[key]==value,'Reassigned global: '..tostring(key))
    end
    for key,value in pairs(snapshot) do
        assert(_G[key]==value,'Removed or reassigned global: '..tostring(key))
    end
end
return Check
