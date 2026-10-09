-- Five-bin measuring window. Presentation only; actions delegate to the app coordinator.
local W=require('src.ui.widgets')
local T=require('src.ui.theme')
local H=require('src.views.helpers')
local M=require('src.ui.timbangan_model')
local Tuning=require('data.tuning')
local Inventory=require('src.systems.inventory')
local O=require('src.ui.draw.outline')
local Materials=require('src.ui.draw.materials')
local Patterns=require('src.ui.draw.patterns')
local Grain=require('src.ui.draw.grain')
local Station=require('src.ui.draw.station')
local Shapes=require('src.ui.draw.shapes')
local Heaps=require('src.ui.draw.heaps')
local V={}
local function choiceBar(a,m)
 for slot,p in ipairs(M.bins) do
  local x=32+(slot-1)*246;local oil=p.saleUnit=='ml'
  O.rect(x,148,234,110,oil and T.mustard or T.steel,8)
  O.rect(x+7,157,70,91,T.bininner,5)
  if oil then Shapes.bottle(x+17,169,49,65,T.mustard) else Heaps.draw(p,x+12,171,59,69) end
  local ink=oil and T.ink or T.paper
  W.text(p.timbangan.label,x+86,158,19,ink,124)
  local display_mode=m.product.id==p.id and m.mode or p.timbangan.mode
  W.text(display_mode=='weigh' and 'Weigh' or oil and 'Pour' or 'Bag & seal',x+86,190,14,ink,124)
  local stock=Inventory.available(a.state,p.id)
  local ratio=math.min(1,stock/(Tuning.startingStock[p.id] or p.portionSizes[#p.portionSizes]))
  O.rect(x+217,161,10,80,T.bininner,3)
  if ratio>0 then O.rect(x+219,239-ratio*76,6,ratio*76,T.sage,2,.5) end
  W.text(stock..' '..p.stockUnit,x+86,221,13,ink,122)
  if m.product.id==p.id then
   W.color(T.maroon);love.graphics.setLineWidth(3);love.graphics.rectangle('line',x+2,150,230,106,8,8)
  end
  W.hit(x,148,234,110,function() if a:selectTimbanganBin(p.id) then a:startPour() end end)
 end
end
local function targetCard(m)
 O.rect(833,278,415,173,T.paper,8)
 W.text('Gusto: '..m.requestLabel..m.target..' '..m.product.saleUnit,851,290,23/(W.textScale or 1),T.maroon,379)
 W.text('Actual: '..m.actual..' '..m.product.saleUnit,851,326,21,T.ink,379)
 W.text(m.prep and 'Seal at the selected bag size.' or 'Confirm range: '..m.lower..'–'..m.upper..' '..m.product.saleUnit,851,361,16,T.ink,379)
 local range=math.max(1,m.target*2)
 O.rect(851,398,374,12,T.blush,3)
 local start=m.lower/range*374
 local band=math.max(6,(m.upper-m.lower)/range*374)
 O.rect(851+start,398,band,12,T.sage,2,.5)
 local marker=851+math.min(1,m.actual/range)*374
 O.line({marker,393,marker,416},T.maroon,2)
 W.text(m.line and m.line.confirmed and 'Sealed on the counter.' or m.line and m.line.spillLocked and 'Natapon! Pindutin ang Ulitin.' or m.reason and 'Adjust the portion before sealing.' or 'Ready to seal.',851,426,16,T.maroon,379)
end
local function prepared(a,m)
 O.rect(833,524,415,99,T.paper,8)
 W.text(m.prep and 'Handa na' or 'On this order',851,534,21,T.maroon,379)
 if m.prep then
  W.text(m.ready..' '..m.product.saleUnit..' sealed • original expiry kept',851,568,17,T.ink,379)
  local last
  for _,b in ipairs(a.state.inventory[m.product.id] or {}) do if b.prepared and b.expiresDay>a.state.day then last=b end end
  if last then W.text('Latest '..last.quantity..' '..m.product.saleUnit..' • expires Day '..last.expiresDay,851,594,16,T.ink,379) end
 else
  if m.bagCount>1 then W.text(m.bagCount..(m.mode=='pour' and ' bottles • capacity ' or ' bags • capacity ')..m.bagSize..' '..m.product.saleUnit,851,597,16,T.maroon,379) end
  W.text(m.line and (m.line.confirmed and 'Portion sealed. Return to the counter.' or (m.bagCount>1 and 'Open portion stays reserved.' or 'Open portion stays reserved when you leave.')) or 'This bin is not requested by your neighbor.',851,568,17,T.ink,379)
 end
end
function V.draw(a)
 local m=M.model(a)
 Patterns.floor(0,135,1280,585,'cement')
 choiceBar(a,m)
 for i,option in ipairs(m.choices) do
  local chosen=a.packChoiceMode and a.packChoiceMode==option.requestMode and a.packChoiceValue==option.requestValue
   or not a.packChoiceMode and option.requestMode=='quantity'
   and (a.packSize or Tuning.mvp.measuredQuantity)==option.quantity
  W.button(option.label,32+(i-1)*194,278,182,48,function()
   a:choosePackOption(option.requestMode,option.requestValue)
  end,chosen and T.mustard or T.paper)
 end
 Materials.wood(32,334,776,290,T.wood);Grain.draw(32,334,776,290,.24)
 W.text(m.mode=='weigh' and (m.product.timbangan.label:upper()..' • WEIGH') or m.mode=='pour' and 'MANTIKA • POUR' or 'REPACK • BAG & SEAL',52,343,18,T.maroon,360)
 if m.mode=='weigh' then
  Station.sack(79,375,158,168,m.product.timbangan.label:upper())
  W.hit(79,375,158,168,function() a:startPour() end)
  love.graphics.push();love.graphics.translate(0,27);Station.scale(m.actual,m.target,m.product.saleUnit,a.uiClock,a.state.settings.reducedMotion);love.graphics.pop()
  Station.pack(698,406,61,93,0,1,'g',false,false)

 else
  if m.mode=='pour' then Shapes.bottle(115,384,78,137,T.mustard) else Heaps.draw(m.product,78,380,161,150) end
  Station.dashed(319,373,434,165)
  if m.bagCount>1 then Shapes.sack(680,412,38,50,T.paper);W.text('x'..m.bagCount,679,472,20,T.maroon,62) end
  Station.pack(514,380,112,138,m.actual,m.target,m.product.saleUnit,m.mode=='pour',a.pouring)
  Shapes.scoop(343,410,105,43,T.steel)
  W.hit(78,380,161,150,function() a:startPour() end)


 end
 require('src.ui.pour_meter').draw(m,772,380,22,151)
 W.button('Hold to fill',52,563,370,48,function() a:startPour() end,T.sage)
 W.button('Ulitin',448,563,173,48,function() a:resetPour() end,T.paper)
 targetCard(m);prepared(a,m)
 W.text('Hawakan ang bin. Bitawan sa berde.',841,477,16,T.maroon,398)
 O.rect(833,642,415,48,T.paper,10)
 W.button(m.mode=='weigh' and 'I-confirm ang timbang' or m.mode=='pour' and 'I-confirm ang bote' or 'I-confirm ang bag',833,642,415,48,function() a:confirmTimbangan() end,T.mustard,m.reason)
 W.button(m.prep and '< Preparation' or '< Counter',32,642,178,48,function() a:go(m.prep and 'preparation' or 'counter') end)
 if not m.prep then W.button('< Shelves',225,642,162,48,function() a:go('shelves') end) end
 H.header(a,'Timbangan',m.prep and 'Untimed • Select a bag, fill, seal, and keep the original expiry.' or '')
end
function V.dialog(a)
 local pending=a.portionSwitch
 W.items={};W.tooltip=nil;W.focus=math.max(1,math.min(2,W.focus))
 W.color({T.plum[1],T.plum[2],T.plum[3],.55});love.graphics.rectangle('fill',0,85,1280,635)
 O.rect(343,272,594,266,T.paper,12)
 W.text('Finish the open portion?',367,290,27,T.maroon,546)
 W.text(pending.prep and 'Continue filling this bag, or discard its unsealed fill before changing bins.' or 'Continue this portion, or discard only its opened contents. Other basket items and your customer stay.',367,338,math.min(23,21*(W.textScale or 1))/(W.textScale or 1),T.ink,546)
 Shapes.sack(383,440,24,21,T.sage)
 Shapes.sack(660,440,24,21,T.blush);O.line({660,440,684,461},T.maroon,1.5)
 W.button('Continue portion',367,467,254,48,function() a:resolveTimbanganSwitch('continue') end,T.sage)
 W.button('Discard portion',641,467,272,48,function() a:resolveTimbanganSwitch('discard') end,T.blush)
end
return V
