-- Purpose: original flat outlined prop silhouettes. API: roundrect,capsule,blob,bottle,can,sack,bowl,scoop. Dependencies: outline/theme/color/LÖVE.
local O=require('src.ui.draw.outline'); local T=require('src.ui.theme'); local C=require('src.ui.color'); local S={}
function S.roundrect(x,y,w,h,c,r) O.rect(x,y,w,h,c,r or 8) end
function S.capsule(x,y,w,h,c) O.rect(x,y,w,h,c,h/2) end
function S.blob(x,y,w,h,c) O.ellipse(x+w/2,y+h/2,w/2,h/2,c) end
function S.bottle(x,y,w,h,c) O.polygon({x+w*.28,y+h*.12,x+w*.72,y+h*.12,x+w*.72,y+h*.29,x+w*.92,y+h*.43,x+w*.92,y+h,x+w*.08,y+h,x+w*.08,y+h*.43,x+w*.28,y+h*.29},c); O.rect(x+w*.24,y,w*.52,h*.13,T.maroon,2); O.rect(x+w*.1,y+h*.55,w*.8,h*.25,T.paper,2) end
function S.can(x,y,w,h,c) O.rect(x,y+h*.1,w,h*.78,c,3); O.ellipse(x+w/2,y+h*.1,w/2,h*.1,T.steel); O.ellipse(x+w/2,y+h*.88,w/2,h*.1,C.shade(c)) end
function S.sack(x,y,w,h,c) O.polygon({x+w*.14,y,x+w*.86,y,x+w*.94,y+h*.32,x+w*.94,y+h*.92,x+w*.75,y+h,x+w*.25,y+h,x+w*.06,y+h*.92,x+w*.06,y+h*.32},c); O.line({x+w*.14,y+h*.07,x+w*.86,y+h*.07},C.shade(c)) end
function S.bowl(x,y,w,h,c) O.ellipse(x+w/2,y+h*.26,w/2,h*.22,c); O.polygon({x,y+h*.26,x+w,y+h*.26,x+w*.81,y+h,x+w*.19,y+h},c); O.ellipse(x+w/2,y+h*.26,w/2,h*.19,T.paper) end
function S.scoop(x,y,w,h,c) O.ellipse(x+w*.72,y+h*.37,w*.28,h*.36,c); O.rect(x,y+h*.3,w*.62,h*.19,T.wood,3) end
return S
