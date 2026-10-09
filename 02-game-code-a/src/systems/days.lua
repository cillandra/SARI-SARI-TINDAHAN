-- Owns preparation, timed service, untimed report and deterministic morning retry.
local Profiles = require('data.days')
local Tuning = require('data.tuning')
local State = require('src.model.state')
local Customers = require('src.systems.customers')
local Economy = require('src.systems.economy')
local Validate = require('src.model.validate')
local Order=require('src.systems.order')
local Config=require('data.config')
local Levels=require('data.levels')
local Restock=require('src.systems.restock')
local Events=require('src.systems.events')
local Days = {}
local function publish(live,staged)
 for key in pairs(live) do live[key]=nil end
 for key,value in pairs(staged) do live[key]=value end
end
function Days.start_card(state)
 local level=Levels.get(state.day);local next_level=Levels.get(state.day+1)
 local tip=level.tip
 if state.day>10 then tip=Events.notice(state) or tip end
 return {day=state.day,customers=level.customers,goal=level.goal,intro=level.intro,tip=tip,
  warning=level.warning,nextWarning=next_level.warning,barya_notice=level.barya_low or next_level.barya_low}
end
function Days.arrival_interval(day)
 local progress=math.min(math.max(day-1,0),Config.arrival_last_day-1)/(Config.arrival_last_day-1)
 return Config.arrival_start+(Config.arrival_min-Config.arrival_start)*progress
end
function Days.progress(state)
 return math.min(1,(state.serviceOutcomes and state.serviceOutcomes.served or 0)/Levels.get(state.day).customers)
end
local function prepare(state)
    if state.retail or #state.queue>0 then return nil,'Finish current service first' end
    if state.dayProfile and state.dayProfile.day~=state.day then
        for field in pairs(state.ledger) do state.ledger[field]=0 end
    end
    state.mvp = true
    local previous_barya=state.dayProfile and state.dayProfile.day==state.day and state.dayProfile.baryaPrepared
    local previous_event=state.dayProfile and state.dayProfile.day==state.day and state.dayProfile.event
    local profile = Profiles.mvpProfiles[math.min(state.day,#Profiles.mvpProfiles)]
    state.dayProfile = State.clone(profile)
    state.dayProfile.day=state.day
    state.dayProfile.baryaPrepared=previous_barya or nil
    if state.day>10 then state.dayProfile.event=previous_event end
    if state.day>5 then
        local increase = math.min(state.day-5,Tuning.mvp.endlessSteps)*Tuning.mvp.rushStepBasisPoints
        state.dayProfile.id='ordinary_endless'
        state.dayProfile.name='Ordinary day '..state.day
        state.dayProfile.arrivalMultiplierBasisPoints=math.min(Tuning.endless.maxArrivalMultiplierBasisPoints,10000+increase)
    end
    state.phase='preparation'
    state.paused=false
    state.time={elapsed=0,spawnCountdown=Days.arrival_interval(state.day),closing=false}
    state.serviceOutcomes={served=0,timedOut=0}
    Order.refresh(state)
    state.time.spawnCountdown=Events.arrival_interval(state,Days.arrival_interval(state.day))
    local ok,err=Restock.prepare(state);if not ok then return nil,err end
    local snapshot=State.clone(state)
    snapshot.morningSnapshot=nil
    state.morningSnapshot=snapshot
    return true
end
function Days.prepare(state)
 local staged=State.clone(state);local ok,err=prepare(staged)
 if not ok then return nil,err end
 publish(state,staged);return true
end
function Days.arrive(state)
 local ok,err=Customers.spawn(state)
 if ok then return true end
 if err=='No stocked products for an order' then
  -- No eligible Day1 stock: count a polite dismissal instead of trapping service.
  state.rng.dayCustomer=(state.rng.dayCustomer or 0)+1
  state.ids.nextCustomer=state.ids.nextCustomer+1
  state.serviceOutcomes.timedOut=state.serviceOutcomes.timedOut+1
  return true,'Wala nang stock. Customer dismissed.'
 end
 return nil,err
end
function Days.open(state)
    if state.phase~='preparation' or not state.mvp or not state.dayProfile then return nil,'Prepare day before opening' end
    if state.reputation==0 then return Customers.lose(state) end
    state.phase='service'
    return Days.arrive(state)
end
function Days.close(state)
 if state.phase~='service' then return nil,'No service to close' end
 if state.reputation==0 then return Customers.lose(state) end
 if #state.queue>0 then state.time.closing=true;return true end
 local report,err=Economy.day_report(state);if not report then return nil,err end
 -- Missing goals or resources do not end a surviving run; only zero Suki does.
 state.time.closing=true;state.phase='report';state.dayReport=report
 state.histories.days[#state.histories.days+1]=State.clone(report)
 return true
end
function Days.update(state,dt)
 if type(dt)~='number' or dt~=dt or dt<0 or dt==math.huge then return nil,'Invalid elapsed time' end
 if state.phase~='service' or state.paused then return true end
 if state.reputation==0 then return Customers.lose(state) end
 local remaining=dt;local notice
 while state.phase=='service' do
  if (state.rng.dayCustomer or 0)>=Levels.get(state.day).customers then state.time.closing=true end
  if state.time.closing and #state.queue==0 then return Days.close(state) end
  if remaining<=0 then break end
  local step=math.min(remaining,state.time.closing and remaining or math.max(0,state.time.spawnCountdown))
  for index,customer in ipairs(state.queue) do
   local rate=Events.patience_rate(state,index)
   step=math.min(step,customer.patience/rate)
  end
  if step>0 then
   local ok,err=Customers.update(state,step);if not ok then return nil,err end
   state.time.elapsed=state.time.elapsed+step;state.time.spawnCountdown=state.time.spawnCountdown-step
   remaining=remaining-step
  end
  if state.phase=='service' and not state.time.closing and state.time.spawnCountdown<=0 then
   if #state.queue<Config.queue_max then
    local ok,err=Days.arrive(state);if not ok then return nil,err end
    notice=err or notice
   end
   state.time.spawnCountdown=Events.arrival_interval(state,Days.arrival_interval(state.day))
  end
 end
 return true,notice
end
function Days.next(state)
    if state.phase~='report' then return nil,'Finish the day first' end
    if not Validate.positive(state.day+1) then return nil,'Invalid day' end
    local staged=State.clone(state);staged.day=staged.day+1
    local ok,err=Days.prepare(staged);if not ok then return nil,err end
    publish(state,staged);return true
end
function Days.retry(state)
    if not state.morningSnapshot then return nil,'No morning snapshot' end
    local restored=State.clone(state.morningSnapshot)
    for key in pairs(state) do state[key]=nil end
    for key,value in pairs(restored) do state[key]=value end
    return Days.prepare(state)
end
return Days

