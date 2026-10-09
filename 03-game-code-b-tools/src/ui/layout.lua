-- Purpose: shared design-canvas transformation. API: resize,toCanvas,begin,finish. Dependencies: LÖVE graphics.
local L={width=1280,height=720,scale=1,x=0,y=0}
function L.resize(w,h) L.scale=math.min(w/L.width,h/L.height); L.x=(w-L.width*L.scale)/2; L.y=(h-L.height*L.scale)/2 end
function L.toCanvas(x,y,w,h) if w then L.resize(w,h) end; x=(x-L.x)/L.scale; y=(y-L.y)/L.scale; return x,y,x>=0 and y>=0 and x<=L.width and y<=L.height end
function L.begin() L.resize(love.graphics.getDimensions()); love.graphics.push(); love.graphics.translate(L.x,L.y); love.graphics.scale(L.scale) end
function L.finish() love.graphics.pop() end
return L
