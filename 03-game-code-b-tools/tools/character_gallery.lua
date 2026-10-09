-- Purpose: smoke-only sheet of all twelve original actors and four expressions.
-- API: draw(app). Dependencies: frontend character/widgets/HUD; no run mutation.
local Character=require('src.ui.draw.character')
local W=require('src.ui.widgets')
local T=require('src.ui.theme')
local Hud=require('src.ui.draw.hud')
local Gallery={}
local expressions={'happy','waiting','impatient','angry'}
function Gallery.draw(app)
    Hud.draw(app,'Neighborhood cast','Smoke sheet: twelve original characters, four face variants each.')
    for id=1,12 do
        local x=24+((id-1)%4)*310
        local y=116+math.floor((id-1)/4)*194
        W.panel(x,y,296,180,T.paper,9)
        local p=Character.profile(id)
        W.text(p.role or p.name,x+10,y+8,18,T.maroon,276,'center')
        for i,expression in ipairs(expressions) do
            Character.draw(id,x+8+(i-1)*71,y+35,0.265,expression)
            W.text(expression,x+4+(i-1)*71,y+133,12,T.ink,72,'center')
        end
        W.text(p.name,x+12,y+155,15,T.ink,272,'center')
    end
end
return Gallery