-- Rendered shared hold/release/reset checks in isolated smoke fixtures.
local L=require('src.ui.layout')
local W=require('src.ui.widgets')
local M=require('src.ui.timbangan_model')
local C={}
local function click(a,x,y) a:mousepressed(L.x+x*L.scale,L.y+y*L.scale,1) end
function C.run(a,fixture)
 for _,scene in ipairs({'timbangan-weigh','timbangan-repack','timbangan-oil'}) do
  fixture(scene);local m=M.model(a);a:adjust(-m.actual);a:draw()
  click(a,200,587);assert(a.pouring,'Every mode shares hold button')
  a:update(.1);local after=M.model(a).actual;assert(after>0,'Held fill adds integer stock units')
  a:mousereleased(0,0,1);a:update(.05);assert(not a.pouring and M.model(a).actual==after,'Release outside stops all modes')
  a:draw();click(a,512,587);assert(M.model(a).actual==0 and not a.pouring,'Rendered Ulitin resets opened fill')
 end
 fixture('timbangan-oil');a:adjust(-M.model(a).actual);a:draw();click(a,1110,190)
 assert(a.pouring and a.timbanganMode=='pour','Holding oil bin starts shared pour')
 a:update(3);assert(not a.pouring and M.model(a).line.spillLocked,'Oil overshoot stops hold and locks once')
 local loss=a.state.ledger.spoilage;a:update(.1);assert(a.state.ledger.spoilage==loss,'No repeated spill after automatic stop')
 a:draw();click(a,512,587);assert(not M.model(a).line.spillLocked,'Rendered Ulitin unlocks spill')
 fixture('timbangan-repack');a:draw();click(a,200,587);a:pause();assert(not a.pouring and a.pourElapsed==0,'Pause resets acceleration')
 a:pause();a:draw();click(a,200,587);a.ticketOpen=true;a:update(.01);assert(not a.pouring,'Ticket stops held tool');a.ticketOpen=false
 fixture('timbangan-repack');a:draw();click(a,180,190);assert(a.portionSwitch,'Open portion requires dialog')
 local qty=M.model(a).actual;a:draw();assert(#W.items==2,'Only modal actions exposed')
 click(a,200,587);assert(M.model(a).actual==qty,'Modal blocks hold')
 click(a,492,487);assert(not a.portionSwitch,'Continue retains portion')
 fixture('timbangan-oil');a:draw();click(a,1030,666)
 assert(a.view=='counter' and M.line(a,'cooking_oil').confirmed,'Rendered oil confirmation returns')
 fixture('timbangan-prepack');a.packQuantity=500;a:draw();click(a,1030,666)
 assert(a.view=='timbangan' and a.packQuantity==0,'Preparation sealing remains exact')
 fixture('peso-prepack');a.packQuantity=0;a:draw();click(a,700,300)
 assert(a.packSize==250 and a.packChoiceMode=='peso','Rendered P20 prep choice resolves sugar target')
 a:draw();click(a,200,587);a:update(.1);a:mousereleased(0,0,1)
 a:draw();click(a,507,300);assert(a.packSize==250,'Opened prep blocks P10 target change')
 a:resetPour();a:draw();click(a,507,300);assert(a.packSize==125,'P10 changes empty prep target')
 fixture('peso-repack');a:draw();local total=a:quote().total;local target=M.model(a).target
 click(a,507,300);assert(a:quote().total==total and M.model(a).target==target and a.packSize==250,'Too small peso choice preserves service quote')
 a:draw();click(a,313,300);assert(a.packSize==500 and a:quote().total==2000 and M.model(a).target==250,'Halfkg capacity keeps P20 quote')
 fixture('peso-oil');a:draw();click(a,700,300);assert(a.packSize==200 and M.model(a).target==200,'Rendered P20 bottle fits its request')
 print('PESO UI CHECK PASS rendered P10/P20 choices, open prep guard and immutable service quote')
 fixture('counter');a:draw()
 print('TIMBANGAN UI CHECK PASS shared three-mode hold, release outside, bin hold, Ulitin, spill lock, pause/ticket/modal and confirm')
end
return C
