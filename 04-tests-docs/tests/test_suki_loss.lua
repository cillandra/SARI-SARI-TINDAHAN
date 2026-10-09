-- Angry timeouts, atomic loss cleanup, persisted loss and new-run recovery.
return function()
 local S=require('src.model.state');local D=require('src.systems.days');local C=require('src.systems.customers')
 local R=require('src.systems.retail');local Cash=require('src.systems.cash');local Codec=require('src.persistence.codec')
 local function same(a,b) if type(a)~=type(b) then return false end;if type(a)~='table' then return a==b end;for k,v in pairs(a) do if not same(v,b[k]) then return false end end;for k in pairs(b) do if a[k]==nil then return false end end;return true end
 local failures={};local function check(ok,label) if not ok then failures[#failures+1]=label end end
 local function opened() local s=S.new(17);assert(D.prepare(s));assert(D.open(s));return s end
 local s=opened();s.queue[1].patience=1;assert(C.spawn(s));s.queue[2].patience=20
 assert(C.update(s,1));check(s.reputation==42 and #s.queue==1,'Angry timeout subtracts eight Suki once')
 assert(C.update(s,0));check(s.reputation==42,'Repeated update does not repeat timeout penalty')
 s=opened();s.paused=true;assert(C.update(s,100));check(s.reputation==50,'Pause prevents timeout penalty')
 s=opened();s.reputation=5;local c=s.queue[1];assert(R.begin(s,c.id))
 assert(R.add(s,c.id,c.lines[1].productId,c.lines[1].quantity));assert(C.spawn(s));c.patience=1
 local cash=Cash.total(s);local inventory=S.clone(s.inventory);assert(D.update(s,100))
 check(s.reputation==0 and s.phase=='lose' and #s.queue==0,'Suki zero clamps and ends service immediately')
 check(not s.retail and not next(s.reservations) and Cash.total(s)==cash and same(s.inventory,inventory),'Loss releases staged sale without charging cash or stock')
 check(not C.spawn(s) and not D.next(s),'Loss blocks arrivals and next day')
 local encoded=Codec.encode(s);check(encoded~=nil,'Lose checkpoint is serializable')
 if encoded then local loaded=assert(Codec.decode(encoded));check(loaded.phase=='lose' and loaded.reputation==0,'Lose checkpoint retains terminal state') end
 check(type(require('src.app').availableViews().lose)=='table','Lose screen registered')
 assert(#failures==0,table.concat(failures,'\n'))
 -- A waiting timeout can trigger loss while a different active sale must be cancelled.
 s=opened();s.reputation=8;c=s.queue[1];assert(R.begin(s,c.id));assert(R.add(s,c.id,c.lines[1].productId,c.lines[1].quantity));assert(C.spawn(s));s.queue[2].patience=.5
 s.reservations[s.retail.lines[1].reservation].quantity=999999

 local original=S.clone(s);local ok=C.update(s,1)
 assert(not ok and same(s,original),'Failed loss cancellation leaves all live state unchanged')
 s=opened();s.reputation=0;assert(D.update(s,0));assert(s.phase=='lose' and #s.queue==0,'Zero Suki resumes into loss before arrivals')
 local App=require('src.app');local Save=require('src.persistence.save');local disk=require('tests.support.memory_disk').new();local a=App.new(Save.new(disk,'loss'))
 a:newRun();assert(a:command('openDay'));a.state.reputation=8;a.state.queue[1].patience=.1;a.pouring=true;a.change={[100]=1}
 a:update(1);assert(a.view=='lose' and not a.pouring and next(a.change)==nil,'App switches to lose and clears transient controls')
 assert(a:save());assert(a:load());assert(a.view=='lose' and a.state.reputation==0,'App loads lose screen')
 a:newRun();assert(a.view=='preparation' and a.state.reputation==50 and a.state.day==1,'New run resets terminal state')
end
