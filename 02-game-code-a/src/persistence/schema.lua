-- Validates serializable checkpoint structure; never repairs malformed save data.
local V=require('src.model.validate')
local Cash=require('src.systems.cash')
local Products=require('data.products')
local Named=require('data.customers').named
local Tuning=require('data.tuning')
local Order=require('src.systems.order')
local Config=require('data.config')
local Schema={}
local topFields={schemaVersion=true,seed=true,rng=true,day=true,phase=true,time=true,inventory=true,drawer=true,wallet=true,debts=true,relationships=true,completedReferences=true,ledger=true,histories=true,shelfLayout=true,prices=true,queue=true,reputation=true,ice=true,luckClaimed=true,ids=true,settings=true,morningSnapshot=true,mvp=true,dayProfile=true,paused=true,serviceOutcomes=true,dayReport=true,reservations=true,cancelledRetail=true,commandHistory=true}
local monetary={goal=true,earned=true,losses=true,scamLosses=true,tips=true,tip=true,balance=true,totalCost=true,retailRevenue=true,serviceFees=true,costOfGoods=true,operatingCosts=true,spoilage=true,changeLosses=true,walletTransfers=true,cashFlow=true,total=true,cost=true,amount=true,unitPrice=true,tenderAmount=true,changeAmount=true,changeLoss=true,cash=true,wallet=true,unpaidCredit=true,profit=true}
local signed={cashFlow=true,walletTransfers=true,profit=true}
local real={elapsed=true,spawnCountdown=true,patience=true,volume=true,textScale=true,time=true}
local function check(condition,message) if not condition then error(message,0) end end
local function tableValue(value,label) check(type(value)=='table',label..' must be a table') end
local function integer(value,label,positive) check((positive and V.positive(value) or not positive and V.nonnegative(value)),label..' must be an integer in range') end
local function boolean(value,label) check(type(value)=='boolean',label..' must be boolean') end
local function array(value,label)
 tableValue(value,label)
 local count=0
 for key in pairs(value) do integer(key,label..' index',true); count=count+1 end
 check(count==#value,label..' must be a dense array')
end
local function plain(value,key,depth,seen)
 check(depth<=64,'Save nesting too deep')
 local kind=type(value)
 if kind=='number' then
  check(value==value and math.abs(value)<=9007199254740991,'Invalid finite number')
  if monetary[key] then check((signed[key] and V.signed(value) or not signed[key] and V.nonnegative(value)),'Invalid money: '..tostring(key))
  elseif not real[key] then check(V.signed(value),'Invalid integer: '..tostring(key)) end
 elseif kind=='table' then
  check(getmetatable(value)==nil and not seen[value],'Save must be plain acyclic data')
  seen[value]=true
  for childKey,child in pairs(value) do
   check(type(childKey)=='string' or V.positive(childKey),'Invalid table key')
   plain(child,childKey,depth+1,seen)
  end
  seen[value]=nil
 else check(kind=='string' or kind=='boolean','Unsupported save value') end
end
local ledgerFields={'retailRevenue','serviceFees','costOfGoods','operatingCosts','spoilage','changeLosses','cashFlow','walletTransfers'}
local function walletLine(line)
 check(line.type=='cash_in' or line.type=='cash_out','Invalid wallet type')
 integer(line.principal,'Wallet principal',true);integer(line.fee,'Wallet fee',true)
 check(V.string(line.reference) and V.string(line.recipient),'Invalid wallet reference or recipient')
 if line.amount~=nil then check(line.amount==(line.type=='cash_in' and line.principal+line.fee or line.fee),'Invalid wallet line amount') end
end
local function saleRecord(record)
 tableValue(record,'Sale history record')
 check(record.kind=='retail' and V.string(record.id),'Invalid sale history reference')
 if record.tip~=nil then integer(record.tip,'Sale tip');check(record.tip==0 or record.tip>=Config.tip_min_pesos*100 and record.tip<=Config.tip_max_pesos*100 and record.tip%100==0,'Invalid tip') end
 integer(record.day,'Sale day',true)
 for _,field in ipairs({'total','cost','changeLoss','tenderAmount','changeAmount'}) do integer(record[field],'Sale '..field) end
 check(record.tenderAmount>=record.total,'Invalid historical tender')
 array(record.lines,'Sale lines'); check(#record.lines>0,'Empty sale history')
 local total,payout=0,0
 for _,line in ipairs(record.lines) do
  if line.type=='cash_in' or line.type=='cash_out' then
   walletLine(line);check(line.confirmed==true,'Unconfirmed wallet history');total=total+line.amount
   if line.type=='cash_out' then payout=payout+line.principal end
  else
   check(Order.valid_goods(line),'Invalid historical line type or product mode')
  check(Products.byId[line.productId],'Unknown historical product')
  integer(line.quantity,'Historical quantity',true); integer(line.unitPrice,'Historical unit price',true); integer(line.priceQuantity,'Historical price quantity',true); integer(line.amount,'Historical line amount',true)
  check(V.string(line.reservation),'Invalid historical reservation'); total=total+line.amount
  if line.measured then check(line.confirmed==true,'Unconfirmed historical portion'); integer(line.targetQuantity,'Historical target',true); integer(line.actualQuantity,'Historical measured quantity',true); local lower,upper=require('src.systems.portions').bounds({day=record.day,mvp=true},line.targetQuantity); check(line.actualQuantity==line.quantity and line.quantity>=lower,'Invalid historical portion'); if line.measuredWithTolerance~=nil then check(line.measuredWithTolerance==true and line.quantity<=upper,'Invalid historical tolerance') end
   -- Legacy overfills remain readable.
  end
  end
 end
 local expected=record.tenderAmount-record.total+payout
 check(record.changeAmount>=expected and record.changeLoss==record.changeAmount-expected,'Invalid historical change')
 check(V.nonnegative(total) and total==record.total,'Invalid historical sale total')
end
local function dailyRecord(record)
 tableValue(record,'Daily history record'); integer(record.day,'Report day',true)
 for _,field in ipairs(ledgerFields) do check(signed[field] and V.signed(record[field]) or not signed[field] and V.nonnegative(record[field]),'Invalid report '..field) end
 for _,field in ipairs({'cash','wallet','unpaidCredit','served','timedOut'}) do integer(record[field],'Report '..field) end
 local goal=require('data.levels').get(record.day).goal;local earned=record.retailRevenue+record.serviceFees
 if record.goal~=nil then check(record.goal==goal,'Invalid report goal') end
 if record.earned~=nil then check(V.nonnegative(record.earned) and record.earned==earned,'Invalid report earned') end
 if record.stars~=nil then integer(record.stars,'Report stars',true);check(record.stars==(earned<goal and 1 or (record.mistakes or 0)>0 and 2 or 3),'Invalid report stars') end
 if record.suki~=nil then integer(record.suki,'Report Suki');check(record.suki<=Tuning.reputationMax,'Invalid report Suki') end
 if record.losses~=nil then check(V.nonnegative(record.losses) and record.losses==record.spoilage+record.changeLosses+(record.scamLosses or 0),'Invalid report losses') end
 if record.nextWarning~=nil then check(record.nextWarning==require('data.levels').get(record.day+1).warning,'Invalid next-day warning') end
 if record.scamLosses~=nil then integer(record.scamLosses,'Report scam losses') end
 for _,field in ipairs({'mistakes','scams'}) do if record[field]~=nil then integer(record[field],'Report '..field) end end
 if record.tips~=nil then integer(record.tips,'Report tips') end
 check(V.signed(record.profit),'Invalid report profit')
 check(record.profit==(record.tips or 0)+record.retailRevenue+record.serviceFees-record.costOfGoods-record.operatingCosts-record.spoilage-record.changeLosses-(record.scamLosses or 0),'Invalid report profit arithmetic')
end
local function checkpointBoundary(s)
 tableValue(s,'State')
 check(s.mvp==true,'Prepare an MVP day before saving')
 check(s.retail==nil,'Finish or cancel the active transaction before saving')
 if s.reservations then
  tableValue(s.reservations,'Reservations')
  check(next(s.reservations)==nil,'Release stock reservations before saving')
 end
end
local function dayProfile(profile,day)
 tableValue(profile,'Day profile')
 check(profile.day==day and V.string(profile.id),'Invalid day profile')
 check(V.string(profile.name),'Day profile name must be a nonempty string')
 if profile.baryaPrepared~=nil then boolean(profile.baryaPrepared,'Coin preparation') end
 if profile.hint~=nil then check(type(profile.hint)=='string','Day profile hint must be a string') end
 if profile.preferred~=nil then
  array(profile.preferred,'Preferred products')
  for _,id in ipairs(profile.preferred) do
   check(V.string(id) and Products.byId[id],'Unknown preferred product')
  end
 end
 integer(profile.arrivalMultiplierBasisPoints,'Arrival multiplier',true)
 check(profile.arrivalMultiplierBasisPoints<=Tuning.endless.maxArrivalMultiplierBasisPoints,'Arrival cap exceeded')
 check(profile.supplierMultiplierBasisPoints==10000,'Invalid MVP supplier multiplier')
 integer(profile.maxLines,'Maximum lines',true)
 check(profile.maxLines<=4,'Invalid maximum lines')
 if profile.event~=nil then check(profile.event=='rain' or profile.event=='payday' or profile.event=='fiesta' or (day>10 and profile.event=='brownout'),'Invalid day event') end
end
-- Histories and idempotency references describe the same committed sale.
local function same_record(left, right)
    if type(left) ~= type(right) then return false end
    if type(left) ~= 'table' then return left == right end
    for key, value in pairs(left) do
        if not same_record(value, right[key]) then return false end
    end
    for key in pairs(right) do
        if left[key] == nil then return false end
    end
    return true
end
local function check_references(s)
    local sales = {}
    local cancelled = s.cancelledRetail or {}
    tableValue(cancelled, 'Cancelled sales')
    for _, record in ipairs(s.histories.retail) do
        check(not sales[record.id], 'Duplicate sale history reference')
        check(same_record(record, s.completedReferences[record.id]),
            'Sale history and completed reference disagree')
        sales[record.id] = true
    end
    for id, record in pairs(s.completedReferences) do
        check(not cancelled[id], 'Completed reference was also cancelled')
        if record.kind == 'retail' then
            check(sales[id], 'Completed sale is missing from history')
        end
    end
    for _, customer in ipairs(s.queue) do
        check(not s.completedReferences[customer.id] and not cancelled[customer.id],
            'Queued customer reference was already used')
    end
end
local function state(s,snapshot)
 checkpointBoundary(s)
 for key in pairs(s) do check(topFields[key],'Unknown state field '..tostring(key)) end
 check(s.schemaVersion==Tuning.schemaVersion,'Unsupported save schema version')
 integer(s.seed,'Seed'); check(s.seed<=Tuning.maxSeed,'Seed outside range')
 tableValue(s.rng,'RNG'); integer(s.rng.state,'RNG state'); check(s.rng.state<=Tuning.maxSeed,'RNG outside range')
 if s.rng.randomState~=nil then
  check(type(s.rng.randomState)=='string' and #s.rng.randomState<=100,'Invalid LÃ–VE RNG state')
  local generator=love.math.newRandomGenerator(1);check(pcall(generator.setState,generator,s.rng.randomState),'Invalid LÃ–VE RNG state')
 end
 if s.rng.lastLoose~=nil then check(Products.byId[s.rng.lastLoose] and Products.byId[s.rng.lastLoose].min_g,'Invalid last loose product') end
 check((s.rng.orderDay==nil)==(s.rng.dayCustomer==nil),'Incomplete day order counter')
 if s.rng.orderDay~=nil then integer(s.rng.orderDay,'Order day',true) end
 if s.rng.dayCustomer~=nil then integer(s.rng.dayCustomer,'Day customer') end
 integer(s.day,'Day',true)
 check(s.phase=='preparation' or s.phase=='service' or s.phase=='report' or s.phase=='recovery' or s.phase=='lose','Invalid phase')
 tableValue(s.time,'Time'); check(type(s.time.elapsed)=='number' and s.time.elapsed>=0,'Invalid elapsed time'); check(type(s.time.spawnCountdown)=='number','Invalid spawn countdown'); boolean(s.time.closing,'Closing')
 tableValue(s.inventory,'Inventory'); tableValue(s.prices,'Prices'); tableValue(s.shelfLayout,'Shelf layout')
 tableValue(s.ids,'IDs'); integer(s.ids.nextBatch,'Next batch',true); integer(s.ids.nextCustomer,'Next customer',true); integer(s.ids.nextTransaction,'Next transaction',true)
 local batchIds={}; local maximumBatch=0; local slots={}
 for id in pairs(s.inventory) do check(Products.byId[id],'Unknown inventory product') end
 for id in pairs(s.prices) do check(Products.byId[id],'Unknown priced product') end
 for id in pairs(s.shelfLayout) do check(Products.byId[id],'Unknown shelf product') end
 for _,product in ipairs(Products.list) do
  local batches=s.inventory[product.id]; array(batches,'Product batches')
  for _,batch in ipairs(batches) do
   tableValue(batch,'Batch'); check(V.string(batch.id) and not batchIds[batch.id],'Invalid or duplicate batch ID')
   local number=tonumber(batch.id:match('^batch:(%d+)$')); check(number and V.positive(number),'Invalid batch ID')
   batchIds[batch.id]=true; maximumBatch=math.max(maximumBatch,number)
   integer(batch.quantity,'Batch quantity',true); integer(batch.totalCost,'Batch cost'); integer(batch.receivedDay,'Received day',true); integer(batch.expiresDay,'Expiry day',true)
   check(batch.expiresDay>batch.receivedDay,'Invalid batch age'); boolean(batch.prepared,'Prepared batch')
   if batch.prepackReference then check(V.string(batch.prepackReference),'Invalid prepack reference') end
  end
  integer(s.prices[product.id],'Price',true)
  local slot=s.shelfLayout[product.id]; tableValue(slot,'Shelf slot'); integer(slot.section,'Section',true); integer(slot.slot,'Slot',true)
  check(slot.section<=6 and slot.slot<=8,'Shelf slot out of range')
  local address=slot.section..':'..slot.slot; check(not slots[address],'Duplicate shelf slot'); slots[address]=true
 end
 check(s.ids.nextBatch>maximumBatch,'Next batch ID must exceed saved batches')
 tableValue(s.wallet,'Wallet'); integer(s.wallet.balance,'Wallet balance')
 local drawerTotal,drawerError=Cash.value(s.drawer); check(drawerTotal,drawerError or 'Invalid drawer')
 tableValue(s.ledger,'Ledger')
 local ledgerAllowed={tips=true,scamLosses=true};if s.ledger.scamLosses~=nil then integer(s.ledger.scamLosses,'Scam losses') end;if s.ledger.tips~=nil then integer(s.ledger.tips,'Ledger tips') end; for _,key in ipairs(ledgerFields) do ledgerAllowed[key]=true; check(signed[key] and V.signed(s.ledger[key]) or not signed[key] and V.nonnegative(s.ledger[key]),'Invalid ledger '..key) end
 for key in pairs(s.ledger) do check(ledgerAllowed[key],'Unknown ledger field') end
 local valid,err=V.monetaryTotals(s.ledger,drawerTotal,s.wallet.balance); check(valid,err or 'Invalid money totals')
 tableValue(s.debts,'Debts'); tableValue(s.relationships,'Relationships')
 for _,person in ipairs(Named) do
  local debt=s.debts[person.id]; tableValue(debt,'Debt'); integer(debt.balance,'Debt balance'); array(debt.entries,'Debt entries'); check(debt.balance==0 and #debt.entries==0,'Deferred debt is unsupported in MVP')
  local relationship=s.relationships[person.id]; tableValue(relationship,'Relationship'); integer(relationship.trust,'Trust'); integer(relationship.visits,'Visits'); integer(relationship.lastVisitDay,'Last visit')
 end
 integer(s.reputation,'Reputation'); check(s.reputation<=Tuning.reputationMax,'Reputation outside range'); boolean(s.ice,'Ice'); boolean(s.luckClaimed,'Luck')
 tableValue(s.histories,'Histories'); for _,key in ipairs({'retail','wallet','days','debts'}) do array(s.histories[key],'History '..key) end
 for _,record in ipairs(s.histories.retail) do saleRecord(record) end
 for _,record in ipairs(s.histories.days) do dailyRecord(record) end
 if s.dayReport then dailyRecord(s.dayReport) end
 check(#s.histories.debts==0,'Deferred debt history is unsupported in MVP')
 local transferReferences={}
 for _,record in ipairs(s.histories.wallet) do
  walletLine(record);integer(record.day,'Wallet day',true);check(V.string(record.customerId),'Invalid wallet customer')
  check(not transferReferences[record.reference],'Duplicate wallet transfer');transferReferences[record.reference]=true
  local sale=s.completedReferences[record.customerId];check(sale and sale.kind=='retail' and record.day==sale.day,'Orphan wallet transfer')
  local found=false;for _,line in ipairs(sale.lines) do if line.reference==record.reference and line.type==record.type and line.principal==record.principal and line.fee==record.fee and line.recipient==record.recipient then found=true end end
  check(found,'Wallet transfer does not match committed sale')
 end
 check(s.ids.nextTransaction>#s.histories.retail,'Invalid next transaction ID')
 tableValue(s.completedReferences,'Completed references')
 for reference,record in pairs(s.completedReferences) do
  check(V.string(reference),'Invalid completed reference'); tableValue(record,'Completed record'); check(record.id==reference and (record.kind=='retail' or record.kind=='prepack'),'Invalid completed record')
  integer(record.day,'Completed day',true); integer(record.cost,'Completed cost'); if record.kind=='retail' then saleRecord(record); local customerId=tonumber(record.id:match('^customer:(%d+)$')); if customerId then check(customerId<s.ids.nextCustomer,'Reused customer ID') end else check(Products.byId[record.productId],'Unknown prepacked product'); integer(record.quantity,'Prepack quantity',true) end
 end
 array(s.queue,'Queue'); check(#s.queue<=Tuning.queueCap,'Queue outside cap')
 local customers={}
 for _,customer in ipairs(s.queue) do
  tableValue(customer,'Customer'); local number=type(customer.id)=='string' and tonumber(customer.id:match('^customer:(%d+)$'))
  check(number and V.positive(number) and number<s.ids.nextCustomer and not customers[customer.id],'Invalid customer ID'); customers[customer.id]=true
  if customer.day~=nil then check(customer.day==s.day,'Invalid customer day') end
  if customer.number~=nil then integer(customer.number,'Customer ordinal',true) end
  if customer.lineBonuses then tableValue(customer.lineBonuses,'Line bonuses');for index,value in pairs(customer.lineBonuses) do check(V.positive(index) and index<=#customer.lines and value==true,'Invalid line bonus') end end
  if customer.initialPatience~=nil then integer(customer.initialPatience,'Starting patience',true);check(customer.initialPatience<=Config.patience_max and customer.patience<=customer.initialPatience,'Invalid starting patience') end
  check(type(customer.patience)=='number' and customer.patience>0,'Invalid customer patience'); array(customer.lines,'Customer lines'); check(#customer.lines>=1 and #customer.lines<=4,'Invalid customer basket')
  local total=0; local products={}
  for _,line in ipairs(customer.lines) do
   if line.type=='cash_in' or line.type=='cash_out' then
    walletLine(line);check(not products[line.type],'Duplicate wallet request');products[line.type]=true
    check(require('src.systems.tindapay').valid_evidence(line,s.day),'Invalid screenshot evidence')
    tableValue(line.transfer,'Wallet verification');check(line.transfer.status=='confirmed' and line.transfer.reference==line.reference and line.transfer.amount==line.principal and line.transfer.recipient==line.recipient,'Invalid wallet verification')
   else
    check(Order.valid_goods(line),'Invalid order line type or product mode')
    check(Products.byId[line.productId] and not products[line.productId],'Invalid order product');products[line.productId]=true
    integer(line.quantity,'Requested quantity',true);boolean(line.measured,'Measured request');check(line.measured==(Products.byId[line.productId].saleUnit~='piece'),'Incorrect measured request');check(line.requestMode=='peso' or line.requestMode=='quantity','Invalid request mode');integer(line.requestValue,'Request value',true)
   end
   integer(line.amount,'Requested amount',true);total=total+line.amount
  end
  if customer.changeMistake~=nil then boolean(customer.changeMistake,'Change mistake') end
  if customer.mistake~=nil then boolean(customer.mistake,'Customer mistake') end
  check(V.nonnegative(total) and total==customer.total,'Incorrect customer total'); if customer.tender~=nil then local tender=Cash.value(customer.tender); check(tender and tender>=total,'Invalid customer tender') end
 end
 check_references(s)
 if s.phase=='lose' then check(s.reputation==0 and s.time.closing,'Invalid loss state') end
 if s.phase~='service' then check(#s.queue==0,'Only service may have customers') end
 tableValue(s.settings,'Settings'); check(s.settings.difficulty=='normal' or s.settings.difficulty=='easy' or s.settings.difficulty=='hard','Invalid difficulty'); boolean(s.settings.reducedMotion,'Reduced motion'); check(type(s.settings.volume)=='number' and s.settings.volume>=0 and s.settings.volume<=1,'Invalid volume'); check(type(s.settings.textScale)=='number' and s.settings.textScale>0 and s.settings.textScale<=3,'Invalid text scale')
 if s.cancelledRetail then tableValue(s.cancelledRetail,'Cancelled sales'); for id,value in pairs(s.cancelledRetail) do check(V.string(id) and value==true,'Invalid cancelled sale') end end
 if s.commandHistory then array(s.commandHistory,'Command history'); check(#s.commandHistory<=200,'Command history exceeds cap'); for _,record in ipairs(s.commandHistory) do check(V.string(record.name),'Invalid command name'); tableValue(record.args,'Command args'); integer(record.day,'Command day',true); check(type(record.time)=='number' and record.time>=0,'Invalid command time'); boolean(record.success,'Command success'); if record.error~=nil then check(type(record.error)=='string','Invalid command error') end end end
 if s.paused~=nil then boolean(s.paused,'Paused') end
 if s.mvp then
  dayProfile(s.dayProfile,s.day)
  for _,field in ipairs({'mistakes','scams'}) do if s.serviceOutcomes[field]~=nil then integer(s.serviceOutcomes[field],'Outcome '..field) end end
  tableValue(s.serviceOutcomes,'Outcomes'); integer(s.serviceOutcomes.served,'Served'); integer(s.serviceOutcomes.timedOut,'Timed out')
 end
 if snapshot then check(s.morningSnapshot==nil,'Recursive morning snapshot')
 else tableValue(s.morningSnapshot,'Morning snapshot'); state(s.morningSnapshot,true); check(s.morningSnapshot.phase=='preparation' and #s.morningSnapshot.queue==0,'Unsafe morning snapshot') end
end
function Schema.canSave(s)
 local ok,err=pcall(checkpointBoundary,s)
 if not ok then return nil,tostring(err) end
 return true
end
function Schema.validate(value)
 local ok,err=pcall(function() plain(value,nil,0,{}); state(value,false) end)
 if not ok then return nil,'Invalid save: '..tostring(err) end
 return true
end
return Schema

