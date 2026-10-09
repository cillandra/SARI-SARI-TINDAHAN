-- Terminal run presentation; restart and navigation delegate to App commands.
local W=require('src.ui.widgets')
local T=require('src.ui.theme')
local Paper=require('src.ui.draw.paper')
local H=require('src.views.helpers')
local V={}
function V.draw(a)
 Paper.desk();H.header(a,'','')
 Paper.sheet(210,145,860,425)
 W.text('Pahinga muna, mga suki!',258,190,39,T.maroon)
 W.text('Day '..a.state.day..'  |  Suki 0%',258,262,27,T.ink)
 W.text('Begin a new shop when you are ready.\nYour finished run can still be saved and loaded.',258,316,23,T.ink,740)
 W.button('New shop',258,438,315,56,function() a:newRun() end,T.mustard)
 W.button('Back to title',607,438,315,56,function() a:go('menu') end)
end
return V
