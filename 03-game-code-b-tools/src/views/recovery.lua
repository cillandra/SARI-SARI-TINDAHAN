-- Purpose: plain actionable recovery. API: draw(app). Dependencies: UI.
local W=require('src.ui.widgets'); local T=require('src.ui.theme'); local Paper=require('src.ui.draw.paper'); local H=require('src.views.helpers'); local V={}
function V.draw(a) Paper.desk(); H.header(a,'Shop recovery','Choose how to begin again.'); Paper.sheet(210,145,860,425); Paper.pin(230,165); Paper.pin(1050,165); W.text('A fresh start is possible',257,197,39,T.maroon); W.text('Your shop needs usable stock or drawer cash.\nRestore this morning, or begin a new run.',258,278,25,T.ink,750); W.button('Retry this morning',258,414,315,56,function() if a:command('retryDay') then a:go('preparation') end end,T.mustard); W.button('New run',607,414,315,56,function() a:newRun() end) end
return V


