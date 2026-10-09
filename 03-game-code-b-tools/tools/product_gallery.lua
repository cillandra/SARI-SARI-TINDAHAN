-- Purpose: smoke sheet of every original product picture. API: draw(app). Dependencies: catalog and frontend only.
local W=require('src.ui.widgets')
local T=require('src.ui.theme')
local H=require('src.ui.draw.heaps')
local Hud=require('src.ui.draw.hud')
local P=require('data.products')
local Gallery={}
function Gallery.draw(a)
    Hud.draw(a,'All 36 product pictures','Smoke sheet · Original procedural art, independent of stock.')
    for i,p in ipairs(P.list) do
        local x=24+((i-1)%6)*207
        local y=116+math.floor((i-1)/6)*98
        W.panel(x,y,195,88,T.paper,6)
        H.draw(p,x+7,y+11,63,63)
        W.text(p.name,x+77,y+21,14,T.ink,111)
    end
end
return Gallery
