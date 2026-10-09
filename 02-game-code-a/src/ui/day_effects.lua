-- Slight service-scene tint below the HUD; modal overlays stay fully readable.
local Events=require('src.systems.events')
local Theme=require('src.ui.theme')
local Effects={}
function Effects.draw(state)
 local opacity=Events.dim(state)
 if opacity<=0 then return end
 love.graphics.push('all')
 love.graphics.setColor(Theme.plum[1],Theme.plum[2],Theme.plum[3],opacity)
 love.graphics.rectangle('fill',0,94,1280,626)
 love.graphics.pop()
end
return Effects
