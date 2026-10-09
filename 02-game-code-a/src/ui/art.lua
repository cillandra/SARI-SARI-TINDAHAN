-- Purpose: compatibility facade delegating to the original procedural helpers. API: product,person,awning,bag (preserved). Dependencies: new drawing helpers only.
local Heaps=require('src.ui.draw.heaps'); local Character=require('src.ui.draw.character'); local Props=require('src.ui.draw.props'); local Station=require('src.ui.draw.station'); local Art={}
function Art.product(product,x,y,size) Heaps.draw(product,x,y,size,size) end
function Art.person(x,y,scale,variant) local actorScale=(scale or 1)*.5; Character.draw(variant and 2 or 1,x-120*actorScale,y-126*actorScale,actorScale,'waiting') end
function Art.awning(x,y,w) Props.awning(x,y,w) end
function Art.bag(x,y,w,h,label) Station.sack(x,y,w,h,label) end
return Art
