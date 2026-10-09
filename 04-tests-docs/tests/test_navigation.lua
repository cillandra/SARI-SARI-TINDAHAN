return function()
 assert(love.filesystem.getInfo('data/navigation.lua'),'Navigation data must exist')
 local Data=require('data.navigation'); local Nav=require('src.ui.navigation'); local T=require('data.tuning')
 local expected={'cash_drawer','timbangan','shelf_cabinet','phone'}
 local targets={'sukli','timbangan','shelves','phone'}
 assert(#Data.counter==4,'Counter must expose exactly four ordered props')
 local state={day=1,phase='service',paused=false}
 for i,id in ipairs(expected) do local d=Data.counter[i]; assert(d.id==id and d.order==i and d.target==targets[i]); assert(Data.byId[id]==d and d.layoutSlot==i) end
 for _,id in ipairs({'cat','candy_jar','alkansya','clock','calendar','radio','curtain','rice_sack','bigas','tingi','hub'}) do assert(not Data.byId[id],'Removed id survived: '..id) end
 local features={utang=true,wallet=true}
 assert(not Nav.status(Data.byId.phone,state,features).enabled)
 state.day=2; assert(Nav.status(Data.byId.phone,state,features).enabled)
 assert(not Data.byId.utang_notebook,'Utang must have no counter navigation')
 assert(not Nav.status(Data.byId.phone,state,{wallet=false}).enabled)

 state.paused=true; assert(not Nav.status(Data.byId.cash_drawer,state,features).enabled)
 local keyTargets={'counter','shelves','sukli','timbangan','phone'}
 for i,target in ipairs(keyTargets) do assert(Data.shortcuts[tostring(i)].target==target) end
 local App=require('src.app'); local Save=require('src.persistence.save')
 local a=App.new(Save.new(require('tests.support.memory_disk').new(),'nav'))
 a:newRun(); assert(a:command('openDay')); a:go('counter')
 assert(a:navigate('shelf_cabinet') and a.view=='shelves')
 assert(not a:navigate('cash_drawer'),'Repeated navigation must debounce')
 a:update(T.ui.navigationDebounceSeconds+.01)
 assert(a:navigate('cash_drawer') and a.view=='sukli')
 a:update(T.ui.navigationDebounceSeconds+.01)
 assert(not a:navigate('phone') and a.view=='sukli' and #a.toast>0)
 a:keypressed('escape'); assert(a.state.paused)
 local elapsed=a.state.time.elapsed; a:update(10); assert(a.state.time.elapsed==elapsed)
 a:keypressed('escape'); assert(not a.state.paused)
 local c=require('src.systems.customers').current(a.state)
 assert(a:takeOrder() and a.state.retail.id==c.id)
 local sale=a.state.retail; assert(a:takeOrder() and a.state.retail==sale)
 a:pause(); a:keypressed('2'); assert(a.view=='sukli')
 local W=require('src.ui.widgets'); W.items={}; W.focus=1; local hits=0
 W.hit(0,0,100,100,function() hits=hits+1 end,{focusable=false,contains=function(x) return x>=50 end})
 W.hit(120,0,100,100,function() end)
 W.key('tab'); assert(W.focus==2,'Disabled prop must be absent from Tab order')
 assert(not W.activate(20,20),'Transparent pixels must not activate')
 assert(W.activate(60,20) and hits==1)
 W.items={}
 local State=require('src.model.state'); local Cmd=require('src.commands'); local Customers=require('src.systems.customers')
 local sugar=State.new(1);sugar.day=4
 assert(Cmd.execute(sugar,'prepareDay'));assert(Cmd.execute(sugar,'openDay'))
 local customer=assert(sugar.queue[1])
 customer.lines={{type='repack',productId='sugar',measured=true,quantity=250,amount=2000,
  requestMode='quantity',requestValue=250}}
 customer.total=2000
 a.state=sugar; a.lastNavigationAt=nil; a:go('counter'); assert(a:openTimbangan())
 assert(a.view=='timbangan' and a.portionProduct=='sugar')
 local before=a:quote().lines[1].actualQuantity
 a.pouring=true; a:update(.1)
 assert(a:quote().lines[1].actualQuantity>before,'Timbangan hold must advance an integer sugar portion')
end
