local W=require('src.ui.widgets')
local T=require('src.ui.theme')
local O=require('src.ui.draw.outline')
local M=require('src.ui.draw.materials')
local F=require('src.ui.format')
local Economy=require('src.systems.economy')
local Navigation=require('data.navigation')
local Pause={}
local function button(a,id,label,color,disabledReason)
 local d=Navigation.pauseControls[id]; local r=d.rect
 W.button(label,r.x,r.y,r.w,r.h,function() a:navigate(id) end,color,disabledReason)
end
local function panel()
 W.color({T.ink[1],T.ink[2],T.ink[3],.68}); love.graphics.rectangle('fill',0,0,1280,720)
 W.items={}; W.tooltip=nil
 M.shadow(360,180,560,438,.2); M.wood(370,180,540,432,T.wood,true)
 O.rect(395,204,490,382,T.paper,9)
end
function Pause.draw(a)
 panel()
 if a.pausePanel=='settings' then
  W.text('Settings',423,224,30,T.maroon,433,'center')
  local s=a.state.settings
  W.text('Audio: silent',425,270,18,T.ink)
  W.text('Day balance: fixed',425,323,18,T.ink)
  W.text('Reduce motion: '..(s.reducedMotion and 'on' or 'off'),425,378,18,T.ink); button(a,'motion','Toggle')
  W.text('Text size: '..(s.textScale==1 and 'normal' or s.textScale==1.15 and 'large' or 'larger'),425,433,18,T.ink); button(a,'text_size','Change')
  W.text('Audio is silent. Save at a safe boundary to keep preferences.',425,477,15,T.maroon,420,'center')
  button(a,'panel_back','Back',T.mustard); return
 elseif a.pausePanel=='summary' then
  local r=Economy.report(a.state)
  W.text('Day '..a.state.day..' summary',423,224,30,T.maroon,433,'center')
  local rows={{'Revenue',r.retailRevenue},{'Cost of goods',r.costOfGoods},{'Spoilage',r.spoilage},{'Change losses',r.changeLosses},{'Cash flow',r.cashFlow},{'Profit',r.profit}}
  for i,row in ipairs(rows) do W.text(row[1],425,268+i*33,17,T.ink); W.text(F.money(row[2]),665,268+i*33,17,T.maroon,175,'right') end
  button(a,'panel_back','Back',T.mustard); return
 elseif a.pausePanel=='quit' then
  W.text('Close the shop?',423,232,30,T.maroon,433,'center')
  local unsafe=a:saveDisabledReason()
  W.text(unsafe and 'An order is still open. Quitting returns to your last saved checkpoint.' or 'Your safe checkpoint will be saved before quitting.',425,307,21,T.ink,420,'center')
  button(a,'quit_confirm',unsafe and 'Quit to last checkpoint' or 'Save and quit',T.blush)
  button(a,'panel_back','Back',T.mustard); return
 end
 W.text('Sandali lang',430,239,34,T.maroon,420,'center')
 W.text('Shop paused. All timers and pouring are stopped.',424,292,17,T.ink,432,'center')
 button(a,'resume','Resume',T.mustard)
 button(a,'save_now','Save',T.paper,a:saveDisabledReason())
 button(a,'title','Back to title',T.sage)
 button(a,'settings','Settings'); button(a,'summary','Day summary')
 button(a,'quit','Quit...',T.blush)
end
return Pause
