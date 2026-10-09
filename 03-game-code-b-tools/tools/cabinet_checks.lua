-- Rendered cabinet input checks using isolated real-domain smoke fixtures.
local L=require('src.ui.layout');local C=require('src.ui.cabinet_layout')
local W=require('src.ui.widgets');local Cash=require('src.systems.cash')
local Checks={}
local function click(a,x,y) a:mousepressed(L.x+x*L.scale,L.y+y*L.scale,1) end
local function release(a,x,y) a:mousereleased(L.x+x*L.scale,L.y+y*L.scale,1) end
function Checks.run(a,fixture)
 fixture('shelves');local pid=a.state.queue[1].lines[1].productId;local r=C.product(pid)
 local x,y=r.x+r.w/2,r.y+r.h/2;local balance=Cash.total(a.state)
 a:draw();click(a,x,y);assert(a.cabinetDrag,'Rendered cubby starts a pick preview')
 release(a,x,y);assert(a:quote().lines[1].productId==pid and Cash.total(a.state)==balance,'Rendered click stages requested goods without cash mutation')
 fixture('shelves');a:draw();click(a,x,y);a:mousemoved(L.x+710*L.scale,L.y+630*L.scale);release(a,710,630)
 assert(#a:quote().lines==0,'Wrong drop cannot reserve goods')
 fixture('shelves');a:draw();click(a,x,y);local b=C.basket
 a:mousemoved(L.x+(b.x+25)*L.scale,L.y+(b.y+25)*L.scale);a:draw();release(a,b.x+25,b.y+25)
 assert(#a:quote().lines==1,'Rendered basket drop picks once')
 release(a,b.x+25,b.y+25);assert(#a:quote().lines==1)
 fixture('shelves');a:draw();click(a,x,y);a:update(require('data.tuning').ui.cabinetHoldSeconds+.01)
 assert(#a:quote().lines==1 and not a.cabinetDrag,'Rendered hold picks once')
 fixture('shelves');local candy=C.product('candy');a.previewPointer={candy.x+20,candy.y+20};a:draw()
 assert(a.cabinetHover and a.cabinetHover.id=='candy')
 a:update(.399);a:draw();assert(a.uiClock<.4)
 a:update(.002);a:draw();assert(require('src.ui.cabinet_model').hover(a,'candy',a.uiClock),'Rendered dwell reaches 400ms')
 fixture('shelves');a:draw();click(a,x,y);a:keypressed('escape');a:update(1);release(a,x,y)
 assert(not a.cabinetDrag and #a:quote().lines==0,'Pause cancels preview without stock mutation')
 fixture('counter');a:draw()
 print('CABINET UI CHECK PASS click, hold, drag/drop, wrong drop, dwell and pause')
end
return Checks
