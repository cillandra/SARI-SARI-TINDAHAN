-- Purpose: input/view coordinator; economic mutation only through Commands. API: new,update,draw,input,resize,save/load hooks. Dependencies: domain/UI/views.
local State=require('src.model.state'); local Cmd=require('src.commands'); local Days=require('src.systems.days'); local Customers=require('src.systems.customers'); local Retail=require('src.systems.retail'); local Cash=require('src.systems.cash'); local Products=require('data.products'); local Tuning=require('data.tuning'); local Layout=require('src.ui.layout'); local W=require('src.ui.widgets'); local T=require('src.ui.theme'); local Hud=require('src.ui.draw.hud'); local Feedback=require('src.ui.feedback'); local Pause=require('src.ui.pause'); local Save=require('src.persistence.save'); local App={}; App.__index=App; local views={}
for _,name in ipairs({'menu','preparation','counter','shelves','drawer','scale','repack','report','recovery','lose'}) do views[name]=require('src.views.'..name) end
local Navigation=require('src.ui.navigation')
local NavigationData=require('data.navigation')
local Order=require('src.systems.order');local TindaPay=require('src.systems.tindapay')
views.phone=require('src.views.tindapay')
views.sukli=views.drawer
views.timbangan=require('src.views.timbangan')
function App.availableViews() return views end
function App:layerDepth() return 1+(self.state.paused and 1 or 0)+(self.ticketOpen and 1 or 0)+(self.portionSwitch and not self.state.paused and 1 or 0) end
function App:takeOrder()
 if self.state.paused then return nil,'Resume first' end
 local c=Customers.current(self.state)
 if not c then self:notify('Wait for a neighbor at the window.'); return nil,'No neighbor' end
 if not self.state.retail and not self:command('beginRetail',c.id) then return nil,'Order unavailable' end
 local ok,err=TindaPay.offer(self.state,c)
 if not ok then
  if self:command('cancelCurrentCustomer',c.id) then self:clearSale();self:go('counter') end
  self:notify(err);return nil,err
 end
 self:notify('Order taken. Choose the requested goods or TindaPay service.')
 return true
end
function App:openTindaPay()
 if not self:takeOrder() then return nil end
 local c=Customers.current(self.state);local q=self:quote();local index
 for i,r in ipairs(c.lines) do
  if r.type=='cash_in' or r.type=='cash_out' then
   local done=false;for _,line in ipairs(q.lines) do if line.requestIndex==i then done=true end end
   if not done then index=i;break end
   index=index or i
  end
 end
 self.walletTab=index and c.lines[index].type or 'cash_in'
 return self:go('phone')
end
local serviceMessages={cash_shortage='Kulang ang cash sa drawer',wallet_shortage='Kulang ang wallet balance'}
function App:serviceOutcome(outcome)
 if outcome~='closed' and outcome~='lose' and not serviceMessages[outcome] then return end
 self:clearSale();self:go(outcome=='lose' and 'lose' or 'counter')
 if outcome=='lose' then self:save() end
end
function App:addWalletLine(index)
 local c=Customers.current(self.state);if not c then return nil end
 local ok,outcome=self:command('acceptWallet',c.id,index);if not ok then return nil end
 self:serviceOutcome(outcome)
 self:notify(serviceMessages[outcome] or (outcome=='accepted' and 'TindaPay verified. Receive payment when all lines are ready.' or 'Pekeng transfer! Nawala ang principal. Suki -5.'))
 return true
end
function App:rejectWalletLine(index)
 local c=Customers.current(self.state);if not c then return nil end
 local ok,outcome=self:command('rejectWallet',c.id,index);if not ok then return nil end
 self:serviceOutcome(outcome);self:notify(serviceMessages[outcome] or 'Transfer rejected. Customer dismissed.');return true
end
local CabinetInput=require('src.app.cabinet_input')
function App:beginCabinetPick(pid,x,y) return CabinetInput.begin(self,pid,x,y) end
function App:moveCabinetPick(x,y) return CabinetInput.move(self,x,y) end
function App:releaseCabinetPick(x,y) return CabinetInput.release(self,x,y) end
local PortionStation=require('src.app.portion_station')
local Preparation=require('src.app.preparation')
function App:restock(pid,quantity) return Preparation.restock(self,pid,quantity) end
function App:exchangeBarya() return Preparation.barya(self) end
function App:openStore() return Preparation.open(self) end
function App:preparePortion(pid) return Preparation.portion(self,pid) end
function App:openTimbangan() return PortionStation.open(self) end
function App:selectTimbanganBin(pid) return PortionStation.select(self,pid) end
function App:resolveTimbanganSwitch(action) return PortionStation.resolve(self,action) end
function App:choosePackSize(size) return PortionStation.size(self,size) end
function App:choosePackOption(mode,value) return PortionStation.option(self,mode,value) end
function App:confirmTimbangan() return PortionStation.confirm(self) end
function App:navigate(id)
 if self.portionSwitch and not self.state.paused and id~='pause' then self:notify('Finish the bin choice first.'); return nil end
 local d=NavigationData.byId[id]
 if d then
  if d.action=='pause' then self:pause(); return true
  elseif d.action=='ticket' then Hud.toggleTicket(self); return true
  elseif d.action=='save' then return self:save()
  elseif d.action=='navigate_ui' then return self:go(d.target)
  elseif d.action=='pause_panel' then self.pausePanel=d.panel; W.items={}; W.focus=1; return true
  elseif d.action=='pause_back' then self.pausePanel=nil; W.items={}; W.focus=1; return true
  elseif d.action=='quit_confirm' then return self:confirmQuit()
  elseif d.action=='setting_step' then return self:setSetting(d.field,math.max(d.min,math.min(d.max,self.state.settings[d.field]+d.delta)))
  elseif d.action=='setting_toggle' then return self:setSetting(d.field,not self.state.settings[d.field])
  elseif d.action=='setting_cycle' then
   local index=1; for i,v in ipairs(d.values) do if v==self.state.settings[d.field] then index=i; break end end
   return self:setSetting(d.field,d.values[index%#d.values+1])
  end
 end
 local status=Navigation.status(d,self.state,Tuning.features)
 if not status.enabled then self:notify(status.reason); return nil,status.reason end
 if self.lastNavigationAt and self.uiClock-self.lastNavigationAt<Tuning.ui.navigationDebounceSeconds then
  self:notify('One click is enough.'); return nil,'Navigation debounce'
 end
 if d.action=='takeOrder' then return self:takeOrder() end
 if not views[d.target] then self:notify('This service is not available yet.'); return nil,'Unavailable view' end
 self.lastNavigationAt=self.uiClock
 if d.target=='timbangan' then return self:openTimbangan() end
 if d.target=='phone' then return self:openTindaPay() end
 return self:go(d.target)
end
function App:setSetting(name,value)
 local valid=(name=='volume' and type(value)=='number' and value==value and value>=0 and value<=1)
  or (name=='textScale' and (value==1 or value==1.15 or value==1.3))
  or (name=='difficulty' and (value=='easy' or value=='normal' or value=='hard'))
  or (name=='reducedMotion' and type(value)=='boolean')
 if not valid then self:notify('Invalid setting.'); return nil,'Invalid setting' end
 self.state.settings[name]=value
 return true
end
function App:confirmQuit()
 local reason=self:saveDisabledReason()
 if not reason and not self:save() then return nil,'Save failed' end
 love.event.quit(0); return true
end

function App.new(persistence) local store=persistence or Save; return setmetatable({persistence=store,hasCheckpoint=store.exists(),state=State.new(1),view='menu',prepSection=1,change={},changeOrder={},packQuantity=0,packSerial=0,toast='',toastTime=0,pouring=false,uiClock=0,ticketOpen=false,feedback=Feedback.new()},App) end
function App:notify(text) self.toast=tostring(text); self.toastTime=5 end
function App:command(name,...) local ok,err=Cmd.execute(self.state,name,...); if not ok then self:notify(err or 'Action unavailable') end; return ok,err end
function App:go(view)
 if not views[view] then self:notify('That view is unavailable.'); return nil,'Unknown view' end
 self.view=view; self.cabinetDrag=nil; self.cabinetHover=nil; self.pouring=false;self.pourElapsed=0;self.pourRemainder=0; self.ticketOpen=false; self.ticketHover=false; self.orderCardHover=false; self.suppressTicketHover=false; self.menuPauseVisible=false; self.pausePanel=nil; W.items={}; W.focus=1; W.pressed=nil
 return true
end
function App:newRun()
 if not self:command('newRun',love.math.random(Tuning.maxSeed)) then return nil end
 self:clearSale()
 self.selected=nil;self.prepackProduct=nil;self.packQuantity=0;self.packSerial=0
 self.pourElapsed=0;self.pourRemainder=0;self.pendingCheckpoint=false
 self.feedback=Feedback.new()
 return self:go('preparation')
end
function App:clearSale() self.walletTab=nil; self.cabinetDrag=nil; self.cabinetHover=nil; self.change={}; self.changeOrder={}; self.portionProduct=nil; self.packSize=nil; self.packChoiceMode=nil; self.packChoiceValue=nil; self.portionSwitch=nil; self.timbanganMode=nil; self.saleId=nil; self.pouring=false end
function App:quote() local c=Customers.current(self.state); if c and self.state.retail and self.state.retail.id==c.id then return Retail.quote(self.state,c.id) end end
function App:pick(pid) local c=Customers.current(self.state); if not c then self:notify('Wait for a neighbor at the counter.'); return end; local requested; for _,r in ipairs(c.lines) do if r.productId==pid then requested=r end end; if not requested then local ok,outcome=self:command('wrongItem',c.id,pid);if ok then self:serviceOutcome(outcome);self:notify('Hindi ito inorder') end;return end; if not self.state.retail and not self:command('beginRetail',c.id) then return end; if Products.byId[pid].timbangan then if self:selectTimbanganBin(pid) then self:go('timbangan') end; return end; local existing; for _,l in ipairs(self.state.retail.lines) do if l.productId==pid then existing=l end end; if existing and not existing.measured then self:notify('That piece is already on the counter.'); return end; if requested.measured then if not existing and not self:command('targetPortion',c.id,pid,requested.requestValue or requested.quantity,requested.requestMode or 'quantity') then return end; self.portionProduct=pid; self:go((pid=='cooking_oil' or pid=='sugar') and 'repack' or 'scale') else if self:command('addRetail',c.id,pid,requested.quantity) then self.feedback:place(pid) end end end
function App:station(view) local c=Customers.current(self.state); if c then for _,r in ipairs(c.lines) do if r.measured and ((view=='repack')==(r.productId=='cooking_oil' or r.productId=='sugar')) then self:pick(r.productId); return end end end; self:notify('Choose a matching measured request from the cabinet.'); end
function App:receive()
 local c=Customers.current(self.state);local q=self:quote()
 if not c or not q then self:notify('Pick the requested goods before receiving payment.');return end
 local bundle,err=Customers.payment(self.state)
 if not bundle then self:notify(err);return end
 if not q.tender and not self:command('stageTender',c.id,bundle) then return end
 self.saleId=c.id;q=self:quote()
 if Retail.changeDue(self.state,c.id)==0 then
  if self:command('confirmPayment',c.id,{}) then self:clearSale();self:go('counter');self:notify('Eksaktong bayad!') end
 else self:go('drawer') end
end
function App:changePiece(d) local q=self:quote(); if not q or not q.tender then self:notify('Receive the customer tender first.'); return end; local bundle=State.clone(self.change); bundle[d]=(bundle[d] or 0)+1; local ok,err=Cash.canPay(self.state,bundle,q.tender); if not ok then self:notify(err); return end; self.change=bundle; self.changeOrder[#self.changeOrder+1]=d end
function App:undoChange() local d=table.remove(self.changeOrder); if d then self.change[d]=self.change[d]-1 end end
function App:cancel() local c=Customers.current(self.state); if c and self.state.retail and self:command('cancelCurrentCustomer',c.id) then self:clearSale(); self:go('counter'); self:notify('Sale cancelled and tender returned. Ready for the next neighbor.') end end
function App:commit()
 local c=Customers.current(self.state)
 if not c or c.id~=self.saleId then self:notify('Receive the current customer tender first.');return end
 local ok,outcome=self:command('confirmPayment',c.id,self.change)
 if not ok then return end
 if outcome=='retry' then
  self.change={};self.changeOrder={};self:notify('Mali ang sukli. Suki -3. Subukan muli (one retry).');return
 end
 self:clearSale()
 if outcome=='lose' then self:go('lose');self:save();return end
 local record=self.state.completedReferences[c.id];local tip=record and record.tip or 0
 self:notify(tip>0 and ('Salamat! Tip P'..(tip/100)..'. Suki +2.') or 'Salamat! Sale completed.')
 self:go('counter')
end
function App:adjust(delta)
 if self.state.paused or self.portionSwitch then return nil end
 if self.state.phase=='preparation' then self.packQuantity=math.max(0,self.packQuantity+delta);return true end
 local c=Customers.current(self.state);local q=self:quote();if not c or not q then return nil end
 for i,l in ipairs(q.lines) do if l.productId==self.portionProduct then
  local ok,outcome=self:command('adjustPortion',c.id,i,math.max(0,l.actualQuantity+delta),self.view=='timbangan' and delta>0)
  if not ok or outcome=='spilled' or outcome=='spilled_removed' then self:release_held_input() end
  if outcome=='spilled' or outcome=='spilled_removed' then self:notify('Natapon ang mantika. Ulitin ang buhos. P1 penalty.') end
  if outcome=='spilled_removed' then self:go('counter');self:notify('Natapon ang mantika. Kulang ang stock para ulitin.') end
  return ok,outcome
 end end
end
function App:startPour()
 if self.view~='timbangan' and self.view~='repack' and self.view~='scale' then return nil end
 local m=require('src.ui.timbangan_model').model(self)
 if self.state.paused or self.portionSwitch or self.ticketOpen or not m.prep and (not m.line or m.line.confirmed or m.line.spillLocked or self.state.retail.tender) then return nil end
 self.pouring=true;self.pourElapsed=0;self.pourRemainder=0;return true
end
function App:resetPour()
 self:release_held_input()
 if self.state.paused or self.portionSwitch or self.ticketOpen then return nil end
 if self.state.phase=='preparation' then self.packQuantity=0;return true end
 local m=require('src.ui.timbangan_model').model(self);local c=Customers.current(self.state)
 if not c or not m.index then return nil end
 local ok,outcome=self:command('resetPortion',c.id,m.index)
 if outcome=='removed' then self:go('counter');self:notify('Kulang ang stock para ulitin.') end
 return ok,outcome
end
function App:confirmPortion(index) if self.state.phase=='preparation' then if self.packQuantity~=Tuning.mvp.measuredQuantity then self:notify('Fill exactly '..Tuning.mvp.measuredQuantity..' units before sealing.'); return end; self.packSerial=self.packSerial+1; if self:command('prepack','ui:pack:'..self.state.day..':'..self.state.ids.nextBatch..':'..self.packSerial,self.prepackProduct,self.packQuantity) then self.packQuantity=0; self.feedback:place(self.prepackProduct); self:notify(Tuning.mvp.measuredQuantity..'-unit pack sealed.'); end else local c=Customers.current(self.state); if c and index and self:command('confirmPortion',c.id,index) then self.feedback:place(self.portionProduct); self:go('shelves') end end end
function App:pause()
 self.cabinetDrag=nil; self.cabinetHover=nil; self.pouring=false;self.pourElapsed=0;self.pourRemainder=0; self.pausePanel=nil; W.items={}; W.focus=1
 local paused=not self.state.paused
 if self.view=='menu' and not self.menuPauseVisible then paused=true end
 self.menuPauseVisible=self.view=='menu' and paused or false
 self:command('setPaused',paused)
end
-- Focus loss stops tools; it never settles a transaction or resumes a hold.
function App:release_held_input()
    self.pouring = false
    self.pourElapsed = 0
    self.pourRemainder = 0
    self.cabinetDrag = nil
    self.cabinetHover = nil
    W.pressed = nil
end
function App:focus(focused)
    if not focused then self:release_held_input() end
end
function App:check_held_input()
    local mouse_held = love.mouse.isDown(1)
    if self.cabinetDrag and not mouse_held then
        self.cabinetDrag = nil
    end
    if self.pouring and not mouse_held
        and not love.keyboard.isDown('space', 'return') then
        self:release_held_input()
    end
end
function App:update(dt) if self.ticketOpen or self.portionSwitch then self:release_held_input() end; if not self.state.paused then self.uiClock=(self.uiClock or 0)+dt; self.feedback:update(dt) end; if self.state.paused or self.view=='menu' then return end; if self.toastTime>0 then self.toastTime=math.max(0,self.toastTime-dt) end; local c=Customers.current(self.state); local id=c and c.id; local ok,message=Days.update(self.state,dt); if not ok then self.state.paused=true;self:release_held_input();self:notify(message);return end; if message then self:notify(message) end; local current=Customers.current(self.state); if id and (not current or id~=current.id) then self:clearSale(); if self.state.phase=='service' then self:go('counter') end end; if (self.state.phase=='report' or self.state.phase=='recovery' or self.state.phase=='lose') and self.view~=self.state.phase then self:go(self.state.phase); self:save() end; CabinetInput.update(self); if self.pouring and (self.view=='repack' or self.view=='timbangan' or self.view=='scale') then local amount,elapsed,rest=require('src.ui.pour_meter').advance(self.pourElapsed or 0,self.pourRemainder or 0,dt); if not amount then self:release_held_input();self:notify(elapsed);return end; self.pourElapsed=elapsed;self.pourRemainder=rest; if amount>0 then self:adjust(amount) end end end
function App:draw() love.graphics.clear(T.darkwood); Layout.begin(); W.color(T.cream); love.graphics.rectangle('fill',0,0,1280,720); local mx,my=Layout.toCanvas(love.mouse.getPosition()); if self.previewPointer then mx,my=self.previewPointer[1],self.previewPointer[2] end; W.textScale=self.state.settings.textScale; W.frame(mx,my); if self.previewDraw then self.previewDraw(self) else views[self.view].draw(self) end; require('src.ui.day_effects').draw(self.state); Hud.overlay(self); if self.cabinetDrag and not self.state.paused and not self.ticketOpen then views.shelves.drag(self) end; if self.portionSwitch and not self.state.paused then views.timbangan.dialog(self) end; if self.state.paused and (self.view~='menu' or self.menuPauseVisible) then Pause.draw(self) end; if self.toastTime>0 then local toast_y=self.view=='timbangan' and 94 or 585; W.panel(300,toast_y,680,45,T.paper); W.text(self.toast,318,toast_y+11,17,T.maroon,644,'center') end; W.drawTooltip(); if self.debugOverlay then require('src.ui.debug_overlay').draw() end; Layout.finish() end
function App:mousepressed(x,y,button) if button~=1 then return end; local cx,cy,inside=Layout.toCanvas(x,y); if inside then W.mx=cx;W.my=cy;self.pointerActivation=true;W.activate(cx,cy);self.pointerActivation=false end end
function App:mousemoved(x,y) local cx,cy=Layout.toCanvas(x,y);self:moveCabinetPick(cx,cy) end
function App:mousereleased(x,y,button) if button==1 then self.pouring=false;self.pourElapsed=0;self.pourRemainder=0;local cx,cy=Layout.toCanvas(x,y);self:releaseCabinetPick(cx,cy) end end
function App:keypressed(key)
 if key=='f1' then self.debugOverlay=not self.debugOverlay;return end
 if self.portionSwitch and not self.state.paused and key~='escape' then W.key(key);return end
 if key=='escape' then
  if self.ticketOpen then Hud.closeTicket(self);return end
  if self.pausePanel then self.pausePanel=nil; W.items={}; W.focus=1; return end
  self:pause(); return
 end
 if self.ticketOpen then W.key(key); return end
 if not self.state.paused and self.state.phase=='service' then
  local destination=NavigationData.shortcuts[key]
  if destination then self:navigate(destination.id); return end
 end
 W.key(key)
end
function App:keyreleased(key) if key=='space' or key=='return' then self.pouring=false;self.pourElapsed=0;self.pourRemainder=0 end end
function App:resize(w,h)
    Layout.resize(w,h)
    require('src.ui.fonts').clear()
    require('src.ui.draw.grain').clear()
    require('src.ui.draw.patterns').clear()
    require('src.ui.draw.character').clear()
    require('src.ui.draw.heaps').clear()
end
function App:saveDisabledReason()
 local ok,reason=self.persistence.canSave(self.state)
 return not ok and reason or nil
end
function App:save()
 local reason=self:saveDisabledReason()
 if reason then self:notify(reason); return nil,reason end
 local ok,err=self.persistence.save(self.state)
 if ok then self.hasCheckpoint=true;self.pendingCheckpoint=false end
 self:notify(ok and 'Shop saved.' or err)
 return ok,err
end
function App:load()
 local state,warning=self.persistence.load()
 if not state then self:notify(warning); return nil,warning end
 self.state=state
 Order.refresh(state)
 self:clearSale()
 self.packQuantity=0
 self.pourRemainder=0
 self.prepackProduct=nil
 self.prepSection=1
 self.selected=nil
 self.feedback=Feedback.new()
 self.hasCheckpoint=true
 self.pendingCheckpoint=false
 self:go(state.phase=='service' and 'counter' or state.phase)
 self:notify(warning or 'Shop loaded.')
 return true,warning
end
function App:nextMorning()
 if self.state.phase~='report' then
  self:notify('Finish the day before starting the next morning.')
  return nil,'Finish the day first'
 end
 local saved,err=self:save()
 if not saved then return nil,err end
 if not self:command('nextDay') then return nil,'Cannot start the next day' end
 self:clearSale()
 self.packQuantity=0
 self.pourRemainder=0
 self.prepackProduct=nil
 self:go('preparation')
 return true
end
return App






