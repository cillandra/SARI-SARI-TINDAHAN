-- Purpose: small original HUD symbols. API: draw(kind,x,y,size,color). Dependencies: outline/theme/LÖVE.
local O=require('src.ui.draw.outline'); local T=require('src.ui.theme'); local Icons={}; local g=love.graphics
local function render(kind,x,y,size,color) g.push(); g.translate(x,y); g.scale(size/32); color=color or T.paper; g.setColor(color); g.setLineWidth(1.5)
 if kind=='sun' then O.ellipse(16,16,7,7,T.mustard); for i=0,7 do local a=i*math.pi/4; g.setColor(T.mustard); g.line(16+11*math.cos(a),16+11*math.sin(a),16+15*math.cos(a),16+15*math.sin(a)) end
 elseif kind=='mood' or kind=='mood_neutral' or kind=='mood_worried' then O.ellipse(16,16,13,13,T.mustard); g.setColor(T.maroon); g.circle('fill',11,13,1.5); g.circle('fill',21,13,1.5); if kind=='mood_worried' then g.arc('line',16,25,6,3.4,6); g.line(8,9,13,11); g.line(19,11,24,9) elseif kind=='mood_neutral' then g.line(12,22,20,22) else g.arc('line',16,17,6,0.25,2.9) end
 elseif kind=='cash' then O.polygon({2,9,24,3,30,23,8,29},T.sage); O.ellipse(16,16,5,7,T.paper); g.setColor(T.maroon); g.line(16,10,16,23); g.line(12,14,20,14)
 elseif kind=='ticket' then O.polygon({5,2,27,2,27,28,24,25,21,28,18,25,15,28,12,25,9,28,5,25},T.paper); g.setColor(T.maroon); g.line(10,9,23,9); g.line(10,14,23,14); g.line(10,19,19,19)
 elseif kind=='menu' or kind=='pause' then O.rect(5,6,22,3,color,1); O.rect(5,14,22,3,color,1); O.rect(5,22,22,3,color,1)
 elseif kind=='lock' then O.rect(7,14,18,15,T.mustard,3); g.setColor(T.ink); g.arc('line','open',16,14,7,math.pi,math.pi*2); g.circle('fill',16,21,2); g.line(16,21,16,25)
 elseif kind=='offline' then O.rect(7,2,18,28,T.maroon,4); O.rect(9,6,14,19,T.paper,2); O.line({5,27,28,4},T.dustyrose,3)
 elseif kind=='wallet' then O.rect(7,2,18,28,T.maroon,4); O.rect(9,6,14,19,T.paper,2); O.rect(11,13,15,10,T.sage,2); O.rect(19,16,8,4,T.mustard,1)
 elseif kind=='coin' then O.ellipse(16,16,13,13,T.mustard); O.ellipse(16,16,10,10,T.mustard,.8); g.setColor(T.maroon); g.line(16,9,16,23); g.line(12,12,20,12); g.line(12,18,20,18) elseif kind=='phone' then O.rect(7,2,18,28,T.maroon,4); O.rect(9,7,14,18,T.paper,2); O.line({12,5,20,5},T.paper,1); O.ellipse(16,28,1,1,T.paper,.5) elseif kind=='moon' then O.ellipse(16,16,13,13,T.mustard); g.setColor(T.maroon); g.circle('fill',21,12,11) end; g.pop() end
Icons.drawers={}
for _,kind in ipairs({'sun','moon','mood','mood_neutral','mood_worried','cash','ticket','menu','pause','coin','phone','wallet','lock','offline'}) do
 local name=kind
 Icons.drawers[name]=function(x,y,size,color) render(name,x,y,size,color) end
end
function Icons.draw(kind,x,y,size,color)
 assert(Icons.drawers[kind],'Unknown procedural icon: '..tostring(kind))(x,y,size,color)
end
return Icons

