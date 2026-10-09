-- Untimed preparation renders backend quotes and forwards commands.
local W=require('src.ui.widgets')
local T=require('src.ui.theme')
local F=require('src.ui.format')
local A=require('src.ui.art')
local H=require('src.views.helpers')
local P=require('data.products')
local I=require('src.systems.inventory')
local Paper=require('src.ui.draw.paper')
local Days=require('src.systems.days')
local Restock=require('src.systems.restock')
local V={}
local function start(a)
 local card=Days.start_card(a.state)
 Paper.sheet(27,126,1221,123)
 W.text('Day '..card.day,44,136,27,T.maroon)
 W.text(card.customers..' customers  •  Goal '..F.money(card.goal),600,142,20,T.maroon,628,'right')
 W.text(card.intro,44,175,18,T.ink,1160)
 W.text('Tip: '..card.tip,44,205,15,T.ink,1160)
 if card.nextWarning then W.text('Tomorrow: '..card.nextWarning,44,230,12,T.maroon,1160) end
 return card
end
local function products(a)
 local names={'Staples','Canned','Snacks','Drinks','Household','Essentials'}
 for section=1,6 do
  W.button(names[section],32+(section-1)*204,255,190,46,function() a.prepSection=section;a.selected=nil end,a.prepSection==section and T.mustard or T.paper)
 end
 for _,p in ipairs(P.list) do if p.cabinet.section==a.prepSection then
  local n=p.cabinet.slot-1;local x=32+(n%4)*181;local y=314+math.floor(n/4)*153
  Paper.sheet(x,y,165,139)
  if a.selected==p.id then W.panel(x+3,y+3,159,133,T.sage) end
  A.product(p,x+45,y+5,70)
  W.text(p.name,x+6,y+77,12,T.ink,153,'center')
  W.text(I.available(a.state,p.id)..' '..p.stockUnit,x+5,y+117,13,T.maroon,155,'center')
  W.hit(x,y,165,139,function() a.selected=p.id end)
 end end
end
local function selection(a)
 Paper.sheet(780,314,468,292)
 if not a.selected then
  W.text('Choose a product',802,333,25,T.maroon)
  W.text('Purchases use drawer cash.\nRestock before opening the store.\nExchange bills for barya below.',802,391,19,T.ink,424)
  return
 end
 local p=P.byId[a.selected];local quote,err=Restock.product_bundle(a.state,p.id)
 W.text(p.name,802,333,21,T.maroon,424)
 W.text('Shelf price '..F.money(a.state.prices[p.id])..' / '..p.priceQuantity..' '..p.saleUnit,802,375,16,T.ink,424)
 W.button('- ₱1',803,416,112,48,function() a:command('stepPrice',p.id,-100) end)
 W.button('+ ₱1',926,416,112,48,function() a:command('stepPrice',p.id,100) end)
 W.text(quote and 'Supplier: '..quote.quantity..' '..p.stockUnit..' for '..F.money(quote.cost) or tostring(err),802,476,16,T.ink,424)
 W.button('Buy bundle',803,525,204,51,function() if quote then a:restock(p.id,quote.quantity) end end,T.mustard,a.pendingCheckpoint and 'Use Save shop to retry the checkpoint.' or not quote and err or nil)
 if p.timbangan then
  W.button(p.saleUnit=='ml' and 'Prepare bottles' or 'Prepare portions',1018,525,209,51,function()
   a:preparePortion(p.id)
  end,T.mint,a.pendingCheckpoint and 'Use Save shop to retry the checkpoint.' or nil)
 end
end
function V.draw(a)
 Paper.desk();H.header(a,'','');local card=start(a)
 products(a);selection(a)
 local bundle=Restock.bundle(a.state)
 W.button('Barya • '..F.money(bundle.cost),360,630,284,56,function() if bundle.enabled then a:exchangeBarya() end end,card.barya_notice and T.mustard or T.mint,a.pendingCheckpoint and 'Use Save shop to retry the checkpoint.' or bundle.reason)
 W.text('Exchange equal-value bills for coins',668,638,13,T.ink,245)
 W.button('Open store >',947,630,301,56,function() a:openStore() end,T.mustard,a.pendingCheckpoint and 'Use Save shop to retry the checkpoint.' or nil)
 W.button('Save shop',32,632,160,48,function() a:save() end,T.paper,a:saveDisabledReason())
 W.button('Menu',204,632,125,48,function() a:go('menu') end)
end
return V
