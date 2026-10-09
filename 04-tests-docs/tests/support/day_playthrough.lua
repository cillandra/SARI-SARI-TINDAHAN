-- Deterministic verification driver. Uses existing application commands only.
local App=require('src.app');local Cash=require('src.systems.cash');local Inventory=require('src.systems.inventory')
local Products=require('data.products');local Customers=require('src.systems.customers');local Codec=require('src.persistence.codec');local Tuning=require('data.tuning')
local Retail=require('src.systems.retail');local TindaPay=require('src.systems.tindapay');local Restock=require('src.systems.restock')
local Levels=require('data.levels');local Config=require('data.config')
local Play={}
function Play.run(store,seed,lastDay,resume,loaded)
 local saves=0;local original=store.save
 store.save=function(state) saves=saves+1;return original(state) end
 local a=App.new(store)
 if loaded then assert(a:load()) else assert(a:command('newRun',seed));a:clearSale();a:go('preparation') end
 local reports={}
 local coverage={scams=0,exchanges=0,events={},lineTypes={},coinDays=0}
 if a.state.phase=='report' then assert(a:nextMorning()) end
 for day=a.state.day,lastDay do
  assert(a.state.day==day and a.state.phase=='preparation' and a.view=='preparation')
  local profileIds={'opening','snacks','rice','repack','baskets','ordinary_endless'}
  assert(a.state.dayProfile.id==(profileIds[day] or 'ordinary_endless'),'Unexpected day profile')
  if a.state.dayProfile.event then coverage.events[a.state.dayProfile.event]=(coverage.events[a.state.dayProfile.event] or 0)+1 end
  local level=Levels.get(day)
  if day>=8 then
   assert(a.state.dayProfile.baryaPrepared,'Later-day coin shortage must be prepared before opening')
   coverage.coinDays=coverage.coinDays+1
  end
  -- A prepared player exchanges while bills remain, both before buying stock
  -- and before opening, using the same finite drawer resources as the player.
  local function prepareCoins()
   for _=1,8 do
    if (a.state.drawer[100] or 0)>=level.customers*4 and (a.state.drawer[500] or 0)>=level.customers*2 then break end
    local bundle=Restock.bundle(a.state)
    if not bundle.enabled then break end
    local cash=Cash.total(a.state);local wallet=a.state.wallet.balance;local coins=a.state.drawer[100] or 0
    assert(a:command('exchangeBarya'),'Available coin exchange must succeed')
    assert(Cash.total(a.state)==cash and a.state.wallet.balance==wallet,'Barya exchange preserves cash and wallet')
    assert(a.state.drawer[100]==coins+10,'Barya exchange adds the actual bundle coins')
    coverage.exchanges=coverage.exchanges+1
   end
  end
  prepareCoins()
  local initial=Cash.total(a.state);local initialWallet=a.state.wallet.balance;local bought=0;local revenue=0;local fees=0;local tips=0;local cashFlow=0;local walletDelta=0;local sales=0;local cancelled=0
  for _,product in ipairs(Products.list) do
   local target=Tuning.startingStock[product.id]
   if target then local need=target-Inventory.available(a.state,product.id)
    if need>0 then
     local step=product.saleUnit=='piece' and 5 or product.priceQuantity;need=math.ceil(need/step)*step
     local quote=assert(Inventory.purchaseQuote(a.state,product.id,need));local before=Cash.total(a.state)
     local payment=Cash.plan(a.state,quote.cost)
     if payment then assert(a:command('purchasePlanned',product.id,need));bought=bought+quote.cost
     else local stock=Inventory.available(a.state,product.id);assert(not a:command('purchasePlanned',product.id,need));assert(Cash.total(a.state)==before and Inventory.available(a.state,product.id)==stock,'Unpayable restock cannot mutate cash or stock') end
    end
   end
  end
  prepareCoins()
  assert(a:command('openDay'));a:go('counter')
  local tickLimit=level.customers*(14+Config.patience_max+4*level.max_lines)
  local ticks=0
  while a.state.phase=='service' do
   local customer=Customers.current(a.state)
   if ticks==0 then
    local before=assert(Codec.encode(a.state));a:pause();local paused=assert(Codec.encode(a.state))
    a:update(20);assert(Codec.encode(a.state)==paused,'Pause must freeze full game state')
    assert(a:save())
    if resume then a=App.new(store);assert(a:load());assert(Codec.encode(a.state)==paused,'Paused reload must preserve full state') end
    a:pause();assert(a.state.time.elapsed==ticks)
   end
   if customer then
    for _,request in ipairs(customer.lines) do coverage.lineTypes[request.type]=(coverage.lineTypes[request.type] or 0)+1 end
    local before=Cash.total(a.state);local walletBefore=a.state.wallet.balance;local tipsBefore=a.state.ledger.tips or 0
    if not a:takeOrder() then
     local current=Customers.current(a.state);assert((not current or current.id~=customer.id) and not a.state.retail,'Unavailable wallet customer must be dismissed')
     assert(Cash.total(a.state)==before and a.state.wallet.balance==walletBefore and (a.state.ledger.tips or 0)==tipsBefore and next(a.state.reservations)==nil,'Dismissal cannot mutate balances, tips or reservations')
     cancelled=cancelled+1
    else
     -- Inspect every receipt before staging any line in this mixed basket.
     local scamIndex
     for index,request in ipairs(customer.lines) do
      if request.type=='cash_in' or request.type=='cash_out' then
       local receipt=request.receipt or request.transfer
       local transfer=request.transfer
       if receipt.reference~=transfer.reference or receipt.amount~=transfer.amount
        or receipt.recipient~=transfer.recipient or receipt.status~=transfer.status then scamIndex=index;break end
      end
     end
     if scamIndex then
      assert(day>=6,'Scams cannot appear before their teaching day')
      coverage.scams=coverage.scams+1
      local reputation=a.state.reputation;local timedOut=a.state.serviceOutcomes.timedOut
      local served=a.state.serviceOutcomes.served
      assert(a:rejectWalletLine(scamIndex),'Successful player must reject a mismatched receipt')
      local current=Customers.current(a.state)
      assert((not current or current.id~=customer.id) and not a.state.retail,'Rejecting a scam dismisses its whole customer')
      assert(Cash.total(a.state)==before and a.state.wallet.balance==walletBefore
       and (a.state.ledger.tips or 0)==tipsBefore and next(a.state.reservations)==nil
       and a.state.reputation==reputation,'Correct scam rejection cannot move money, tips, reservations or Suki')
      assert(a.state.serviceOutcomes.timedOut==timedOut+1 and a.state.serviceOutcomes.served==served,'Rejected scam receives exactly one cancelled disposition')
      cancelled=cancelled+1
     else
     for requestIndex,request in ipairs(customer.lines) do
      if request.type=='cash_in' or request.type=='cash_out' then assert(a:addWalletLine(requestIndex))
      else
       a:pick(request.productId)
       local q=assert(a:quote());local index,line
       for i,item in ipairs(q.lines) do if item.productId==request.productId then index=i;line=item end end
       assert(line,'Requested product must be staged')
       if request.measured then
        a:adjust(line.targetQuantity)
        if a.view=='timbangan' then assert(a:confirmTimbangan()) else a:confirmPortion(index) end
        assert(a:quote().lines[index].confirmed)
       end
      end
     end
     local q=assert(a:quote());local incoming=q.total;local summary=TindaPay.summary(q);local completed=true
     a:receive();q=a:quote()
     if q then
      assert(q.tender and a.view=='drawer')
      local change,why=Cash.plan(a.state,assert(Retail.changeDue(a.state,customer.id)),q.tender)
      if change then
       for _,d in ipairs(Tuning.denominations) do for _=1,change[d] or 0 do a:changePiece(d) end end
       a:commit()
      else
       assert(why=='No exact denomination payment; change quantity or exchange coins' or why=='Not enough drawer cash',why)
       a:cancel();assert(not a.state.retail and Cash.total(a.state)==before and a.state.wallet.balance==walletBefore and next(a.state.reservations)==nil,'Unpayable change cancels without balance or reservation loss')
       cancelled=cancelled+1;completed=false
      end
     else assert(a.view=='counter' and a.toast=='Eksaktong bayad!','Exact payment skips the drawer') end
     local tip=0
     if completed then
      local record=assert(a.state.completedReferences[customer.id]);tip=record.tip or 0
      assert(tip%100==0 and (tip==0 or tip>=500 and tip<=1000),'Tip must be zero or a whole-peso reward from P5 to P10')
     end
     assert((a.state.ledger.tips or 0)-tipsBefore==tip,'Only a completed sale may record its single tip')
     local delta=completed and incoming-summary.payout+tip or 0
     local walletChange=completed and summary.walletDelta or 0
     assert(not a.state.retail and Cash.total(a.state)==before+delta and a.state.wallet.balance==walletBefore+walletChange and next(a.state.reservations)==nil)
     if completed then revenue=revenue+summary.retailRevenue;fees=fees+summary.fees;tips=tips+tip;cashFlow=cashFlow+delta;walletDelta=walletDelta+walletChange;sales=sales+1 end
     end
    end
   end
   a:update(1);ticks=ticks+1;assert(ticks<=tickLimit,'Count-limited day must finish')
  end
  assert(a.state.phase=='report' and a.view=='report' and sales+cancelled>0)
  if sales==0 then
   local parts={}
   for _,d in ipairs(Tuning.denominations) do parts[#parts+1]=d..'x'..(a.state.drawer[d] or 0) end
   print('PLAYTHROUGH BLOCKED day='..day..' drawer='..table.concat(parts,',')..' exchange='..tostring(Restock.bundle(a.state).reason)..' priorExchanges='..coverage.exchanges)
  end
  assert(sales>0,'Prepared player must complete at least one transaction on day '..day)
  assert(sales+cancelled==level.customers,'Every planned customer must receive exactly one disposition')
  local report=a.state.dayReport
  assert(report.retailRevenue==revenue and report.serviceFees==fees and (report.tips or 0)==tips and report.cash==initial-bought+cashFlow and report.wallet==initialWallet+walletDelta)
  assert(report.served==sales and report.timedOut==cancelled and report.changeLosses==0)
  assert(#a.state.histories.days==day and report.day==day)
  local saved=assert(store.load());assert(Codec.encode(saved)==Codec.encode(a.state),'Report entry must autosave the full closed day')
  local before=saves;a:update(1);a:update(1);assert(saves==before,'Report frames cannot repeat checkpoint writes')
  reports[#reports+1]=report
  print('PLAYTHROUGH DAY '..day..' seed='..seed..' served='..sales..' cancelled='..cancelled..' revenue='..revenue..' fees='..fees..' tips='..tips..' wallet='..report.wallet..' purchases='..bought..' cash='..report.cash..' profile='..a.state.dayProfile.id..' event='..tostring(a.state.dayProfile.event))
  if day<lastDay then
   assert(a:nextMorning());assert(not a:nextMorning(),'Repeated next morning cannot skip a day')
   assert(a.state.ledger.retailRevenue==0 and a.state.ledger.costOfGoods==0)
   if resume then assert(a:save());a=App.new(store);assert(a:load());assert(a.view=='preparation') end
  end
 end
 return {app=a,reports=reports,saves=saves,coverage=coverage}
end
return Play
