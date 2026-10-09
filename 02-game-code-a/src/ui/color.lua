-- Purpose: immutable related-color shading. API: darken(color,amount=.2),shade(color). Dependencies: none.
local Color={}
local function clamp(value) return math.max(0,math.min(1,value)) end
function Color.darken(color,amount) local factor=1-clamp(amount==nil and 0.2 or amount); return {clamp(color[1]*factor),clamp(color[2]*factor),clamp(color[3]*factor),color[4]==nil and 1 or color[4]} end
function Color.shade(color) return Color.darken(color,0.22) end
return Color
