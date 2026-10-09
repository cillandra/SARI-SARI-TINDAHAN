-- Purpose: original shop foreground/window props. API: plant,lamp,sign,awning. Dependencies: shapes/outline/materials/theme/widgets.
local O=require('src.ui.draw.outline'); local C=require('src.ui.color'); local T=require('src.ui.theme'); local W=require('src.ui.widgets'); local P={}; local g=love.graphics
function P.plant(x,y,scale) g.push(); g.translate(x,y); g.scale(scale or 1); O.rect(-21,-8,42,40,T.paper,8); O.line({0,-8,0,-105},T.darkwood,3); for i=0,4 do local by=-23-i*18; local dir=i%2==0 and -1 or 1; O.ellipse(dir*18,by-6,19,8,i%2==0 and T.sage or T.teal); O.line({0,by,dir*31,by-6},C.shade(T.sage),1) end; g.pop() end
function P.lamp(x,y) O.line({x,y,x,y+30},T.ink,1); O.polygon({x-22,y+30,x+22,y+30,x+35,y+52,x-35,y+52},T.paper); O.ellipse(x,y+52,34,6,T.mustard,1) end
function P.sign(x,y) O.line({x+15,y-32,x+15,y},T.ink,.9); O.line({x+116,y-32,x+116,y},T.ink,.9); O.rect(x,y,132,51,T.maroon,7); W.text('BUKAS',x+9,y+12,23,T.paper,114,'center') end
function P.awning(x,y,w) for i=0,11 do local color=i%2==0 and T.dustyrose or T.paper; O.rect(x+i*w/12,y,w/12,31,color,0,.7); O.ellipse(x+(i+.5)*w/12,y+31,w/24,10,color,.7) end end
return P
