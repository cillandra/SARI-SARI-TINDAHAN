-- Cabinet geometry only; all 48 cubbies and input/drop controls share these rectangles.
local Products=require('data.products')
local L={sections={},slots={},byProduct={},basket={x=697,y=642,w=551,h=48},controls={
 back={x=32,y=642,w=178,h=48},cancel={x=224,y=642,w=178,h=48},receive={x=414,y=642,w=267,h=48}}}
for section=1,6 do
 local x=32+(section-1)%3*409;local y=136+math.floor((section-1)/3)*256
 L.sections[section]={x=x,y=y,w=395,h=238}
 L.slots[section]={}
 for slot=1,8 do L.slots[section][slot]={x=x+10+(slot-1)%4*95,y=y+35+math.floor((slot-1)/4)*101,w=90,h=94} end
end
for _,p in ipairs(Products.list) do L.byProduct[p.id]=L.slots[p.cabinet.section][p.cabinet.slot] end
function L.slot(section,slot) return L.slots[section] and L.slots[section][slot] end
function L.product(id) return L.byProduct[id] end
function L.contains(r,x,y) return x>=r.x and y>=r.y and x<=r.x+r.w and y<=r.y+r.h end
return L
