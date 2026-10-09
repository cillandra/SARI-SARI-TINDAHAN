-- Purpose: original title storefront and neighborhood cast. API: draw(app). Dependencies: procedural UI helpers only.
local W=require('src.ui.widgets'); local T=require('src.ui.theme'); local O=require('src.ui.draw.outline'); local Room=require('src.ui.draw.room'); local Ch=require('src.ui.draw.character'); local Materials=require('src.ui.draw.materials'); local Grain=require('src.ui.draw.grain'); local Sparkle=require('src.ui.draw.sparkle'); local V={}
function V.draw(a)
 Room.draw(); O.rect(327,22,626,67,T.maroon,9); W.text('SARI-SARI  •  YOUR NEIGHBORHOOD SHOP',351,43,24,T.paper,579,'center'); local back={5,2,7,3,6,10}; local front={9,1,4,11,12,8}; for i,id in ipairs(back) do Ch.draw(id,691+(i-1)*85,283,.49,'happy') end; for i,id in ipairs(front) do Ch.draw(id,685+(i-1)*87,389,.55,'happy') end; Materials.wood(0,567,1280,153,T.wood); Grain.draw(0,567,1280,153,.24); O.rect(73,160,610,408,T.paper,17,1.5); W.text('Tindahan',107,190,67,T.maroon); W.text('A little shop. A neighborhood of stories.',111,277,22,T.ink,540); W.text('Stock the shelves, weigh tingi, count sukli.\nTen growing days, then endless neighborhood days.',111,325,21,T.ink,526)
 if a.state.mvp then W.button('Resume shop',111,410,254,53,function() a:command('setPaused',false); a:go(a.state.phase=='service' and 'counter' or a.state.phase) end,T.mustard); W.button('New shop',379,410,239,53,function() a:newRun() end,T.blush) else W.button('New shop',111,410,507,53,function() a:newRun() end,T.mustard) end; W.button('Load shop',111,481,240,48,function() a:load() end,T.blush,not a.hasCheckpoint and 'No valid checkpoint yet. Start a new shop.' or nil); W.text('Mouse to play\nEscape to pause',374,483,18,T.ink,241); Sparkle.draw(642,190,11,a.uiClock); Sparkle.draw(694,537,10,a.uiClock); 
end
return V



