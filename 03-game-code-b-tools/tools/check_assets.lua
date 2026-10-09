-- Purpose: inspect only runtime asset files, fail strict compliance, report optional procedural fallbacks.
local Manifest=require('data.assets'); local Rules=require('src.ui.asset_rules'); local Assets=require('src.ui.assets')
local Check={}
local function walk(path,files)
    if not love.filesystem.getInfo(path,'directory') then return end
    local names=love.filesystem.getDirectoryItems(path); table.sort(names)
    for _,name in ipairs(names) do
        local file=path..'/'..name; local info=love.filesystem.getInfo(file)
        if info and info.type=='directory' then walk(file,files) else files[#files+1]=file end
    end
end
function Check.collect()
    local files,metadata,errors={},{},{}; walk('assets/img',files)
    local known={}; for _,spec in ipairs(Manifest.list) do known[spec.path]=spec end
    for _,path in ipairs(files) do
        local spec=known[path]
        if not spec then errors[#errors+1]='unknown runtime file '..path
        else
            local record,reason=Assets.inspect(spec)
            if not record then errors[#errors+1]=reason else metadata[spec.id]=record.meta; record.imageData:release() end
        end
    end
    for _,path in ipairs(files) do
        local spec=known[path]
        if spec and metadata[spec.id] then
            local ok,why=Rules.validate(spec,metadata[spec.id],spec.variantOf and metadata[spec.variantOf])
            if not ok then errors[#errors+1]=why end
        end
    end
    return files,metadata,errors
end
function Check.run()
    local files,metadata,errors=Check.collect(); local imported,procedural=0,0
    print('ASSET CHECK | ID | STATUS | PIXELS | ALPHA | BOUNDS | SOURCE SCALE / REASON')
    for _,spec in ipairs(Manifest.list) do
        local meta=metadata[spec.id]
        if meta then
            imported=imported+1; local b=meta.bounds
            print(string.format('%s | PNG | %dx%d | %s | %s | %s',spec.id,meta.width,meta.height,tostring(meta.alpha),b and string.format('%d,%d,%d,%d',b.x,b.y,b.w,b.h) or 'empty',meta.scale and string.format('%.4f',meta.scale) or 'no source normalization'))
        else
            procedural=procedural+1
            print(spec.id..' | PROCEDURAL | '..(spec.deferredReason or spec.fallbackReason or 'optional PNG absent'))
            if spec.imported then errors[#errors+1]=spec.id..': confirmed imported output missing; run --normalize' end
        end
    end
    if #errors==0 then local ok,why=Rules.validateManifest(Manifest,files,metadata); if not ok then errors[#errors+1]=why end end
    for _,why in ipairs(errors) do print('FAIL '..why) end
    print(string.format('ASSET CHECK %d PNG, %d procedural, %d failures',imported,procedural,#errors))
    return #errors==0 and 0 or 1
end
return Check
