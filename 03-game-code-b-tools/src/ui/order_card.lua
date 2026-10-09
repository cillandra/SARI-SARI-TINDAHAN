-- Purpose: query-only order card, geometry and transient ticket presentation.
local Customers=require('src.systems.customers')
local Line=require('src.ui.order_line')
local F=require('src.ui.format')
local W=require('src.ui.widgets')
local T=require('src.ui.theme')
local O=require('src.ui.draw.outline')
local M={compact={x=934,y=98,w=300,h=132},expanded={x=348,y=535,w=584,h=175}}
function M.fitLine(text,width,measure)
 if measure(text)<=width then return text end
 local chars={}
 for char in text:gmatch('[%z\1-\127\194-\244][\128-\191]*') do chars[#chars+1]=char end
 while #chars>0 do
  table.remove(chars)
  local candidate=table.concat(chars)..'...'
  if measure(candidate)<=width then return candidate end
 end
 return ''
end
function M.model(state)
 local c=Customers.current(state)
 local m={title='ORDER',lines={},queue=#state.queue,empty=not c,patience=0}
 if not c then m.lines[1]='Wala pang order.';return m end
 m.patience=Customers.patience_ratio(c);m.total=c.total
 if state.retail and state.retail.id==c.id then for _,line in ipairs(state.retail.lines) do if line.measured and not line.confirmed then m.openPortion=true;m.title='ORDER *';break end end end
 for i,line in ipairs(c.lines) do
  if i<=4 then m.lines[i]=Line.request(line) end
 end
 return m
end
local function inside(r) return W.mx>=r.x and W.mx<=r.x+r.w and W.my>=r.y and W.my<=r.y+r.h end
local function compact(m)
 local r=M.compact
 O.rect(r.x,r.y,r.w,r.h,T.paper,5,1)
 O.rect(r.x+10,r.y-1,90,25,T.maroon,4,1)
 W.text(m.title,r.x+17,r.y+2,18/(W.textScale or 1),T.paper,76,'center')
 W.text('Pila: '..m.queue,r.x+197,r.y+5,18,T.maroon,93,'right')
 local size=math.min(18,15*(W.textScale or 1))
 local font=require('src.ui.fonts').get(size)
 assert(font:getHeight()<=22,'Compact order line exceeds its vertical budget')
 for i,line in ipairs(m.lines) do
  local fitted=M.fitLine(line,r.w-24,function(text) return font:getWidth(text) end)
  W.text(fitted,r.x+12,r.y+29+(i-1)*22,size/(W.textScale or 1),m.empty and T.darkwood or T.ink)
 end
 local g=love.graphics
 W.color(T.blush);g.rectangle('fill',r.x+12,r.y+r.h-12,r.w-24,5,2,2)
 W.color(m.patience>.3 and T.sage or T.dustyrose);g.rectangle('fill',r.x+12,r.y+r.h-12,(r.w-24)*m.patience,5,2,2)
end
local function expanded(m,a,toggle)
 local r=M.expanded
 local points={r.x,r.y,r.x+r.w,r.y,r.x+r.w,r.y+r.h-5}
 for i=1,48 do points[#points+1]=r.x+r.w-r.w*i/48;points[#points+1]=r.y+r.h-(i%2==0 and 5 or 0) end
 O.polygon(points,T.paper,1.2)
 W.text(m.title,r.x+18,r.y+10,22/(W.textScale or 1),T.maroon,380)
 if a.ticketOpen then W.button('Close',r.x+r.w-130,r.y+9,112,44,function() toggle(a) end,T.blush)
 else W.text('Click card to pin',r.x+r.w-174,r.y+14,16,T.maroon,156,'right') end
 local size=math.min(20,18*(W.textScale or 1))
 local spacing=#m.lines>3 and 24 or 28
 for i,line in ipairs(m.lines) do W.text(line,r.x+18,r.y+43+(i-1)*spacing,size/(W.textScale or 1),m.empty and T.darkwood or T.ink,r.w-36) end
 local footer=(m.total and 'Order total  '..F.money(m.total)..'   |   ' or '')..'Pila: '..m.queue..(m.openPortion and ' | * Open portion' or '')
 W.text(footer,r.x+18,r.y+r.h-35,18/(W.textScale or 1),T.maroon,r.w-36)
end
function M.hover(a)
 local hot=inside(M.compact) or inside(M.expanded) or inside(require('data.navigation').ticket.rect)
 if a.suppressTicketHover then
  if not hot then a.suppressTicketHover=false end
  a.orderCardHover=false;return false
 end
 local hover=a.ticketHover or a.view=='counter' and inside(M.compact) or a.orderCardHover and inside(M.expanded)
 a.orderCardHover=not not hover
 return a.orderCardHover
end
function M.overlay(a,toggle)
 if a.view=='menu' then a.ticketHover=false;a.orderCardHover=false;return end
 local shown=a.view=='counter'
 local hover=M.hover(a)
 if a.ticketOpen then W.items={};W.tooltip=nil;W.focus=1 end
 local m=M.model(a.state)
 if shown then
  compact(m)
  W.hit(M.compact.x,M.compact.y,M.compact.w,M.compact.h,function() toggle(a) end,{id='order_card'})
 end
 if not a.ticketOpen and not hover then return end
 if not a.ticketOpen then W.hit(M.expanded.x,M.expanded.y,M.expanded.w,M.expanded.h,function() toggle(a) end,{id='expanded_order'}) end
 expanded(m,a,toggle)
end
return M
