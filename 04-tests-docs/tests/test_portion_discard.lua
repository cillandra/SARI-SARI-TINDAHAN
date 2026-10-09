-- Approved portion-only discard: reference stability, FIFO spoilage and atomic failures.
return function()
 local S=require('src.model.state')
 local P=require('src.systems.portions')
 local R=require('src.systems.retail')
 local I=require('src.systems.inventory')
 local C=require('src.systems.cash')
 local Cmd=require('src.commands')
 assert(type(P.discard)=='function','Approved portion-only discard API is missing')
 local function fixture(opened,actual)
  local s=S.new(19); s.phase='service'
  s.queue={{id='neighbor',patience=84}}
  assert(R.begin(s,'sale'))
  assert(R.add(s,'sale','candy',1))
  assert(P.target(s,'sale','sugar',250))
  assert(P.adjust(s,'sale',2,actual or 300,opened))
  assert(P.target(s,'sale','rice_regular',1000))
  assert(P.adjust(s,'sale',3,1000)); assert(P.confirm(s,'sale',3))
  return s,s.retail.lines[2].reservation
 end
 local function same(a,b)
  if type(a)~=type(b) then return false end
  if type(a)~='table' then return a==b end
  for k,v in pairs(a) do if not same(v,b[k]) then return false end end
  for k in pairs(b) do if a[k]==nil then return false end end
  return true
 end
 local function unchanged(s,id,ref)
  local before=S.clone(s)
  local ok,err=P.discard(s,id,ref)
  assert(not ok and type(err)=='string' and #err>0,'Discard failure must explain why')
  assert(same(s,before),'Failed discard must be atomic')
 end
 local s,ref=fixture(true)
 local cash=C.total(s); local wallet=s.wallet.balance
 local total=s.retail.total; local nextLine=s.retail.nextLine
 local candyRef=s.retail.lines[1].reservation; local riceRef=s.retail.lines[3].reservation
 assert(P.discard(s,'sale',ref))
 assert(s.retail.id=='sale' and #s.retail.lines==2 and s.retail.total==total-2000)
 assert(s.retail.nextLine==nextLine,'Reservation serial must never rewind')
 assert(s.retail.lines[1].reservation==candyRef and s.retail.lines[2].reservation==riceRef)
 assert(s.reservations[candyRef].quantity==1 and s.reservations[riceRef].quantity==1000)
 assert(not s.reservations[ref] and s.inventory.sugar[1].quantity==1700)
 assert(s.ledger.spoilage==1920 and s.ledger.retailRevenue==0 and s.ledger.costOfGoods==0 and s.ledger.cashFlow==0)
 assert(C.total(s)==cash and s.wallet.balance==wallet and s.queue[1].patience==84)
 assert(not s.cancelledRetail and not s.completedReferences.sale)
 unchanged(s,'sale',ref)
 assert(P.target(s,'sale','sugar',250))
 local freshRef=s.retail.lines[3].reservation
 assert(freshRef~=ref)
 unchanged(s,'sale',ref)
 assert(s.reservations[freshRef],'Stale retry cannot discard replacement portion')

 -- Removing a preceding line must not redirect a captured reference.
 s,ref=fixture(true,100)
 assert(R.remove(s,'sale',1))
 assert(P.discard(s,'sale',ref))
 assert(#s.retail.lines==1 and s.retail.lines[1].productId=='rice_regular')
 assert(s.ledger.spoilage==640 and s.inventory.sugar[1].quantity==1900)

 -- Intact and empty portions return every reserved unit.
 for _,case in ipairs({{false,300},{true,0}}) do
  s,ref=fixture(case[1],case[2]); assert(P.discard(s,'sale',ref))
  assert(s.inventory.sugar[1].quantity==2000 and s.ledger.spoilage==0 and I.available(s,'sugar')==2000)
 end

 -- FIFO exact recorded costs, partial batch rounding and expiry skip.
 s=S.new(7); s.phase='service'
 s.inventory.sugar={
  {id='expired',quantity=100,totalCost=500,receivedDay=0,expiresDay=1,prepared=false},
  {id='old',quantity=100,totalCost=101,receivedDay=1,expiresDay=40,prepared=false},
  {id='new',quantity=200,totalCost=401,receivedDay=1,expiresDay=40,prepared=false}}
 assert(R.begin(s,'fifo')); assert(P.target(s,'fifo','sugar',250))
 assert(P.adjust(s,'fifo',1,150,true)); ref=s.retail.lines[1].reservation
 assert(P.discard(s,'fifo',ref))
 assert(s.ledger.spoilage==201 and #s.inventory.sugar==2)
 assert(s.inventory.sugar[1].id=='expired' and s.inventory.sugar[2].quantity==150 and s.inventory.sugar[2].totalCost==301)
 assert(s.retail.total==0 and #s.retail.lines==0 and I.available(s,'sugar')==150)

 s,ref=fixture(true)
 unchanged(s,'other-sale',ref); unchanged(s,'sale','retail:foreign:2')
 unchanged(s,'sale',2); unchanged(s,'sale',nil)
 unchanged(s,'sale',s.retail.lines[1].reservation)
 unchanged(s,'sale',s.retail.lines[3].reservation)
 s,ref=fixture(true); s.reservations[ref]=nil; unchanged(s,'sale',ref)
 s,ref=fixture(true); s.reservations[ref].productId='salt'; unchanged(s,'sale',ref)
 s,ref=fixture(true); s.reservations[ref].quantity=50; unchanged(s,'sale',ref)
 s,ref=fixture(true); s.inventory.sugar[1].expiresDay=1; unchanged(s,'sale',ref)
 s,ref=fixture(true); s.ledger.spoilage=9007199254740900; unchanged(s,'sale',ref)
 s,ref=fixture(true); assert(P.confirm(s,'sale',2))
 assert(R.stageTender(s,'sale',{[10000]=1})); unchanged(s,'sale',ref)

 -- Gateway integrates the new API without cancelling the customer.
 s,ref=fixture(true)
 assert(Cmd.execute(s,'discardPortion','sale',ref))
 assert(s.retail and s.queue[1].id=='neighbor' and s.commandHistory[#s.commandHistory].success)
end
