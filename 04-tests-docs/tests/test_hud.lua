return function()
 local Hud=require('src.ui.draw.hud')
 local Icons=require('src.ui.draw.icons')
 local State=require('src.model.state')
 local s=State.new(1)
 assert(type(Hud.models)=='function','D5 HUD needs query-only plate models')
 local ids={'day','suki','cash','wallet','ticket','menu'}
 local models=Hud.models(s,{wallet=true})
 for i,id in ipairs(ids) do
  assert(models[i].id==id and type(Icons.drawers[models[i].icon])=='function','Every plate needs a registered icon drawer')
  assert(models[i].rect.h==70,'HUD plates must have equal height')
 end
 assert(models[4].locked and models[4].icon=='lock' and models[4].value=='Bukas sa Araw 2')
 s.day=2; models=Hud.models(s,{wallet=true}); assert(not models[4].locked and models[4].icon=='wallet')
 assert(Hud.models(s,{wallet=false})[4].locked,'Unavailable feature must stay locked')
 s.dayProfile={walletOutage=true}; assert(Hud.models(s,{wallet=true})[4].icon=='offline')
 for _,case in ipairs({{39,'mood_worried'},{40,'mood_neutral'},{69,'mood_neutral'},{70,'mood'}}) do
  s.reputation=case[1]; assert(Hud.models(s,{wallet=true})[2].icon==case[2])
 end
 s.serviceOutcomes={served=0,timedOut=0}
 local morning=Hud.models(s,{wallet=true})[1]
 assert(morning.value=='8:00 AM' and morning.icon=='sun','Count clock begins at 8 AM')
 s.time.elapsed=9999
 assert(Hud.models(s,{wallet=true})[1].value==morning.value,'Elapsed time cannot advance the served-count clock')
 s.serviceOutcomes.served=require('data.levels').get(s.day).customers
 local evening=Hud.models(s,{wallet=true})[1]
 assert(evening.value=='8:00 PM' and evening.icon=='moon','Full served count ends the clock at 8 PM')
 assert(require('src.ui.format').money(98000):match('980%.00$'))
end
