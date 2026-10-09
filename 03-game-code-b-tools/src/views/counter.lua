-- Purpose: descriptor-driven four-prop counter, query-only order display. API: draw(app).
local W = require('src.ui.widgets')
local T = require('src.ui.theme')
local H = require('src.views.helpers')
local Customers = require('src.systems.customers')
local Line = require('src.ui.order_line')
local Order = require('src.systems.order')
local F = require('src.ui.format')
local O = require('src.ui.draw.outline')
local Room = require('src.ui.draw.room')
local Props = require('src.ui.draw.counter_props')
local Character = require('src.ui.draw.character')
local Materials = require('src.ui.draw.materials')
local Grain = require('src.ui.draw.grain')
local Sparkle = require('src.ui.draw.sparkle')
local Tuning = require('data.tuning')
local Navigation = require('data.navigation')
local Nav = require('src.ui.navigation')
local CounterLayout = require('src.ui.counter_layout')
local Assets = require('src.ui.assets')
local Portraits = require('data.portraits')
local V = {}
local motion = setmetatable({}, {__mode='k'})
local g = love.graphics

local function inside(r)
    return W.mx>=r.x and W.my>=r.y and W.mx<=r.x+r.w and W.my<=r.y+r.h
end
local function reducedMotion(a)
    local settings=a.state.settings
    if settings and settings.reducedMotion~=nil then return settings.reducedMotion end
    return Tuning.reducedMotion
end
local function animate(a,desc,hover,status)
    local all=motion[a]
    if not all then all={}; motion[a]=all end
    local now=a.uiClock or 0
    local m=all[desc.id]
    if not m then m={hover=false,from=1,value=1,changedAt=now}; all[desc.id]=m end
    local reduced=reducedMotion(a)
    local ui=Tuning.ui or {}
    local hoverScale=ui.propHoverScale or 1.08
    if hover~=m.hover then m.from=m.value; m.hover=hover; m.changedAt=now end
    local target=hover and hoverScale or 1
    local progress=reduced and 1 or math.min(1,math.max(0,(now-m.changedAt)/(ui.propHoverSeconds or .12)))
    m.value=m.from+(target-m.from)*(1-(1-progress)^3)
    local pressed=m.pressedAt and now-m.pressedAt<(ui.propHoverSeconds or .12)
    local breathing=not reduced and not hover and status.enabled
        and 1+(ui.breathScale or 0)*(1+math.sin(now*math.pi*2*ui.breathHz))/2 or 1
    local walletPulse=desc.id=='phone' and status.enabled and Order.hasWallet(Customers.current(a.state))
    local pulse=walletPulse and not reduced and 1+ui.walletPulseScale*(1+math.sin(now*math.pi*2*ui.walletPulseHz))/2 or 1
    m.renderScale=pressed and (ui.propPressScale or .96) or m.value*breathing*pulse
    return m,{enabled=status.enabled,scale=m.renderScale}
end
local function drawCustomer(a,c)
    local placement
    g.push('all')
    g.stencil(function() g.rectangle('fill',130,96,1020,CounterLayout.COUNTER_TOP_Y-96) end,'replace',1)
    g.setStencilTest('greater',0)
    for i=#a.state.queue,2,-1 do
        local box=CounterLayout.queuedCustomer(i-1,#a.state.queue-1)
        Character.draw(a.state.queue[i].id,box.x,box.y,box.scale,'waiting')
    end
    if c then
        local ratio=Customers.patience_ratio(c)
        local expression=Customers.mood(c)
        local assetId=Portraits.assetId(c.id,expression)
        local record=Assets.get(assetId)
        placement=CounterLayout.customer(record)
        if record then
            g.push('all');g.translate(placement.drawX,placement.drawY);g.scale(placement.factor)
            Assets.draw(assetId,0,0,400,500,1);g.pop()
        else Character.draw(c.id,placement.drawX,placement.drawY,placement.factor,expression) end
    end
    g.pop()
    if c then
        local desc=Navigation.customer
        local r=placement.rect
        W.hit(r.x,r.y,r.w,r.h,function() a:navigate(desc.id) end,{id=desc.id,focusable=true})
        if inside(r) then W.tooltip={text='Click your neighbor to take the order.',x=r.x+r.w/2,y=r.y+r.h} end
        local ratio=Customers.patience_ratio(c)
        local ring=placement.ring
        O.ellipse(ring.x,ring.y,24,24,T.paper,1)
        W.color(ratio>.3 and T.sage or T.dustyrose)
        g.setLineWidth(3)
        if ratio>0 then g.arc('line','open',ring.x,ring.y,20,-math.pi/2,-math.pi/2+math.pi*2*ratio) end
        W.text(math.ceil(c.patience),ring.x-23,ring.y-10,17,T.ink,46,'center')
    end
end
local function drawProp(a,desc)
    local r=CounterLayout.get(desc.id)
    local status=Nav.status(desc,a.state,Tuning.features)
    local record=Assets.get('prop_'..desc.id)
    local previous=motion[a] and motion[a][desc.id]
    local hoverRect,hoverContains=Props.hit(r,record,previous and previous.renderScale or 1)
    local hover=inside(hoverRect) and (not hoverContains or hoverContains(W.mx,W.my))
    local m,visual=animate(a,desc,hover,status)
    local hitRect,contains=Props.hit(r,record,visual.scale)
    local index=W.hit(hitRect.x,hitRect.y,hitRect.w,hitRect.h,function()
        m.pressedAt=a.uiClock or 0
        a:navigate(desc.id)
    end,{id=desc.id,focusable=status.enabled,contains=contains})
    local art=Props.geometry(r,record,visual.scale)
    require('src.ui.contact_shadow').draw(r.x+r.w/2,r.baseline,art.w,desc.id)
    require('src.ui.prop_effects').behind(desc.id,art,record,status.enabled,hover)
    Props.draw(desc.id,r,visual,record)
    a.counterArtRects=a.counterArtRects or {}
    a.counterArtRects[desc.id]=art
    if W.focus==index and status.enabled then
        W.color(T.mustard)
        g.setLineWidth(2)
        g.rectangle('line',hitRect.x-4,hitRect.y-4,hitRect.w+8,hitRect.h+8,7,7)
    end
    if status.enabled then
        Sparkle.draw(r.x+r.w-9,r.y+8,hover and 10 or 7,reducedMotion(a) and 0 or a.uiClock)
    end
    local captionWidth=math.min(170,math.max(130,r.w))
    local captionSize=math.min(20,17*(W.textScale or 1))
    O.rect(r.x+(r.w-captionWidth)/2,r.baseline+18,captionWidth,31,T.paper,4,1)
    W.text(desc.label,r.x+(r.w-captionWidth)/2+5,r.baseline+24,captionSize/(W.textScale or 1),T.ink,captionWidth-10,'center')
    if hover then W.tooltip={text=status.reason or desc.hint,x=r.x+r.w/2,y=r.baseline} end

end
local function basket(a,c)
    local q=a:quote()
    O.rect(303,542,674,81,T.paper,7,1.2)
    W.text('ON THE COUNTER',319,550,15,T.maroon)
    if not q or #q.lines==0 then
        W.text(c and 'Take the order, then choose a station above.' or 'Ready for the next neighbor.',319,578,19,T.ink,641,'center')
        return
    end
    local slotWidth=math.min(214,641/#q.lines)
    for i,line in ipairs(q.lines) do
        local x=319+(i-1)*slotWidth
        local badge=Line.wallet(line) and 'OK' or line.measured and (line.confirmed and 'OK' or '...') or tostring(line.quantity)..'x'
        O.ellipse(x+17,590,16,16,line.measured and not line.confirmed and T.mustard or T.sage,1)
        W.text(badge,x+1,582,14,T.ink,32,'center')
        W.text(Line.name(line),x+39,580,16,T.ink,slotWidth-45)
    end
end
function V.draw(a)
    Room.draw(require('src.systems.days').progress(a.state))
    local c=Customers.current(a.state)
    drawCustomer(a,c)
    Materials.wood(0,470,1280,250,T.wood)
    local area=require('src.ui.full_bleed').coverage(g.getDimensions())
    W.color(T.wood);g.rectangle('fill',area.x,470,area.w,area.y+area.h-470)
    local foreground=Assets.get('scene_counter_fg')
    if foreground then require('src.ui.full_bleed').draw(foreground,foreground.spec.drawY)
    else Grain.draw(0,470,1280,250,.24) end
    for _,desc in ipairs(Navigation.counter) do drawProp(a,desc) end
    basket(a,c)
    O.rect(303,638,674,43,T.paper,7,1.2)
    W.text('In line '..#a.state.queue..'   |   Served '..a.state.serviceOutcomes.served..'   |   Left '..a.state.serviceOutcomes.timedOut,303,651,18,T.ink,674,'center')
    require('src.ui.prop_effects').vignette()
    H.header(a,'The neighborhood counter')
end
return V
