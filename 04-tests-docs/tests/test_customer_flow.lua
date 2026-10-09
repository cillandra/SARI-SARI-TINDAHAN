-- Count-driven service, fair queued patience and once-only completion bonuses.
return function()
 local S=require('src.model.state');local D=require('src.systems.days');local C=require('src.systems.customers')
 local R=require('src.systems.retail');local P=require('src.systems.portions');local Cash=require('src.systems.cash')
 local Config=require('data.config');local Levels=require('data.levels');local Wallet=require('src.systems.tindapay')
 local failures={};local function check(ok,label) if not ok then failures[#failures+1]=label end end
 -- A new customer must survive 49 seconds; pause freezes the last second,
 -- then the fiftieth active second expires the order exactly once.
 for _,day in ipairs({1,3,10,12,20}) do
  local timed=S.new(1);timed.day=day;assert(D.prepare(timed));assert(D.open(timed))
  timed.dayProfile.event=nil
  local customer=timed.queue[1];local id=customer.id
  check(customer.patience==50 and customer.initialPatience==50,'Day '..day..' starts at fifty seconds')
  assert(C.update(timed,49))
  check(timed.queue[1] and timed.queue[1].id==id and timed.queue[1].patience==1,'Day '..day..' survives forty-nine seconds')
  timed.paused=true;assert(C.update(timed,10));timed.paused=false
  check(timed.queue[1] and timed.queue[1].patience==1,'Pause preserves the remaining second')
  assert(C.update(timed,1))
  check(#timed.queue==0 and timed.serviceOutcomes.timedOut==1,'Day '..day..' expires once at fifty seconds')
 end
 assert(#failures==0,table.concat(failures,'\n'))
 local s=S.new(1);assert(D.prepare(s));assert(D.open(s));s.time.elapsed=1000
 assert(D.update(s,0));check(s.phase=='service' and not s.time.closing,'Elapsed clock cannot close day before customer count')
 check(Config.queue_max==3 and Config.line_bonus==4,'Configured queue cap and line bonus')
 s=S.new(1);assert(D.prepare(s));assert(D.open(s));assert(C.spawn(s));assert(C.spawn(s))
 check(not C.spawn(s) and #s.queue==3,'Queue capped at three')
 s.queue={s.queue[1],s.queue[2]};s.queue[1].patience=30;s.queue[2].patience=30
 assert(C.update(s,4));check(s.queue[1].patience==26 and s.queue[2].patience==28,'Waiting drains at half speed')
 s.queue[1].patience=1;s.queue[2].patience=20;assert(C.update(s,4))
 check(#s.queue==1 and s.queue[1].patience==16.5,'Promoted customer drains normally for remaining time')
 s=S.new(1);assert(D.prepare(s));assert(D.open(s))
 local c=s.queue[1];c.lines={{type='item',productId='candy',quantity=1,amount=100,measured=false,requestMode='quantity',requestValue=1}};c.total=100;c.patience=20
 assert(R.begin(s,c.id));assert(R.add(s,c.id,'candy',1));check(c.patience==24,'Completed shelf line gives four seconds')
 assert(R.remove(s,c.id,1));assert(R.add(s,c.id,'candy',1));check(c.patience==24,'Remove/re-add cannot farm bonus')
 s=S.new(1);s.day=3;assert(D.prepare(s));assert(D.open(s));c=s.queue[1]
 c.lines={{type='weigh',productId='rice_regular',quantity=250,amount=1400,measured=true,requestMode='quantity',requestValue=250}};c.total=1400;c.patience=48
 assert(R.begin(s,c.id));assert(P.target(s,c.id,'rice_regular',250));check(c.patience==48,'Unfinished portion gives no bonus')
 assert(P.adjust(s,c.id,1,250));assert(P.confirm(s,c.id,1));check(c.patience==50,'Measured bonus capped at daily starting patience')
 assert(not P.confirm(s,c.id,1));check(c.patience==50,'Repeated confirmation cannot award twice')
 s=S.new(1);s.day=2;assert(D.prepare(s));assert(D.open(s));c=s.queue[1];c.patience=20
 assert(R.begin(s,c.id));assert(Wallet.add(s,c.id,1,c.lines[1].transfer));check(c.patience==24,'Wallet verification gives bonus')
 assert(Wallet.add(s,c.id,1,c.lines[1].transfer));check(c.patience==24,'Repeated wallet verification gives no bonus')
 assert(#failures==0,table.concat(failures,'\n'))
 s=S.new(1);assert(D.prepare(s));assert(D.open(s))
 for number=1,6 do
  c=s.queue[1];check(c and c.number==number,'Day1 customer ordinal '..number)
  c.lines={{type='item',productId='candy',quantity=1,amount=100,measured=false,requestMode='quantity',requestValue=1}};c.total=100
  assert(R.begin(s,c.id));assert(R.add(s,c.id,'candy',1));local tender=assert(C.payment(s));assert(R.stageTender(s,c.id,tender))
  local change=assert(Cash.plan(s,assert(R.changeDue(s,c.id)),tender));assert(R.commit(s,c.id,change))
  assert(D.update(s,number==6 and 0 or 14))
 end
 check(s.phase=='report' and #s.histories.days==1 and s.serviceOutcomes.served==6 and #s.queue==0,'Day ends at exactly six resolved customers')
 check(not C.spawn(s),'No post-ending arrivals');assert(D.update(s,100));check(#s.histories.days==1,'Day report appended once')
 local fast=S.new(17);assert(D.prepare(fast));assert(D.open(fast));local slow=S.clone(fast)
 assert(D.update(fast,1000));for _=1,1000 do if slow.phase~='service' then break end;assert(D.update(slow,1)) end
 local Codec=require('src.persistence.codec')
 check(Codec.encode(fast)==Codec.encode(slow),'Large update and one-second ticks finish with identical full state')
 local empty=S.new(1);assert(D.prepare(empty));for id in pairs(empty.inventory) do empty.inventory[id]={} end
 local before=Cash.total(empty);assert(D.open(empty));assert(D.update(empty,1000))
 check(empty.phase=='report' and empty.serviceOutcomes.timedOut==6 and #empty.queue==0 and Cash.total(empty)==before,'No-stock arrivals dismiss politely and complete the count without cash loss')
 local legacy=S.new(1);assert(D.prepare(legacy));assert(D.open(legacy))
 legacy.queue[1].initialPatience=nil;legacy.queue[1].patience=120
 assert(require('src.systems.order').refresh(legacy))
 check(legacy.queue[1].patience==50 and legacy.queue[1].initialPatience==50,'Legacy refresh migrates capped starting patience')
 local resumed=S.new(1);assert(D.prepare(resumed));assert(D.open(resumed))
 resumed.queue[1].initialPatience=30;resumed.queue[1].patience=20
 assert(require('src.systems.order').refresh(resumed))
 check(resumed.queue[1].initialPatience==50 and resumed.queue[1].patience==40,'Old thirty-second customer gains twenty seconds while preserving elapsed time')
 assert(require('src.systems.order').refresh(resumed))
 check(resumed.queue[1].patience==40,'Repeated load refresh cannot refill customer patience')
 check(type(D.arrival_interval)=='function','Arrival interval query exists')
 if D.arrival_interval then check(D.arrival_interval(1)==14 and D.arrival_interval(10)==8 and D.arrival_interval(12)==8,'Arrival curve14 to8') end
 assert(#failures==0,table.concat(failures,'\n'))
end
