return function()
 local Levels=require('data.levels');local State=require('src.model.state');local Cmd=require('src.commands');local Customers=require('src.systems.customers')
 local Codec=require('src.persistence.codec');local Cash=require('src.systems.cash');local Retail=require('src.systems.retail')
 assert(table.concat(Levels.list[2].unlocks,',')=='item,cash_in,cash_out')
 assert(table.concat(Levels.get(2).unlocks or {},',')=='item,cash_in,cash_out','Day2 must unlock item,cash_in,cash_out')
 local Order=require('src.systems.order');local Wallet=require('src.systems.tindapay')
 for day=2,12 do local l=Levels.get(day);assert(l.unlocks[1]=='item' and l.unlocks[2]=='cash_in' and l.unlocks[3]=='cash_out');assert(table.concat(Order.pool(l),',')==table.concat(l.unlocks,',')) end
 assert(table.concat(Levels.get(1).unlocks,',')=='item')
 for seed=1,10 do
  local s=State.new(seed);s.day=2;assert(Cmd.execute(s,'prepareDay'));assert(Cmd.execute(s,'openDay'))
  assert(s.queue[1].number==1 and s.queue[1].lines[1].type=='cash_in')
  s.queue={};assert(Customers.spawn(s));assert(s.queue[1].number==2 and s.queue[1].lines[1].type=='cash_out')
 end
 local function fixture(kind,mixed)
  local s=State.new(1);s.day=2;assert(Cmd.execute(s,'prepareDay'));assert(Cmd.execute(s,'openDay'))
  local ref='transfer:'..kind
  s.queue={{id='customer:1',day=2,number=1,patience=120,total=kind=='cash_in' and 6000 or 1000,lines={{type=kind,principal=5000,fee=1000,amount=kind=='cash_in' and 6000 or 1000,reference=ref,recipient='store',transfer={reference=ref,amount=5000,recipient='store',status='confirmed'}}}}}
  if mixed then local c=s.queue[1];c.lines[#c.lines+1]={type='item',productId='candy',quantity=1,amount=100,measured=false,requestMode='quantity',requestValue=1};c.total=c.total+100 end
  assert(Cmd.execute(s,'beginRetail','customer:1'));return s
 end
 for _,kind in ipairs({'cash_in','cash_out'}) do for _,mixed in ipairs({false,true}) do
  local s=fixture(kind,mixed);local before=Cash.total(s);local balance=s.wallet.balance
  local transfer=State.clone(s.queue[1].lines[1].transfer);transfer.status='pending'
  local cash=Cash.total(s);assert(not Wallet.add(s,'customer:1',1,transfer));assert(Cash.total(s)==cash and s.wallet.balance==balance and #s.retail.lines==0)
  assert(Cmd.execute(s,'stageWallet','customer:1',1,s.queue[1].lines[1].transfer));assert(Cash.total(s)==before and s.wallet.balance==balance,'Wallet stage cannot move money')
  assert(Cmd.execute(s,'stageWallet','customer:1',1,s.queue[1].lines[1].transfer));assert(#s.retail.lines==1,'Repeated stage cannot duplicate line')
  if mixed then assert(Cmd.execute(s,'addRetail','customer:1','candy',1)) end
  assert(Customers.payment(s));assert(Cmd.execute(s,'stageTender','customer:1',s.queue[1].tender))
  local due=assert(Retail.changeDue(s,'customer:1'));local change=assert(Cash.plan(s,due,s.retail.tender));assert(Cmd.execute(s,'commitRetail','customer:1',change))
  local delta=kind=='cash_in' and 6000 or -4000;assert(Cash.total(s)==before+delta+(mixed and 100 or 0));assert(s.wallet.balance==balance+(kind=='cash_in' and -5000 or 5000))
  assert(s.ledger.serviceFees==1000 and s.ledger.retailRevenue==(mixed and 100 or 0) and #s.histories.wallet==1)
  local result=assert(Codec.encode(s));assert(Cmd.execute(s,'commitRetail','customer:1',change));s.commandHistory=nil;local clone=assert(Codec.decode(result));clone.commandHistory=nil;assert(Codec.encode(s)==Codec.encode(clone),'Repeated commit cannot change financial state')
  assert(Codec.decode(result),'Completed wallet history must save/load')
 end end
 local low=fixture('cash_in');low.wallet.balance=0;assert(not Wallet.add(low,'customer:1',1,low.queue[1].lines[1].transfer));assert(#low.retail.lines==0 and #low.histories.wallet==0)
 local s=fixture('cash_in');assert(Cmd.execute(s,'stageWallet','customer:1',1,s.queue[1].lines[1].transfer));local before=Cash.total(s);local wallet=s.wallet.balance;s.queue[1].patience=.001;assert(Customers.update(s,.01));assert(not s.retail and #s.queue==0 and Cash.total(s)==before and s.wallet.balance==wallet and #s.histories.wallet==0)
 for _,kind in ipairs({'cash_in','cash_out'}) do
  local failed=fixture(kind,true);assert(Cmd.execute(failed,'stageWallet','customer:1',1,failed.queue[1].lines[1].transfer));assert(Cmd.execute(failed,'addRetail','customer:1','candy',1))
  assert(Cmd.execute(failed,'stageTender','customer:1',assert(Customers.payment(failed))))
  local plan=assert(Cash.plan(failed,assert(Retail.changeDue(failed,'customer:1')),failed.retail.tender))
  if kind=='cash_in' then failed.wallet.balance=0 else for d in pairs(failed.drawer) do failed.drawer[d]=0 end end
  local snapshot=State.clone(failed);assert(not Retail.commit(failed,'customer:1',plan));local function same(a,b) if type(a)~='table' then return a==b end;for k,v in pairs(a) do if not same(v,b[k]) then return false end end;for k in pairs(b) do if a[k]==nil then return false end end;return true end;assert(same(failed,snapshot),'Rejected wallet commit must not mutate state')
  assert(Retail.cancel(failed,'customer:1'));assert(#failed.histories.wallet==0 and not failed.retail)
 end
 local App=require('src.app');local Save=require('src.persistence.save');local store=Save.new(require('tests.support.memory_disk').new(),'wallet')
 local a=App.new(store);a.state=fixture('cash_out');a.state.retail=nil;for d in pairs(a.state.drawer) do a.state.drawer[d]=0 end
 assert(not a:takeOrder());assert(a.toast=='Kulang ang cash sa drawer' and #a.state.queue==0 and not a.state.retail)
 a.state=State.new(1);a.state.day=3;assert(Cmd.execute(a.state,'prepareDay'));a.state.dayProfile.unlocks={'item'};assert(store.save(a.state));assert(a:load());assert(table.concat(a.state.dayProfile.unlocks,',')=='item,cash_in,cash_out,weigh','Load must refresh unlocks')
 print('TINDAPAY PASS cumulative Day2/3/endless; spotlights10seeds; mixed atomic cash_in/out; duplicate/cancel/timeout; save/load; low drawer')
end
