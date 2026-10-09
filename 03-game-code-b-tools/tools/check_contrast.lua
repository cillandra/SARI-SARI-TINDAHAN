-- Purpose: measured screenshot luminance inside alpha masks and a 20px external ring.
local M={}
local U=require('data.tuning').ui
local function linear(value)
    return value<=.04045 and value/12.92 or ((value+.055)/1.055)^2.4
end
function M.luminance(r,g,b)
    return .2126*linear(r)+.7152*linear(g)+.0722*linear(b)
end
local function metadata(path)
    local text=assert(love.filesystem.read(path..'.csv'))
    local result={props={}}
    for line in text:gmatch('[^\r\n]+') do
        local values={}
        for value in line:gmatch('[^,]+') do values[#values+1]=value end
        if #values==2 then result[values[1]]=tonumber(values[2])
        else
            result.props[#result.props+1]={id=values[1],x=tonumber(values[2]),y=tonumber(values[3]),
                w=tonumber(values[4]),h=tonumber(values[5]),factor=tonumber(values[6])}
        end
    end
    assert(#result.props==4,'Expected four screenshot masks')
    return result
end
local function masks(image,meta)
    local grid,individual={},{}
    local Rules=require('src.ui.asset_rules')
    for _,prop in ipairs(meta.props) do
        local record=assert(require('src.ui.assets').inspect(require('data.assets').byId['prop_'..prop.id]))
        local own={}
        for y=math.max(0,math.floor(prop.y)),math.min(image:getHeight()-1,math.ceil(prop.y+prop.h)) do
            local row={};own[y]=row;grid[y]=grid[y] or {}
            for x=math.max(0,math.floor(prop.x)),math.min(image:getWidth()-1,math.ceil(prop.x+prop.w)) do
                local sx=(x+.5-prop.x)/prop.factor*2+record.bounds.x
                local sy=(y+.5-prop.y)/prop.factor*2+record.bounds.y
                if Rules.contains(record.imageData,sx,sy) then row[x]=true;grid[y][x]=true end
            end
        end
        record.imageData:release();individual[prop.id]=own
    end
    return grid,individual
end
local function dilate(own,radius,width,height)
    local result={}
    for y,row in pairs(own) do
        local spans,start={},nil
        for x=0,width do
            if row[x] and not start then start=x
            elseif not row[x] and start then spans[#spans+1]={start,x-1};start=nil end
        end
        for dy=-radius,radius do
            local ny=y+dy
            if ny>=0 and ny<height then
                result[ny]=result[ny] or {}
                local dx=math.floor(math.sqrt(radius*radius-dy*dy))
                for _,span in ipairs(spans) do
                    for x=math.max(0,span[1]-dx),math.min(width-1,span[2]+dx) do
                        result[ny][x]=true
                    end
                end
            end
        end
    end
    return result
end
local function mean(image,mask,exclude,counter_top)
    local sum,count=0,0
    for y,row in pairs(mask) do
        if not counter_top or y+.5<counter_top then
            for x in pairs(row) do
                if not exclude or not (exclude[y] and exclude[y][x]) then
                    local r,g,b=image:getPixel(x,y)
                    sum=sum+M.luminance(r,g,b);count=count+1
                end
            end
        end
    end
    assert(count>0,'Empty screenshot mask/ring')
    return sum/count,count
end
local function grayscale(image)
    local output=love.image.newImageData(image:getDimensions())
    output:mapPixel(function(x,y)
        local r,g,b=image:getPixel(x,y)
        local lum=M.luminance(r,g,b)
        local gray=lum<=.0031308 and lum*12.92 or 1.055*lum^(1/2.4)-.055
        return gray,gray,gray,1
    end)
    local bytes=output:encode('png')
    local file=assert(io.open(love.filesystem.getSource()..'/docs/screenshots/m1fix/counter_gray.png','wb'))
    file:write(bytes:getString());file:close();bytes:release();output:release()
end
function M.run(args)
    local path
    for i,value in ipairs(args or {}) do if value=='--screenshot' then path=args[i+1] end end
    if not path or path:find('..',1,true) or not path:match('^docs/screenshots/m1fix/') then
        print('CONTRAST FAIL: use --screenshot docs/screenshots/m1fix/...-counter.png');return 1
    end
    local image=love.image.newImageData(path)
    local meta=metadata(path)
    local all,individual=masks(image,meta)
    local failures=0
    print('PROP | MASK LUMINANCE | RING LUMINANCE | DIFFERENCE | STATUS')
    for _,prop in ipairs(meta.props) do
        local own=individual[prop.id]
        local ring=dilate(own,math.floor(U.contrastRing*meta.scale+.5),image:getWidth(),image:getHeight())
        local inside=mean(image,own)
        local outside=mean(image,ring,all,meta.counterTop)
        local delta=math.abs(inside-outside)
        local status=delta>=U.contrastPass and 'PASS' or delta>=U.contrastWarn and 'WARN' or 'FAIL'
        if status~='PASS' then failures=failures+1 end
        print(string.format('%s | %.4f | %.4f | %.4f | %s',prop.id,inside,outside,delta,status))
    end
    grayscale(image);image:release()
    print('GRAYSCALE docs/screenshots/m1fix/counter_gray.png')
    print('CONTRAST '..(failures==0 and 'PASS' or 'FAIL')..' '..failures..' below PASS threshold')
    return failures==0 and 0 or 1
end
return M
