-- Purpose: reference-informed maroon HUD and query-only receipt overlay. API: draw(app,title,subtitle),overlay(app). Dependencies: UI/domain queries.
local W=require('src.ui.widgets'); local T=require('src.ui.theme'); local O=require('src.ui.draw.outline'); local Icons=require('src.ui.draw.icons'); local F=require('src.ui.format'); local Cash=require('src.systems.cash'); local Tuning=require('data.tuning'); local Hud={}; local Navigation=require('data.navigation');local Days=require('src.systems.days')
local function plate(x,y,w,h) O.rect(x,y,w,h,T.maroon,8,1.5) end
function Hud.closeTicket(a)
 a.ticketOpen=false;a.ticketHover=false;a.orderCardHover=false;a.suppressTicketHover=true
 W.items={};W.focus=1
end
function Hud.toggleTicket(a)
 if a.ticketOpen then Hud.closeTicket(a);return end
 a.ticketOpen=true;a.ticketHover=false;a.orderCardHover=false;a.suppressTicketHover=false
 W.items={};W.focus=1
end
local function contains(r) return W.mx>=r.x and W.mx<=r.x+r.w and W.my>=r.y and W.my<=r.y+r.h end
function Hud.models(state,features)
 features=features or Tuning.features
 local progress=Days.progress(state)
 local minutes=480+math.floor(progress*720); local hour=math.floor(minutes/60)
 local clock=string.format('%d:%02d %s',hour%12==0 and 12 or hour%12,minutes%60,hour>=12 and 'PM' or 'AM')
 local mood=math.floor(state.reputation/Tuning.reputationMax*100)
 local locked=not features.wallet or state.day<Navigation.byId.phone.unlock
 local offline=not locked and state.dayProfile and state.dayProfile.walletOutage
 return {
  {id='day',label='ARAW '..state.day,value=clock,icon=progress>=.8 and 'moon' or 'sun',rect={x=24,y=15,w=224,h=70}},
  {id='suki',label='SUKI',value=mood..'%',icon=mood>=70 and 'mood' or mood>=40 and 'mood_neutral' or 'mood_worried',rect={x=260,y=15,w=160,h=70}},
  {id='cash',label='CASH',value=F.money(Cash.total(state)),icon='cash',rect={x=432,y=15,w=220,h=70}},
  {id='wallet',label=Tuning.walletName,value=locked and 'Bukas sa Araw '..Navigation.byId.phone.unlock or offline and 'Offline' or F.money(state.wallet.balance),icon=locked and 'lock' or offline and 'offline' or 'wallet',locked=locked,rect={x=664,y=15,w=404,h=70}},
  {id='ticket',icon='ticket',rect=Navigation.ticket.rect},
  {id='menu',icon='menu',rect=Navigation.pause.rect}
 }
end
local function paint(model,a)
 local r=model.rect
 local g=love.graphics
 g.push('all')
 plate(r.x,r.y,r.w,r.h)
 W.color(T.dustyrose);g.setLineWidth(1);g.rectangle('line',r.x+3,r.y+3,r.w-6,r.h-6,6,6)
 local cx=model.label and r.x+30 or r.x+r.w/2
 O.ellipse(cx,r.y+r.h/2,20,20,T.paper,1)
 Icons.draw(model.icon,cx-15,r.y+r.h/2-15,30,T.ink)
 if model.label then
  W.text(model.label,r.x+60,r.y+5,18,T.paper,r.w-68)
  O.rect(r.x+58,r.y+32,r.w-68,30,T.paper,3,1)
  W.text(model.value,r.x+63,r.y+37,18,T.ink,r.w-78,'center')
 end
 if model.locked then
  W.color({T.maroon[1],T.maroon[2],T.maroon[3],.22});g.rectangle('fill',r.x,r.y,r.w,r.h,8,8)
  if contains(r) then W.tooltip={text=Tuning.features.wallet and 'Bukas sa Araw 2' or 'TindaPay transactions are not available in this build.',x=r.x+r.w/2,y=r.y+r.h} end
 end
 g.pop()
 if model.id=='ticket' then
  a.ticketHover=contains(r)
  W.hit(r.x,r.y,r.w,r.h,function() a:navigate(Navigation.ticket.id) end,{id='ticket'})
 elseif model.id=='menu' then
  W.hit(r.x,r.y,r.w,r.h,function() a:navigate(Navigation.pause.id) end,{id='pause'})
 end
end
function Hud.draw(a,title,subtitle)
 for _,model in ipairs(Hud.models(a.state)) do paint(model,a) end
 if a.view~='counter' then W.text(title or '',32,94,20,T.maroon,880) end
 if a.state.phase=='preparation' then W.text(subtitle or '',32,120,18,T.ink,1216) end
end
function Hud.overlay(a) require('src.ui.order_card').overlay(a,Hud.toggleTicket) end
return Hud
