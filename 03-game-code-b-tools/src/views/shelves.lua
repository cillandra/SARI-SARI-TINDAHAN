-- Six-section cabinet; stock and prices are queried, actions delegate to the app.
local W=require('src.ui.widgets');local T=require('src.ui.theme')
local H=require('src.views.helpers');local F=require('src.ui.format')
local P=require('data.products');local O=require('src.ui.draw.outline')
local Wood=require('src.ui.draw.materials');local Heaps=require('src.ui.draw.heaps')
local Sparkle=require('src.ui.draw.sparkle');local L=require('src.ui.cabinet_layout')
local Model=require('src.ui.cabinet_model');local Fonts=require('src.ui.fonts')
local Fit=require('src.ui.order_card').fitLine
local Line=require('src.ui.order_line')
local V={};local names={'Staples & loose goods','Noodles & canned','Snacks & sweets','Drinks & sachets','Household','Everyday essentials'}
local labels={rice_regular='Rice',rice_premium='Prem.\nrice',cooking_oil='Oil',sugar='Sugar',salt='Salt',flour='Flour',mongo_beans='Mongo',pancit_canton='Pancit',soup_noodles='Soup\nnoodle',sardines='Fish',tuna='Tuna',corned_beef='Beef',meat_loaf='Loaf',canned_beans='Beans',candy='Candy',chewing_gum='Gum',crackers='Crack.',biscuits='Biscuit',chips='Chips',peanuts='Peanut',bottled_water='Water',cola='Cola',orange_soda='Orange',powdered_juice='Juice',instant_coffee='Coffee',coffee_mix='Coffee\nmix',powdered_milk='Milk',shampoo='Hair\nwash',conditioner='Cond.',bath_soap='Soap',toothpaste='Paste',detergent='Wash',dishwashing='Dish\nsoap',eggs='Eggs',candles='Candle',matches='Match'}

local function dashed(r)
 W.color(T.steel);love.graphics.setLineWidth(1)
 for x=r.x+5,r.x+r.w-8,12 do love.graphics.line(x,r.y+5,math.min(x+6,r.x+r.w-5),r.y+5);love.graphics.line(x,r.y+r.h-5,math.min(x+6,r.x+r.w-5),r.y+r.h-5) end
 for y=r.y+5,r.y+r.h-8,12 do love.graphics.line(r.x+5,y,r.x+5,math.min(y+6,r.y+r.h-5));love.graphics.line(r.x+r.w-5,y,r.x+r.w-5,math.min(y+6,r.y+r.h-5)) end
end
local function meter(r,stock,ratio)
 O.rect(r.x+82,r.y+8,5,38,T.bininner,1,.6)
 if stock>0 then O.rect(r.x+83,r.y+46-38*ratio,3,38*ratio,ratio<.25 and T.dustyrose or ratio<.5 and T.mustard or T.sage,1,.4) end
end
local function tooltip(a,p,stock)
 local x=math.max(32,math.min(864,W.mx+18));local y=math.max(128,math.min(517,W.my>400 and W.my-123 or W.my+22))
 O.rect(x,y,384,112,T.paper,7)
 local size=math.min(24,20*(W.textScale or 1));local font=Fonts.get(size)
 W.text(Fit(p.name,360,function(s) return font:getWidth(s) end),x+12,y+11,size/(W.textScale or 1),T.maroon)
 W.text('Stock '..stock..' '..p.stockUnit,x+12,y+46,18,T.ink,360)
 W.text('Price '..F.money(a.state.prices[p.id])..' / '..p.priceQuantity..' '..p.saleUnit,x+12,y+77,17,T.ink,360)
end
function V.draw(a)
 local m=Model.model(a);local hoverProduct,hoverStock
 local reduced=a.state.settings.reducedMotion
 for section=1,6 do
  local frame=L.sections[section];Wood.wood(frame.x,frame.y,frame.w,frame.h,T.wood,true)
  O.line({frame.x+48,frame.y-9,frame.x+48,frame.y+4},T.darkwood,1.5)
  O.line({frame.x+frame.w-48,frame.y-9,frame.x+frame.w-48,frame.y+4},T.darkwood,1.5)
  O.rect(frame.x+23,frame.y-8,frame.w-46,28,T.mustard,5)
  W.text(names[section],frame.x+31,frame.y-5,17,T.maroon,frame.w-62,'center')
  for slot=1,8 do
   local r=L.slot(section,slot);local p=Model.slots[section][slot]
   O.rect(r.x,r.y,r.w,r.h,T.darkwood,4,.8)
   O.rect(r.x+3,r.y+3,r.w-6,r.h-6,T.paper,3,.6)
   if p then
    local stock,ratio=Model.stock(a.state,p);local picked=m.picked[p.id]
    local hover=L.contains(r,W.mx,W.my)
    local size=45*(a.feedback and a.feedback:scale(p.id,reduced) or 1)
    local wiggle=hover and not reduced and math.sin(a.uiClock*4) or 0
    Heaps.draw(p,r.x+19+(45-size)/2+wiggle,r.y+4+(45-size)/2,size,size)
    if stock<=0 and not picked then W.color({T.paper[1],T.paper[2],T.paper[3],.65});love.graphics.rectangle('fill',r.x+4,r.y+4,73,45) end
    meter(r,stock,ratio)
    local smallDrawer=p.saleUnit=='piece' and (section==3 or section==5 or section==4 and slot>=4)
    local pull=smallDrawer and hover and (stock>0 or picked) and 3 or 0
    O.rect(r.x+4,r.y+50+pull,r.w-8,17,smallDrawer and T.wood or T.paper,2,.6)
    if smallDrawer then O.line({r.x+31,r.y+48+pull,r.x+58,r.y+48+pull},T.darkwood,2) end
    local fontSize=math.min(15,13*(W.textScale or 1));local font=Fonts.get(fontSize)
    local label=(labels[p.id] or p.name):gsub('\n',' ')
    W.text(Fit(label,r.w-12,function(s) return font:getWidth(s) end),r.x+6,r.y+50+pull,fontSize/(W.textScale or 1),T.ink,r.w-12,'center')
    O.rect(r.x+5,r.y+72,r.w-10,19,picked and T.sage or T.paper,3,.6)
    W.text(F.money(a.state.prices[p.id]),r.x+7,r.y+72,math.min(16,14*(W.textScale or 1))/(W.textScale or 1),T.maroon,r.w-14,'center')
    if picked then O.ellipse(r.x+9,r.y+10,3,3,T.sage,.5) end
    if stock>0 and ratio<.25 then Sparkle.draw(r.x+10,r.y+18,4,reduced and 0 or a.uiClock) end
    if stock>0 or picked then W.hit(r.x,r.y,r.w,r.h,function()
     if a.pointerActivation then a:beginCabinetPick(p.id,W.mx,W.my) else a:pick(p.id) end
    end) end
    if hover then hoverProduct=p;hoverStock=stock end
   else dashed(r) end
  end
 end
 local c=L.controls
 W.button('< Counter',c.back.x,c.back.y,c.back.w,c.back.h,function() a:go('counter') end)
 W.button('Cancel sale',c.cancel.x,c.cancel.y,c.cancel.w,c.cancel.h,function() a:cancel() end,T.blush)
 W.button('Receive payment >',c.receive.x,c.receive.y,c.receive.w,c.receive.h,function() a:receive() end,T.mustard)
 local b=L.basket
 W.button('',b.x,b.y,b.w,b.h,function() a:notify('Pick or drag requested goods here, then receive payment.') end,T.sage)
 W.text('Basket',b.x+10,b.y+3,16,T.ink,110,'center')
 W.text(m.count..' / '..m.requested,b.x+10,b.y+24,14,T.ink,110,'center')
 if #m.items==0 then W.text('Drop requested goods here',b.x+126,b.y+14,16,T.ink,b.w-138,'center') end
 for i,line in ipairs(m.items) do
  if i>3 then break end
  local x=b.x+126+(i-1)*134;local p=P.byId[line.productId]
  O.rect(x,b.y+4,128,40,T.paper,5,.7)
  local size=math.min(16,14*(W.textScale or 1));local font=Fonts.get(size)
  local label=p and (labels[p.id] or p.name):gsub('\n',' ') or Line.name(line)
  W.text(Fit(label,116,function(text) return font:getWidth(text) end),x+6,b.y+5,size/(W.textScale or 1),T.ink,116,'center')
  W.text(Line.quantity(line),x+6,b.y+24,13,T.maroon,116,'center')
 end
 if Model.hover(a,hoverProduct and hoverProduct.id,a.uiClock) then tooltip(a,hoverProduct,hoverStock) end
 H.header(a,'The shelf cabinet','')
end
function V.drag(a)
 local d=a.cabinetDrag;if not d then return end
 Heaps.draw(P.byId[d.productId],d.x-28,d.y-28,56,56)
 local b=L.basket;W.color(T.mustard);love.graphics.setLineWidth(2);love.graphics.rectangle('line',b.x+2,b.y+2,b.w-4,b.h-4,9,9)
end
return V
