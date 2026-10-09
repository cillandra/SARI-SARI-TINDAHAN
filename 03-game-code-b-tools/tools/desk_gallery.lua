-- Purpose: smoke-only visual hooks for deferred desk services and equipment. API: draw(app). Dependencies: frontend only, no active wallet/credit/upgrade behavior.
local W=require('src.ui.widgets')
local T=require('src.ui.theme')
local Desk=require('src.ui.draw.desk_props')
local Hud=require('src.ui.draw.hud')
local Gallery={}
function Gallery.draw(a)
    Hud.draw(a,'Desk prop hooks','Art only · Credit, wallet and equipment upgrades remain deferred in the MVP.')
    W.panel(42,133,714,488,T.paper,10)
    W.text('Spiral notebook',72,156,26,T.maroon)
    Desk.notebook(81,215,616,345)
    Desk.phone(794,151,211,322)
    W.text('Inactive phone prop',781,485,18,T.ink,243,'center')
    Desk.bin(1041,169,184,128,false)
    W.text('Basic steel',1041,309,18,T.ink,184,'center')
    Desk.bin(1041,367,184,128,true)
    W.text('Gold frame variant',1030,507,18,T.ink,206,'center')
end
return Gallery
