-- Purpose: restrained flat material strokes and shadows. API: wood,shadow,steel. Dependencies: outline/color/theme/LÖVE.
local O=require('src.ui.draw.outline'); local C=require('src.ui.color'); local T=require('src.ui.theme'); local M={}; local g=love.graphics
function M.shadow(x,y,w,h,opacity) g.setColor(T.plum[1],T.plum[2],T.plum[3],opacity or .16); g.ellipse('fill',x+w/2,y+h/2,w/2,h/2) end
function M.wood(x,y,w,h,color,vertical) color=color or T.wood; O.rect(x,y,w,h,color,3); local count=vertical and math.ceil(w/94) or math.ceil(h/40); for i=1,count-1 do local position=vertical and x+i*w/count or y+i*h/count; O.line(vertical and {position,y,position,y+h} or {x,position,x+w,position},C.darken(color,.17),1); end; for i=1,14 do local px=x+(i*89%251)/251*w; local py=y+(i*43%97)/97*h; O.line({px,py,math.min(x+w-5,px+18+(i%3)*9),py+1},C.darken(color,.09),.8) end end
function M.steel(x,y,w,h) O.rect(x,y,w,h,T.steel,5); O.rect(x+8,y+8,w-16,h-16,T.bininner,2); O.line({x+5,y+4,x+w-5,y+4},T.paper,1) end
return M
