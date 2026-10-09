-- Purpose: original cork and paper desk surfaces. API: desk(),sheet(x,y,w,h),pin(x,y). Dependencies: frontend only.
local O=require('src.ui.draw.outline'); local T=require('src.ui.theme'); local M=require('src.ui.draw.materials'); local G=require('src.ui.draw.grain'); local Paper={}
function Paper.desk() O.rect(0,0,1280,720,T.blush,0); M.wood(0,103,1280,617,T.wood); O.rect(20,112,1240,495,T.darkwood,9); O.rect(29,121,1222,477,T.mustard,6); G.draw(29,121,1222,477,.24) end
function Paper.sheet(x,y,w,h) O.rect(x+4,y+5,w,h,T.darkwood,5); O.rect(x,y,w,h,T.paper,5); O.line({x+17,y+12,x+w-17,y+12},T.blush,1) end
function Paper.pin(x,y) O.ellipse(x+1,y+2,5,5,T.darkwood,.8); O.ellipse(x,y,4,4,T.maroon,.8) end
return Paper
