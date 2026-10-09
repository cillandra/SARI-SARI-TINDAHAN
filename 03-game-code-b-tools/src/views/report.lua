-- Daily summary renders a nonmutating, validated backend query.
local W=require('src.ui.widgets')
local T=require('src.ui.theme')
local F=require('src.ui.format')
local H=require('src.views.helpers')
local E=require('src.systems.economy')
local Paper=require('src.ui.draw.paper')
local O=require('src.ui.draw.outline')
local V={}
local function stars(count)
 for i=1,3 do
  local vertices={};local x=1018+(i-1)*72
  for point=0,9 do
   local angle=-math.pi/2+point*math.pi/5;local radius=point%2==0 and 23 or 10
   vertices[#vertices+1]=x+math.cos(angle)*radius;vertices[#vertices+1]=169+math.sin(angle)*radius
  end
  W.color(i<=count and T.mustard or T.blush);love.graphics.polygon('fill',vertices)
  W.color(T.maroon);love.graphics.setLineWidth(1);love.graphics.polygon('line',vertices)
 end
end
local function metrics(r)
 local rows={{'Sales',r.retailRevenue},{'Service fees',r.serviceFees},{'Tips',r.tips},{'Profit',r.profit},
  {'Drawer cash',r.cash},{'Wallet balance',r.wallet},{'Cost of goods',r.costOfGoods},{'Losses',r.losses}}
 for i,row in ipairs(rows) do
  local column=i>4 and 1 or 0;local index=(i-1)%4;local x=54+column*610;local y=265+index*44
  O.line({x,y+34,x+551,y+34},T.blush,.8)
  W.text(row[1],x,y,19,T.ink,300)
  W.text(F.money(row[2]),x+305,y,19,T.maroon,245,'right')
 end
end
function V.draw(a)
 Paper.desk();H.header(a,'Shutters down','A quiet moment to count the day.')
 local r,err=E.summary(a.state)
 if not r then W.text(tostring(err),54,150,24,T.maroon,1160);return end
 Paper.sheet(32,126,1216,479)
 W.text('Day '..r.day..' complete',54,143,30,T.maroon)
 stars(r.stars)
 W.text('Sales + fees: '..F.money(r.earned)..' / '..F.money(r.goal),54,204,21,T.ink,750)
 W.text(({'Survived','Goal reached','Goal + no mistakes'})[r.stars],861,204,17,T.maroon,351,'right')
 metrics(r)
 W.text('Suki '..r.suki..' / 100  •  Mistakes '..r.mistakes,54,456,22,T.maroon,1155)
 W.text('Served '..r.served..'  •  Neighbors left '..r.timedOut,54,499,20,T.ink,1155)
 if r.nextWarning then
  W.panel(50,544,1174,47,T.blush)
  W.text('Tomorrow: '..r.nextWarning,64,555,16,T.maroon,1146)
 else W.text('A new morning awaits. Restock before opening.',54,553,18,T.ink,1155) end
 W.button('Next morning >',867,626,312,56,function() a:nextMorning() end,T.mustard)
 W.button('Save shop',101,632,175,48,function() a:save() end,T.paper,a:saveDisabledReason())
end
return V
