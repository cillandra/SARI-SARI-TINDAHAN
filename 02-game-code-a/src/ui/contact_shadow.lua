-- Purpose: load-cached flat elliptical contact shadows.
local T=require('src.ui.theme')
local Settings=require('data.tuning').ui
local M={}
local cache={}
function M.opacity(distance)
 return Settings.shadowOpacity*math.max(0,1-distance)^Settings.shadowFalloff
end
local function make(width,key)
    local w=math.max(1,math.ceil(width*Settings.shadowWidth*2))
    local h=math.max(1,math.ceil(width*Settings.shadowHeight*2))
    local data=love.image.newImageData(w,h)
    data:mapPixel(function(x,y)
        local distance=((x+.5-w/2)/(w/2))^2+((y+.5-h/2)/(h/2))^2
        return T.plum[1],T.plum[2],T.plum[3],M.opacity(math.sqrt(distance))
    end)
    local image=love.graphics.newImage(data);data:release()
    cache[key or width]=image;return image
end
function M.preload()
    local Assets=require('src.ui.assets')
    local Props=require('src.ui.draw.counter_props')
    for _,r in ipairs(require('src.ui.counter_layout').list()) do
        local art=Props.geometry(r,Assets.get('prop_'..r.id),1)
        make(art.w,r.id)
    end
end
function M.draw(cx,baseline,width,id)
    local image=cache[id or width] or make(width,id)
    local w,h=image:getDimensions()
    local g=love.graphics
    g.push('all');g.setColor(1,1,1,1)
    local factor=width*Settings.shadowWidth/w
    g.draw(image,cx-w*factor/2,baseline-4-h*factor/2,0,factor,factor);g.pop()
end
return M
