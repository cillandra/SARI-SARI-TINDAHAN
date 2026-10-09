-- Purpose: copy confirmed raw PNGs uniformly onto exact 2x canvases; never modify originals.
local Manifest=require('data.assets'); local Mapping=require('data.asset_mapping'); local Rules=require('src.ui.asset_rules')
local Normalize={}
local repair=false
for _,value in ipairs(arg or {}) do if value=='--repair-m1' then repair=true end end
local function close(data) if data and data.release then data:release() end end
local function read(path)
    local ok,data=pcall(love.image.newImageData,path)
    if not ok then return nil,'PNG decode failed '..path..': '..tostring(data) end
    return data
end
local function writeNew(path,bytes)
    local existing=io.open(path,'rb'); if existing then existing:close(); if not repair then return nil,'refusing to overwrite existing output '..path end end
    local file,why=io.open(path,'wb'); if not file then return nil,'cannot write source-local output '..path..': '..tostring(why) end
    local written,errorMessage=file:write(bytes); local closed,closeError=file:close()
    if not written or not closed then return nil,'PNG write failed '..path..': '..tostring(errorMessage or closeError) end
    return true
end
local function matching(spec,meta,source,scale)
    local ok=Rules.validate(spec,meta); if not ok then return false end
    local b=source.bounds
    if spec.fullBleed then return meta.width==spec.width and meta.height==spec.height end
    return math.abs(meta.bounds.w-b.w*scale)<=4 and math.abs(meta.bounds.h-b.h*scale)<=4
end
function Normalize.run()
    if not love.graphics then print('NORMALIZE FAIL: graphics context required for mipmap linear resampling'); return 1 end
    local sourceRoot=love.filesystem.getSource()
    if not love.filesystem.getInfo('assets_raw','directory') then print('NORMALIZE FAIL: run from editable project with assets_raw and existing assets/img folders'); return 1 end
    local _,existing,errors=require('tools.check_assets').collect()
    if #errors>0 and not repair then for _,why in ipairs(errors) do print('NORMALIZE REFUSE '..why) end; return 1 end
    if repair then for id,meta in pairs(existing) do if not Rules.validate(Manifest.byId[id],meta) then existing[id]=nil end end end
    local sources,families,failures={},{},0
    -- Preflight raw geometry first, retaining only metadata to bound peak texture memory.
    for _,entry in ipairs(Mapping.list) do
        if entry.policy=='import' then
            local data,why=read(entry.source)
            if not data then print('NORMALIZE FAIL '..why); failures=failures+1
            else
                local meta=Rules.metadata(data); close(data); sources[entry.id]=meta
                local b=meta.bounds; local audited=entry.sourceBox
                if not b or b.x~=audited.x or b.y~=audited.y or b.w~=audited.w or b.h~=audited.h then
                    print('NORMALIZE REFUSE '..entry.id..': raw alpha bounds differ from confirmed M0 source; review mapping'); failures=failures+1
                elseif entry.family then
                    local family=families[entry.family] or {w=0,h=0,count=0}; families[entry.family]=family
                    family.w=math.max(family.w,b.w);family.h=math.max(family.h,b.h);family.count=family.count+1
                end
            end
        else print('NORMALIZE '..entry.policy:upper()..' '..entry.source..': '..entry.reason) end
    end
    for id,family in pairs(families) do if family.count~=4 then print('NORMALIZE FAIL '..id..': all four expressions required'); failures=failures+1 end end
    if failures>0 then return 1 end
    for _,entry in ipairs(Mapping.list) do
        if entry.policy=='import' then
            local spec=Manifest.byId[entry.id]; local meta=sources[entry.id]
            local plan,planWhy=Rules.plan(spec,meta,entry.family and families[entry.family])
            if not plan then print('NORMALIZE FAIL '..planWhy); failures=failures+1
            else
                entry.runPlan=plan; entry.runScale=plan.scale
                if existing[entry.id] and not matching(spec,existing[entry.id],meta,plan.scale) then print('NORMALIZE REFUSE '..entry.id..': existing output does not match confirmed source geometry'); failures=failures+1 end
            end
            if not love.filesystem.getInfo('assets/img/'..spec.kind,'directory') then print('NORMALIZE FAIL missing output folder '..spec.kind); failures=failures+1 end
        end
    end
    if failures>0 then return 1 end
    local generated,skipped=0,0
    for _,entry in ipairs(Mapping.list) do
        if entry.policy=='import' then
            local spec=Manifest.byId[entry.id]; local meta=sources[entry.id]; local scale=entry.runScale
            print(string.format('NORMALIZE %s scale=%.4f%s',entry.id,scale,(scale<.5 or scale>1.25) and ' WARNING source scale outside 0.5..1.25' or ''))
            if existing[entry.id] then skipped=skipped+1; print('SKIP validated matching '..spec.path)
            else
                local data,why=read(entry.source)
                if not data then print('NORMALIZE FAIL '..why); return 1 end
                local valid=Rules.validate(spec,meta)
                local bytes
                if valid and matching(spec,meta,meta,1) then
                    local raw,readWhy=love.filesystem.read(entry.source); bytes=raw
                    if not bytes then close(data); print('NORMALIZE FAIL copy '..tostring(readWhy)); return 1 end
                    print('COPY already conforming '..entry.source)
                else
                    local b=spec.fullBleed and {x=0,y=0,w=meta.width,h=meta.height} or meta.bounds; local g=love.graphics
                    local image=g.newImage(data,{mipmaps=true}); image:setFilter('linear','linear'); image:setMipmapFilter('linear')
                    local quad=g.newQuad(b.x,b.y,b.w,b.h,data:getWidth(),data:getHeight())
                    local canvas=g.newCanvas(spec.width,spec.height,{format='rgba8',msaa=0})
                    local previous=g.getCanvas(); g.push('all');g.setCanvas(canvas);g.origin();g.setScissor();g.clear(0,0,0,0)
                    g.setBlendMode('alpha','premultiplied');g.setColor(1,1,1,1)
                    local x,y=entry.runPlan.x,entry.runPlan.y
                    -- Source pixels are straight alpha; replace RGB/A once, preserving edge coverage.
                    if spec.edgeBand then
                        g.setColor(require('src.ui.theme').wood)
                        g.rectangle('fill',0,math.floor(meta.firstOpaqueY*scale),spec.width,spec.height)
                        g.setColor(1,1,1,1);g.setBlendMode('alpha','alphamultiply')
                    else g.setBlendMode('replace','alphamultiply') end
                    g.draw(image,quad,x,y,0,scale,scale);g.flushBatch()
                    g.setCanvas(previous);g.pop()
                    local output=canvas:newImageData(); local outputMeta=Rules.metadata(output,scale)
                    if spec.edgeBand then
                        -- Linear filtering may reveal one earlier row; extend from the measured row.
                        g.push('all');g.setCanvas(canvas);g.origin();g.setScissor()
                        g.setBlendMode('replace','alphamultiply');g.setColor(require('src.ui.theme').wood)
                        for _,edgeX in ipairs({0,spec.width-4}) do
                            g.rectangle('fill',edgeX,outputMeta.firstOpaqueY,4,spec.height-outputMeta.firstOpaqueY)
                        end
                        g.rectangle('fill',0,spec.height-4,spec.width,4);g.flushBatch()
                        g.setCanvas(previous);g.pop();output:release()
                        output=canvas:newImageData();outputMeta=Rules.metadata(output,scale)
                    end
                    local ok,reason=Rules.validate(spec,outputMeta)
                    if not ok then close(output);close(canvas);close(quad);close(image);close(data);print('NORMALIZE FAIL '..reason); return 1 end
                    local encoded=output:encode('png'); bytes=encoded:getString();close(encoded);close(output);close(canvas);close(quad);close(image)
                end
                close(data)
                local ok,reason=writeNew(sourceRoot..'/'..spec.path,bytes)
                if not ok then print('NORMALIZE FAIL '..reason); return 1 end
                generated=generated+1
            end
        end
    end
    print(string.format('NORMALIZE %d generated, %d validated outputs skipped',generated,skipped))
    print('RESAMPLING: mipmaps + linear; normalized softness/sharpness remains visually unverified. Inspect output; repair soft originals offline.')
    return 0
end
return Normalize
