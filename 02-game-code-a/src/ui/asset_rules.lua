-- Purpose: pure PNG metadata compliance and alpha picking. All coordinates are pixel units.
local Rules={}
local expressions={'happy','waiting','impatient','angry'}
local kinds={scene=true,prop=true,char=true,icon=true,ui=true,fx=true,tile=true}
local function fail(spec,message) return nil,(spec.id or 'asset')..': '..message end
local function nameValid(spec)
    if type(spec.id)~='string' or not spec.id:match('^[a-z][a-z0-9_]*$') or spec.id:find('__',1,true) or spec.id:match('_v%d+$') then return false end
    local kind=spec.path and spec.path:match('^assets/img/([^/]+)/')
    return kinds[kind] and spec.id:sub(1,#kind+1)==kind..'_' and spec.path=='assets/img/'..kind..'/'..spec.id..'.png'
end
function Rules.validate(spec,meta,base)
    if not nameValid(spec) then return fail(spec,'name must be lowercase snake_case, filename=id in its kind folder, without version suffix') end
    if not meta or meta.width~=spec.width or meta.height~=spec.height then return fail(spec,'size must be '..spec.width..'x'..spec.height) end
    if spec.alpha==true and not meta.alpha then return fail(spec,'alpha transparency required') end
    if spec.alpha==false and not meta.opaque then return fail(spec,'opaque canvas required') end
    local b=meta.bounds
    if not b or b.w<=0 or b.h<=0 then return fail(spec,'empty art: provide visible pixels with alpha > 8') end
    local margin=not spec.fullBleed and spec.minMargin or 0
    if b.x<margin or b.y<margin or b.x+b.w>spec.width-margin or b.y+b.h>spec.height then return fail(spec,'margin: keep left/right/top at least '..margin..' px and all art within canvas') end
    if spec.fullBleed and meta.edgeOpaque==false then return fail(spec,'full-bleed edge columns/bottom rows must be fully opaque') end
    if spec.baseline and math.abs(b.y+b.h-spec.baseline)>4 then return fail(spec,'baseline must end within 4 px of y='..spec.baseline) end
    if spec.center and math.abs(b.x+b.w/2-spec.center)>8 then return fail(spec,'center must be within 8 px of x='..spec.center) end
    if spec.maxArtBox and (b.w>spec.maxArtBox.w+4 or b.h>spec.maxArtBox.h+4) then return fail(spec,'art exceeds maximum box; scale uniformly') end
    if spec.artBox and (math.abs(b.w-spec.artBox.w)>spec.artBox.w*.1 or math.abs(b.h-spec.artBox.h)>spec.artBox.h*.1) then return fail(spec,'art box must be within 10% of '..spec.artBox.w..'x'..spec.artBox.h..'; correct the source silhouette, never stretch') end
    if meta.scale and meta.scale>1.25 then return fail(spec,'upscale '..string.format('%.4f',meta.scale)..' exceeds 1.25x; supply a larger source') end
    if spec.variantOf then
        if not base or not base.bounds then return fail(spec,'base '..spec.variantOf..' must be present and valid before its variant') end
        if base.width~=meta.width or base.height~=meta.height then return fail(spec,'variant canvas must equal base') end
        for _,key in ipairs({'x','y','w','h'}) do if math.abs(b[key]-base.bounds[key])>8 then return fail(spec,'variant '..key..' differs from base by more than 8 px') end end
    end
    return true
end
function Rules.validateManifest(manifest,files,metadata)
    local known,present={},{}
    for _,spec in ipairs(manifest.list) do
        if not nameValid(spec) then return fail(spec,'name invalid in manifest') end
        if known[spec.path] then return fail(spec,'duplicate manifest file') end
        known[spec.path]=spec; present[spec.id]=false
    end
    for _,file in ipairs(files) do
        local spec=known[file]
        if not spec then return nil,'unknown runtime file '..file..': add a conforming manifest entry or move it out of assets/img' end
        present[spec.id]=true
        local ok,why=Rules.validate(spec,metadata[spec.id],spec.variantOf and metadata[spec.variantOf]); if not ok then return nil,why end
    end
    local families={}
    for _,spec in ipairs(manifest.list) do
        if spec.family and present[spec.id] then families[spec.family]=true end
    end
    for family in pairs(families) do
        for _,expression in ipairs(expressions) do
            local id='char_'..family..'_'..expression
            if not present[id] then return nil,'char_'..family..': missing imported-family expression '..expression..'; provide all four expressions or use whole-family procedural fallback' end
        end
    end
    return true
end
local function scan(data)
    local w,h=data:getWidth(),data:getHeight(); local x0,y0,x1,y1=w,h,-1,-1
    local transparent,opaque=false,true
    -- LÖVE 11.5 ImageData exposes RGBA8 bytes. FFI avoids millions of Lua getPixel calls.
    local pointer
    if data.getFFIPointer and data.getFormat and data:getFormat()=='rgba8' then
        local ok,ffi=pcall(require,'ffi'); if ok then pointer=ffi.cast('const unsigned char *',data:getFFIPointer()) end
    end
    for y=0,h-1 do for x=0,w-1 do
        local a
        if pointer then a=tonumber(pointer[(y*w+x)*4+3]) else local _,_,_,alpha=data:getPixel(x,y); a=alpha*255 end
        if a<255 then transparent=true; opaque=false end
        if a>8 then x0=math.min(x0,x);y0=math.min(y0,y);x1=math.max(x1,x);y1=math.max(y1,y) end
    end end
    local b=x1>=0 and {x=x0,y=y0,w=x1-x0+1,h=y1-y0+1} or nil
    return b,transparent,opaque
end
function Rules.bounds(data) return (scan(data)) end
function Rules.metadata(data,scale)
    local b,alpha,opaque=scan(data)
    local w,h=data:getWidth(),data:getHeight()
    local first
    for y=0,h-1 do
        local _,_,_,a=data:getPixel(math.floor(w/2),y)
        if a*255>8 then first=y;break end
    end
    local edgeOpaque=true
    for y=first or 0,h-1 do
        for offset=0,3 do
            local _,_,_,left=data:getPixel(offset,y)
            local _,_,_,right=data:getPixel(w-1-offset,y)
            if left<1 or right<1 then edgeOpaque=false end
        end
    end
    return {width=w,height=h,bounds=b,alpha=alpha,opaque=opaque,scale=scale,
        firstOpaqueY=first,edgeOpaque=edgeOpaque}
end
function Rules.contains(data,x,y)
    if type(x)~='number' or type(y)~='number' or x<0 or y<0 or x>=data:getWidth() or y>=data:getHeight() then return false end
    local _,_,_,alpha=data:getPixel(math.floor(x),math.floor(y)); return alpha*255>8
end
-- Uniform source trim/placement. Family maxima keep expression scale stable; prop art boxes outrank canvas size.
function Rules.plan(spec,meta,familyBox)
    if spec.fullBleed then
        local scale=math.min(spec.width/meta.width,spec.height/meta.height)
        if math.abs(meta.width*scale-spec.width)>1 or math.abs(meta.height*scale-spec.height)>1 then
            return nil,spec.id..': full-bleed source aspect must match the full canvas'
        end
        return {scale=scale,x=0,y=0,width=spec.width,height=spec.height}
    end
    local source=meta and meta.bounds
    local box=familyBox or source
    if not source or not box or box.w<=0 or box.h<=0 then return nil,(spec.id or 'asset')..': empty art cannot be normalized' end
    local target=spec.maxArtBox or spec.artBox or {w=spec.width,h=spec.height}
    local scale=math.min(target.w/box.w,target.h/box.h)
    if scale>1.25 then return nil,(spec.id or 'asset')..': upscale exceeds 1.25x; supply larger source' end
    return {scale=scale,x=(spec.center or spec.width/2)-source.w*scale/2,y=(spec.baseline or spec.height)-source.h*scale,width=spec.width,height=spec.height}
end
return Rules
