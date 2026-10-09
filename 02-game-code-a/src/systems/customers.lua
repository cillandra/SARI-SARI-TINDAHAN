-- Seeded customer generation and globally ticking service patience.
local Products = require('data.products')
local Tuning = require('data.tuning')
local Inventory = require('src.systems.inventory')
local Retail = require('src.systems.retail')
local State = require('src.model.state')
local Customers = {}
local Reputation=require('src.systems.reputation')
local Levels=require('data.levels')
local Config=require('data.config')
local Order=require('src.systems.order')
local TindaPay=require('src.systems.tindapay')
local Events=require('src.systems.events')
local MeasuredRequests=require('src.systems.measured_requests')
local random=Order.random
local function wholePesos(price,quantity,base)
 return math.floor((price*quantity+base*50)/(base*100))*100
end
local function eligible(product,kind)
 if kind=='item' then return product.saleUnit=='piece' end
 if kind=='pour' then return product.id=='cooking_oil' end
 if kind=='weigh' then return product.saleUnit=='g' and product.min_g~=nil end
 return kind=='repack' and product.timbangan and product.timbangan.mode=='repack'
end
local function quantities(state,product,kind)
 local result={};local available=Inventory.available(state,product.id)
 local function add(q)
  local amount=wholePesos(state.prices[product.id],q,product.priceQuantity)
  if q<=available and amount>0 then result[#result+1]={quantity=q,amount=amount,requestMode='quantity',requestValue=q} end
 end
 if kind=='weigh' then for q=product.min_g,product.max_g,product.step_g do add(q) end
 elseif kind=='item' then for _,q in ipairs(product.portionSizes) do add(q) end
 else for _,option in ipairs(MeasuredRequests.options(state,product,kind)) do
  if option.quantity<=available then result[#result+1]=option end
 end end
 return result
end
local function candidates(state,kind,used)
 local result={}
 for _,p in ipairs(Products.list) do
  if not used[p.id] and state.day>=p.unlock.demandDay and eligible(p,kind) and #quantities(state,p,kind)>0 then result[#result+1]=p end
 end
 return result
end
local function goods(state,kind,used)
 local choices=candidates(state,kind,used);local alternatives={}
 for _,p in ipairs(choices) do if kind=='item' or p.id~=state.rng.lastLoose then alternatives[#alternatives+1]=p end end
 if #alternatives>0 then choices=alternatives end
 if #choices==0 then return nil end
 local p=choices[random(state,#choices)];local sizes=quantities(state,p,kind);local q=sizes[random(state,#sizes)]
 used[p.id]=true
 if kind~='item' then state.rng.lastLoose=p.id end
 return {type=kind,productId=p.id,quantity=q.quantity,amount=q.amount,
  measured=kind~='item',requestMode=q.requestMode,requestValue=q.requestValue}
end
-- Presentation queries use each customer's original patience, including legacy saves.
function Customers.patience_ratio(customer)
 if not customer then return 0 end
 local start=customer.initialPatience or Tuning.mvp.patienceSeconds
 return math.max(0,math.min(1,customer.patience/start))
end
function Customers.mood(customer)
 local ratio=Customers.patience_ratio(customer)
 if ratio>.7 then return 'happy' end
 if ratio>=.4 then return 'waiting' end
 if ratio>=.15 then return 'impatient' end
 return 'angry'
end
function Customers.current(state)
 return state.queue[1] and State.clone(state.queue[1]) or nil
end
function Customers.generate(state)
 local level=Levels.get(state.day);local availability={};local used={}
 for _,kind in ipairs(Order.pool(level)) do
  if kind~='cash_in' and kind~='cash_out' then availability[kind]=#candidates(state,kind,used) end
 end
 local types,number=Order.plan(state,random(state,level.max_lines),availability)
 local lines,total={},0
 for index,kind in ipairs(types) do
  local request
  if kind=='cash_in' or kind=='cash_out' then request=Order.service(state,kind,index) else request=goods(state,kind,used) end
  if request then lines[#lines+1]=request;total=total+request.amount end
 end
 if #lines==0 then return nil,'No stocked products for an order' end
 local customer={id='customer:'..state.ids.nextCustomer,day=state.day,number=number,lines=lines,total=total,
  patience=level.patience,initialPatience=level.patience}
 Order.log(state,customer)
 state.ids.nextCustomer=state.ids.nextCustomer+1
 return customer
end
function Customers.spawn(state)
 if state.reputation==0 or state.phase~='service' or state.time.closing or #state.queue>=Config.queue_max then return nil,'Arrivals closed or queue full' end
 if (state.rng.dayCustomer or 0)>=Levels.get(state.day).customers then return nil,'Daily customer count reached' end
 local customer,err=Customers.generate(state)
 if not customer then return nil,err end
 state.queue[#state.queue+1]=customer
 return true
end
-- Called only after all requested lines exist and measured portions are confirmed.
-- Cache the decision so navigation/repeated receive cannot reroll tender.
function Customers.payment(state)
 local c=state.queue[1];local sale=state.retail
 if not c or not sale or sale.id~=c.id or #sale.lines~=#c.lines then return nil,'Complete the requested basket first' end
 for _,request in ipairs(c.lines) do
  local complete=false
  for _,line in ipairs(sale.lines) do
   if Order.is_wallet(request) then if TindaPay.match(line,request) then complete=true end
   elseif Order.matches_goods(line,request) then complete=true end
  end
  if not complete then return nil,'Complete the requested basket first' end
 end
 if c.tender then return State.clone(c.tender) end
 if sale.total%100~=0 then return nil,'Receipt total must be whole pesos' end
 local level=Levels.get(state.day);local roll=random(state)
 local number=tonumber(c.id:match('^customer:(%d+)$')) or 0
 local change=state.day==1 and number>=1 and number<=2 or roll<level.change_chance
 local amount=sale.total
 if change then
  local bills={};for _,bill in ipairs(level.tender_bills) do if bill>sale.total then bills[#bills+1]=bill end end
  table.sort(bills)
  if #bills==0 then
   for _,bill in ipairs({50000,100000}) do if bill>sale.total then bills[1]=bill;break end end
  end
  if #bills==0 then return nil,'No configured bill covers this order' end
  local index=1
  if #bills>1 and random(state)>=.8 then index=random(state,#bills) end
  amount=bills[index]
 end
 local bundle={};local remaining=amount
 for i=#Tuning.denominations,1,-1 do local d=Tuning.denominations[i];local n=math.floor(remaining/d);if n>0 then bundle[d]=n;remaining=remaining-n*d end end
 if remaining~=0 then return nil,'Tender cannot be represented by drawer denominations' end
 c.tender=bundle
 if Config.debug then print(string.format('PAYMENT customer=%d total / tender / change due = %d / %d / %d pesos',number,sale.total/100,amount/100,(amount-sale.total+TindaPay.summary(sale).payout)/100)) end
 return State.clone(bundle)
end
-- Loss cleanup uses the same cancellation rules as ordinary service, atomically.
local function publish(live,staged)
 for _,key in ipairs({'queue','serviceOutcomes','inventory','reservations','ledger','cancelledRetail','retail','reputation','phase','time'}) do live[key]=staged[key] end
end
function Customers.lose(state)
 if state.reputation>0 then return nil,'Suki remains above zero' end
 if state.phase=='lose' then return true end
 local staged=State.clone(state)
 if staged.retail then
  local ok,err=Retail.cancel(staged,staged.retail.id);if not ok then return nil,err end
 end
 staged.queue={};staged.time.closing=true;staged.phase='lose'
 publish(state,staged)
 return true
end
function Customers.update(state, dt)
    if type(dt)~='number' or dt~=dt or dt<0 or dt==math.huge then return nil,'Invalid elapsed time' end
    if state.phase ~= 'service' or state.paused then return true end
    if state.reputation==0 then return Customers.lose(state) end
    local live = state
    -- A waiting timeout may end the run and require cancelling the active sale.
    if state.retail then
        for index,customer in ipairs(state.queue) do
            local rate=Events.patience_rate(state,index)
            if customer.patience<=dt*rate then state=State.clone(state);break end
        end
    end
    local remaining=dt
    while remaining>0 and #state.queue>0 and state.phase=='service' do
        local step=remaining
        for index,customer in ipairs(state.queue) do
            local rate=Events.patience_rate(state,index)
            step=math.min(step,customer.patience/rate)
        end
        for index,customer in ipairs(state.queue) do
            local rate=Events.patience_rate(state,index)
            customer.patience=math.max(0,customer.patience-step*rate)
        end
        for index=#state.queue,1,-1 do
            local customer=state.queue[index]
            if customer.patience<=0 then
                if state.retail and state.retail.id==customer.id then
                    local ok,err=Retail.cancel(state,customer.id)
                    if not ok then return nil,err end
                end
                table.remove(state.queue,index)
                state.serviceOutcomes.timedOut=state.serviceOutcomes.timedOut+1
                Reputation.adjust(state,-Config.timeout_penalty)
                if state.reputation==0 then
                    local ok,err=Customers.lose(state);if not ok then return nil,err end
                    break
                end
            end
        end
        remaining=remaining-step
    end
    if state ~= live then publish(live,state) end
    return true
end
return Customers


