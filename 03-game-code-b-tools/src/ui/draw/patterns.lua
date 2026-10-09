-- Purpose: cached original cement/checker floor and wallpaper. API: floor(x,y,w,h,variant),stripes. Dependencies: outline/layout/theme/LÖVE.
local O=require('src.ui.draw.outline'); local T=require('src.ui.theme'); local L=require('src.ui.layout'); local P={}; local cache={}; local currentDensity; local g=love.graphics
function P.stripes(x,y,w,h) O.rect(x,y,w,h,T.paper,0); for px=x,x+w,14 do g.setColor(T.blush); g.rectangle('fill',px,y,5,h) end end
function P.floor(x,y,w,h,variant) local density=L.scale*love.window.getDPIScale(); local densityKey=string.format('%.3f',density); if currentDensity~=densityKey then cache={}; currentDensity=densityKey end; local key=w..':'..h..':'..string.format('%.3f',density)..':'..tostring(variant); local canvas=cache[key]; if not canvas then canvas=g.newCanvas(math.ceil(w*density),math.ceil(h*density)); local previous=g.getCanvas(); g.push('all'); g.setCanvas(canvas); g.origin(); g.setScissor(); g.clear(T.paper); g.scale(density); local tile=62; for row=0,math.ceil(h/tile) do for col=0,math.ceil(w/tile) do local px=col*tile; local py=row*tile; local color=(row+col)%2==0 and T.blush or T.paper; O.rect(px,py,tile,tile,color,0,.65); if variant~='checker' then local centerX=px+tile/2; local centerY=py+tile/2; O.polygon({centerX,py+6,px+tile-6,centerY,centerX,py+tile-6,px+6,centerY},(row+col)%2==0 and T.paper or T.teal,.6); O.ellipse(centerX,centerY,8,8,T.blush,.6); end end end; g.setCanvas(previous); g.pop(); cache[key]=canvas end; g.setColor(1,1,1,1); g.draw(canvas,x,y,0,1/density,1/density) end
function P.clear() cache={}; currentDensity=nil end
return P



