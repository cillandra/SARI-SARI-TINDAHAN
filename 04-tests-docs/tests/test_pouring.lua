-- Shared hold integration and atomic reset/spill losses; no mocked economy.
return function()
 local S=require('src.model.state');local D=require('src.systems.days');local P=require('src.systems.portions')
 local I=require('src.systems.inventory');local C=require('src.systems.cash');local Cmd=require('src.commands')
 local function fixture(pid,target)
  local s=S.new(4);s.day=5;assert(D.prepare(s));assert(D.open(s));local c=s.queue[1]
  c.lines={{type=pid=='cooking_oil' and 'pour' or 'repack',productId=pid,quantity=target,amount=1000,measured=true,requestMode='quantity',requestValue=target}};c.total=1000
  assert(Cmd.execute(s,'beginRetail',c.id));assert(P.target(s,c.id,pid,target));return s,c.id
 end
 local s,id=fixture('sugar',250);assert(P.adjust(s,id,1,100,true))
 assert(Cmd.execute(s,'resetPortion',id,1),'Ulitin resets opened fill through backend')
 assert(s.retail.lines[1].actualQuantity==0 and s.ledger.spoilage==640 and s.reservations[s.retail.lines[1].reservation].quantity==250,'Reset wastes actual FIFO contents and reserves target')
 assert(Cmd.execute(s,'resetPortion',id,1));assert(s.ledger.spoilage==640,'Empty reset does not waste twice')
 s,id=fixture('cooking_oil',100);local cash=C.total(s);local wallet=s.wallet.balance
 assert(P.adjust(s,id,1,115,true));assert(s.ledger.spoilage==0,'Exactly plus15 percent does not spill')
 local ok,outcome=P.adjust(s,id,1,116,true);assert(ok and outcome=='spilled','Above plus15 percent spills')
 assert(I.available(s,'cooking_oil')==1784 and s.ledger.spoilage==928 and s.ledger.operatingCosts==100 and s.ledger.cashFlow==-100,'Spill wastes116ml FIFO once plus P1 cost')
 assert(C.total(s)==cash-100 and s.wallet.balance==wallet and s.retail.total==1000 and s.retail.lines[1].spillLocked,'Spill debits only drawer fee and preserves price')
 assert(P.adjust(s,id,1,116,true));assert(s.ledger.spoilage==928 and C.total(s)==cash-100,'Repeated locked fill cannot repeat spill')
 assert(Cmd.execute(s,'resetPortion',id,1));assert(not s.retail.lines[1].spillLocked and s.ledger.spoilage==928,'Explicit reset unlocks fresh pour without another loss')
 assert(P.adjust(s,id,1,100,true));assert(P.confirm(s,id,1));assert(not Cmd.execute(s,'resetPortion',id,1),'Confirmed line cannot reset')
 s,id=fixture('cooking_oil',100);s.drawer={[5000]=1};assert(P.adjust(s,id,1,116,true));assert(C.total(s)==4900 and s.drawer[5000]==0,'Actual bill changes at equal value before fee')
 s,id=fixture('cooking_oil',100);s.drawer={};local stock=I.available(s,'cooking_oil');assert(not P.adjust(s,id,1,116,true));assert(I.available(s,'cooking_oil')==stock and s.ledger.spoilage==0,'Unfunded fee refuses atomic loss')
 s,id=fixture('cooking_oil',100);s.ledger.operatingCosts=9007199254740900;stock=I.available(s,'cooking_oil');cash=C.total(s);assert(not P.adjust(s,id,1,116,true));assert(I.available(s,'cooking_oil')==stock and C.total(s)==cash,'Overflow refuses spill atomically')
 s,id=fixture('sugar',250);s.paused=true;assert(not Cmd.execute(s,'resetPortion',id,1));assert(not P.adjust(s,id,1,20,true),'Paused pouring cannot mutate stock')
 s,id=fixture('cooking_oil',100);s.inventory.cooking_oil={{id=s.inventory.cooking_oil[1].id,quantity=150,totalCost=1200,receivedDay=1,expiresDay=181,prepared=false}}
 local ok,outcome=P.adjust(s,id,1,116,true);assert(ok and outcome=='spilled_removed' and #s.retail.lines==0 and s.retail.total==0,'Insufficient restart stock removes only unfinished spilled line')
 assert(I.available(s,'cooking_oil')==34 and next(s.reservations)==nil,'Spill removal releases target and keeps unwasted remainder')
 assert(Cmd.execute(s,'cancelCurrentCustomer',id));assert(require('src.persistence.codec').decode(assert(require('src.persistence.codec').encode(s))),'Spill loss ledger round trips after cancelled empty sale')
 s,id=fixture('cooking_oil',100);assert(P.adjust(s,id,1,1000,true));assert(s.ledger.spoilage==928,'Coarse fill stops at first spill boundary rather than wasting a whole frame')
 local M=require('src.ui.pour_meter');local amount,t,remainder=M.advance(0,0,1);assert(amount==100 and t==1,'First hold second integrates slow acceleration')
 amount,t,remainder=M.advance(t,remainder,1);assert(amount==140,'Second hold second is faster')
 amount,t,remainder=M.advance(t,remainder,1);assert(amount==160,'Pour speed caps')
 local elapsed,rest,sum=0,0,0
 for i=1,300 do local n;n,elapsed,rest=M.advance(elapsed,rest,.01);sum=sum+n end
 assert(sum==400,'Frame chunks preserve cumulative integer fill')
 assert(not M.advance(0,0,-1),'Invalid dt refused')
 local App=require('src.app');local Save=require('src.persistence.save');local a=App.new(Save.new(require('tests.support.memory_disk').new(),'pour-input'))
 a.state,id=fixture('cooking_oil',100);a:pick('cooking_oil');assert(a:startPour());a:update(1.2)
 assert(not a.pouring and a:quote().lines[1].spillLocked,'Shared hold stops immediately on spill')
 assert(a:resetPour());assert(a:startPour());a:update(.25);local q=a:quote().lines[1].actualQuantity;a:focus(false);a:update(.2)
 assert(a:quote().lines[1].actualQuantity==q and a.pourElapsed==0,'Focus loss stops and clears acceleration')
 assert(a:startPour());a:pause();assert(not a.pouring and a.pourElapsed==0,'Pause clears shared hold')
 print('POURING PASS accelerated shared hold, integer dt invariance, release/focus/pause, reset FIFO and atomic locked oil spill/fee')
end
