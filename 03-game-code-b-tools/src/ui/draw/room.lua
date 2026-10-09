-- Purpose: shared original shop interior background; no interaction or state. API: draw(). Dependencies: procedural drawing modules/theme.
local O=require('src.ui.draw.outline'); local T=require('src.ui.theme'); local P=require('src.ui.draw.patterns'); local Street=require('src.ui.draw.street'); local Props=require('src.ui.draw.props'); local Grain=require('src.ui.draw.grain'); local Room={}
function Room.draw(progress)
 local record=require('src.ui.assets').get('scene_counter_bg_interior')
 if record then
  local effects=require('src.ui.prop_effects')
  local street=require('src.ui.assets').get('scene_counter_bg_street')
  if street then effects.background(street) end
  effects.background(record);return
 end
 local area=require('src.ui.full_bleed').coverage(love.graphics.getDimensions())
 love.graphics.setColor(T.cream);love.graphics.rectangle('fill',area.x,area.y,area.w,area.h)
 P.stripes(24,113,1232,424); O.rect(117,126,1046,277,T.wood,4); Street.draw(130,138,1020,217,progress); P.floor(24,356,1232,185,'cement'); O.line({130,139,130,355,1150,355,1150,139},T.darkwood,5); O.line({445,140,445,355},T.wood,8); O.line({818,140,818,355},T.wood,8); O.line({131,218,1150,218},T.wood,6); Props.awning(119,126,1041); Props.sign(969,263); Props.plant(94,372,.94); Props.plant(1194,383,.88); Props.lamp(243,114); Props.lamp(670,114); Props.lamp(1064,114); local dusk=math.max(0,math.min(1,((progress or 0)-.55)/.45)); if dusk>0 then love.graphics.setColor(T.plum[1],T.plum[2],T.plum[3],dusk*.07); love.graphics.rectangle('fill',24,356,1232,185); for _,lampX in ipairs({243,670,1064}) do love.graphics.setColor(T.mustard[1],T.mustard[2],T.mustard[3],dusk*.08); love.graphics.polygon('fill',lampX-25,166,lampX+25,166,lampX+95,454,lampX-95,454) end end; Grain.draw(24,113,1232,420,.24) end
return Room

