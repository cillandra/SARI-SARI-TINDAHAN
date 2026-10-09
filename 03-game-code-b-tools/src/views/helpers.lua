-- Purpose: view queries and common panels, no economic calculations. API: header,request,basket,back. Dependencies: UI/domain queries.
local W=require('src.ui.widgets'); local T=require('src.ui.theme'); local F=require('src.ui.format'); local Products=require('data.products'); local Customers=require('src.systems.customers'); local Retail=require('src.systems.retail'); local Cash=require('src.systems.cash'); local Hud=require('src.ui.draw.hud'); local Line=require('src.ui.order_line'); local H={}
function H.header(a,title,subtitle) Hud.draw(a,title,subtitle) end
function H.back(a) W.button('< Counter',32,642,175,48,function() a:go('counter') end); W.button('Pause',1100,642,148,48,function() a:pause() end) end
function H.request(a,x,y,w)
 local c=Customers.current(a.state)
 W.panel(x,y,w,220,T.paper)
 W.text(c and 'Your neighbor asks for' or 'Waiting for a neighbor…',x+18,y+16,w<300 and 19 or 23,T.maroon,w-36)
 if c then
  local spacing=#c.lines>3 and 29 or 37
  for i,line in ipairs(c.lines) do W.text(Line.request(line),x+18,y+66+(i-1)*spacing,w<300 and 15 or 18,T.ink,w-36) end
  W.text('Patience  '..math.ceil(c.patience)..'s',x+18,y+177,17)
 end
 return c
end
function H.basket(a,x,y,w) local q=a:quote(); W.panel(x,y,w,220,T.cream); W.text('On the counter',x+18,y+14,23,T.maroon); if q then for i,l in ipairs(q.lines) do W.text(Line.name(l)..(l.measured and (l.confirmed and '  OK' or '  weighing') or '  OK'),x+18,y+50+(i-1)*30,17,T.ink,w-36) end; W.text('Total  '..F.money(q.total),x+18,y+181,21) else W.text('Pick the requested goods.',x+18,y+58,18) end end
function H.find(a,pid) local q=a:quote(); if q then for i,l in ipairs(q.lines) do if l.productId==pid then return l,i end end end end
return H



