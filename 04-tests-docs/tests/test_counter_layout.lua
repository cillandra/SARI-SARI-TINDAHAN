return function()
 local Layout=require('src.ui.counter_layout')
 local Props=require('src.ui.draw.counter_props')
 local Assets=require('src.ui.assets')
 local T=require('data.tuning').ui
 local list=Layout.list();local widths={200,230,200,110}
 local center=640
 for i,r in ipairs(list) do
  assert(r.w==widths[i] and r.w>=44 and r.h>=44 and r.h<=170)
  assert(r.x>=0 and r.x+r.w<=1280)
  assert(r.baseline==Layout.COUNTER_TOP_Y+T.baselineOverlap and r.y+r.h==r.baseline)
  if i<=2 then assert(r.x+r.w<=center-130-24,'Left props must clear the enlarged customer lane')
  else assert(r.x>=center+130+24,'Right props must clear the enlarged customer lane') end
 end
 assert(#list==4 and list[1].id=='cash_drawer' and list[2].id=='timbangan' and list[3].id=='shelf_cabinet' and list[4].id=='phone')
 assert(list[2].x-list[1].x-list[1].w==T.slotGap)
 assert(list[4].x-list[3].x-list[3].w==T.slotGap)
 assert(type(Layout.customer)=='function','Customer must share the measured counter anchor')
 local function overlaps(a,b) return a.x<b.x+b.w and a.x+a.w>b.x and a.y<b.y+b.h and a.y+a.h>b.y end
 for _,spec in ipairs(require('data.assets').list) do
  if spec.id:match('^char_') and love.filesystem.getInfo(spec.path) then
   local record=assert(Assets.inspect(spec));local customer=Layout.customer(record)
   local art=customer.artBox
   assert(math.abs(art.x+art.w/2-center)<.001 and art.h>250 and art.w<=260.001)
   assert(art.y+art.h==Layout.COUNTER_TOP_Y+T.customerCounterOverlap,'Customer must extend behind the counter')
   assert(art.y>=96 and customer.rect.w>=44 and customer.rect.h>=44)
   local source=record.bounds
   assert(math.abs(art.w/(source.w/2)-art.h/(source.h/2))<.001,'Customer art must scale uniformly')
   for _,r in ipairs(list) do
    local prop=assert(Assets.inspect(require('data.assets').byId['prop_'..r.id]))
    for _,scale in ipairs({1,1.015,1.08}) do
     local box=Props.geometry(r,prop,scale)
     assert(box.w<=r.w+.001 and box.h<=170.001 and box.y+box.h==r.baseline)
     assert(not overlaps(box,art),'Prop must not overlap any part of the customer')
     assert(not overlaps(r,customer.rect),'Customer click area must clear all prop slots')
    end
    prop.imageData:release()
   end
   record.imageData:release()
  end
 end
 local fallback=Layout.customer()
 assert(fallback.artBox.y+fallback.artBox.h==Layout.COUNTER_TOP_Y+T.customerCounterOverlap)
 for i=1,5 do
  local queued=Layout.queuedCustomer(i,5)
  assert(queued.x>=510 and queued.x+queued.w<=770 and queued.y+queued.h==Layout.COUNTER_TOP_Y+T.customerCounterOverlap)
  for _,prop in ipairs(list) do assert(not overlaps(queued,prop),'Queued customers must clear side props') end
 end
 local Screen=require('src.ui.layout')
 for _,size in ipairs({{1024,768},{1280,720},{1920,1080},{2560,1080}}) do
  Screen.resize(size[1],size[2])
  for _,r in ipairs(list) do
   local x,y,inside=Screen.toCanvas(Screen.x+(r.x+r.w/2)*Screen.scale,Screen.y+(r.y+r.h/2)*Screen.scale)
   assert(inside and math.abs(x-r.x-r.w/2)<.001 and math.abs(y-r.y-r.h/2)<.001)
  end
 end
 Screen.resize(1280,720)
end
