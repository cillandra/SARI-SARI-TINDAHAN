local T=require('src.ui.theme')
local Loading={}
function Loading.draw()
 love.graphics.clear(T.paper)
 local w,h=love.graphics.getDimensions()
 love.graphics.setColor(T.maroon)
 love.graphics.printf('Tindahan\nPreparing the shop...',0,h/2-30,w,'center')
end
return Loading
