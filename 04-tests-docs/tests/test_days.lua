return function()
 local S=require('src.model.state'); local D=require('src.systems.days'); local C=require('src.systems.customers'); local R=require('src.systems.retail'); local I=require('src.systems.inventory'); local E=require('src.systems.economy')
 local a=S.new(42); local b=S.new(42)
 assert(D.prepare(a)); assert(D.prepare(b)); assert(D.open(a)); assert(D.open(b))
 assert(C.current(a).id==C.current(b).id and C.current(a).lines[1].productId==C.current(b).lines[1].productId)
 local customer=C.current(a); for _,l in ipairs(customer.lines) do assert(l.quantity>0 and I.available(a,l.productId)>=l.quantity) end
 assert(R.begin(a,customer.id)); assert(not R.add(a,customer.id,'matches',6))
 assert(R.add(a,customer.id,customer.lines[1].productId,customer.lines[1].quantity))
 local elapsed=a.time.elapsed; local patience=a.queue[1].patience; a.paused=true; assert(D.update(a,10)); assert(a.time.elapsed==elapsed and a.queue[1].patience==patience); a.paused=false
 assert(D.update(a,1000)); assert(not a.retail and not next(a.reservations or {}) and #a.queue==0 and a.phase=='report')
 assert(a.serviceOutcomes.timedOut>=1)
 assert(D.next(a)); assert(a.day==2 and a.phase=='preparation'); assert(D.open(a)); assert(D.close(a)); local n=#a.queue; assert(D.update(a,1)); assert(#a.queue<=n and a.time.closing)
 assert(D.retry(a)); assert(a.phase=='preparation' and a.day==2 and #a.queue==0)
 a.day=6; assert(D.prepare(a)); assert(a.dayProfile.supplierMultiplierBasisPoints==10000 and not a.dayProfile.credit)
 a.day=99; assert(D.prepare(a)); assert(a.dayProfile.arrivalMultiplierBasisPoints<=require('data.tuning').endless.maxArrivalMultiplierBasisPoints)
 for id in pairs(a.inventory) do a.inventory[id]={} end; for d in pairs(a.drawer) do a.drawer[d]=0 end; assert(E.needsRecovery(a))
  assert(D.retry(a)); assert(I.available(a,'candy')>0)
 local p=require('src.systems.portions'); local cash=require('src.systems.cash')
 local s=S.new(8); assert(D.prepare(s)); local rng=s.rng.state; local money=cash.total(s); assert(D.open(s))
 local first=C.current(s); assert(R.begin(s,first.id))
 for _,request in ipairs(first.lines) do
  if request.measured then assert(p.target(s,first.id,request.productId,request.requestValue,request.requestMode)); assert(p.adjust(s,first.id,#s.retail.lines,request.quantity)); assert(p.confirm(s,first.id,#s.retail.lines))
  else assert(R.add(s,first.id,request.productId,request.quantity)) end
 end
 local tender=assert(C.payment(s));assert(R.stageTender(s,first.id,tender));local change=assert(cash.plan(s,s.retail.tenderAmount-s.retail.total,tender));assert(R.commit(s,first.id,change)); assert(s.serviceOutcomes.served==1 and cash.total(s)==money+first.total)
  local reports=S.clone(s); assert(D.close(reports)); assert(D.update(reports,1000)); assert(reports.dayReport.retailRevenue==first.total)
 assert(D.next(reports)); assert(D.open(reports)); assert(D.update(reports,1000)); assert(reports.phase=='lose' and reports.reputation==0 and reports.ledger.retailRevenue==0 and reports.ledger.costOfGoods==0,'quiet second day loses Suki without repeating prior money')
 assert(C.spawn(s)); local nextId=C.current(s).id; assert(R.commit(s,first.id,{})); assert(C.current(s).id==nextId and s.serviceOutcomes.served==1)
 assert(D.retry(s)); assert(s.rng.state==rng and s.ledger.retailRevenue==0 and cash.total(s)==money and not s.retail)
  assert(D.open(s)); assert(C.current(s).id==first.id and C.current(s).lines[1].productId==first.lines[1].productId)
  for _=1,20 do C.spawn(s) end; assert(#s.queue==require('data.config').queue_max)
  local dayLedger=S.new(9); assert(D.prepare(dayLedger)); dayLedger.phase='report'; dayLedger.ledger.retailRevenue=100; dayLedger.ledger.costOfGoods=80; assert(D.next(dayLedger)); assert(dayLedger.ledger.retailRevenue==0 and dayLedger.ledger.costOfGoods==0,'daily report resets financial activity')
 local themed=S.new(3); themed.day=3; assert(D.prepare(themed)); assert(D.open(themed)); for _,line in ipairs(C.current(themed).lines) do assert(line.type=='cash_in' or line.type=='cash_out' or require('data.products').byId[line.productId],'Day3 order uses unlocked goods or wallet services') end
 themed=S.new(4); themed.day=4; assert(D.prepare(themed)); assert(D.open(themed)); for _,line in ipairs(C.current(themed).lines) do assert(line.type=='cash_in' or line.type=='cash_out' or require('data.products').byId[line.productId],'Day4 order uses unlocked goods or wallet services') end
end




