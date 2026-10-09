return function()
 assert(love.filesystem.getInfo('src/ui/cabinet_layout.lua'),'Cabinet must own its geometry in cabinet_layout.lua')
 local L=require('src.ui.cabinet_layout');local P=require('data.products')
 local T=require('data.tuning');local Cash=require('src.systems.cash')
 local App=require('src.app');local Save=require('src.persistence.save')
 local function overlap(a,b) return a.x<b.x+b.w and a.x+a.w>b.x and a.y<b.y+b.h and a.y+a.h>b.y end
 local rects={}
 for section=1,6 do for slot=1,8 do local r=L.slot(section,slot)
  assert(r.x>=0 and r.y>=120 and r.x+r.w<=1280 and r.y+r.h<=638 and r.w>=44 and r.h>=44)
  for _,other in ipairs(rects) do assert(not overlap(r,other)) end
  rects[#rects+1]=r
 end end
 assert(#rects==48)
 for _,p in ipairs(P.list) do assert(L.product(p.id)==L.slot(p.cabinet.section,p.cabinet.slot)) end
 local function fixture()
  local a=App.new(Save.new(require('tests.support.memory_disk').new(),'cabinet'))
  a:newRun();assert(a:command('openDay'))
  a.state.queue={{id='cabinet-test',patience=120,total=300,lines={{productId='candy',quantity=3,amount=300}},tender={[2000]=1}}}
  a:go('shelves');return a
 end
 local r=L.product('candy');local x,y=r.x+r.w/2,r.y+r.h/2
 local a=fixture();local cash=Cash.total(a.state)
 assert(a:beginCabinetPick('candy',x,y));assert(not a.state.retail,'Press is a preview until release/hold/drop')
 a:releaseCabinetPick(x,y);assert(a:quote().lines[1].quantity==3 and Cash.total(a.state)==cash)
 a:releaseCabinetPick(x,y);assert(#a:quote().lines==1,'Repeated release cannot add twice')
 a=fixture();assert(a:beginCabinetPick('candy',x,y));a:moveCabinetPick(690,660)
 a:releaseCabinetPick(690,660);assert(not a.state.retail,'Dragging outside basket does not pick goods')
 a=fixture();assert(a:beginCabinetPick('candy',x,y));local b=L.basket
 a:moveCabinetPick(b.x+20,b.y+20);a:releaseCabinetPick(b.x+20,b.y+20)
 assert(a:quote().lines[1].quantity==3 and not a.cabinetDrag)
 a=fixture();a:beginCabinetPick('candy',x,y);a:update(T.ui.cabinetHoldSeconds+.01)
 assert(a:quote().lines[1].quantity==3 and not a.cabinetDrag)
 a:update(1);a:releaseCabinetPick(x,y);assert(#a:quote().lines==1,'Held pick commits the requested quantity once')
 a=fixture();a:beginCabinetPick('candy',x,y);a:pause();a:update(1);a:releaseCabinetPick(x,y)
 assert(not a.state.retail and not a.cabinetDrag,'Pause clears unfinished drag without picking')
 a:pause();a:beginCabinetPick('candy',x,y);a:go('counter');assert(not a.cabinetDrag and not a.state.retail)
 a=fixture();a:beginCabinetPick('candy',x,y);a.state.queue[1].patience=.1;a:update(.2)
 assert(not a.cabinetDrag and not a.state.retail,'Timeout clears preview for the old customer')
 a=fixture();assert(not a:beginCabinetPick('rice_premium',x,y),'Sold-out goods cannot begin a pick')
 a=fixture();a.state.queue[1].lines={{productId='sugar',measured=true,quantity=2000,amount=16000}};a.state.queue[1].total=16000;a.state.queue[1].tender={[10000]=2}
 a:pick('sugar');local ref=a:quote().lines[1].reservation;a:adjust(50);a:go('shelves')
 local sugar=L.product('sugar');assert(a:beginCabinetPick('sugar',sugar.x+20,sugar.y+20),'A fully reserved open portion must remain reachable')
 a:releaseCabinetPick(sugar.x+20,sugar.y+20);assert(a.view=='timbangan' and a:quote().lines[1].reservation==ref and a:quote().lines[1].actualQuantity==50)
 a=fixture()
 local Model=require('src.ui.cabinet_model')
 a:pick('candy');local basket=Model.model(a);assert(#basket.items==1 and basket.items[1].productId=='candy' and basket.items[1].quantity==3,'Basket must expose staged item quantities')
 assert(not Model.hover(a,'candy',0));assert(not Model.hover(a,'candy',.399))
 assert(Model.hover(a,'candy',.4),'Tooltip starts at 400ms')
 assert(not Model.hover(a,'rice_regular',.4),'Changing cubbies restarts the delay')
 Model.hover(a,nil,.5);assert(not Model.hover(a,'rice_regular',1),'Leaving clears the delay')
 a:go('counter');assert(not a.cabinetHover)
end
