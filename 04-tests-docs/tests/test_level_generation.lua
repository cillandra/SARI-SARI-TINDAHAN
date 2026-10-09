-- Ten-day definitions and unlocked fresh order generation; no UI or settlement mocks.
return function()
 local Levels=require('data.levels');local Config=require('data.config');local State=require('src.model.state')
 local Days=require('src.systems.days');local Customers=require('src.systems.customers');local Products=require('data.products')
 local Order=require('src.systems.order');local Codec=require('src.persistence.codec')
 local rows={{6,1,50,nil,30000},{8,2,50,nil,50000},{8,2,50,.10,65000},{10,3,50,.07,80000},
  {10,3,50,.07,100000},{10,3,50,.05,120000},{12,3,50,.05,145000},{12,3,50,.05,170000},{14,4,50,.05,200000},{18,4,50,.05,280000}}
 local failures={};local function check(ok,message) if not ok then failures[#failures+1]=message end end
 for day,row in ipairs(rows) do
  local l=Levels.get(day)
  check(l.day==day and l.customers==row[1] and l.max_lines==row[2] and l.patience==row[3] and l.tolerance==row[4] and l.goal==row[5],'Day '..day..' exact metadata')
  check(type(l.intro)=='string' and type(l.tip)=='string','Day '..day..' intro/tip')
  check(l.scam_chance==(day>=6 and .2 or 0) and l.barya_low==(day>=8),'Day '..day..' persistent challenges')
 end
 check(Config.patience_max==50,'Config patience cap')
 local patienceCap=Config.patience_max;Config.patience_max=20;check(Levels.get(1).patience==20,'Level query clamps cap');Config.patience_max=patienceCap
 check(Levels.get(11).customers==19 and Levels.get(12).patience==50 and Levels.get(12).goal==340000,'Endless formulas')
 check(Levels.get(20).patience==50,'Endless retains fifty-second patience')
 local changed=Levels.get(5);changed.unlocks[1]='bad';check(Levels.get(5).unlocks[1]=='item','Independent level copies')
 assert(#failures==0,table.concat(failures,'\n'))
 local endless=State.new(17);endless.day=11;assert(Days.prepare(endless))
 local event=endless.dayProfile.event;local rng=endless.rng.randomState
 assert(Order.refresh(endless));check(endless.dayProfile.event==event and endless.rng.randomState==rng,'Repeated refresh does not reroll endless event')
 assert(Days.open(endless));local first=State.clone(endless.queue[1])
 assert(Days.retry(endless));check(endless.dayProfile.event==event and endless.rng.randomState==rng,'Endless retry retains selected event and RNG')
 assert(Days.open(endless));check(endless.queue[1].lines[1].type==first.lines[1].type and endless.queue[1].total==first.total,'Endless retry repeats first order')
 assert(#failures==0,table.concat(failures,'\n'))
 for _,case in ipairs({{30,'happy'},{21,'waiting'},{12,'waiting'},{11,'impatient'},{4.5,'impatient'},{4,'angry'}}) do
  check(Customers.mood({patience=case[1],initialPatience=30})==case[2],'Exact mood thresholds')
 end
 local fallback=State.new(1);assert(Days.prepare(fallback));assert(Days.open(fallback))
 local c=fallback.queue[1];c.lines={{type='item',productId='candy',quantity=2,amount=25000,measured=false,requestMode='quantity',requestValue=2}};c.total=25000
 fallback.prices.candy=12500;local Retail=require('src.systems.retail');local Cash=require('src.systems.cash')
 assert(Retail.begin(fallback,c.id));assert(Retail.add(fallback,c.id,'candy',2))
 check(Cash.value(assert(Customers.payment(fallback)))==50000,'Configured bills fallback to P500 when none covers total')
 assert(#failures==0,table.concat(failures,'\n'))
 local totalOrders=0
 for day=1,12 do
  local s=State.new(17);s.day=day;assert(Days.prepare(s))
  for _,p in ipairs(Products.list) do
   if p.min_g then s.inventory[p.id]={{id='batch:'..s.ids.nextBatch,quantity=10000,totalCost=p.cost*10,receivedDay=1,expiresDay=100,prepared=false}};s.ids.nextBatch=s.ids.nextBatch+1 end
  end
  s.phase='service';local weights={};local types={};local level=Levels.get(day)
  for number=1,200 do
   s.queue={};local customer,err=Customers.generate(s);local ok=customer~=nil;if customer then s.queue={customer} end;check(ok,'Day '..day..' spawn '..number..': '..tostring(err))
   if ok then
    local c=s.queue[1];totalOrders=totalOrders+1;local used={}
    check(#c.lines>=1 and level.max_lines and #c.lines<=level.max_lines,'Day '..day..' bounded lines')
    check(level.patience and c.patience==level.patience,'Day '..day..' capped starting patience')
    if level.spotlight and level.spotlight[number] then check(c.lines[1].type==level.spotlight[number],'Day '..day..' spotlight '..number) end
    for _,line in ipairs(c.lines) do
     local kind=line.type;types[kind]=true
     check(Order.allowed(day,kind),'Day '..day..' only unlocked '..tostring(kind))
     check(line.amount%100==0,'Whole peso receipt line')
     if Order.is_goods(line) then
      local p=Products.byId[line.productId]
      check(not used[p.id],'No duplicate goods product');used[p.id]=true
      check((kind=='item')==(p.saleUnit=='piece'),'Canonical shelf/measured mode')
      if kind=='weigh' then
       check(line.quantity>=p.min_g and line.quantity<=p.max_g and (line.quantity-p.min_g)%p.step_g==0,'Weigh range/step')
       weights[line.quantity]=true
      elseif kind=='repack' or kind=='pour' then
       local allowed=false
       if line.requestMode=='peso' then
        allowed=(line.requestValue==1000 or line.requestValue==2000) and line.amount==line.requestValue
       else for _,q in ipairs(p.requestSizes or p.portionSizes) do if q==line.quantity then allowed=true end end end
       check(allowed,'Allowed quantity or peso bag/bottle request')
      end
     end
    end
   end
  end
  if day>=3 then local count=0;for _ in pairs(weights) do count=count+1 end;check(count>=6,'Day '..day..' varied weigh targets') end
  for _,kind in ipairs(level.unlocks) do check(types[kind],'Day '..day..' observes unlocked '..kind) end
  local saved=assert(Codec.encode(s));local loaded=assert(Codec.decode(saved))
  s.queue={assert(Customers.generate(s))};loaded.queue={assert(Customers.generate(loaded))}
  check(Codec.encode(s)==Codec.encode(loaded),'Day '..day..' RNG save continuation')
 end
 local empty=State.new(1);empty.day=5;assert(Days.prepare(empty));empty.phase='service'
 for id in pairs(empty.inventory) do empty.inventory[id]={} end
 assert(Customers.spawn(empty));check(Order.hasWallet(empty.queue[1]),'Empty goods select eligible wallet, no empty spotlight')
 empty=State.new(1);assert(Days.prepare(empty));empty.phase='service';for id in pairs(empty.inventory) do empty.inventory[id]={} end
 local id=empty.ids.nextCustomer;check(not Customers.spawn(empty) and #empty.queue==0 and empty.ids.nextCustomer==id,'Empty Day1 does not create empty orders')
 assert(#failures==0,table.concat(failures,'\n'))
 print('LEVEL GENERATION PASS '..totalOrders..' orders Days1-12; canonical unlocks, spotlight, targets, whole pesos and RNG continuation')
end
