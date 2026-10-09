-- Purpose: asset compliance and transparent picking regression fixtures; no graphics context.
return function()
    local loaded, Rules = pcall(require, 'src.ui.asset_rules')
    assert(loaded, 'asset validator must exist: ' .. tostring(Rules))
    local prop = {id='prop_cash_drawer', path='assets/img/prop/prop_cash_drawer.png', kind='prop', width=1024,height=1024,alpha=true,minMargin=32,baseline=992,center=512,artBox={w=460,h=270}}
    local function valid() return {width=1024,height=1024,alpha=true,bounds={x=282,y=722,w=460,h=270},scale=1} end
    assert(Rules.validate(prop,valid()), 'conforming class-L prop accepted')
    local function rejects(change, clue, spec, base)
        local meta=valid(); change(meta)
        local ok,why=Rules.validate(spec or prop,meta,base)
        assert(not ok and type(why)=='string' and why:find(clue,1,true), 'actionable rejection for '..clue..': '..tostring(why))
    end
    rejects(function(m) m.width=1000 end,'size')
    rejects(function(m) m.alpha=false end,'alpha')
    rejects(function(m) m.bounds=nil end,'empty')
    rejects(function(m) m.bounds.x=31 end,'margin')
    rejects(function(m) m.bounds.y=31 end,'margin')
    rejects(function(m) m.bounds.x=533 end,'margin')
    rejects(function(m) m.bounds.y=717 end,'baseline')
    rejects(function(m) m.bounds.x=291 end,'center')
    rejects(function(m) m.bounds.w=413; m.bounds.x=305.5 end,'art box')
    rejects(function(m) m.bounds.h=242; m.bounds.y=750 end,'art box')
    rejects(function(m) m.scale=1.251 end,'upscale')
    local edges=valid(); edges.bounds.y=718; edges.bounds.x=290; edges.scale=1.25
    assert(Rules.validate(prop,edges), 'baseline4, center8 and upscale1.25 boundaries accepted')
    local variant={id='prop_cash_drawer_open',path='assets/img/prop/prop_cash_drawer_open.png',kind='prop',width=1024,height=1024,alpha=true,minMargin=32,baseline=992,center=512,artBox={w=460,h=270},variantOf='prop_cash_drawer'}
    rejects(function(m) m.bounds.w=478; m.bounds.x=273 end,'variant',variant,valid())
    local near=valid(); near.bounds.x=278; near.bounds.w=468
    assert(Rules.validate(variant,near,valid()), 'variant8 boundary accepted')
    rejects(function() end,'base',variant)
    local scene={id='scene_counter_bg_street',path='assets/img/scene/scene_counter_bg_street.png',kind='scene',width=2560,height=1440,alpha=false}
    local sm={width=2560,height=1440,alpha=false,opaque=true,bounds={x=0,y=0,w=2560,h=1440},scale=1}
    assert(Rules.validate(scene,sm), 'opaque scene accepted')
    sm.opaque=false; local ok,why=Rules.validate(scene,sm); assert(not ok and why:find('opaque',1,true),'street cannot have transparent holes')
    local bad={id='prop_Drawer_v2',path='assets/img/prop/prop_Drawer_v2.png',kind='prop',width=1024,height=1024}
    ok,why=Rules.validate(bad,valid()); assert(not ok and why:find('name',1,true),'uppercase/version name rejected')
    local manifest={list={prop},byId={[prop.id]=prop}}
    assert(Rules.validateManifest(manifest,{prop.path},{[prop.id]=valid()}))
    ok,why=Rules.validateManifest(manifest,{prop.path,'assets/img/prop/prop_unknown.png'},{[prop.id]=valid()})
    assert(not ok and why:find('unknown',1,true),'unknown runtime file rejected')
    local chars={list={},byId={}}; local files,metas={},{}
    for _,expression in ipairs({'happy','waiting','impatient','angry'}) do
        local id='char_teacher_'..expression
        local spec={id=id,path='assets/img/char/'..id..'.png',kind='char',family='teacher',expression=expression,width=800,height=1000,alpha=true,baseline=1000,center=400}
        chars.list[#chars.list+1]=spec; chars.byId[id]=spec
        files[#files+1]=spec.path; metas[id]={width=800,height=1000,alpha=true,bounds={x=100,y=80,w=600,h=920},scale=.33}
    end
    assert(Rules.validateManifest(chars,files,metas),'complete imported family accepted')
    assert(Rules.validateManifest(chars,{},{}),'wholly absent optional family uses procedural fallback')
    files[4]=nil; metas.char_teacher_angry=nil
    ok,why=Rules.validateManifest(chars,files,metas)
    assert(not ok and why:find('angry',1,true),'partially imported family must identify missing expression')
    -- Pixels hand-picked around alpha8 cutoff, including a transparent hole inside bbox.
    local pixels={{0,9/255,0},{1,0,8/255},{0,1,0}}
    local image={getWidth=function() return 3 end,getHeight=function() return 3 end,
        getPixel=function(_,x,y) return 1,1,1,pixels[y+1][x+1] end}
    local box=Rules.bounds(image)
    assert(box.x==0 and box.y==0 and box.w==2 and box.h==3,'alpha>8 exclusive bounding box')
    assert(Rules.contains(image,1,0) and Rules.contains(image,0,1),'opaque pixel picking')
    assert(not Rules.contains(image,1,1) and not Rules.contains(image,2,1),'holes and alpha8 excluded')
    assert(not Rules.contains(image,-1,0) and not Rules.contains(image,3,0),'out-of-canvas picking safe')
    local Assets=require('data.assets'); local count=0
    for _,spec in ipairs(Assets.list) do if spec.path:find('assets/img/icon/',1,true) then count=count+1 end end
    assert(count==36,'all existing optional product icons retained')
    local Mapping=require('data.asset_mapping'); local families={}; local characterCount=0
    for _,entry in ipairs(Mapping.list) do
        if entry.id and entry.id:find('char_',1,true)==1 then
            local spec=Assets.byId[entry.id]; assert(spec and spec.family,'confirmed portrait manifest')
            families[spec.family]=(families[spec.family] or 0)+1; characterCount=characterCount+1
        end
    end
    local familyCount=0; for _,n in pairs(families) do assert(n==4); familyCount=familyCount+1 end
    assert(characterCount==32 and familyCount==8,'all eight confirmed four-expression families mapped')
    -- A deferred raw source does not invalidate a corrected runtime PNG.
    prop.deferredReason='raw source has incompatible silhouette'
    assert(Rules.validateManifest(manifest,{prop.path},{[prop.id]=valid()}),'valid runtime replacement overrides raw-processing deferral')
    local regressions={}
    local loaderOK,loaderWhy=pcall(function()
        local spec=Assets.byId.scene_counter_fg
        if not love.filesystem.getInfo(spec.path,'file') then return end -- all PNGs remain optional
        local previousReason,previousGraphics=spec.deferredReason,love.graphics
        local previousModule=package.loaded['src.ui.assets']
        spec.deferredReason='raw-source audit note only'
        -- Keep actual PNG decoding/alpha validation; only the unavailable headless texture upload is stubbed.
        love.graphics={newImage=function() return {setFilter=function() end,setMipmapFilter=function() end} end}
        package.loaded['src.ui.assets']=nil
        local ok,why=pcall(function()
            local record,reason=require('src.ui.assets').get(spec.id)
            assert(record and record.imageData:getWidth()==2560 and record.bounds.h>=430,'conforming runtime PNG must load despite raw deferredReason: '..tostring(reason))
            record.imageData:release()
        end)
        spec.deferredReason=previousReason;love.graphics=previousGraphics;package.loaded['src.ui.assets']=previousModule
        assert(ok,why)
    end)
    if not loaderOK then regressions[#regressions+1]=tostring(loaderWhy) end
    local planOK,planWhy=pcall(function()
        assert(type(Rules.plan)=='function','normalization plan must use declared art box')
        local plan=assert(Rules.plan(prop,{width=1800,height=1800,alpha=true,bounds={x=40,y=80,w=920,h=540}}))
        assert(plan.scale==.5 and plan.x==282 and plan.y==722,'prop normalization fits460x270 art box on1024canvas at baseline992')
        local character={id='char_teacher_waiting',width=800,height=1000,center=400,baseline=1000}
        plan=assert(Rules.plan(character,{bounds={x=10,y=20,w=600,h=800}},{w=1000,h=2000}))
        assert(plan.scale==.5 and plan.x==250 and plan.y==600,'family largest box sets same uniform scale for smaller expression')
    end)
    if not planOK then regressions[#regressions+1]=tostring(planWhy) end
    assert(#regressions==0,table.concat(regressions,' | '))
end
