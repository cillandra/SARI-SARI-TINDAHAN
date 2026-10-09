return function()
 assert(love.filesystem.getInfo('src/ui/sukli_layout.lua'),'Sukli must own its slot geometry')
 local L=require('src.ui.sukli_layout');local Model=require('src.ui.sukli_model')
 local App=require('src.app');local Save=require('src.persistence.save');local Cash=require('src.systems.cash');local Inventory=require('src.systems.inventory')
 local expected={2000,5000,10000,50000,100000,100,500,1000}
 assert(#L.bills==5 and #L.coins==3)
 local rects={}
 for i,d in ipairs(expected) do
  local r=assert(L.slots[d]);assert(r.w>=44 and r.h>=44 and r.x>=0 and r.y>=120 and r.x+r.w<=1280 and r.y+r.h<=720)
  for _,other in ipairs(rects) do assert(not (r.x<other.x+other.w and r.x+r.w>other.x and r.y<other.y+other.h and r.y+r.h>other.y)) end
  rects[#rects+1]=r
 end
 local function fixture()
  local a=App.new(Save.new(require('tests.support.memory_disk').new(),'sukli'))
  a:newRun();assert(a:command('openDay'))
  a.state.queue={{id='sukli-test',patience=120,total=300,lines={{productId='candy',quantity=3,amount=300}},tender={[2000]=1}}}
  a:pick('candy');a:receive();return a
 end
 local a=fixture();local cash=Cash.total(a.state);local m=Model.model(a)
 assert(m.receipt.total==300 and m.receipt.tender==2000 and m.selected==0)
 local fields=0;for key in pairs(m.receipt) do assert(key=='total' or key=='tender');fields=fields+1 end;assert(fields==2,'Receipt exposes no computed change')
 a:changePiece(100);m=Model.model(a);assert(m.selected==100 and m.counts[100]==Cash.available(a.state,a:quote().tender)[100]-1 and Cash.total(a.state)==cash)
 a:undoChange();assert(Model.model(a).selected==0 and Cash.total(a.state)==cash)
 a:commit();assert(Cash.total(a.state)==cash and a.state.retail,'Incorrect change cannot commit')
 a:cancel();assert(Cash.total(a.state)==cash and not a.state.retail and next(a.state.reservations)==nil)
 -- M2 sale gate: piece goods, weigh and repack all use existing commands.
 a=fixture();a:cancel();a.state.queue={{id='m2-sale',patience=120,total=13800,lines={{productId='candy',quantity=3,amount=300},{productId='rice_regular',measured=true,quantity=1000,amount=5500},{productId='sugar',measured=true,quantity=1000,amount=8000}},tender={[10000]=2}}}
 local initial=Cash.total(a.state);local stock={};for _,pid in ipairs({'candy','rice_regular','sugar'}) do stock[pid]=Inventory.available(a.state,pid) end
 a:pick('candy');a:pick('candy');assert(#a:quote().lines==1)
 for _,pid in ipairs({'rice_regular','sugar'}) do a:pick(pid);a:adjust(1000);assert(a:confirmTimbangan());assert(a.view=='counter') end
 a:receive();local q=a:quote();assert(q.total==13800)
 local change=assert(Cash.plan(a.state,q.tenderAmount-q.total,q.tender))
 for d,n in pairs(change) do for _=1,n do a:changePiece(d) end end
 a:commit();local served=a.state.serviceOutcomes.served
 local record=assert(a.state.completedReferences['m2-sale']);local tip=record.tip or 0
 assert(tip%100==0 and (tip==0 or tip>=500 and tip<=1000),'Tip must be zero or a whole-peso reward from P5 to P10')
 assert(Cash.total(a.state)==initial+13800+tip and served==1)
 assert((a.state.ledger.tips or 0)==tip,'Tips remain separate from retail revenue')
 assert(Inventory.available(a.state,'candy')==stock.candy-3 and Inventory.available(a.state,'rice_regular')==stock.rice_regular-1000 and Inventory.available(a.state,'sugar')==stock.sugar-1000)
 a:commit();assert(Cash.total(a.state)==initial+13800+tip and a.state.serviceOutcomes.served==served and (a.state.ledger.tips or 0)==tip)
 for _,view in ipairs({'counter','shelves','drawer','timbangan','scale','repack'}) do
  a=fixture();local before=Cash.total(a.state);a:go(view);a.state.queue[1].patience=.1;a:update(.2)
  assert(not a.state.retail and next(a.state.reservations)==nil and Cash.total(a.state)==before,'Timeout must release staged sale in '..view)
 end
end
