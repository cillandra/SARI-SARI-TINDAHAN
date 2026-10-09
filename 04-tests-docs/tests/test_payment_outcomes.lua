-- Gameplay settlement: bounded retry, exact-once rewards and atomic money movement.
return function()
 local S=require('src.model.state');local D=require('src.systems.days');local R=require('src.systems.retail');local Cmd=require('src.commands')
 local C=require('src.systems.cash');local I=require('src.systems.inventory');local Codec=require('src.persistence.codec');local E=require('src.systems.economy')
 local function fixture(patience)
  local s=S.new(1);assert(D.prepare(s));assert(D.open(s));local c=s.queue[1]
  c.lines={{type='item',productId='candy',quantity=1,amount=100,measured=false,requestMode='quantity',requestValue=1}};c.total=100
  assert(R.begin(s,c.id));assert(R.add(s,c.id,'candy',1));assert(R.stageTender(s,c.id,{[1000]=1}));c.patience=patience or c.initialPatience
  return s,c.id
 end
 local function stockQuantity(s) local q=0;for _,batch in ipairs(s.inventory.candy) do q=q+batch.quantity end;return q end
 local s,id=fixture();local cash=C.total(s);local stock=stockQuantity(s)
 local ok,result=Cmd.execute(s,'confirmPayment',id,{})
 assert(ok and result=='retry','First wrong change offers one retry')
 assert(s.reputation==47 and s.retail and C.total(s)==cash and stockQuantity(s)==stock,'Retry costs three Suki without settling cash/stock')
 ok,result=Cmd.execute(s,'confirmPayment',id,{})
 assert(ok and result=='completed' and not s.retail and s.reputation==47,'Second wrong change finishes and charges Suki only once')
 assert(C.total(s)==cash+100 and stockQuantity(s)==stock-1 and s.histories.retail[1].changeAmount==900,'Second error settles correct feasible change')
 assert((s.ledger.tips or 0)==0,'Mistaken order cannot earn a tip')
 assert(Codec.encode(s));assert(Cmd.execute(s,'confirmPayment',id,{}));assert(s.reputation==47 and C.total(s)==cash+100,'Repeated confirmation cannot duplicate penalty or cash')
 s,id=fixture();cash=C.total(s);ok,result=Cmd.execute(s,'confirmPayment',id,{[1000]=1})
 assert(ok and result=='retry' and s.reputation==47 and C.total(s)==cash,'Overpayment also gets a retry before any money changes')
 assert(Cmd.execute(s,'confirmPayment',id,{[100]=9}));assert(s.reputation==47 and (s.ledger.tips or 0)==0,'Correct retry has no repeated penalty or perfect reward')
 s,id=fixture();cash=C.total(s);assert(Cmd.execute(s,'confirmPayment',id,{[100]=9}))
 local tip=s.histories.retail[1].tip;assert(tip>=500 and tip<=1000 and tip%100==0 and s.reputation==52,'Happy perfect order gets two Suki and whole-peso P5-P10 tip')
 assert(C.total(s)==cash+100+tip and s.ledger.tips==tip and s.ledger.cashFlow==100+tip,'Tip enters real denominations and cash ledger')
 assert(E.report(s).profit==20+tip,'Profit includes tips separately from retail revenue')
 assert(Codec.decode(assert(Codec.encode(s))),'Reward checkpoint survives strict codec')
 local finalCash=C.total(s);local rng=s.rng.randomState;assert(Cmd.execute(s,'confirmPayment',id,{}));assert(C.total(s)==finalCash and s.reputation==52 and s.rng.randomState==rng,'Completed reference cannot reroll reward')
 s,id=fixture(35);assert(Cmd.execute(s,'confirmPayment',id,{[100]=9}));assert(s.reputation==50 and (s.ledger.tips or 0)==0,'Seventy percent patience is not happy')
 s,id=fixture();s.reputation=99;assert(Cmd.execute(s,'confirmPayment',id,{[100]=9}));assert(s.reputation==100,'Happy reward clamps Suki')
 s,id=fixture();s.reputation=3;cash=C.total(s);assert(Cmd.execute(s,'confirmPayment',id,{}));assert(s.phase=='lose' and s.reputation==0 and not s.retail and C.total(s)==cash,'Mistake reaching zero cancels instead of settling')
 s,id=fixture();local snapshot=S.clone(s);ok=Cmd.execute(s,'confirmPayment',id,{[100000]=1});assert(not ok and s.reputation==50 and not s.queue[1].changeMistake and s.retail and C.total(s)==C.total(snapshot),'Infeasible selection is rejected without mistake penalty')
 -- Principal-inclusive cash_out correction cannot underpay the withdrawal.
 local Wallet=require('src.systems.tindapay');local Customers=require('src.systems.customers')
 s=S.new(1);s.day=2;assert(D.prepare(s));assert(D.open(s));assert(Customers.spawn(s));table.remove(s.queue,1)
 local customer=s.queue[1];id=customer.id;local request=customer.lines[1];assert(request.type=='cash_out')
 assert(R.begin(s,id));assert(Wallet.add(s,id,1,request.transfer));assert(R.stageTender(s,id,{[2000]=1}));cash=C.total(s);local wallet=s.wallet.balance
 assert(Cmd.execute(s,'confirmPayment',id,{}));assert(Cmd.execute(s,'confirmPayment',id,{}))
 assert(C.total(s)==cash+1000-request.principal and s.wallet.balance==wallet+request.principal and s.histories.retail[1].changeAmount==request.principal+1000 and s.reputation==47,'Second error pays principal and preserves wallet conservation')
 -- An unavailable correction remains staged with no second penalty or reward draw.
 s,id=fixture();assert(Cmd.execute(s,'confirmPayment',id,{}));s.drawer[100]=0;s.drawer[500]=0
 cash=C.total(s);local priorRng=s.rng.randomState
 assert(not Cmd.execute(s,'confirmPayment',id,{}));assert(s.retail and s.reputation==47 and C.total(s)==cash and s.rng.randomState==priorRng and #s.histories.retail==0,'No correction denominations leaves payment staged')
 -- Optional reward fields preserve legacy checkpoints and report arithmetic.
 local old=S.new(1);assert(D.prepare(old));local loaded=assert(Codec.decode(assert(Codec.encode(old))))
 assert(loaded.ledger.tips==nil and E.report(loaded).tips==0 and E.report(loaded).profit==0,'Legacy checkpoint needs no reward fields')
 local App=require('src.app');local Save=require('src.persistence.save');local a=App.new(Save.new(require('tests.support.memory_disk').new(),'retry-ui'))
 a.state,id=fixture();a.saleId=id;a:go('drawer');a.change={[100]=1};a.changeOrder={100};cash=C.total(a.state)
 a:commit();assert(a.view=='drawer' and a.state.retail and next(a.change)==nil and #a.changeOrder==0 and a.state.reputation==47 and C.total(a.state)==cash,'Rendered retry clears staged tray without moving cash')
 -- A tip can overflow the drawer even when raw sale settlement still fits.
 s,id=fixture();s.drawer={[100]=90071992547408};cash=C.total(s);local drawerRng=s.rng.randomState
 local safe,result=pcall(Cmd.execute,s,'confirmPayment',id,{[100]=9})
 assert(safe and not result,'Drawer reward overflow returns an error instead of asserting')
 assert(s.retail and #s.histories.retail==0 and C.total(s)==cash and s.reputation==50 and s.rng.randomState==drawerRng,'Drawer reward overflow leaves settlement and reward RNG untouched')
 -- Tip overflow must not publish a partly settled sale or advanced reward RNG.
 s,id=fixture();s.ledger.tips=9007199254740900;cash=C.total(s);local previousRng=s.rng.randomState
 assert(not Cmd.execute(s,'confirmPayment',id,{[100]=9}));assert(s.retail and #s.histories.retail==0 and C.total(s)==cash and s.reputation==50 and s.rng.randomState==previousRng,'Reward overflow rejects atomically')
end
