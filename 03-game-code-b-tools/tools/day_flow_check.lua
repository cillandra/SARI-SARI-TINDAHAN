-- Fresh-process M3 verification in a dedicated project-local save slot.
local Check={}
function Check.run(args)
 local mode,id
 for i,value in ipairs(args) do if value=='--m3-check' then mode=args[i+1];id=args[i+2] end end
 assert(type(id)=='string' and id:match('^%d+$'),'Numeric verification ID required')
 local root=love.filesystem.getSource():gsub('\\','/')
 assert(not root:lower():match('%.love$'),'Run this development check from source')
 local path=root..'/saves/m3-verification-'..id..'/checkpoint.tinda'
 local Save=require('src.persistence.save');local Codec=require('src.persistence.codec');local Cash=require('src.systems.cash')
 local Play=require('tests.support.day_playthrough');local store=Save.new(nil,path);local expected=Save.new(nil,path..'.expected')
 if mode=='write' then
  assert(not store.exists() and not expected.exists(),'Preserve existing verification slots; choose a new ID')
  local baseline=Play.run(Save.new(require('tests.support.memory_disk').new(),'expected'),1,6,false)
  assert(expected.save(baseline.app.state))
  local result=Play.run(store,1,3,false)
  print('M3 NATIVE WRITE PASS checkpoint_day=3 cash='..Cash.total(result.app.state))
 elseif mode=='resume' then
  local result=Play.run(store,1,6,true,true);local baseline=assert(expected.load())
  assert(Codec.encode(result.app.state)==Codec.encode(baseline),'Fresh-process resumed state differs from uninterrupted six-day state')
  print('M3 NATIVE RESUME PASS day=6 cash='..Cash.total(result.app.state)..' full_state_identical=true')
 else error('Unknown M3 verification mode') end
 return 0
end
return Check
