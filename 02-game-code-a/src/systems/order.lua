-- Allowed line types and daily spotlight; all draws use saved LÖVE state.
local Levels=require('data.levels');local State=require('src.model.state');local Config=require('data.config')
local Products=require('data.products')
local Events=require('src.systems.events')
local Order={}
function Order.kind(line) return line.type or 'item' end
function Order.is_wallet(line)
 local kind=Order.kind(line);return kind=='cash_in' or kind=='cash_out'
end
function Order.is_goods(line)
 local kind=Order.kind(line);return kind=='item' or kind=='weigh' or kind=='repack' or kind=='pour'
end
function Order.valid_goods(line)
 local product=Products.byId[line.productId]
 if not product or not Order.is_goods(line) then return false end
 local kind=Order.kind(line)
 -- Legacy saves used item (or no type) for measured goods.
 if kind=='item' then return true end
 return line.measured==true and ((kind=='pour' and product.saleUnit=='ml')
  or ((kind=='weigh' or kind=='repack') and product.saleUnit=='g'))
end
function Order.matches_goods(line,request)
 return Order.valid_goods(line) and Order.valid_goods(request) and Order.kind(line)==Order.kind(request)
  and line.productId==request.productId and (line.targetQuantity or line.quantity)==request.quantity
  and line.amount==request.amount and (not line.measured or line.confirmed==true)
end
function Order.pool(level) local pool={};for _,kind in ipairs(level.unlocks) do pool[#pool+1]=kind end;return pool end
function Order.allowed(day,kind) for _,value in ipairs(Levels.get(day).unlocks) do if value==kind then return true end end;return false end
function Order.random(state,count)
 local previous=love.math.getRandomState()
 love.math.setRandomState(state.rng.randomState or love.math.newRandomGenerator(state.rng.state):getState())
 local value=count and love.math.random(count) or love.math.random()
 state.rng.randomState=love.math.getRandomState();love.math.setRandomState(previous);return value
end
function Order.refresh(state)
 local level=Levels.get(state.day)
 if state.dayProfile then
  state.dayProfile.unlocks=State.clone(level.unlocks)
  state.dayProfile.maxLines=level.max_lines
  if state.day<=10 then state.dayProfile.event=level.event
  elseif not state.dayProfile.event then
   local events={'rain','payday','brownout'};state.dayProfile.event=events[Order.random(state,#events)]
  end
 end
 -- Retain older overflow queues until they drain; future arrivals obey the new cap.
 for _,customer in ipairs(state.queue) do
  local previousStart=customer.initialPatience or level.patience
  customer.patience=math.max(0,math.min(level.patience,customer.patience+level.patience-previousStart))
  customer.initialPatience=level.patience
 end
 if state.rng.orderDay~=state.day then
  state.rng.orderDay=state.day
  local outcomes=state.serviceOutcomes or {};state.rng.dayCustomer=(outcomes.served or 0)+(outcomes.timedOut or 0)+#state.queue
 end
 if Config.debug then print('DAY '..state.day..' UNLOCKS '..table.concat(level.unlocks,',')) end
 return level
end
function Order.plan(state,count,availability)
 if state.rng.orderDay~=state.day then Order.refresh(state) end
 local level=Levels.get(state.day);local number=state.rng.dayCustomer+1;local result={};local used={}
 local remaining=State.clone(availability)
 for index=1,math.min(count,level.max_lines) do
  local pool={}
  for _,kind in ipairs(Order.pool(level)) do
   if (kind=='cash_in' or kind=='cash_out') and not used[kind]
    or (remaining[kind] or 0)>0 then
    for weight=1,Events.line_weight(state,kind) do pool[#pool+1]=kind end
   end
  end
  if #pool==0 then break end
  local kind=index==1 and level.spotlight[number] or nil
  local eligible=false;for _,value in ipairs(pool) do if value==kind then eligible=true end end
  if not eligible then kind=pool[#pool==1 and 1 or Order.random(state,#pool)] end
  result[#result+1]=kind
  if kind=='cash_in' or kind=='cash_out' then used[kind]=true else remaining[kind]=remaining[kind]-1 end
 end
 if #result>0 then state.rng.dayCustomer=number end
 return result,number
end
function Order.service(state,kind,index)
 local principal=Config.tindapay.principalSizes[Order.random(state,#Config.tindapay.principalSizes)]
 local reference='transfer:'..state.ids.nextCustomer..':'..index
 local recipient=kind=='cash_out' and Config.tindapay.storeAccount or 'neighbor:'..state.ids.nextCustomer
 local request={type=kind,principal=principal,fee=Config.tindapay.fee,amount=kind=='cash_in' and principal+Config.tindapay.fee or Config.tindapay.fee,
  reference=reference,recipient=recipient,transfer={reference=reference,amount=principal,recipient=recipient,status='confirmed'}}
 request.receipt=State.clone(request.transfer)
 if Levels.get(state.day).scam_chance>0 and Order.random(state)<Levels.get(state.day).scam_chance then
  local field=Order.random(state,4)
  if field==1 then request.receipt.amount=principal+100
  elseif field==2 then request.receipt.reference=reference..':fake'
  elseif field==3 then request.receipt.recipient=recipient..':other'
  else request.receipt.status='pending' end
 end
 return request
end
function Order.hasWallet(customer) if customer then for _,line in ipairs(customer.lines) do if line.type=='cash_in' or line.type=='cash_out' then return true end end end;return false end
function Order.log(state,customer)
 if not Config.debug then return end
 for _,line in ipairs(customer.lines) do
  print(string.format('ORDER day=%d customer=%d id=%s line=%s details=%s target=%d',state.day,customer.number,customer.id,Order.kind(line),line.productId or line.reference,line.quantity or line.principal))
 end
end
return Order
