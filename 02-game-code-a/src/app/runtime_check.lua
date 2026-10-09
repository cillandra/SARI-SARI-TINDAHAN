-- Opt-in graphics measurement for source and release; no save writes.
local State=require('src.model.state')
local Commands=require('src.commands')
local Check={};Check.__index=Check
local cases={{1920,1080,'counter'},{1920,1080,'shelves'},
 {2560,1440,'counter'},{2560,1440,'shelves'},
 {1280,720,'timbangan',5},{1280,720,'phone',2},
 {1280,720,'drawer',1},{1280,720,'oil-preparation',5}}
function Check.persistence()
 return {exists=function() return false end,
  canSave=function() return nil,'Verification does not write saves' end,
  save=function() return nil,'Verification does not write saves' end,
  load=function() return nil,'Verification does not load saves' end}
end
function Check.new(app,args)
 local root=love.filesystem.getSource():gsub('\\','/')
 if root:match('%.love$') then root=love.filesystem.getSourceBaseDirectory():gsub('\\','/') end
 local dir
 for i,v in ipairs(args) do if v=='--verify-dir' then dir=args[i+1] end end
 assert(dir,'--verify-dir is required');dir=dir:gsub('\\','/')
 assert(dir:sub(1,#root+1)==root..'/' and not dir:find('%.%.'),'Verification output must stay inside source/package folder')
 local count=0
 for _,entry in ipairs(require('data.asset_mapping').list) do
  if entry.policy=='import' then assert(require('src.ui.assets').get(entry.id),'Required imported artwork failed: '..entry.id);count=count+1 end
 end
 print('RELEASE ART PASS '..count..' imported assets decoded and uploaded')
 return setmetatable({app=app,dir=dir,index=0,frame=0,run=tostring(os.time())},Check)
end
local function prepare_case(a,case)
 a.state=State.new(1);a.state.day=case[4] or 1
 assert(Commands.execute(a.state,'prepareDay'))
 a:clearSale();a.packQuantity=0;a.prepackProduct=nil
 if case[3]=='oil-preparation' then
  assert(a:preparePortion('cooking_oil'))
  assert(a.timbanganMode=='pour' and a.packSize==50)
  return
 end
 assert(Commands.execute(a.state,'openDay'))
 if case[3]=='timbangan' then
  assert(a:openTimbangan());assert(a:startPour());a:update(.3);a:release_held_input()
 elseif case[3]=='phone' then assert(a:openTindaPay())
 elseif case[3]=='drawer' then
  local c=assert(a.state.queue[1])
  for _,line in ipairs(c.lines) do a:pick(line.productId) end
  a:receive();assert(a.view=='drawer' and a:quote().tender,'Packaged Day1 reaches staged sukli')
 else assert(a:go(case[3])) end
end
function Check:update(dt)
 if self.finished or self.busy then return end
 if self.frame==0 then
  self.index=self.index+1;local c=cases[self.index]
  if not c then print('RUNTIME CHECK COMPLETE '..#cases..' cases; no save writes');love.event.quit(0);self.finished=true;return end
  assert(love.window.setMode(c[1],c[2],{resizable=true,highdpi=true,msaa=4,vsync=1,minwidth=960,minheight=540}))
  local a=self.app;prepare_case(a,c);a:resize(c[1],c[2]);a.debugOverlay=true
  self.times={};self.drawTime=0;self.texturePeak=0;self.drawcalls=0
 end
 self.app:update(dt);self.frame=self.frame+1
 if self.frame>60 then self.times[#self.times+1]=dt end
end
function Check:afterDraw(elapsed)
 if self.finished or self.busy or self.frame==0 then return end
 local stats=love.graphics.getStats();self.texturePeak=math.max(self.texturePeak,stats.texturememory)
 if self.frame>60 then self.drawTime=self.drawTime+elapsed;self.drawcalls=math.max(self.drawcalls,stats.drawcalls) end
 if self.frame<240 then return end
 local total=0;for _,dt in ipairs(self.times) do total=total+dt end
 table.sort(self.times);local c=cases[self.index]
 print(string.format('MEASURE %dx%d %s frames=%d FPS=%.2f mean=%.2fms p95=%.2fms drawCPU=%.2fms textures=%.2fMiB drawcalls=%d',c[1],c[2],c[3],#self.times,#self.times/total,total/#self.times*1000,self.times[math.ceil(#self.times*.95)]*1000,self.drawTime/#self.times*1000,self.texturePeak/1048576,self.drawcalls))
 assert(self.texturePeak<250*1048576,'Texture memory exceeds 250 MiB')
 self.busy=true
 local path=self.dir..'/'..self.run..'-'..c[1]..'x'..c[2]..'-'..c[3]..'-debug.png'
 love.graphics.captureScreenshot(function(data)
  local encoded=data:encode('png');local file=assert(io.open(path,'wb'));assert(file:write(encoded:getString()));file:close();data:release();encoded:release()
  print('CAPTURE '..path);self.frame=0;self.busy=false
 end)
end
return Check
