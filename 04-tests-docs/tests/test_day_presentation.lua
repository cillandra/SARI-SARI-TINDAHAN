-- Day goals, warnings and currency-conserving restock preparation.
return function()
 local S=require('src.model.state');local D=require('src.systems.days');local E=require('src.systems.economy');local C=require('src.systems.cash')
 local Cmd=require('src.commands');local Codec=require('src.persistence.codec')
 local function closed(revenue,fees,mistakes)
  local s=S.new(1);assert(D.prepare(s));assert(D.open(s));s.queue={};s.ledger.retailRevenue=revenue;s.ledger.serviceFees=fees;s.serviceOutcomes.mistakes=mistakes
  assert(D.close(s));return s
 end
 local s=closed(29900,100,0)
 assert(s.dayReport.goal==30000 and s.dayReport.earned==30000 and s.dayReport.stars==3 and s.dayReport.suki==50,'Goal uses sales plus fees and rewards a mistake-free goal')
 s=closed(29900,0,0);assert(s.dayReport.stars==1,'Missing goal awards survived star')
 s=closed(30000,0,1);assert(s.dayReport.stars==2,'Mistake limits goal result to two stars')
 s=closed(0,0,0);local cash=C.total(s);assert(D.next(s));assert(s.day==2 and C.total(s)==cash,'Missed goal never blocks next day or resets money')
 s=S.new(1);s.day=7;assert(D.prepare(s));assert(D.open(s));s.queue={};assert(D.close(s));assert(s.dayReport.nextWarning==require('data.levels').get(8).warning,'Day7 summary warns for Day8')
 local encoded=assert(Codec.encode(s));assert(Codec.decode(encoded),'New summary round trip')
 local malformed=S.clone(s);malformed.dayReport.stars=3;assert(not Codec.encode(malformed),'Incorrect persisted stars rejected')
 local old=S.clone(s);for _,record in ipairs({old.dayReport,old.histories.days[1]}) do record.goal=nil;record.earned=nil;record.stars=nil;record.suki=nil;record.nextWarning=nil end
 assert(Codec.decode(assert(Codec.encode(old))),'Old reports without presentation fields still load')
 assert(E.summary(old).stars==1,'Old summary display derives missing rating')
 s=S.new(1);assert(D.prepare(s));assert(D.open(s));s.queue={};for id in pairs(s.inventory) do s.inventory[id]={} end;for d in pairs(s.drawer) do s.drawer[d]=0 end
 assert(D.close(s));assert(s.phase=='report' and D.next(s),'Surviving empty shop may continue rather than be trapped in recovery')
 s=S.new(1);s.day=8;cash=C.total(s);assert(D.prepare(s));assert(C.total(s)==cash and s.drawer[100]<=4 and s.drawer[500]<=1,'Low coins convert to larger denominations without losing money')
 assert(s.dayProfile.baryaPrepared,'Low-coin preparation recorded once')
 local beforeLedger=S.clone(s.ledger);local billCount=s.drawer[5000];assert(Cmd.execute(s,'exchangeBarya'))
 assert(s.drawer[5000]==billCount-1 and s.drawer[100]>=10 and s.drawer[500]>=4 and C.total(s)==cash and s.ledger.cashFlow==beforeLedger.cashFlow,'P50 bill exchanges for actual coins with zero net flow')
 local ones,fives=s.drawer[100],s.drawer[500];assert(D.prepare(s));assert(s.drawer[100]==ones and s.drawer[500]==fives,'Repeated prepare does not remove exchanged coins')
 local loaded=assert(Codec.decode(assert(Codec.encode(s))));assert(D.prepare(loaded));assert(loaded.drawer[100]==ones,'Load preserves once-only low-coin preparation')
 assert(D.retry(s));assert(s.drawer[100]==ones,'Retry preserves prepared morning coin state')
 s=S.new(1);assert(D.prepare(s));s.drawer={[100]=50};cash=C.total(s);assert(not Cmd.execute(s,'exchangeBarya'));assert(C.total(s)==cash and s.drawer[100]==50,'Coin-only drawer cannot fund a bill exchange')
 s=S.new(1);assert(D.prepare(s));s.drawer={[10000]=1};cash=C.total(s)
 local ledger=S.clone(s.ledger);local wallet=s.wallet.balance
 assert(require('src.systems.restock').bundle(s).enabled,'A larger bill must fund the P50 coin bundle')
 assert(Cmd.execute(s,'exchangeBarya'))
 assert(s.drawer[100]==10 and s.drawer[500]==4 and s.drawer[1000]==2 and s.drawer[5000]==1
  and s.drawer[10000]==0 and C.total(s)==10000 and s.wallet.balance==wallet
  and s.ledger.cashFlow==ledger.cashFlow,'P100 exchange returns P50 plus the exact coin bundle with no gain')
 s.drawer={[2000]=3};cash=C.total(s);assert(Cmd.execute(s,'exchangeBarya'))
 assert(C.total(s)==cash and s.drawer[1000]==3,'P60 bills return P10 plus the P50 coin bundle')
 s.drawer={[2000]=2};cash=C.total(s);assert(not Cmd.execute(s,'exchangeBarya'))
 assert(C.total(s)==cash and s.drawer[2000]==2,'Insufficient bill value refuses atomically')
 s.drawer={[5000]=1};s.paused=true;assert(not Cmd.execute(s,'exchangeBarya'));assert(s.drawer[5000]==1,'Paused restock does not exchange')
 s.paused=false;assert(D.open(s));assert(not Cmd.execute(s,'exchangeBarya'));assert(s.drawer[5000]==1,'Service cannot exchange coins')
 s=S.new(1);s.day=8;s.drawer={[100]=23,[500]=13,[1000]=0};cash=C.total(s);assert(D.prepare(s));assert(C.total(s)==cash and s.drawer[100]<=4 and s.drawer[500]<=1,'Odd coin conversion conserves all centavos')
 local card=D.start_card(s);assert(card.day==8 and card.customers==12 and card.goal==170000 and card.intro and card.tip and card.barya_notice,'Start card and restock query use current level')
 s=S.new(1);assert(D.prepare(s));assert(D.open(s));s.queue={};s.ledger.retailRevenue=9007199254740900;s.ledger.serviceFees=100
 local phase=s.phase;local closing=s.time.closing;assert(not D.close(s));assert(s.phase==phase and s.time.closing==closing and #s.histories.days==0,'Summary overflow refuses closure atomically')
 s=S.new(1);s.day=9007199254740991;assert(not E.day_report(s),'Out-of-range endless goal refuses a report')
 print('DAY PRESENTATION PASS goal/stars, warnings, legacy reports, neutral coin exchange and once-only scarcity')
end
