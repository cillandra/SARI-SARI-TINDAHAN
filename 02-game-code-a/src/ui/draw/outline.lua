-- Purpose: thin related-color contour primitives. API: rect,ellipse,polygon,line. Dependencies: color/LÖVE graphics.
local Color=require('src.ui.color'); local O={}; local g=love.graphics
local function stroke(color,width) g.setColor(Color.shade(color)); g.setLineWidth(width or 1.25); g.setLineJoin('bevel') end
function O.rect(x,y,w,h,color,radius,width) g.setColor(color); g.rectangle('fill',x,y,w,h,radius or 5,radius or 5); stroke(color,width); g.rectangle('line',x,y,w,h,radius or 5,radius or 5) end
function O.ellipse(x,y,rx,ry,color,width) g.setColor(color); g.ellipse('fill',x,y,rx,ry); stroke(color,width); g.ellipse('line',x,y,rx,ry) end
function O.polygon(points,color,width) g.setColor(color); g.polygon('fill',points); stroke(color,width); g.polygon('line',points) end
function O.line(points,color,width) g.setColor(color); g.setLineWidth(width or 1.25); g.setLineJoin('bevel'); g.line(points) end
function O.shape(fill,drawFn,width) g.setColor(fill); drawFn('fill'); stroke(fill,width); drawFn('line') end
return O


