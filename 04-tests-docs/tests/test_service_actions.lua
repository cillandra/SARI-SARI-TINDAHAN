-- Wrong-item and truthful/forged wallet outcomes through gameplay commands.
return function()
 local S=require('src.model.state');local D=require('src.systems.days');local R=require('src.systems.retail');local Cmd=require('src.commands')
 local Cash=require('src.systems.cash');local Order=require('src.systems.order');local Codec=require('src.persistence.codec');local E=require('src.systems.economy')
 local function fixture(kind,fake)
  local s=S.new(17);s.day=6;assert(D.prepare(s));assert(D.open(s));local c=s.queue[1]
  local request=Order.service(s,kind,1);request.receipt=S.clone(request.transfer);if fake then request.receipt.status='pending' end
  c.lines={request};c.total=request.amount;assert(R.begin(s,c.id));return s,c.id,request
 end
 local s,id=fixture('cash_out',false);local cash=Cash.total(s);local wallet=s.wallet.balance
 local ok=Cmd.execute(s,'rejectWallet',id,1)
 assert(ok,'Valid transfer can be rejected by gameplay command')
 assert(s.reputation==47 and #s.queue==0 and not s.retail and Cash.total(s)==cash and s.wallet.balance==wallet,'Valid rejection costs three Suki without moving funds')
 assert(not Cmd.execute(s,'rejectWallet',id,1));assert(s.reputation==47 and s.serviceOutcomes.timedOut==1,'Repeated rejection cannot dismiss or penalize twice')
 s,id=fixture('cash_out',true);cash=Cash.total(s);assert(Cmd.execute(s,'rejectWallet',id,1));assert(s.reputation==50 and Cash.total(s)==cash and (s.ledger.scamLosses or 0)==0,'Reject scam without penalty or loss')
 for _,kind in ipairs({'cash_in','cash_out'}) do
  local request;s,id,request=fixture(kind,true);cash=Cash.total(s);wallet=s.wallet.balance
  assert(Cmd.execute(s,'acceptWallet',id,1));assert(s.reputation==45 and #s.queue==0 and not s.retail,'Accept scam loses five Suki and ends customer')
  assert(Cash.total(s)==cash-(kind=='cash_out' and request.principal or 0) and s.wallet.balance==wallet-(kind=='cash_in' and request.principal or 0),'Scam loses principal from correct account without fake credit')
  assert(s.ledger.scamLosses==request.principal and s.ledger.serviceFees==0 and #s.histories.wallet==0 and #s.histories.retail==0 and E.report(s).profit==-request.principal,'Scam loss separate from real transactions/profit')
  assert(Codec.decode(assert(Codec.encode(s))),'Scam checkpoint round trip')
  assert(not Cmd.execute(s,'acceptWallet',id,1));assert(s.reputation==45 and s.ledger.scamLosses==request.principal,'Accepted scam cannot repeat')
 end
 s,id=fixture('cash_in',false);cash=Cash.total(s);wallet=s.wallet.balance;assert(Cmd.execute(s,'acceptWallet',id,1));assert(Cmd.execute(s,'acceptWallet',id,1))
 assert(#s.retail.lines==1 and s.reputation==50 and Cash.total(s)==cash and s.wallet.balance==wallet,'Valid acceptance stages exactly once without moving balances')
 assert(not Cmd.execute(s,'rejectWallet',id,1),'Cannot reject already verified line')
 s,id=fixture('cash_in',false);s.paused=true;assert(not Cmd.execute(s,'rejectWallet',id,1));assert(s.reputation==50 and s.retail,'Pause blocks rejection')
 s,id=fixture('cash_in',false);assert(not Cmd.execute(s,'acceptWallet',id,99));assert(s.reputation==50 and #s.retail.lines==0,'Invalid line has no side effects')
 s,id=fixture('cash_out',true);s.reputation=5;assert(Cmd.execute(s,'acceptWallet',id,1));assert(s.phase=='lose' and s.reputation==0 and #s.queue==0,'Scam penalty can end run')
 -- Corrupt basket cancellation must roll back all scam consequences.
 s,id=fixture('cash_out',true);local c=s.queue[1];c.lines[2]={type='item',productId='candy',quantity=1,amount=100,measured=false,requestMode='quantity',requestValue=1};c.total=c.total+100
 assert(R.add(s,id,'candy',1));s.reservations[s.retail.lines[1].reservation].quantity=999
 cash=Cash.total(s);wallet=s.wallet.balance;assert(not Cmd.execute(s,'acceptWallet',id,1));assert(s.reputation==50 and s.retail and #s.queue==1 and Cash.total(s)==cash and s.wallet.balance==wallet and not s.ledger.scamLosses,'Failed cancellation does not publish scam loss')
 -- Each inappropriate shelf pick penalizes Suki, never stock/money.
 s=S.new(1);assert(D.prepare(s));assert(D.open(s));c=s.queue[1];id=c.id
 c.lines={{type='item',productId='candy',quantity=1,amount=100,measured=false,requestMode='quantity',requestValue=1}};c.total=100
 cash=Cash.total(s);local inventory=S.clone(s.inventory)
 assert(Cmd.execute(s,'wrongItem',id,'matches'));assert(s.reputation==47 and s.queue[1].mistake and Cash.total(s)==cash and not s.retail,'Wrong shelf pick costs three without adding goods')
 for pid,batches in pairs(inventory) do for i,batch in ipairs(batches) do assert(s.inventory[pid][i].quantity==batch.quantity and s.inventory[pid][i].totalCost==batch.totalCost,'Wrong pick preserves all stock quantities and costs') end end
 assert(not Cmd.execute(s,'wrongItem',id,'candy'));assert(s.reputation==47,'Requested item is not a wrong selection')
 local App=require('src.app');local Save=require('src.persistence.save');local a=App.new(Save.new(require('tests.support.memory_disk').new(),'mistakes'));a.state=s;a:pick('matches')
 assert(a.state.reputation==44 and a.toast=='Hindi ito inorder' and not a.state.retail,'App routes wrong item to backend')
 a.state.reputation=3;a:pick('matches');assert(a.state.phase=='lose' and a.view=='lose' and a.state.reputation==0,'Wrong-item zero Suki enters lose immediately')
 -- Reviewer regressions: malformed evidence, resource shortage and complete mistake stats.
 local failures={};local function check(ok,label) if not ok then failures[#failures+1]=label end end
 local request
 s,id,request=fixture('cash_out',false);request.recipient=123;request.transfer.recipient=123;request.receipt.recipient='other';cash=Cash.total(s)
 check(not Cmd.execute(s,'acceptWallet',id,1) and s.reputation==50 and Cash.total(s)==cash,'Malformed canonical recipient cannot cause scam loss')
 s,id,request=fixture('cash_in',false);request.receipt=false
 check(not Cmd.execute(s,'acceptWallet',id,1) and #s.retail.lines==0,'Explicit false receipt is malformed, not legacy fallback')
 for _,action in ipairs({'acceptWallet','rejectWallet'}) do
  s,id=fixture('cash_out',false);for d in pairs(s.drawer) do s.drawer[d]=0 end
  check(Cmd.execute(s,action,id,1) and s.reputation==50 and #s.queue==0 and not s.retail,action..' low drawer dismisses without penalty')
 end
 s,id=fixture('cash_in',false);assert(Cmd.execute(s,'acceptWallet',id,1));assert(R.stageTender(s,id,{[50000]=1}));assert(Cmd.execute(s,'confirmPayment',id,{}))
 check(s.serviceOutcomes.mistakes==1,'Wrong change counts one reported mistake')
 assert(#failures==0,table.concat(failures,'\n'))
 -- Generated screenshots are truthful before Day6 and differ in one field thereafter.
 local fields={'amount','reference','recipient','status'};local types={};local fakes=0
 for day=1,12 do
  local generated=S.new(29);generated.day=day
  for _=1,100 do
   local line=Order.service(generated,'cash_out',1);local receipt=line.receipt or line.transfer;local n=0;local changed
   for _,field in ipairs(fields) do if receipt[field]~=line.transfer[field] then n=n+1;changed=field end end
   assert(n<=1 and (day>=6 or n==0),'Exactly one mismatching field only when scam chance unlocked')
   if n==1 then fakes=fakes+1;types[changed]=true end
  end
 end
 local count=0;for _ in pairs(types) do count=count+1 end;assert(fakes>0 and count==4,'Random scam generation covers all four mismatch fields')
 print('SERVICE ACTIONS PASS wrong items, accept/reject, scam money/rollback, legacy receipts; generated screenshot mismatches='..fakes)
end
