-- Purpose: immediate buttons, pointer/focus and basic drawing. API: frame,button,hit,activate,text,panel. Dependencies: theme/fonts,LÖVE.
local T=require('src.ui.theme'); local Color=require('src.ui.color'); local Outline=require('src.ui.draw.outline'); local F=require('src.ui.fonts'); local W={items={},focus=1,mx=-1,my=-1}
function W.color(c) love.graphics.setColor(c) end
function W.panel(x,y,w,h,c,r) Outline.rect(x,y,w,h,c or T.paper,r or 8,1.25) end
-- The built-in font lacks the peso sign; draw that original glyph as vectors.
function W.text(text,x,y,size,color,width,align)
 size=(size or 18)*(W.textScale or 1); F.set(size); W.color(color or T.ink); local font=love.graphics.getFont(); local lines={}
 if width then local _,wrapped=font:getWrap(text,width); lines=wrapped else for line in (text..'\n'):gmatch('(.-)\n') do lines[#lines+1]=line end end
 for n,line in ipairs(lines) do local tx=x; if width and align=='center' then tx=x+(width-font:getWidth(line))/2 elseif width and align=='right' then tx=x+width-font:getWidth(line) end; local ty=y+(n-1)*font:getHeight()*font:getLineHeight(); local position=1
  while true do local first,last=line:find('₱',position,true); if not first then love.graphics.print(line:sub(position),tx,ty); break end; local before=line:sub(position,first-1); love.graphics.print(before,tx,ty); tx=tx+font:getWidth(before); local gw=font:getWidth('₱'); local height=size; local left=tx+gw*0.24; love.graphics.setLineWidth(math.max(1.2,size/13)); love.graphics.line(left,ty+height*0.2,left,ty+height*0.98); love.graphics.line(left,ty+height*0.2,tx+gw*0.74,ty+height*0.2,tx+gw*0.89,ty+height*0.32,tx+gw*0.89,ty+height*0.49,tx+gw*0.74,ty+height*0.6,left,ty+height*0.6); love.graphics.line(tx+gw*0.03,ty+height*0.36,tx+gw*0.98,ty+height*0.36); love.graphics.line(tx+gw*0.03,ty+height*0.47,tx+gw*0.98,ty+height*0.47); tx=tx+gw; position=last+1 end
 end
end
function W.frame(mx,my) W.items={}; W.tooltip=nil; W.mx=mx; W.my=my end
function W.hit(x,y,w,h,fn,options) options=options or {}; W.items[#W.items+1]={x=x,y=y,w=w,h=h,fn=fn,id=options.id,focusable=options.focusable~=false and not options.disabledReason,disabledReason=options.disabledReason,contains=options.contains}; return #W.items end
local function press(b)
    if b.disabledReason then return end
    W.pressed={x=b.x,y=b.y,w=b.w,h=b.h,untilTime=love.timer.getTime()+.12}
    b.fn()
end
function W.button(label,x,y,w,h,fn,color,disabledReason)
    local index=W.hit(x,y,w,h,fn,{disabledReason=disabledReason})
    local hover=W.mx>=x and W.mx<=x+w and W.my>=y and W.my<=y+h
    local fill=hover and Color.darken(color or T.paper,.06) or color or T.paper
    local textColor=color==T.maroon and T.paper or T.ink
    if disabledReason then
        fill={fill[1],fill[2],fill[3],.55}
        textColor={textColor[1],textColor[2],textColor[3],.55}
        if hover then W.tooltip={text=disabledReason,x=x+w/2,y=y+h} end
    end
    local p=W.pressed
    local pressed=p and p.x==x and p.y==y and p.w==w and p.h==h and love.timer.getTime()<p.untilTime
    love.graphics.push('all')
    if pressed then
        love.graphics.translate(x+w/2,y+h/2)
        love.graphics.scale(.96)
        love.graphics.translate(-x-w/2,-y-h/2)
    end
    W.panel(x,y,w,h,fill,10)
    if W.focus==index then
        W.color(T.maroon)
        love.graphics.setLineWidth(1.5)
        love.graphics.rectangle('line',x+4,y+4,w-8,h-8,8,8)
    end
    W.text(label,x+8,y+(h-22)/2,18,textColor,w-16,'center')
    love.graphics.pop()
end
function W.drawTooltip()
    local tip=W.tooltip
    if not tip then return end
    local x=math.max(24,math.min(936,tip.x-160))
    local y=tip.y+8
    if y+58>704 then y=tip.y-112 end
    W.panel(x,y,320,58,T.paper,6)
    W.text(tip.text,x+12,y+10,16,T.maroon,296,'center')
end
function W.activate(x,y)
 for i=#W.items,1,-1 do
  local b=W.items[i]
  if x>=b.x and y>=b.y and x<=b.x+b.w and y<=b.y+b.h and (not b.contains or b.contains(x,y)) then
   if b.focusable then W.focus=i end
   press(b); return true
  end
 end
 return false
end
function W.key(key)
 if key=='tab' then
  for step=1,#W.items do local i=(W.focus+step-1)%#W.items+1; if W.items[i].focusable then W.focus=i; return end end
 elseif key=='return' or key=='space' then local b=W.items[W.focus]; if b and b.focusable then press(b) end end
end
return W
