-- Purpose: guarded PNG preload/cache with strict design-size drawing and explicit procedural fallback.
local Manifest=require('data.assets'); local Rules=require('src.ui.asset_rules')
local Assets={}; local cache,failures,warned={},{},{}
local function fallback(id,reason)
    failures[id]=reason
    if not warned[id] then print('ASSET FALLBACK '..tostring(id)..': '..reason); warned[id]=true end
    return nil,reason
end
function Assets.inspect(spec)
    if not love or not love.filesystem or not love.image then return nil,'PNG image/filesystem modules unavailable' end
    if not love.filesystem.getInfo(spec.path,'file') then return nil,'missing '..spec.path..'; '..(spec.deferredReason or spec.fallbackReason or 'using procedural drawing') end
    local ok,data=pcall(love.image.newImageData,spec.path)
    if not ok then return nil,'PNG decode failed for '..spec.path..': '..tostring(data) end
    local meta=Rules.metadata(data,spec.sourceScale)
    return {imageData=data,bounds=meta.bounds,spec=spec,meta=meta}
end
function Assets.get(id)
    local spec=Manifest.byId[id]
    if not spec then return fallback(id,'unknown manifest id; using procedural drawing') end
    id=spec.id
    if cache[id] then return cache[id] end
    if failures[id] then return nil,failures[id] end
    local record,reason=Assets.inspect(spec)
    if not record then return fallback(id,reason) end
    local base
    if spec.variantOf then local baseRecord=Assets.get(spec.variantOf); base=baseRecord and baseRecord.meta end
    local valid,why=Rules.validate(spec,record.meta,base)
    if not valid then record.imageData:release(); return fallback(id,why) end
    if not love.graphics then record.imageData:release(); return fallback(id,'graphics unavailable; PNG cannot be uploaded') end
    local ok,image=pcall(love.graphics.newImage,record.imageData,{mipmaps=true})
    if not ok then record.imageData:release(); return fallback(id,'texture upload failed: '..tostring(image)) end
    image:setFilter('linear','linear'); image:setMipmapFilter('linear')
    record.image=image; cache[id]=record; return record
end
function Assets.preload()
    local diagnostics={}; local bytes=0
    for _,spec in ipairs(Manifest.list) do
        local record,reason=Assets.get(spec.id)
        diagnostics[#diagnostics+1]={id=spec.id,status=record and 'PNG' or 'PROCEDURAL',reason=reason}
        if record then bytes=bytes+spec.width*spec.height*4*4/3 end
    end
    Assets.estimatedTextureBytes=math.ceil(bytes)
    local stats=love.graphics and love.graphics.getStats and love.graphics.getStats()
    Assets.textureBytes=stats and stats.texturememory or nil
    if Assets.textureBytes then print(string.format('ASSET TEXTURES %.2f MiB reported by LOVE; RGBA8 mip-chain estimate %.2f MiB',Assets.textureBytes/1048576,Assets.estimatedTextureBytes/1048576))
    else print(string.format('ASSET TEXTURES RGBA8 mip-chain estimate %.2f MiB; actual allocation unavailable',Assets.estimatedTextureBytes/1048576)) end
    return diagnostics
end
function Assets.draw(id,x,y,w,h,alpha)
    local record,reason=Assets.get(id); if not record then return false,reason end
    local size=record.spec.designSize
    if (w and math.abs(w-size.w)>.0001) or (h and math.abs(h-size.h)>.0001) then return false,'draw size for '..id..' must be declared '..size.w..'x'..size.h..'; transform the canvas explicitly for animation' end
    local g=love.graphics; g.push('all'); g.setColor(1,1,1,alpha or 1); g.draw(record.image,x,y,0,.5,.5); g.pop(); return true
end
return Assets
