-- Purpose: measured counter edge and computed prop placements; no game rules.
local Data=require('data.navigation')
local Spec=require('data.assets').byId.scene_counter_fg
local L={}
local rects,byId={},{}
local function counter_top()
    local fallback_top=720-require('data.tuning').ui.counterBandHeight
    if love.filesystem.getInfo(Spec.path,'file') then
        local ok,image=pcall(love.image.newImageData,Spec.path)
        if not ok then return fallback_top end
        for y=0,image:getHeight()-1 do
            local _,_,_,alpha=image:getPixel(math.floor(image:getWidth()/2),y)
            if alpha*255>8 then
                image:release()
                return Spec.drawY+y/2
            end
        end
        image:release()
    end
    return fallback_top
end
L.COUNTER_TOP_Y=counter_top()
local U=require('data.tuning').ui
local center=1280/2
local function place(side,left,right)
 local group={};local total=0
 for _,d in ipairs(Data.counter) do
  if d.side==side then group[#group+1]=d;total=total+d.designSize.w end
 end
 total=total+U.slotGap*(#group-1)
 assert(total<=right-left,'Counter side group does not fit its lane')
 local x=left+(right-left-total)/2
 for _,d in ipairs(group) do
  local baseline=L.COUNTER_TOP_Y+U.baselineOverlap
  local r={x=x,y=baseline-d.designSize.h,w=d.designSize.w,h=d.designSize.h,baseline=baseline,id=d.id}
  byId[d.id]=r;x=x+r.w+U.slotGap
 end
end
place('left',U.counterSideInset,center-U.customerWidth/2-U.customerClearance)
place('right',center+U.customerWidth/2+U.customerClearance,1280-U.counterSideInset)
for i,d in ipairs(Data.counter) do rects[i]=byId[d.id] end
function L.list() return rects end
function L.get(id) return byId[id] end
function L.customer(record)
 -- Imported bounds are native 2x pixels; procedural torsos end at y=330.
 local b=record and record.bounds
 local x,y,w,h=b and b.x/2 or 0,b and b.y/2 or 0,b and b.w/2 or 240,b and b.h/2 or 330
 local factor=math.min(U.customerWidth/w,U.customerHeight/h)
 local width,height=w*factor,h*factor
 local art={x=center-width/2,y=L.COUNTER_TOP_Y+U.customerCounterOverlap-height,w=width,h=height}
 return {artBox=art,factor=factor,drawX=art.x-x*factor,drawY=art.y-y*factor,
  rect={x=art.x+width*.15,y=art.y+height*.10,w=width*.70,h=height*.45},
  ring={x=art.x-32,y=art.y+height*.30}}
end
function L.queuedCustomer(index,count)
 local scale=U.queuePortraitScale
 local width,height=240*scale,330*scale
 local step=(U.customerWidth-width)/math.max(1,count-1)
 return {x=center-U.customerWidth/2+(index-1)*step,
  y=L.COUNTER_TOP_Y+U.customerCounterOverlap-height,w=width,h=height,scale=scale}
end
return L
