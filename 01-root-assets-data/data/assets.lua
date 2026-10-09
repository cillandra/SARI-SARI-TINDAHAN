-- Purpose: canonical optional PNG manifest. API: list/byId. Product aliases preserve catalog callers.
local Assets={list={},byId={}}
local Mapping=require('data.asset_mapping')
local function add(spec)
    spec.optional=true; spec.scale2x=true; spec.designSize={w=spec.width/2,h=spec.height/2}
    spec.kind=spec.id:match('^([^_]+)_'); spec.path='assets/img/'..spec.kind..'/'..spec.id..'.png'
    local mapped=Mapping.byId[spec.id]
    if mapped then spec.sourceScale=mapped.scale; spec.fallbackReason=mapped.reason; spec.imported=mapped.policy=='import' end
    Assets.list[#Assets.list+1]=spec; Assets.byId[spec.id]=spec; return spec
end
for _,product in ipairs(require('data.products').list) do
    local spec=add({id='icon_'..product.id,width=512,height=512,anchor={x=.5,y=1},alpha=true,fallbackLabel=product.name})
    Assets.byId[product.icon]=spec
end
for _,role in ipairs(require('data.portraits').roles) do
    for _,expression in ipairs({'happy','waiting','impatient','angry'}) do
        add({id='char_'..role..'_'..expression,family=role,expression=expression,width=800,height=1000,alpha=true,baseline=1000,center=400,anchor={x=.5,y=1},fallbackLabel=role})
    end
end
add({id='scene_counter_bg_street',width=2560,height=1440,alpha=false,fullBleed=true,anchor={x=0,y=0}})
add({id='scene_counter_bg_interior',width=2560,height=1440,alpha=false,fullBleed=true,anchor={x=0,y=0}})
add({id='scene_counter_fg',width=2560,height=1440,alpha=true,fullBleed=true,edgeBand=true,anchor={x=0,y=1},drawY=-30})
add({id='scene_title_bg',width=2560,height=1440,alpha=false,anchor={x=0,y=0}})
add({id='tile_floor_cement',width=1024,height=1024,alpha=false,anchor={x=0,y=0}})
local props={{'cash_drawer',400,340},{'timbangan',460,340},{'shelf_cabinet',400,340},{'utang_notebook',340,340},{'phone',220,340}}
for _,p in ipairs(props) do
    add({id='prop_'..p[1],width=1024,height=1024,alpha=true,minMargin=32,baseline=992,center=512,maxArtBox={w=p[2],h=p[3]},anchor={x=.5,y=992/1024}})
end
for _,v in ipairs({{'cash_drawer_open','cash_drawer',460,270},{'utang_notebook_locked','utang_notebook',400,240},{'phone_outage','phone',260,400}}) do
    add({id='prop_'..v[1],variantOf='prop_'..v[2],width=1024,height=1024,alpha=true,minMargin=32,baseline=992,center=512,artBox={w=v[3],h=v[4]},anchor={x=.5,y=992/1024}})
end
return Assets
