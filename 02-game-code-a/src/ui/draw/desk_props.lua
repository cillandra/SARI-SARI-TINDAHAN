-- Purpose: inactive desk props and equipment art variants. API: notebook,phone,bin. Dependencies: frontend primitives only; no services/input/money.
local O=require('src.ui.draw.outline')
local T=require('src.ui.theme')
local W=require('src.ui.widgets')
local Icons=require('src.ui.draw.icons')
local Desk={}
function Desk.notebook(x,y,w,h)
    O.rect(x-6,y+5,w+12,h,T.maroon,8)
    O.rect(x,y,w,h,T.paper,6)
    O.line({x+w/2,y+8,x+w/2,y+h-8},T.wood,1)
    for row=1,7 do
        local py=y+18+row*(h-35)/8
        O.line({x+16,py,x+w/2-12,py},T.blush,1)
        O.line({x+w/2+12,py,x+w-16,py},T.blush,1)
        O.ellipse(x+w/2,py-5,7,3,T.steel,.9)
    end
end
function Desk.phone(x,y,w,h)
    O.rect(x,y,w,h,T.maroon,14)
    O.rect(x+8,y+16,w-16,h-31,T.paper,8)
    O.line({x+w*.38,y+9,x+w*.62,y+9},T.blush,2)
    W.text('TindaPay',x+14,y+32,18,T.maroon,w-28,'center')
    for i,color in ipairs({T.sage,T.teal,T.blush}) do
        local py=y+78+(i-1)*48
        O.rect(x+19,py,w-38,38,color,6)
        Icons.draw(i==1 and 'cash' or i==2 and 'coin' or 'ticket',x+31,py+7,24,T.paper)
        O.line({x+68,py+15,x+w-28,py+15},T.paper,2)
    end
end
function Desk.bin(x,y,w,h,upgraded)
    O.rect(x,y,w,h,upgraded and T.mustard or T.steel,5)
    O.rect(x+6,y+6,w-12,h-12,T.bininner,3)
    O.line({x+14,y+h-13,x+w-14,y+h-13},T.paper,2)
end
return Desk
