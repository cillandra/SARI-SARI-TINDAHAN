-- Purpose: native PNG props with alpha picking and four original fallbacks. API: draw(id,rect,visual,record), hit(rect,record,scale).
local O = require('src.ui.draw.outline')
local W = require('src.ui.widgets')
local T = require('src.ui.theme')
local Assets = require('src.ui.assets')
local Rules = require('src.ui.asset_rules')
local P = {}
local g = love.graphics
local palettes = {}
for _, alpha in ipairs({1, .55}) do
    local palette = {}
    for name, value in pairs(T) do
        if type(value) == 'table' and type(value[1]) == 'number' then
            palette[name] = {value[1], value[2], value[3], alpha}
        end
    end
    palettes[alpha] = palette
end
local function drawer(c)
    O.polygon({10,0,207,0,230,57,0,57},c.steel,1.5)
    O.rect(0,57,230,78,c.steel,4,1.5)
    O.rect(11,67,208,52,c.bininner,3,1.2)
    O.rect(17,72,196,41,c.sky,2,1.1)
    O.rect(81,87,68,10,c.bininner,3,1.1)
    O.ellipse(198,91,5,5,c.mustard,1)
    O.line({21,35,199,35},c.paper,1)
    O.rect(33,123,15,12,c.bininner,2,1)
    O.rect(183,123,15,12,c.bininner,2,1)
end
local function scale(c)
    -- Scale and sack form one prop and share its one navigation target.
    O.polygon({189,34,253,34,266,160,257,195,177,195,169,164},c.paper,1.5)
    O.ellipse(221,33,33,11,c.darkwood,1.2)
    O.ellipse(221,28,29,9,c.paper,1.1)
    for i=1,14 do
        local x=198+(i*13%45)
        local y=24+(i*7%9)
        O.ellipse(x,y,3,1.3,c.mustard,.6)
    end
    O.line({183,52,259,52},c.wood,1)
    O.rect(192,80,57,51,c.wood,3,1)
    W.text('BIGAS',196,97,15,c.paper,49,'center')
    O.line({180,165,187,184,251,184,257,164},c.wood,1)
    O.rect(5,171,164,24,c.wood,4,1.5)
    O.polygon({47,170,65,150,112,150,133,170},c.steel,1.3)
    O.ellipse(88,111,67,66,c.maroon,1.5)
    O.ellipse(88,111,57,56,c.paper,1.2)
    for i=0,8 do
        local angle=math.pi+i*math.pi/8
        O.line({88+math.cos(angle)*43,111+math.sin(angle)*43,88+math.cos(angle)*49,111+math.sin(angle)*49},c.wood,1)
    end
    O.line({88,111,120,78},c.dustyrose,3)
    O.ellipse(88,111,6,6,c.wood,1)
    O.rect(76,31,22,19,c.steel,2,1)
    O.ellipse(88,27,85,12,c.steel,1.2)
    O.ellipse(88,23,76,8,c.sky,1)
end
local function cabinet(c)
    O.rect(0,0,230,200,c.darkwood,5,1.5)
    O.rect(8,10,214,177,c.wood,3,1.2)
    local fills={c.sage,c.dustyrose,c.mustard,c.sky,c.teal,c.paper}
    for row=0,1 do
        for col=0,2 do
            local x=15+col*68
            local y=18+row*82
            O.rect(x,y,64,76,c.darkwood,1,1)
            O.rect(x+7,y+16,22,45,fills[row*3+col+1],3,1)
            O.rect(x+33,y+24,23,37,fills[(row*3+col+2)%6+1],3,1)
            O.line({x+12,y+25,x+24,y+25},c.paper,1)
            O.line({x+37,y+33,x+51,y+33},c.paper,1)
        end
    end
    O.rect(0,188,230,12,c.wood,2,1.2)
end
local function phone(c)
    O.rect(0,0,130,200,c.bininner,14,1.5)
    O.rect(9,12,112,176,c.sky,8,1.1)
    O.rect(43,5,43,5,c.steel,2,1)
    W.text('TindaPay',12,34,20,c.ink,106,'center')
    O.line({19,66,111,66},c.teal,1)
    O.rect(19,85,92,34,c.paper,6,1)
    W.text('Cash In',23,94,16,c.ink,84,'center')
    O.rect(19,130,92,34,c.mustard,6,1)
    W.text('Cash Out',23,139,16,c.ink,84,'center')
    O.line({51,178,79,178},c.steel,2)
end
local drawers={cash_drawer=drawer,timbangan=scale,shelf_cabinet=cabinet,phone=phone}
local natural={cash_drawer={230,135},timbangan={270,195},shelf_cabinet={230,200},phone={130,200}}
function P.geometry(rect,record,scale)
    local b=record and record.bounds
    local n=natural[rect.id] or {rect.w,rect.h}
    local width,height=b and b.w/2 or n[1],b and b.h/2 or n[2]
    local reserve=require('data.tuning').ui.propHoverScale
    local fit=math.min(rect.w/(width*reserve),rect.h/(height*reserve))
    local factor=fit*(scale or 1)
    local w,h=width*factor,height*factor
    return {x=rect.x+(rect.w-w)/2,y=rect.baseline-h,w=w,h=h,factor=factor}
end
function P.hit(rect,record,scale)
    local art=P.geometry(rect,record,scale)
    local w,h=math.max(44,art.w),math.max(44,art.h)
    local hit={x=art.x+(art.w-w)/2,y=art.y+(art.h-h)/2,w=w,h=h}
    if not record then return hit end
    local b=record.bounds
    return hit,function(px,py)
        return Rules.contains(record.imageData,(px-art.x)/art.factor*2+b.x,
            (py-art.y)/art.factor*2+b.y)
    end
end
function P.draw(id,rect,visual,record)
    local draw=drawers[id]
    if not draw then return end
    local art=P.geometry(rect,record,visual.scale)
    local c=palettes[visual.enabled and 1 or .55]
    g.push('all');g.translate(art.x,art.y);g.scale(art.factor)
    if record then
        local b=record.bounds
        require('src.ui.prop_effects').tint(id)
        Assets.draw(record.spec.id,-b.x/2,-b.y/2,512,512,visual.enabled and 1 or .55)

    else draw(c) end
    g.pop()
end
return P
