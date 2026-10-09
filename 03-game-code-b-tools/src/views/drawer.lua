-- Sukli presentation; all staged-cash actions delegate to the app.
local W=require('src.ui.widgets');local T=require('src.ui.theme');local F=require('src.ui.format')
local H=require('src.views.helpers');local O=require('src.ui.draw.outline');local Wood=require('src.ui.draw.materials')
local Money=require('src.ui.draw.money');local L=require('src.ui.sukli_layout');local Model=require('src.ui.sukli_model')
local V={}
local function slots(a,denoms,m)
 for _,d in ipairs(denoms) do
  local r=L.slots[d];O.rect(r.x,r.y,r.w,r.h,T.steel,5);O.rect(r.x+5,r.y+5,r.w-10,r.h-63,T.bininner,4)
  Money.piece(d,r.x+9,r.y+12,r.w-18,r.h-82)
  O.rect(r.x+5,r.y+r.h-53,r.w-10,48,T.paper,3)
  W.text('Have '..m.counts[d],r.x+7,r.y+r.h-50,16,T.ink,r.w-14,'center')
  W.text('Pick '..(a.change[d] or 0),r.x+7,r.y+r.h-28,16,T.maroon,r.w-14,'center')
  W.hit(r.x,r.y,r.w,r.h,function() a:changePiece(d) end)
 end
end
function V.draw(a)
 local m=Model.model(a);local r=L.receipt;O.rect(r.x,r.y,r.w,r.h,T.paper,7)
 W.text('Receipt',r.x+16,r.y+19,25,T.maroon,r.w-32,'center')
 O.line({r.x+16,r.y+64,r.x+r.w-16,r.y+64},T.darkwood,1)
 W.text('Total',r.x+18,r.y+103,22,T.ink);W.text(F.money(m.receipt.total),r.x+18,r.y+139,27,T.maroon,r.w-36)
 W.text('Tender',r.x+18,r.y+216,22,T.ink);W.text(F.money(m.receipt.tender),r.x+18,r.y+252,27,T.maroon,r.w-36)
 local dr=L.drawer;Wood.wood(dr.x,dr.y,dr.w,dr.h,T.wood)
 slots(a,L.bills,m);slots(a,L.coins,m)
 if m.payout>0 then O.rect(999,137,249,79,T.paper,7);W.text('cash_out payout',1011,148,17,T.maroon,225,'center');W.text(F.money(m.payout),1011,176,23,T.ink,225,'center') end
 local tray=L.tray;O.rect(tray.x,tray.y,tray.w,tray.h,T.wood,8)
 O.rect(tray.x+8,tray.y+8,tray.w-16,tray.h-16,T.paper,6)
 W.text('Napili: '..F.money(m.selected),tray.x+14,tray.y+15,22,m.correct and T.teal or T.maroon,tray.w-28,'center')
 local index=0
 for _,denoms in ipairs({L.bills,L.coins}) do for _,d in ipairs(denoms) do
  local n=a.change[d] or 0
  if n>0 then
   local x=tray.x+17+(index%2)*110;local y=tray.y+64+math.floor(index/2)*48
   W.text(F.money(d)..' x '..n,x,y,14,T.ink,104,'center');index=index+1
  end
 end end
 local c=L.controls
 W.button('Receive tender',c.receive.x,c.receive.y,c.receive.w,c.receive.h,function() a:receive() end,T.blush)
 W.button('Undo last piece',c.undo.x,c.undo.y,c.undo.w,c.undo.h,function() a:undoChange() end)
 W.button('Confirm sale',c.confirm.x,c.confirm.y,c.confirm.w,c.confirm.h,function() a:commit() end,T.mustard)
 W.button('< Counter',c.back.x,c.back.y,c.back.w,c.back.h,function() a:go('counter') end)
 W.button('Cancel sale',c.cancel.x,c.cancel.y,c.cancel.w,c.cancel.h,function() a:cancel() end,T.blush)
 W.text('Select actual pieces, then confirm.',430,654,18,T.ink,600)
 H.header(a,'Count the sukli','')
end
return V
