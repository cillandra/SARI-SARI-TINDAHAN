-- Shared continuous hold integration and query-only gauge drawing.
local Config=require('data.config')
local W=require('src.ui.widgets')
local T=require('src.ui.theme')
local Meter={}
local function distance(t)
 local p=Config.pouring;local ramp=(p.cap-p.base)/p.acceleration
 local accelerating=math.min(t,ramp)
 return p.base*accelerating+p.acceleration*accelerating*accelerating/2+p.cap*math.max(0,t-ramp)
end
function Meter.advance(elapsed,remainder,dt)
 local values={elapsed,remainder,dt}
 for i=1,3 do
  local v=values[i]
  if type(v)~='number' or v~=v or v<0 or v==math.huge then return nil,'Invalid pour time' end
 end
 local total=distance(elapsed+dt)-distance(elapsed)+remainder
 local quantity=math.floor(total+1e-9)
 return quantity,elapsed+dt,math.max(0,total-quantity)
end
function Meter.draw(model,x,y,w,h)
 local max=math.max(1,model.target*1.3)
 W.panel(x,y,w,h,T.bininner,4)
 local lower=math.min(1,model.lower/max);local upper=math.min(1,model.upper/max)
 W.color(T.sage);love.graphics.rectangle('fill',x+2,y+h*(1-upper),w-4,math.max(2,h*(upper-lower)))
 local target=math.min(1,model.target/max)
 W.color(T.maroon);love.graphics.setLineWidth(2);love.graphics.line(x-4,y+h*(1-target),x+w+4,y+h*(1-target))
 local actual=math.min(1,model.actual/max)
 W.color(T.mustard);love.graphics.setLineWidth(3);love.graphics.line(x-3,y+h*(1-actual),x+w+3,y+h*(1-actual))
end
return Meter
