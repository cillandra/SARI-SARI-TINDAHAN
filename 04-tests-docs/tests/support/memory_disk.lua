-- Purpose: controlled I/O boundary for real persistence tests/smoke. API: new() -> disk with files/failure/read/write/rename. Dependencies: Lua only.
local Memory={}
function Memory.new()
    local disk={files={}}
    function disk.read(path) return disk.files[path],disk.files[path] and nil or 'Missing' end
    function disk.write(path,data)
        if disk.failure=='write' then return nil,'Injected write failure' end
        disk.files[path]=data
        return true
    end
    function disk.rename(from,to)
        if disk.failure=='promote' and from:find('.tmp.',1,true) then return nil,'Injected promotion failure' end
        if not disk.files[from] or disk.files[to] then return nil,'Rename failed' end
        disk.files[to]=disk.files[from]
        disk.files[from]=nil
        return true
    end
    return disk
end
return Memory
