-- Presentation-only runtime statistics; never included in saved state.
local W=require('src.ui.widgets')
local Overlay={}
function Overlay.draw()
 local stats=love.graphics.getStats()
 W.panel(0,694,1280,26,{.08,.08,.08,1})
 W.text(string.format('F1 | %d FPS | %.2f ms/frame | textures %.2f MiB',love.timer.getFPS(),love.timer.getDelta()*1000,stats.texturememory/1048576),12,699,12/(W.textScale or 1),{1,1,1,1},1256)
end
return Overlay
