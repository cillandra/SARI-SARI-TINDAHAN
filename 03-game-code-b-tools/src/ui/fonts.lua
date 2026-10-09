-- Purpose: density-aware cached built-in fonts. API: get(size),set(size). Dependencies: layout,LÖVE only; no external font files.
local Layout=require('src.ui.layout'); local F={}; local cache={}
function F.get(size) local density=Layout.scale*(love.window.getDPIScale() or 1); local key=size..':'..string.format('%.3f',density); if not cache[key] then cache[key]=love.graphics.newFont(size,'normal',density) end; return cache[key] end
function F.set(size) love.graphics.setFont(F.get(size)) end
function F.clear() cache={} end
return F
