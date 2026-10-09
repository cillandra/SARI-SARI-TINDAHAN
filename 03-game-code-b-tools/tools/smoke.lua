-- Purpose: deterministic real-domain visual fixtures and project-local capture. API: new(app,args),update,afterDraw. Dependencies: domain/app/LÖVE; no assets.
local State=require('src.model.state'); local Cmd=require('src.commands'); local Customers=require('src.systems.customers'); local Cash=require('src.systems.cash'); local Smoke={}; Smoke.__index=Smoke
local sizes={{1024,768},{1280,720},{1920,1080},{2560,1440}}; local scenes={'menu','peso-repack','peso-oil','peso-prepack','peso-large-text','peso-ticket','pour-holding-weigh','pour-holding-repack','pour-holding-oil','pour-spilled','pour-spilled-large-text','timbangan-sugar-weigh','timbangan-oil','timbangan-oil-large-text','timbangan-green-lower','timbangan-green-upper','event-normal','event-rain','event-payday','event-fiesta','event-brownout','event-brownout-large-text','preparation-day2-large-text','preparation-endless','preparation-day8','preparation-large-text','report-goal','report-warning','report-large-text','preparation','counter','shelves','drawer','scale','repack','report','pause','ticket','recovery','lose','dusk','characters','large-order','shelves-hover','products','oil-repack','sugar-repack','prepack','pouring','desk-props','pause-toast','large-basket','counter-hover','counter-locked','pause-settings','pause-summary','pause-quit','counter-large-text','counter-empty','ticket-large-text','counter-queue','counter-fallback','timbangan-repack','timbangan-weigh','timbangan-flour','timbangan-salt','timbangan-discard','timbangan-prepack','timbangan-pouring','timbangan-large-text','timbangan-discard-large-text','timbangan-large-bags','timbangan-large-bags-large-text','cabinet-tooltip','cabinet-large-text','cabinet-drag','sukli-selected','sukli-large-text','sukli-retry','payment-tip','tindapay-cash-in','tindapay-cash-out','tindapay-payout','tindapay-counter','tindapay-large-text','tindapay-ticket','tindapay-scam-amount','tindapay-scam-reference','tindapay-scam-recipient','tindapay-scam-status','tindapay-scam-large-text','four-line-counter','four-line-measurement','four-line-ticket'}
local function command(s,name,...) local ok,err=Cmd.execute(s,name,...); assert(ok,err) end
-- Station captures use literal orders; daily RNG coverage belongs to generation tests.
local function service(day,kind)
 local s=State.new(1);s.day=day;command(s,'prepareDay');command(s,'openDay')
 if not kind then return s,true end
 local c=assert(s.queue[1])
 local function measured(lineType,pid,quantity,amount)
  return {type=lineType,productId=pid,measured=true,quantity=quantity,amount=amount,
   requestMode='quantity',requestValue=quantity}
 end
 local pid
 if kind=='four-line-counter' or kind=='four-line-measurement' or kind=='four-line-ticket' then
  pid='cooking_oil'
  c.lines={measured('pour',pid,100,1000),measured('weigh','rice_regular',500,2800),
   measured('repack','sugar',250,2000),{type='item',productId='candy',quantity=1,amount=100,measured=false,requestMode='quantity',requestValue=1}}
 elseif kind=='large-order' then
  c.lines={{type='item',productId='candy',quantity=1,amount=100,measured=false,
   requestMode='quantity',requestValue=1},measured('weigh','rice_regular',500,2800),measured('repack','sugar',250,2000)}
 elseif kind=='scale' then pid='rice_regular';c.lines={measured('weigh',pid,500,2800)}
 elseif kind=='oil-repack' then pid='cooking_oil';c.lines={measured('pour',pid,250,2500)}
 elseif kind=='sugar-repack' or kind=='repack' then pid='sugar';c.lines={measured('repack',pid,250,2000)}
 else error('Unknown station fixture: '..tostring(kind)) end
 c.total=0;for _,line in ipairs(c.lines) do c.total=c.total+line.amount end
 c.tender=nil;c.paymentRoll=nil
 return s,pid or true
end
local function fill(s) local c=Customers.current(s); command(s,'beginRetail',c.id); for requestIndex,r in ipairs(c.lines) do if r.type=='cash_in' or r.type=='cash_out' then command(s,'stageWallet',c.id,requestIndex,r.transfer) elseif r.measured then command(s,'targetPortion',c.id,r.productId,r.requestValue or r.quantity,r.requestMode or 'quantity'); local i=#s.retail.lines; command(s,'adjustPortion',c.id,i,s.retail.lines[i].targetQuantity); command(s,'confirmPortion',c.id,i) else command(s,'addRetail',c.id,r.productId,r.quantity) end end; c.tender=assert(Customers.payment(s)); command(s,'stageTender',c.id,c.tender); return c end
function Smoke.selectScenes(args)
 for i,value in ipairs(args or {}) do if value=='--smoke-scenes' then
  local names=assert(args[i+1],'Missing --smoke-scenes list')
  local available={};for _,scene in ipairs(scenes) do available[scene]=true end
  local selected,seen={},{}
  for scene in names:gmatch('[^,]+') do
   assert(available[scene] and not seen[scene],'Unknown or duplicate smoke scene: '..scene)
   selected[#selected+1]=scene;seen[scene]=true
  end
  assert(#selected>0,'Empty --smoke-scenes list')
  return selected
 end end
 return scenes
end
function Smoke.new(a,args) a.persistence=require('src.persistence.save').new(require('tests.support.memory_disk').new(),'smoke-checkpoint'); a.hasCheckpoint=false; local root=love.filesystem.getSource():gsub('\\','/'); if root:match('%.love$') then root=root:match('^(.*)/[^/]+$') end; local dir=root..'/docs/reviews/screens'; for i,value in ipairs(args or {}) do if value=='--smoke-dir' then dir=assert(args[i+1],'Missing --smoke-dir path'):gsub('\\','/') end end; assert(dir:sub(1,#root+1)==root..'/' and not dir:find('%.%.'),'Smoke directory must be inside the project'); return setmetatable({app=a,dir=dir,scenes=Smoke.selectScenes(args),run=tostring(os.time()),index=0,wait=0,busy=false},Smoke) end
local function timbanganFixture(a,scene)
 a:clearSale();a.packQuantity=0;a.packSize=nil;a.toastTime=0;a.uiClock=0
 a.previewPointer={-1,-1};a.previewDraw=nil;a.lastNavigationAt=nil
 if scene=='timbangan-large-bags' or scene=='timbangan-large-bags-large-text' then
  a.state=State.new(1);command(a.state,'prepareDay');command(a.state,'purchasePlanned','flour',2000);command(a.state,'stepPrice','flour',-5000);command(a.state,'openDay')
  a.state.queue={{id='large-flour',patience=120,total=2000,lines={{productId='flour',measured=true,quantity=2000,amount=2000}},tender={[2000]=1}}}
  a:pick('flour');a:adjust(1500);if scene=='timbangan-large-bags-large-text' then a.state.settings.textScale=1.3 end
 elseif scene=='timbangan-flour' or scene=='timbangan-salt' or scene=='timbangan-prepack' then
  a.state=State.new(1);command(a.state,'prepareDay')
  a.prepackProduct=scene=='timbangan-flour' and 'flour' or scene=='timbangan-salt' and 'salt' or 'sugar'
  if a.prepackProduct~='sugar' then command(a.state,'purchasePlanned',a.prepackProduct,1000) end
  a.timbanganMode='repack';a:go('timbangan');assert(a:choosePackSize(500));a.packQuantity=350
  if scene=='timbangan-prepack' then a.packQuantity=500;assert(a:confirmTimbangan());a.packQuantity=200;a.toastTime=0 end
 else
  local weigh=scene=='timbangan-weigh'
  local pid;a.state,pid=service(weigh and 3 or 4,weigh and 'scale' or 'sugar-repack')
  a:pick(pid);a:go('timbangan');a:adjust(150)
  if scene=='timbangan-discard' or scene=='timbangan-discard-large-text' then a:selectTimbanganBin('rice_regular') end
  if scene=='timbangan-pouring' then a.pouring=true end
  if scene=='timbangan-large-text' or scene=='timbangan-discard-large-text' then a.state.settings.textScale=1.3 end
 end
end
local function walletFixture(a,scene,seed)
 a:clearSale();a.packQuantity=0;a.toastTime=0;a.ticketOpen=false;a.ticketHover=false;a.orderCardHover=false;a.uiClock=0;a.lastNavigationAt=nil;a.previewPointer={-1,-1};a.previewDraw=nil
 a.state=State.new(seed or 1)
 if scene:match('^tindapay%-scam') then
  a.state.day=6;command(a.state,'prepareDay');command(a.state,'openDay')
  local c=a.state.queue[1];local request=require('src.systems.order').service(a.state,'cash_out',1)
  request.receipt=State.clone(request.transfer)
  local field=scene:match('scam%-(.+)$');if field=='large-text' then field='status';a.state.settings.textScale=1.3 end
  if field=='amount' then request.receipt.amount=request.principal+100
  elseif field=='reference' then request.receipt.reference=request.reference..':fake'
  elseif field=='recipient' then request.receipt.recipient=request.recipient..':other'
  else request.receipt.status='pending' end
  c.lines={request};c.total=request.amount;assert(a:openTindaPay());a.toastTime=0;return
 end
 a.state.day=2;command(a.state,'prepareDay');command(a.state,'openDay')
 local cashOut=scene=='tindapay-cash-out' or scene=='tindapay-payout'
 if cashOut then a.state.queue={};assert(Customers.spawn(a.state)) end
 local c=assert(Customers.current(a.state));assert(c.lines[1].type==(cashOut and 'cash_out' or 'cash_in'),'Day2 spotlight fixture must use actual generated service')
 if scene=='tindapay-counter' or scene=='tindapay-ticket' then a:go('counter');a.ticketOpen=scene=='tindapay-ticket'
 elseif scene=='tindapay-payout' then fill(a.state);a.saleId=c.id;a:go('drawer')
 else assert(a:openTindaPay());if scene=='tindapay-large-text' then a.state.settings.textScale=1.3 end end
 a.toastTime=0
end
function Smoke:checkWalletInput()
 local a=self.app;local L=require('src.ui.layout')
 local function click(x,y) a:mousepressed(L.x+x*L.scale,L.y+y*L.scale,1) end
 walletFixture(a,'tindapay-counter');a:draw()
 local phone=require('src.ui.counter_layout').get('phone');click(phone.x+phone.w/2,phone.y+phone.h/2)
 assert(a.view=='phone' and a.walletTab=='cash_in','Rendered Phone opens the matching cash_in tab')
 local before=Cash.total(a.state);local wallet=a.state.wallet.balance;a:draw();click(632,500)
 assert(a:quote().lines[1].type=='cash_in' and a:quote().lines[1].confirmed,'Rendered Verify stages cash_in')
 assert(Cash.total(a.state)==before and a.state.wallet.balance==wallet,'Verification must not move money')
 local exact=false
 for seed=1,200 do
  walletFixture(a,'tindapay-cash-out',seed);a:go('counter');a:draw();click(phone.x+phone.w/2,phone.y+phone.h/2)
  assert(a.view=='phone' and a.walletTab=='cash_out','Rendered Phone opens the matching cash_out tab')
  before=Cash.total(a.state);wallet=a.state.wallet.balance;a:draw();click(632,500)
  assert(a:quote().lines[1].type=='cash_out' and a:quote().lines[1].confirmed,'Rendered Verify stages cash_out')
  assert(Cash.total(a.state)==before and a.state.wallet.balance==wallet,'cash_out verification remains staged')
  local tender=assert(Customers.payment(a.state))
  if Cash.value(tender)==a:quote().total then exact=true;break end
 end
 assert(exact,'Seed search must provide a naturally exact cash_out fee payment')
 a:draw();click(640,592)
 assert(a.view=='drawer' and a:quote().tenderAmount==a:quote().total,'cash_out opens drawer even for exact fee tender')
 assert(Cash.total(a.state)==before and a.state.wallet.balance==wallet,'Receiving cash_out keeps balances staged')
 local payout=require('src.systems.tindapay').summary(a:quote()).payout
 assert(payout>0 and require('src.ui.sukli_model').model(a).payout==payout,'Drawer exposes cash_out payout')
 for _,field in ipairs({'amount','reference','recipient','status'}) do
  walletFixture(a,'tindapay-scam-'..field);before=Cash.total(a.state);wallet=a.state.wallet.balance
  a:draw();click(1040,500)
  assert(a.view=='counter' and not a.state.retail and #a.state.queue==0 and a.state.reputation==50 and Cash.total(a.state)==before and a.state.wallet.balance==wallet,'Rendered Reject safely dismisses '..field..' scam')
 end
 walletFixture(a,'tindapay-scam-status');before=Cash.total(a.state);local principal=a.state.queue[1].lines[1].principal
 a:draw();click(632,500)
 assert(a.view=='counter' and a.state.reputation==45 and Cash.total(a.state)==before-principal and a.state.ledger.scamLosses==principal,'Rendered accept publishes one scam loss')
 walletFixture(a,'tindapay-cash-out');before=Cash.total(a.state);wallet=a.state.wallet.balance
 a:draw();click(1040,500);click(1040,500)
 assert(a.view=='counter' and a.state.reputation==47 and Cash.total(a.state)==before and a.state.wallet.balance==wallet and a.state.serviceOutcomes.timedOut==1,'Rendered valid rejection penalizes/dismisses once')
 print('SERVICE UI CHECK PASS four scam-field rejections, accepted scam loss, valid rejection and repeated click')
 self.walletInputChecked=true
 print('TINDAPAY UI CHECK PASS rendered phone tabs, verification staging, exact-fee cash_out drawer and payout')
 walletFixture(a,'tindapay-counter')
end
local function presentationFixture(a,scene)
 a:clearSale();a.toastTime=0;a.uiClock=0;a.previewPointer={-1,-1};a.previewDraw=nil
 a.state=State.new(1);a.state.day=scene=='preparation-day2-large-text' and 2 or scene=='preparation-endless' and 11 or scene:match('^preparation') and 8 or 7
 command(a.state,'prepareDay');a.prepSection=1;a.selected='rice_regular'
 if scene:match('large%-text') then a.state.settings.textScale=1.3 end
 if scene:match('^preparation') then a:go('preparation');return end
 command(a.state,'openDay');a.state.queue={}
 a.state.ledger.retailRevenue=scene=='report-goal' and 150000 or 120000
 a.state.ledger.serviceFees=1000;a.state.ledger.tips=500;a.state.serviceOutcomes.served=10
 command(a.state,'closeDay');a:go('report')
end
local function eventFixture(a,scene)
 a:clearSale();a.toastTime=0;a.uiClock=0;a.ticketOpen=false;a.ticketHover=false
 a.lastNavigationAt=nil;a.previewPointer={-1,-1};a.previewDraw=nil
 local day=scene=='event-rain' and 7 or scene=='event-payday' and 9 or scene=='event-fiesta' and 10 or 11
 a.state=service(day)
 if scene=='event-normal' then a.state.dayProfile.event='payday'
 elseif scene:match('brownout') then a.state.dayProfile.event='brownout' end
 if scene:match('large%-text') then a.state.settings.textScale=1.3 end
 local E=require('src.systems.events')
 local wallet=require('src.ui.draw.hud').models(a.state)[4]
 assert(wallet.value~='Offline','Brownout does not disable TindaPay')
 local saved=assert(require('src.persistence.codec').encode(a.state))
 local loaded=assert(require('src.persistence.codec').decode(saved))
 local interval=loaded.time.spawnCountdown;local rng=loaded.rng.randomState
 require('src.systems.order').refresh(loaded)
 assert(loaded.dayProfile.event==a.state.dayProfile.event and loaded.time.spawnCountdown==interval and loaded.rng.randomState==rng,'Event service save/refresh preserves selected event/countdown/RNG')
 a:go('counter')
 print('EVENT SMOKE '..scene..' dim='..E.dim(a.state)..' wallet-online=true save-refresh=true')
end
local function measuredFixture(a,scene)
 a:clearSale();a.toastTime=0;a.uiClock=0;a.previewPointer={-1,-1};a.previewDraw=nil;a.lastNavigationAt=nil
 local oil=scene=='timbangan-oil' or scene=='timbangan-oil-large-text'
 a.state=service(oil and 5 or 3,oil and 'oil-repack' or 'scale')
 local pid=oil and 'cooking_oil' or scene=='timbangan-sugar-weigh' and 'sugar' or 'rice_regular'
 if scene=='timbangan-sugar-weigh' then a.state.queue[1].lines[1].productId=pid end
 a:pick(pid);assert(a:openTimbangan())
 local m=require('src.ui.timbangan_model').model(a)
 a:adjust((scene=='timbangan-green-lower' and m.lower or scene=='timbangan-green-upper' and m.upper or m.target)-m.actual)
 if scene=='timbangan-oil-large-text' then a.state.settings.textScale=1.3 end
end
local function pouringFixture(a,scene)
 a:clearSale();a.toastTime=0;a.uiClock=0;a.previewPointer={-1,-1};a.previewDraw=nil;a.lastNavigationAt=nil
 local weigh=scene=='pour-holding-weigh';local oil=scene:match('oil') or scene:match('spilled')
 a.state=service(weigh and 3 or oil and 5 or 4,weigh and 'scale' or oil and 'oil-repack' or 'sugar-repack')
 a:pick(weigh and 'rice_regular' or oil and 'cooking_oil' or 'sugar');a:startPour()
 a:update(scene:match('spilled') and 3 or 1)
 if scene=='pour-spilled-large-text' then a.state.settings.textScale=1.3 end
 if scene=='pour-spilled' then a.toastTime=0 end
 if scene:match('spilled') then assert(not a.pouring and require('src.ui.timbangan_model').model(a).line.spillLocked) end
end
local function pesoFixture(a,scene)
 a:clearSale();a.toastTime=0;a.uiClock=0;a.ticketOpen=false;a.ticketHover=false;a.orderCardHover=false
 a.previewPointer={-1,-1};a.previewDraw=nil;a.lastNavigationAt=nil;a.packQuantity=0
 a.state=State.new(1);a.state.day=5;command(a.state,'prepareDay')
 if scene=='peso-prepack' then
  a.prepackProduct='sugar';a.timbanganMode='repack';a:go('timbangan')
  assert(a:choosePackOption('peso',1000));a.packQuantity=75;return
 end
 command(a.state,'openDay');local c=a.state.queue[1]
 local oil=scene=='peso-oil';local pid=oil and 'cooking_oil' or 'sugar';local target=oil and 200 or 250
 c.lines={{type=oil and 'pour' or 'repack',productId=pid,quantity=target,amount=2000,
  measured=true,requestMode='peso',requestValue=2000}}
 c.total=2000;c.tender=nil;a:pick(pid);a:adjust(oil and 140 or 150)
 if scene=='peso-large-text' then a.state.settings.textScale=1.3 end
 if scene=='peso-ticket' then a:go('counter');a.ticketOpen=true end
end
function Smoke:fixture(scene) if scene:match('^peso%-') then pesoFixture(self.app,scene);return end; if scene:match('^pour%-') then pouringFixture(self.app,scene);return end; if scene=='timbangan-sugar-weigh' or scene=='timbangan-oil' or scene=='timbangan-oil-large-text' or scene=='timbangan-green-lower' or scene=='timbangan-green-upper' then measuredFixture(self.app,scene);return end; if scene:match('^event%-') then eventFixture(self.app,scene);return end; if scene=='preparation-day2-large-text' or scene=='preparation-endless' or scene=='preparation-day8' or scene=='preparation-large-text' or scene=='report-goal' or scene=='report-warning' or scene=='report-large-text' then presentationFixture(self.app,scene);return end; if scene:match('^tindapay%-') then walletFixture(self.app,scene);return end; if scene:match('^timbangan%-') then timbanganFixture(self.app,scene);return end; local extra=scene; if scene=='sukli-selected' or scene=='sukli-large-text' or scene=='sukli-retry' or scene=='payment-tip' then scene='drawer' end; if scene=='cabinet-tooltip' or scene=='cabinet-large-text' or scene=='cabinet-drag' then scene='shelves' end; if scene=='ticket-large-text' then scene='ticket' end; if scene=='counter-hover' or scene=='counter-locked' or scene=='counter-large-text' or scene=='counter-empty' or scene=='counter-queue' or scene=='counter-fallback' then scene='counter' elseif scene=='pause-settings' or scene=='pause-summary' or scene=='pause-quit' then scene='pause' end; local a=self.app; a:clearSale(); a.packQuantity=0; a.toastTime=0; a.ticketOpen=false; a.ticketHover=false; a.uiClock=0; a.lastNavigationAt=nil; a.previewPointer={-1,-1}; a.previewDraw=nil; a.state=State.new(1); command(a.state,'prepareDay'); a.prepSection=1; a.selected='rice_regular'; if scene=='lose' then a.state=service(1);a.state.reputation=8;a.state.queue[1].patience=.1;assert(require('src.systems.days').update(a.state,1));a:go('lose') elseif scene=='menu' then a.state=State.new(1); a:go('menu') elseif scene=='preparation' then a:go('preparation') elseif scene=='prepack' then a.prepackProduct='cooking_oil'; a.packQuantity=150; a:go('repack') elseif scene=='report' or scene=='recovery' then a.state=service(1); local c=fill(a.state); local change=assert(Cash.plan(a.state,assert(require('src.systems.retail').changeDue(a.state,c.id)),c.tender)); command(a.state,'commitRetail',c.id,change); command(a.state,'closeDay'); a:go(scene) else local kind=scene=='large-basket' and 'large-order' or (scene=='scale' or scene=='repack' or scene=='large-order' or scene=='oil-repack' or scene=='sugar-repack' or scene=='four-line-counter' or scene=='four-line-measurement' or scene=='four-line-ticket') and scene or scene=='pouring' and 'oil-repack' or nil; local pid; a.state,pid=service(kind and (kind:match('^four%-line') and 9 or kind=='scale' and 3 or kind=='large-order' and 5 or kind=='oil-repack' and 5 or 4) or 1,kind); if scene=='counter' or scene=='pause' or scene=='ticket' or scene=='dusk' or scene=='characters' or scene=='large-order' or scene=='four-line-counter' or scene=='four-line-ticket' or scene=='products' or scene=='desk-props' or scene=='pause-toast' then a:go('counter') elseif scene=='shelves' or scene=='shelves-hover' then command(a.state,'beginRetail',a.state.queue[1].id); a:go('shelves'); if scene=='shelves-hover' then local r=require('src.ui.cabinet_layout').product('candy');a.previewPointer={r.x+r.w/2,r.y+r.h/2};a.cabinetHover={id='candy',at=0};a.uiClock=.5 end elseif scene=='drawer' then local c=fill(a.state); a.saleId=c.id; a:go('drawer') elseif scene=='large-basket' then fill(a.state); a:go('shelves') elseif kind then local c=a.state.queue[1]; command(a.state,'beginRetail',c.id); a:pick(pid); command(a.state,'adjustPortion',c.id,1,math.min(150,a.state.retail.lines[1].targetQuantity)); a:go(kind=='scale' and 'scale' or 'repack'); a.pouring=scene=='pouring' end; if scene=='pause' or scene=='pause-toast' then if scene=='pause-toast' then fill(a.state) end; command(a.state,'setPaused',true); if scene=='pause-toast' then a:save() end elseif scene=='ticket' or scene=='four-line-ticket' then a.ticketOpen=true elseif scene=='dusk' then a.state.time.elapsed=require('data.tuning').dayDurationSeconds*.9; a.state.reputation=20; a.state.queue[1].patience=15 elseif scene=='characters' then a.previewDraw=require('tools.character_gallery').draw elseif scene=='products' then a.previewDraw=require('tools.product_gallery').draw elseif scene=='desk-props' then a.previewDraw=require('tools.desk_gallery').draw end end; if extra=='sukli-retry' then a:changePiece(100);a:commit() elseif extra=='payment-tip' then a.change=assert(Cash.plan(a.state,assert(require('src.systems.retail').changeDue(a.state,a.saleId)),a:quote().tender));a:commit() elseif extra=='sukli-selected' then a:changePiece(100);a:changePiece(500);a:changePiece(1000) elseif extra=='sukli-large-text' then a.state.settings.textScale=1.3;a:changePiece(100);a:changePiece(500);a:changePiece(1000) elseif extra=='cabinet-tooltip' then local r=require('src.ui.cabinet_layout').product('candy');a.previewPointer={r.x+r.w/2,r.y+r.h/2};a.cabinetHover={id='candy',at=0};a.uiClock=.5 elseif extra=='cabinet-large-text' then a.state.settings.textScale=1.3 elseif extra=='cabinet-drag' then local pid=a.state.queue[1].lines[1].productId;local r=require('src.ui.cabinet_layout').product(pid);a:beginCabinetPick(pid,r.x+r.w/2,r.y+r.h/2);a:moveCabinetPick(1160,661);a.previewPointer={1160,661} elseif extra=='counter-hover' or extra=='counter-locked' then local id=extra=='counter-hover' and 'cash_drawer' or 'phone'; local r=require('src.ui.counter_layout').get(id); a.previewPointer={r.x+r.w/2,r.y+r.h/2} elseif extra=='counter-large-text' or extra=='ticket-large-text' then a.state=service(5,'large-order');a.state.settings.textScale=1.3 elseif extra=='counter-empty' then a.state.queue={} elseif extra=='counter-queue' then for i=1,5 do Customers.spawn(a.state) end elseif extra=='counter-fallback' then a.state.queue[1].id=9 elseif extra=='pause-settings' then a.pausePanel='settings' elseif extra=='pause-summary' then a.pausePanel='summary' elseif extra=='pause-quit' then a.pausePanel='quit' end end
function Smoke:update() if self.busy then return end; if self.wait>0 then self.wait=self.wait-1; return end; self.index=self.index+1; if self.index>#sizes*#self.scenes then if self.globalSnapshot then require('tools.global_check').verify(self.globalSnapshot); print('GLOBAL CHECK PASS no new or reassigned _G keys') end; print('SMOKE COMPLETE '..(#sizes*#self.scenes)..' captures'); love.event.quit(0); return end; local size=sizes[math.floor((self.index-1)/#self.scenes)+1]; local scene=self.scenes[(self.index-1)%#self.scenes+1]; if not self.windowSize or self.windowSize[1]~=size[1] or self.windowSize[2]~=size[2] then assert(love.window.setMode(size[1],size[2],{resizable=true,highdpi=true,msaa=4,vsync=1,minwidth=960,minheight=540})); self.app:resize(size[1],size[2]); self.windowSize={size[1],size[2]} end; self:fixture(scene); self.scene=scene; self.path=self.dir..'/'..self.run..'-'..size[1]..'x'..size[2]..'-'..scene..'.png'; self.wait=3; self.busy=true; self.frames=0 end
function Smoke:checkInput()
 local a=self.app
 local W=require('src.ui.widgets')
 local L=require('src.ui.layout')
 local function click(x,y) a:mousepressed(L.x+x*L.scale,L.y+y*L.scale,1) end
 local Navigation=require('data.navigation')
 local current=Customers.current(a.state)
 local r=require('src.ui.counter_layout').customer().rect
 click(r.x+r.w/2,r.y+r.h/2)
 assert(a.state.retail and a.state.retail.id==current.id,'Rendered customer must take the current order')
 local sale=a.state.retail
 a:draw(); click(r.x+r.w/2,r.y+r.h/2)
 assert(a.state.retail==sale,'Repeated customer clicks retain the same sale')
 a:draw()
 local drawer=require('src.ui.counter_layout').get('cash_drawer')
 click(drawer.x+drawer.w/2,drawer.y+drawer.h/2)
 assert(a.view=='sukli','Rendered drawer prop must navigate through shared data')
 a:go('counter'); a:draw()
 local phone=require('src.ui.counter_layout').get('phone')
 click(phone.x+phone.w/2,phone.y+phone.h/2)
 assert(a.view=='counter' and #a.toast>0,'Locked phone must explain without switching')
 a:draw()
 click(1119,40)
 assert(a.ticketOpen and #W.items==0,'Ticket must immediately invalidate underlying hitboxes')
 click(1119,40)
 assert(a.ticketOpen,'Repeated click before draw cannot use a stale ticket hitbox')
 a:draw()
 a:keypressed('2')
 assert(a.view=='counter' and a.ticketOpen,'Station shortcut cannot bypass a modal ticket')
 a:keypressed('escape')
 assert(not a.ticketOpen and #W.items==0,'Ticket Escape clears modal input')
 a:draw()
 click(1198,40)
 assert(a.state.paused and #W.items==0,'Pause must immediately invalidate underlying hitboxes')
 a:draw()
 a:keypressed('return')
 assert(not a.state.paused,'Keyboard focus resumes the paused shop')
 a:draw()
 a:go('shelves')
 assert(#W.items==0,'View navigation clears previous view hitboxes')
 a:go('counter')
 a:draw()
 require('tools.ui_checks').run(a,function(scene) self:fixture(scene) end)
 require('tools.timbangan_checks').run(a,function(scene) self:fixture(scene) end)
 require('tools.presentation_checks').run(a,function(scene) self:fixture(scene) end)
 require('tools.cabinet_checks').run(a,function(scene) self:fixture(scene) end)
 self.inputChecked=true
 print('UI CHECK PASS ticket modal, repeated input, pause/resume and view hitboxes')
end
function Smoke:checkPreparationInput()
 local a=self.app;local before=Cash.total(a.state);local ones=a.state.drawer[100];local fives=a.state.drawer[500]
 local W=require('src.ui.widgets');assert(W.activate(500,654),'Rendered Barya button hitbox')
 assert(Cash.total(a.state)==before and a.state.drawer[100]==ones+10 and a.state.drawer[500]==fives+4,'Rendered Barya button exchanges equal-value bills')
 a:draw();assert(W.activate(1100,654),'Rendered open-store hitbox')
 assert(a.state.phase=='service' and a.view=='counter','Preparation opens store through command')
 self:fixture('preparation-day8');a:draw();self.preparationInputChecked=true
 print('PREPARATION UI CHECK PASS equal-value barya exchange and open-store navigation')
end
function Smoke:afterDraw() if not self.busy then return end; self.frames=self.frames+1; if not self.app.state.paused then self.app.uiClock=self.app.uiClock+1/60 end; if self.scene=='counter' and not self.inputChecked then self:checkInput() end; if self.scene=='tindapay-counter' and not self.walletInputChecked then self:checkWalletInput() end; if self.scene=='preparation-day8' and not self.preparationInputChecked then self:checkPreparationInput() end; if self.frames<9 then return end; if self.scene=='counter' or self.scene=='shelves' then local stats=love.graphics.getStats(); local w,h=love.graphics.getDimensions(); print(string.format('SMOKE TEXTURE %s %dx%d %.2f MiB',self.scene,w,h,stats.texturememory/1048576)) end; local path=self.path; self.busy=false; self.wait=2; love.graphics.captureScreenshot(function(image) if self.scene=='counter' then
 local L=require('src.ui.layout');local y=math.floor(L.y+510*L.scale)
 local clear=require('src.ui.theme').darkwood
 for _,x in ipairs({0,image:getWidth()-1}) do
  local red,green,blue=image:getPixel(x,y)
  assert(math.abs(red-clear[1])+math.abs(green-clear[2])+math.abs(blue-clear[3])>.02,'D1 counter edge is clear color')
 end
 print('BLEED CHECK PASS counter edge columns')
 local meta=assert(io.open(path..'.csv','w'))
 meta:write('counterTop,'..(L.y+require('src.ui.counter_layout').COUNTER_TOP_Y*L.scale)..'\n')
 meta:write('scale,'..L.scale..'\n')
 for _,d in ipairs(require('data.navigation').counter) do
  local art=self.app.counterArtRects[d.id]
  meta:write(string.format('%s,%.6f,%.6f,%.6f,%.6f,%.6f\n',d.id,
   L.x+art.x*L.scale,L.y+art.y*L.scale,art.w*L.scale,art.h*L.scale,art.factor*L.scale))
 end
 meta:close()
end
local data=image:encode('png'); local file=assert(io.open(path,'wb')); assert(file:write(data:getString())); assert(file:close()); print('SMOKE '..path) end) end
return Smoke

