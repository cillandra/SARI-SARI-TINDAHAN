-- Purpose: pointed cream dialogue and lettered reply buttons. API: draw(x,y,w,h,tailX),reply(label,badge,x,y,w,callback). Dependencies: outline/widgets/theme.
local O=require('src.ui.draw.outline'); local W=require('src.ui.widgets'); local T=require('src.ui.theme'); local B={}
function B.draw(x,y,w,h,tailX) O.rect(x,y,w,h,T.paper,18,1.4); O.polygon({tailX or x+45,y+h-1,(tailX or x+45)+22,y+h-1,(tailX or x+45)-9,y+h+26},T.paper,1.4); W.color(T.paper); love.graphics.rectangle('fill',tailX or x+45,y+h-3,22,5) end
function B.reply(label,badge,x,y,w,callback) W.button(label,x,y,w,48,callback,T.paper); O.ellipse(x+w-15,y+43,12,12,T.dustyrose,1); W.text(badge,x+w-23,y+33,15,T.ink,16,'center') end
return B
