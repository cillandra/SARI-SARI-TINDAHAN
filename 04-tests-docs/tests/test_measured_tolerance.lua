-- Real measured reservations, receipt prices and historical save validation.
return function()
 local S=require('src.model.state');local D=require('src.systems.days');local P=require('src.systems.portions')
 local R=require('src.systems.retail');local I=require('src.systems.inventory');local C=require('src.systems.cash')
 local Codec=require('src.persistence.codec');local Products=require('data.products')
 local function fixture(day,pid,target,kind)
  local s=S.new(4);s.day=day;assert(D.prepare(s));assert(D.open(s));local c=s.queue[1]
  c.lines={{type=kind,productId=pid,quantity=target,amount=2800,measured=true,requestMode='quantity',requestValue=target}};c.total=2800
  assert(R.begin(s,c.id));assert(P.target(s,c.id,pid,target));return s,c.id
 end
 local s,id=fixture(3,'rice_regular',500,'weigh')
 assert(P.adjust(s,id,1,450));assert(P.confirm(s,id,1),'Day3 lower green boundary confirms')
 assert(s.retail.lines[1].quantity==450 and s.retail.lines[1].targetQuantity==500 and s.retail.total==2800,'Actual stock differs from unchanged target and receipt')
 assert(s.reservations[s.retail.lines[1].reservation].quantity==450,'Confirmed underfill releases unused target reservation')
 assert(not P.confirm(s,id,1),'Repeated confirmation cannot reward again')
 assert(R.stageTender(s,id,{[5000]=1}));assert(R.commit(s,id,{[2000]=1,[100]=2}))
 assert(s.ledger.costOfGoods==2025 and I.available(s,'rice_regular')==4550,'Sale consumes actual450g at original FIFO cost')
 assert(Codec.decode(assert(Codec.encode(s))),'Modern underfill history round trips')
 local bad=S.clone(s);bad.histories.retail[1].lines[1].quantity=449;bad.histories.retail[1].lines[1].actualQuantity=449
 assert(not Codec.encode(bad),'History below that day tolerance rejected')
 for _,case in ipairs({{3,449,false},{3,550,true},{3,551,false},{4,465,true},{4,464,false},{6,475,true},{6,474,false},{6,525,true},{6,526,false}}) do
  s,id=fixture(case[1],'rice_regular',500,'weigh');assert(P.adjust(s,id,1,case[2]));local ok=P.confirm(s,id,1)
  assert((ok==true)==case[3],'Day tolerance boundary '..case[1]..' quantity '..case[2])
 end
 s,id=fixture(3,'rice_regular',500,'weigh');assert(P.adjust(s,id,1,450));assert(P.confirm(s,id,1));assert(R.cancel(s,id))
 assert(I.available(s,'rice_regular')==5000 and next(s.reservations)==nil,'Cancel confirmed underfill releases stock')
 s,id=fixture(3,'rice_regular',500,'weigh');assert(P.adjust(s,id,1,450,true));assert(P.confirm(s,id,1));s.queue[1].patience=1;assert(D.update(s,1))
 assert(not s.retail and next(s.reservations)==nil and s.ledger.spoilage==2025,'Timeout confirmed open underfill wastes actual FIFO contents once')
 assert(Products.byId.cooking_oil.timbangan and Products.byId.cooking_oil.timbangan.slot==5,'Mantika fifth permanent bin')
 local App=require('src.app');local Save=require('src.persistence.save');local a=App.new(Save.new(require('tests.support.memory_disk').new(),'oil-bin'))
 a.state,id=fixture(5,'cooking_oil',100,'pour');a.portionProduct='cooking_oil';assert(a:openTimbangan())
 assert(a.view=='timbangan' and a.timbanganMode=='pour','Oil opens matching shared station mode')
 local m=require('src.ui.timbangan_model').model(a);assert(m.lower==93 and m.upper==107,'Oil model reflects Day5 tolerance')
 a.state,id=fixture(3,'sugar',500,'weigh');a.portionProduct='sugar';assert(a:openTimbangan())
 assert(a.timbanganMode=='weigh','Day3 sugar weigh request overrides bin repack preset')
 assert(a:selectTimbanganBin('sugar') and a.timbanganMode=='weigh','Same-bin selection retains requested weigh mode')
 print('MEASURED TOLERANCE PASS daily green bounds, actual FIFO stock, unchanged price, cancel/timeout, historical save and fifth oil bin')
end
