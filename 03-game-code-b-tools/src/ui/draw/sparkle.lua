-- Purpose: original four-point attention accent. API: draw(x,y,size,clock). Dependencies: outline/theme/LÖVE.
local O=require('src.ui.draw.outline'); local T=require('src.ui.theme'); local S={}
function S.draw(x,y,size,clock) local pulse=1+.06*math.sin((clock or 0)*2); size=size*pulse; O.polygon({x,y-size,x+size*.25,y-size*.25,x+size*.65,y,x+size*.25,y+size*.25,x,y+size,x-size*.25,y+size*.25,x-size*.65,y,x-size*.25,y-size*.25},T.mustard,1) end
return S
