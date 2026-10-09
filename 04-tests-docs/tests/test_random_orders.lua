return function()
 local State=require('src.model.state');local Days=require('src.systems.days');local Customers=require('src.systems.customers')
 local Products=require('data.products');local Cash=require('src.systems.cash');local App=require('src.app');local Save=require('src.persistence.save')
 local Levels=require('data.levels');local chances={.60,.65,.70,.75,.80,.85,.90,.90,.95,.95};for day,chance in ipairs(chances) do assert(Levels.get(day).change_chance==chance) end;assert(Levels.get(11).change_chance==.95)
 local Codec=require('src.persistence.codec')
 local s=State.new(1);s.day=3;assert(Days.prepare(s))
 for _,p in ipairs(Products.list) do
  s.inventory[p.id]={}
  if p.id=='rice_regular' or p.id=='flour' or p.id=='sugar' or p.id=='salt' or p.id=='cooking_oil' then
   s.inventory[p.id]={{id='batch:'..s.ids.nextBatch,quantity=10000,totalCost=p.cost*10,receivedDay=1,expiresDay=100,prepared=false}};s.ids.nextBatch=s.ids.nextBatch+1
  end
 end
 assert(Days.open(s));local weights,products={},{};local previous
 local number,attempts=0,0
 while number<20 do
  attempts=attempts+1;assert(attempts<=200,'Expected 20 weigh customers')
  local hasItem=false
  local c=assert(Customers.current(s));assert(not c.tender,'Tender must wait for a complete basket')
  for _,line in ipairs(c.lines) do
   if line.type=='weigh' then
   hasItem=true
   local p=Products.byId[line.productId];assert(line.measured and line.requestMode=='quantity')
   assert(line.quantity>=p.min_g and line.quantity<=p.max_g and (line.quantity-p.min_g)%p.step_g==0)
   assert(line.productId~=previous,'Consecutive loose products must differ when alternatives exist');previous=line.productId
   assert(line.amount%100==0 and line.amount==math.floor((s.prices[p.id]*line.quantity+p.priceQuantity*50)/(p.priceQuantity*100))*100)
   weights[line.quantity]=true;products[p.id]=true
   end
  end
  if hasItem then number=number+1 end
  s.queue={assert(Customers.generate(s))}
 end
 local count=0;for _ in pairs(weights) do count=count+1 end;assert(count>=6,'20 customers need at least six distinct quantities in seeded sample')
 local n=0;for _ in pairs(products) do n=n+1 end;assert(n==4,'All four dry loose products are eligible for Day3 weigh; oil unlocks Day5')
 print('RANDOM ORDER SAMPLE PASS 20 customers; '..count..' targets; '..n..' products')
 local store=Save.new(require('tests.support.memory_disk').new(),'orders');assert(store.save(s));local loaded=assert(store.load())
 local bad=State.clone(s);bad.rng.randomState='broken';assert(not Codec.encode(bad),'Malformed RNG state cannot load')
 bad=State.clone(s);bad.rng.lastLoose='candy';assert(not Codec.encode(bad),'Previous loose product must be eligible')
 s.queue={assert(Customers.generate(s))};loaded.queue={assert(Customers.generate(loaded))};assert(Codec.encode(s)==Codec.encode(loaded),'RNG continuation survives save/load')
 local a=App.new(Save.new(require('tests.support.memory_disk').new(),'payments'));a.state=State.new(1);assert(a:command('prepareDay'));assert(a:command('openDay'));local changed=0
 for number=1,6 do
  local c=assert(Customers.current(a.state));assert(not Customers.payment(a.state),'Incomplete basket cannot generate payment')
  for _,r in ipairs(c.lines) do a:pick(r.productId);if r.measured then local q=a:quote();local i=#q.lines;a:adjust(q.lines[i].targetQuantity);if a.view=='timbangan' then assert(a:confirmTimbangan()) else a:confirmPortion(i) end end end
  local quote=a:quote();local total=quote.total;local before=Cash.total(a.state)
  local bundle=assert(Customers.payment(a.state));local tender=assert(Cash.value(bundle));assert(tender>=total and total%100==0)
  local rng=Codec.encode(a.state);assert(Customers.payment(a.state));assert(Codec.encode(a.state)==rng,'Payment cannot reroll')
  if number<=2 then assert(tender>total,'Day1 first two require change') end
  a:receive()
  if tender>total then
   changed=changed+1;assert(a.view=='drawer' and Cash.total(a.state)==before,'Nonexact tender remains staged')
   local q=a:quote();local plan=assert(Cash.plan(a.state,q.tenderAmount-q.total,q.tender));for d,n in pairs(plan) do for _=1,n do a:changePiece(d) end end;a:commit()
  else assert(a.view=='counter' and a.toast=='Eksaktong bayad!','Exact tender skips Sukli') end
  local record=assert(a.state.completedReferences[c.id]);local tip=record.tip or 0
  assert(tip%100==0 and (tip==0 or tip>=500 and tip<=1000),'Tip must be zero or a whole-peso reward from P5 to P10')
  assert(not a.state.retail and Cash.total(a.state)==before+total+tip and #a.state.histories.retail==number)
  local tipsBeforeRepeat=a.state.ledger.tips or 0
  a:commit();assert(Cash.total(a.state)==before+total+tip and (a.state.ledger.tips or 0)==tipsBeforeRepeat,'Repeated confirmation cannot duplicate money or tips')
  if number<6 then assert(Customers.spawn(a.state)) end
 end
 assert(changed>=3,'Seeded Day1 six-customer sample needs at least three change sales');print('PAYMENT SAMPLE PASS Day1 six customers; '..changed..' change sales; first two guaranteed')
end
