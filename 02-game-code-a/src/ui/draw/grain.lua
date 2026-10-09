-- Purpose: fixed-seed ImageData grain with baked 24% strength, cached at current density. API: draw(x,y,w,h,opacity=.24),clear(). Dependencies: layout/LÖVE; no texture files.
local Layout=require('src.ui.layout'); local G={}; local cached,key; local g=love.graphics
local function tile(opacity) local density=Layout.scale*love.window.getDPIScale(); local densityKey=string.format('%.3f:%.3f',density,opacity); if key==densityKey then return cached,density end; local side=math.max(32,math.ceil(64*density)); local data=love.image.newImageData(side,side); local rng=love.math.newRandomGenerator(83492791); data:mapPixel(function() local raw=.91+rng:random()*.09; local shade=1+(raw-1)*opacity; return shade,shade,shade,1 end); cached=g.newImage(data); key=densityKey; return cached,density end
function G.draw(x,y,w,h,opacity) local image,density=tile(opacity or .24); local side=image:getWidth()/density; g.push('all'); g.setScissor(x*Layout.scale+Layout.x,y*Layout.scale+Layout.y,w*Layout.scale,h*Layout.scale); g.setBlendMode('multiply','premultiplied'); g.setColor(1,1,1,1); for py=y,y+h,side do for px=x,x+w,side do g.draw(image,px,py,0,1/density,1/density) end end; g.pop() end
function G.clear() cached=nil; key=nil end
return G

