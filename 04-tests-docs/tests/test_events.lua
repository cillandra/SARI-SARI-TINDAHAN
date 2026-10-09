-- Event effects exercise real timers, generation and save/retry boundaries.
return function()
 local S=require('src.model.state');local D=require('src.systems.days')
 local C=require('src.systems.customers');local O=require('src.systems.order')
 local Codec=require('src.persistence.codec')
 local function prepared(day,seed)
  local s=S.new(seed or 31);s.day=day;assert(D.prepare(s));return s
 end
 local s=prepared(7)
 assert(math.abs(s.time.spawnCountdown-7)<.000001,'Rain starts with 30 percent shorter arrival interval')
 assert(D.open(s));assert(D.update(s,7));assert(#s.queue==2,'Rain arrivals use shortened interval during service')
 assert(math.abs(s.time.spawnCountdown-7)<.000001,'Rain reset interval remains shortened')
 s=prepared(10);assert(math.abs(s.time.spawnCountdown-5.6)<.000001,'Fiesta combines rain timing')
 local plain=prepared(8);assert(math.abs(plain.time.spawnCountdown-9.333333333333333)<.000001,'Ordinary interval remains unmodified')
 -- Literal event fixtures isolate timing from the existing once-only random choice.
 s=prepared(11);s.dayProfile.event='brownout';assert(D.open(s));assert(C.spawn(s))
 local first,second=s.queue[1].patience,s.queue[2].patience
 assert(C.update(s,5));assert(math.abs(s.queue[1].patience-(first-4))<.000001 and math.abs(s.queue[2].patience-(second-2))<.000001,'Brownout slows both active and waiting patience by 20 percent')
 s.paused=true;first=s.queue[1].patience;assert(D.update(s,100));assert(s.queue[1].patience==first,'Pause freezes brownout patience')
 s=prepared(11);s.dayProfile.event='brownout';assert(D.open(s));s.queue[1].patience=1;s.time.spawnCountdown=100
 assert(D.update(s,1.25));assert(#s.queue==0 and s.serviceOutcomes.timedOut==1,'Brownout timeout boundary matches drain rate')
 local E=require('src.systems.events')
 assert(E.dim(s)>0 and E.dim(s)<.2,'Brownout dims slightly')
 s.day=10;assert(E.dim(s)==0 and E.patience_rate(s,1)==1,'Brownout has no effect before endless')
 local function sample(event)
  local state=prepared(9,17);state.dayProfile.event=event;local n=0
  for i=1,6000 do
   local types=O.plan(state,1,{item=1,weigh=1,repack=1,pour=1})
   if types[1]=='cash_in' or types[1]=='cash_out' then n=n+1 end
  end
  return n
 end
 local ordinary,payday,fiesta=sample(nil),sample('payday'),sample('fiesta')
 assert(ordinary>1800 and ordinary<2200,'Ordinary unlocked pool uses uniform line weights')
 assert(payday>2800 and payday<3200 and fiesta==payday,'Payday doubles each wallet weight and fiesta shares it')
 s=prepared(1);s.dayProfile.event='payday'
 for i=1,20 do assert(O.plan(s,1,{item=1})[1]=='item','Event cannot unlock wallet types') end
 s=prepared(11,42);local event=s.dayProfile.event;local rng=s.rng.randomState
 local loaded=assert(Codec.decode(assert(Codec.encode(s))));assert(O.refresh(loaded));assert(loaded.dayProfile.event==event and loaded.rng.randomState==rng,'Save/refresh retains event and RNG')
 assert(D.open(s));assert(D.retry(s));assert(s.dayProfile.event==event and s.rng.randomState==rng,'Retry retains once-selected endless event')
 print('EVENTS PASS rain/fiesta arrivals, payday weighted lines, endless brownout rates, pause and save/retry')
 print('EVENT SAMPLE ordinary='..ordinary..' payday='..payday..' fiesta='..fiesta..' of 6000 each')
end
