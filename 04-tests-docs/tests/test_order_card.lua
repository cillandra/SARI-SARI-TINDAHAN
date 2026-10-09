return function()
 local Card=require('src.ui.order_card')
 local State=require('src.model.state');local s=State.new(1)
 local empty=Card.model(s)
 assert(empty.title=='ORDER' and empty.empty and empty.lines[1]=='Wala pang order.')
 local c={id='fixture',patience=60,total=1200,lines={{productId='candy',quantity=2},{productId='sardines',quantity=1},{productId='rice_regular',amount=2000,measured=true}}}
 s.queue={c};local m=Card.model(s)
 assert(m.title=='ORDER' and #m.lines==3 and m.queue==1 and m.patience==.5)
 local function overlaps(a,b) return a.x<b.x+b.w and a.x+a.w>b.x and a.y<b.y+b.h and a.y+a.h>b.y end
 assert(Card.compact.w<=300 and Card.compact.h<=132)
 assert(Card.expanded.y>=535,'Expanded ticket must stay below prop labels')
 local opening={x=330,y=100,w=570,h=370}
 for _,rect in ipairs({Card.compact,Card.expanded}) do
  assert(rect.x>=0 and rect.y>=85 and rect.x+rect.w<=1280 and rect.y+rect.h<=720)
  assert(not overlaps(rect,opening),'Order card must not cover the window opening')
  for _,prop in ipairs(require('src.ui.counter_layout').list()) do assert(not overlaps(rect,prop),'Order card must not cover props') end
 end
 c.lines[4]={productId='sugar',quantity=250,amount=2000,measured=true,requestMode='quantity'}
 c.initialPatience=30;c.patience=30
 local four=Card.model(s);assert(#four.lines==4 and four.patience==1,'Four-line ticket and full capped patience must display')
 local snapshot=State.clone(s);Card.model(s)
 assert(s.queue[1].patience==snapshot.queue[1].patience and s.queue[1].total==snapshot.queue[1].total,'Order display must not mutate the sale')
 local Hud=require('src.ui.draw.hud');local W=require('src.ui.widgets')
 local positions={};local panel,text=W.panel,W.text
 W.panel=function() end
 W.text=function(label,x,y) positions[#positions+1]={label=label,y=y} end
 local drawn,why=pcall(require('src.views.helpers').request,{state=s},819,115,429)
 W.panel,W.text=panel,text
 assert(drawn,why)
 assert(positions[#positions].y-positions[#positions-1].y>=22,'Fourth request must not overlap patience text')
 local a={view='counter',ticketOpen=true,ticketHover=false,orderCardHover=true}
 W.mx=Card.expanded.x+100;W.my=Card.expanded.y+100
 Hud.toggleTicket(a)
 assert(not a.ticketOpen and not a.orderCardHover,'Explicit Close must clear hover expansion')
 assert(type(Card.hover)=='function' and not Card.hover(a),'Close must stay collapsed until pointer leaves')
 W.mx=-1;W.my=-1;assert(not Card.hover(a))
 W.mx=Card.compact.x+20;W.my=Card.compact.y+20;assert(Card.hover(a),'Hover expansion resumes after pointer leaves')
 W.mx=-1;W.my=-1
 assert(type(Card.fitLine)=='function','Compact summary needs a bounded single-line formatter')
 local fitted=Card.fitLine('P20.00 of Luntian Regular Rice',120,function(text) return #text*10 end)
 assert(#fitted*10<=120 and fitted:sub(-3)=='...')
 assert(Card.fitLine('Rice',120,function(text) return #text*10 end)=='Rice')
end
