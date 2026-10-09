-- Read-only event effects; selection and persistence belong to daily order refresh.
local Config=require('data.config')
local Events={}
local function event(state)
 local value=state.dayProfile and state.dayProfile.event
 if value=='brownout' and state.day<=10 then return nil end
 return value
end
function Events.arrival_interval(state,base)
 local value=event(state)
 return base*((value=='rain' or value=='fiesta') and Config.event_effects.rain_interval or 1)
end
function Events.line_weight(state,kind)
 local value=event(state)
 if (value=='payday' or value=='fiesta') and (kind=='cash_in' or kind=='cash_out') then
  return Config.event_effects.payday_wallet_weight
 end
 return 1
end
function Events.patience_rate(state,index)
 local rate=index==1 and 1 or Config.queue_wait_rate
 return rate*(event(state)=='brownout' and Config.event_effects.brownout_patience or 1)
end
function Events.dim(state)
 return state.phase=='service' and event(state)=='brownout' and Config.event_effects.brownout_dim or 0
end
function Events.notice(state)
 local value=event(state)
 local notices={rain='Ulan: mas mabilis ang dating ng suki.',payday='Payday: mas maraming TindaPay.',
  fiesta='Fiesta: mabilis ang dating at maraming TindaPay.',brownout='Brownout: mas mabagal maubos ang pasensya.'}
 return notices[value]
end
return Events
