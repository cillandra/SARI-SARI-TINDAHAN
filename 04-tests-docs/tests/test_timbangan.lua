-- Tests for the four-bin coordinator using actual domain commands and in-memory saves.
return function()
 local App=require('src.app')
 local Products=require('data.products')
 local State=require('src.model.state')
 local Cash=require('src.systems.cash')
 local Inventory=require('src.systems.inventory')
 local Save=require('src.persistence.save')
 local function app()
  local a=App.new(Save.new(require('tests.support.memory_disk').new(),'timbangan'))
  a:newRun();assert(a:command('openDay'))
  a.state.queue={{id='portion-test',patience=120,total=9000,lines={
   {productId='sugar',measured=true,quantity=250,amount=2000},
   {productId='rice_regular',measured=true,quantity=1000,amount=5500},
   {productId='candy',quantity=5,amount=1500}},tender={[10000]=1}}}
  return a
 end
 local ids={'rice_regular','flour','sugar','salt'}
 for slot,id in ipairs(ids) do
  local p=Products.byId[id]
  assert(p.timbangan and p.timbangan.slot==slot,'Four timbangan data slots are required')
  assert(p.timbangan.mode==(slot==1 and 'weigh' or 'repack'))
 end
 assert(Products.byId.cooking_oil.timbangan.slot==5 and Products.byId.cooking_oil.timbangan.mode=='pour' and not Products.byId.rice_premium.timbangan)
 local a=app();a:pick('candy');assert(a:openTimbangan())
 assert(a.view=='timbangan' and a.portionProduct=='sugar' and a.timbanganMode=='repack')
 assert(not a:choosePackSize(100),'A service bag cannot be smaller than the target')
 assert(a:choosePackSize(500) and a:quote().lines[2].targetQuantity==250 and a:quote().total==3500,'Service bag size must not change requested quantity or price')
 local cash=Cash.total(a.state);local customer=a.state.queue[1].id
 local line=a:quote().lines[2];local ref=line.reservation
 a:adjust(100);assert(a:quote().lines[2].openedSpoilage,'Filling must mark the open contents')
 a:go('shelves');a:pick('rice_regular');assert(a.portionSwitch,'Cabinet pick must ask once about the open portion')
 assert(a:layerDepth()==2,'The bin dialog must be counted as the active overlay')
 local pending=a.portionSwitch
 a:selectTimbanganBin('flour');assert(a.portionSwitch==pending,'Repeated clicks cannot replace the pending destination')
 assert(a.state.reservations[ref].quantity==250 and a.portionProduct=='sugar')
 assert(a:resolveTimbanganSwitch('continue') and not a.portionSwitch)
 assert(a.portionProduct=='sugar' and a:quote().lines[2].actualQuantity==100)
 assert(not a:selectTimbanganBin('rice_regular'));assert(a:resolveTimbanganSwitch('discard'))
 assert(a.portionProduct=='rice_regular' and a.timbanganMode=='weigh' and not a.portionSwitch and a.view=='timbangan','Discard from cabinet must enter the workbench')
 assert(a.state.queue[1].id==customer and a:quote().lines[1].productId=='candy')
 assert(not a.state.reservations[ref] and Inventory.available(a.state,'sugar')==1900)
 assert(a.state.ledger.spoilage==640 and Cash.total(a.state)==cash,'Only opened contents are discarded')
 assert(not a:resolveTimbanganSwitch('discard'),'Repeat discard must be a no-op')
 local rice=a:quote().lines[2];a:adjust(rice.targetQuantity-1)
 assert(not a:confirmTimbangan() and a.view=='timbangan','Underfill must not confirm')
 a:adjust(7);assert(not a:confirmTimbangan(),'Target+6 must not confirm')
 a:adjust(-1);assert(a:confirmTimbangan() and a.view=='counter','Target+5 must confirm and return')
 assert(a:quote().lines[2].confirmed and a:quote().lines[2].quantity==1005)
 a:openTimbangan();assert(a.portionProduct=='sugar')
 local zeroRef=a:quote().lines[3].reservation
 assert(not a:selectTimbanganBin('salt'));assert(a:resolveTimbanganSwitch('discard'))
 assert(not a.state.reservations[zeroRef] and a.state.ledger.spoilage==640,'Untouched reservation releases without spoilage')
 assert(a.portionProduct=='salt' and #a:quote().lines==2,'Unrequested bins cannot add a sale line')
 assert(not a:confirmTimbangan())
 a:selectTimbanganBin('sugar');a:adjust(50);local openRef=a:quote().lines[3].reservation
 a:go('counter');assert(a.state.reservations[openRef],'Leaving keeps the open transaction')
 assert(require('src.ui.order_card').model(a.state).openPortion,'Order card needs an open portion marker')
 a:openTimbangan();assert(a.portionProduct=='sugar' and a:quote().lines[3].actualQuantity==50)
 assert(not a:selectTimbanganBin('rice_regular'));a:pause();assert(a:layerDepth()==2,'Pause replaces the visible bin dialog');assert(not a:resolveTimbanganSwitch('discard'))
 assert(a:navigate('resume') and not a.state.paused,'Mouse Resume must work while a bin choice is pending');a:update(121);assert(not a.state.reservations[openRef] and not a.portionSwitch,'Timeout clears stale dialog and reservation')
 a=app();a:openTimbangan();a:selectTimbanganBin('rice_regular')
 assert(not a:resolveTimbanganSwitch('invalid') and a.portionSwitch,'Unknown dialog action is atomic')
 -- Full sale through the new station and existing staged-cash path.
 a=app();a:pick('candy');a:openTimbangan();a:adjust(250);assert(a:confirmTimbangan())
 a:pick('rice_regular');assert(a.timbanganMode=='weigh');a:adjust(1000);assert(a:confirmTimbangan())
 local balance=Cash.total(a.state)
 a:receive();assert(a:quote().tenderAmount==10000 and Cash.total(a.state)==balance,'Tender stays staged')
 a.change=assert(Cash.plan(a.state,1000,a:quote().tender));a:commit()
 local committed=Cash.total(a.state);local riceStock=Inventory.available(a.state,'rice_regular')
 a:commit();assert(Cash.total(a.state)==committed and Inventory.available(a.state,'rice_regular')==riceStock,'Repeat confirm cannot commit twice')
 assert(committed==balance+9000 and a.state.ledger.retailRevenue==9000)
 -- Legal low prices can create requests larger than the largest catalog bag.
 a=app();a:newRun();assert(a:command('purchasePlanned','flour',2000));a.state.prices.flour=1000
 assert(a:command('openDay'))
 a.state.queue={{id='large-flour',patience=120,total=2000,lines={{productId='flour',measured=true,quantity=2000,amount=2000}},tender={[2000]=1}}}
 a:pick('flour');local large=require('src.ui.timbangan_model').model(a)
 assert(a.packSize==1000 and large.bagCount==2,'Large targets need an explicit multiple-bag presentation')
 assert(a:choosePackSize(1000) and a:quote().lines[1].targetQuantity==2000)
 a:adjust(2000);assert(a:confirmTimbangan() and a:quote().lines[1].quantity==2000)
 -- Untimed preparation uses catalog sizes, preserves cost/expiry and stays at the bench.
 a:newRun();a.prepackProduct='sugar';a:go('timbangan')
 assert(a:choosePackSize(500));a:adjust(500)
 assert(a:selectTimbanganBin('sugar') and a.packQuantity==500,'Selecting the same bin cannot erase fill')
 local originalCost=a.state.inventory.sugar[1].totalCost
 local expiry=a.state.inventory.sugar[1].expiresDay
 assert(a:confirmTimbangan() and a.view=='timbangan' and a.packQuantity==0)
 assert(a.state.inventory.sugar[1].totalCost<originalCost)
 local sealed
 for _,b in ipairs(a.state.inventory.sugar) do if b.prepared then sealed=b end end
 assert(sealed and sealed.quantity==500 and sealed.expiresDay==expiry)
 assert(not a:choosePackSize(123),'Bag sizes must come from product data')
 local count=#a.state.inventory.sugar;assert(not a:confirmTimbangan());assert(#a.state.inventory.sugar==count)
 assert(not a.state.retail and next(a.state.reservations or {})==nil)
end
