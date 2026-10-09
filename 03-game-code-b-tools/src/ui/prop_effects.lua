-- Purpose: cached frontend contrast effects and phone display cover; no game state.
local T=require('src.ui.theme')
local U=require('data.tuning').ui
local M={}
local g=love.graphics
local ShaderSupport=require('src.ui.shader_support')
local outline_cache,pool_cache={},{}
local vignette,vignette_key
local pop,mask
local function shaders()
    if pop~=nil then return end
    local result,reason=ShaderSupport.create(g.newShader, [[
        extern number brightness;
        extern number saturation;
        vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen) {
            vec4 p=Texel(texture,uv);
            number gray=dot(p.rgb,vec3(0.2126,0.7152,0.0722));
            p.rgb=clamp(mix(vec3(gray),p.rgb,saturation)*brightness,0.0,1.0);
            return p*color;
        }
    ]])
    if result then pop=result;print('CONTRAST SHADER PASS')
    else pop=false;print('CONTRAST SHADER FALLBACK '..tostring(reason)) end
    mask=ShaderSupport.create(g.newShader,[[
        vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen) {
            return vec4(1.0,1.0,1.0,Texel(texture,uv).a)*color;
        }
    ]])
end
local function image_from_canvas(canvas)
    local data=canvas:newImageData()
    local image=g.newImage(data,{mipmaps=true})
    image:setFilter('linear','linear');data:release();canvas:release()
    return image
end
local function cover_phone(record)
    local b=record.bounds
    local canvas=g.newCanvas(1024,1024)
    g.push('all');g.setCanvas(canvas);g.origin();g.setScissor();g.clear(0,0,0,0)
    g.setBlendMode('replace','alphamultiply');g.setColor(1,1,1,1);g.draw(record.image)
    g.setBlendMode('alpha','alphamultiply')
    g.translate(b.x,b.y);g.scale(2)
    local w,h=b.w/2,b.h/2
    local O=require('src.ui.draw.outline')
    O.rect(w*.09,h*.08,w*.83,h*.84,T.paper,5,1.2)
    require('src.ui.widgets').text('TindaPay',w*.10,h*.20,14,T.ink,w*.80,'center')
    O.rect(w*.24,h*.49,w*.55,h*.24,T.sage,3,1)
    O.rect(w*.60,h*.55,w*.23,h*.10,T.mustard,2,1)
    g.flushBatch();g.setCanvas();g.pop()
    record.image=image_from_canvas(canvas)
end
local function outline(record)
    local canvas=g.newCanvas(1024,1024)
    g.push('all');g.setCanvas(canvas);g.origin();g.setScissor();g.clear(0,0,0,0)
    local source=record.image
    if not mask then
        local alpha=love.image.newImageData(record.imageData:getDimensions())
        alpha:mapPixel(function(x,y)
            local _,_,_,a=record.imageData:getPixel(x,y)
            return 1,1,1,a
        end)
        source=g.newImage(alpha);alpha:release()
    end
    g.setShader(mask or nil);g.setColor(1,1,1,1)
    for i=0,31 do
        local angle=i*math.pi/16
        g.draw(source,math.cos(angle)*U.outlineWidth*2,math.sin(angle)*U.outlineWidth*2)
    end
    g.draw(source);g.flushBatch();g.setCanvas();g.pop()
    if source~=record.image then source:release() end
    return image_from_canvas(canvas)
end
local function pool(radius)
    local side=math.ceil(radius*4)
    local data=love.image.newImageData(side,side)
    data:mapPixel(function(x,y)
        local d=math.sqrt((x+.5-side/2)^2+(y+.5-side/2)^2)/(side/2)
        return T.cream[1],T.cream[2],T.cream[3],U.poolOpacity*math.max(0,1-d)^U.poolFalloff
    end)
    local image=g.newImage(data);data:release();return image
end
function M.preload()
    shaders()
    local Assets=require('src.ui.assets')
    for _,d in ipairs(require('data.navigation').counter) do
        local record=Assets.get('prop_'..d.id)
        if record then
            if d.id=='phone' then cover_phone(record) end
            outline_cache[d.id]=outline(record)
            local rect=require('src.ui.counter_layout').get(d.id)
            local art=require('src.ui.draw.counter_props').geometry(rect,record,1)
            record.poolRadius=math.max(art.w,art.h)*U.poolRadius
            pool_cache[d.id]=pool(record.poolRadius)
        end
    end
end
function M.background(record)
    if pop then
        pop:send('brightness',1);pop:send('saturation',U.backgroundSaturation);g.setShader(pop)
    end
    require('src.ui.full_bleed').draw(record)
    g.setShader()
    local area=require('src.ui.full_bleed').coverage(g.getDimensions())
    g.setColor(T.cream[1],T.cream[2],T.cream[3],record.spec.id=='scene_counter_bg_street' and U.veilStreet or U.veilInterior)
    g.rectangle('fill',area.x,area.y,area.w,area.h)
end
function M.behind(id,art,record,enabled,hovered)
    local radius=record and record.poolRadius or math.max(art.w,art.h)*U.poolRadius
    pool_cache[id]=pool_cache[id] or pool(radius)
    local image=pool_cache[id]
    g.push('all');g.setColor(1,1,1,1)
    g.draw(image,art.x+art.w/2-radius,art.y+art.h/2-radius,0,.5,.5)
    local silhouette=outline_cache[id]
    if silhouette and record then
        local tint=hovered and T.mustard or T.propOutline
        local opacity=enabled and 1 or .55
        g.setBlendMode('alpha','premultiplied')
        g.setColor(tint[1]*opacity,tint[2]*opacity,tint[3]*opacity,opacity)
        g.draw(silhouette,art.x-record.bounds.x/2*art.factor,
            art.y-record.bounds.y/2*art.factor,0,art.factor/2,art.factor/2)
    end
    g.pop()
end
function M.tint(id)
    if not pop then return end
    local settings=U.popTint[id] or U.popTint.default
    pop:send('brightness',settings.brightness);pop:send('saturation',settings.saturation)
    g.setShader(pop)
end
function M.vignette()
    local w,h=g.getDimensions()
    local key=w..'x'..h
    if vignette_key~=key then
        if vignette then vignette:release() end
        local data=love.image.newImageData(w,h)
        data:mapPixel(function(x,y)
            local edge=math.max(math.abs(2*x/w-1),math.abs(2*y/h-1))
            local alpha=U.vignetteOpacity*math.max(0,(edge-.60)/.40)^2
            return T.plum[1],T.plum[2],T.plum[3],alpha
        end)
        vignette=g.newImage(data);data:release();vignette_key=key
    end
    local L=require('src.ui.layout')
    g.push('all');g.setColor(1,1,1,1)
    g.draw(vignette,-L.x/L.scale,-L.y/L.scale,0,1/L.scale,1/L.scale);g.pop()
end
return M
