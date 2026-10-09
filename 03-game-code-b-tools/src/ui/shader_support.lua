-- Purpose: preserve a usable visual fallback when shader compilation is unavailable.
local M={}
function M.create(factory,source)
 local ok,result=pcall(factory,source)
 if ok then return result end
 return false,tostring(result)
end
return M
