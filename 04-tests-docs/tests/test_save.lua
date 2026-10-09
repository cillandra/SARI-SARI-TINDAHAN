return function()
 local State=require('src.model.state'); local Days=require('src.systems.days'); local Codec=require('src.persistence.codec'); local Save=require('src.persistence.save')
 local function equal(a,b)
  if type(a)~=type(b) then return false end
  if type(a)~='table' then return a==b end
  for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
  for k in pairs(b) do if a[k]==nil then return false end end
  return true
 end
 local s=State.new(42); assert(Days.prepare(s)); local encoded=assert(Codec.encode(s)); local loaded=assert(Codec.decode(encoded)); assert(equal(s,loaded),'roundtrip preserves exact state')
 assert(not Codec.decode('return os.execute("bad")')); assert(not Codec.decode(encoded:sub(1,#encoded-1)))
 local invalid=State.clone(s); invalid.schemaVersion=999; assert(not Codec.encode(invalid)); invalid=State.clone(s); invalid.drawer[100]=1.5; assert(not Codec.encode(invalid))
 invalid=State.clone(s); invalid.inventory.candy[1].totalCost=-1; assert(not Codec.encode(invalid)); invalid=State.clone(s); invalid.ids.nextBatch=1; assert(not Codec.encode(invalid),'next batch id must exceed actual ids')
 invalid=State.clone(s); invalid.morningSnapshot.wallet.balance=0/0; assert(not Codec.encode(invalid)); invalid=State.clone(s); invalid.settings.renderer=function() end; assert(not Codec.encode(invalid))
  invalid=State.clone(s); invalid.completedReferences.bad={kind='retail',id='bad',day=1,total=100,cost=80,lines={{productId='candy',quantity=1,amount='oops'}}}; assert(not Codec.encode(invalid),'completed sale nested money requires integer schema')
 invalid=State.clone(s); invalid.histories.days={{day=1,retailRevenue='100'}}; assert(not Codec.encode(invalid),'history monetary strings are invalid')
 local service=State.clone(s); assert(Days.open(service)); local serviceEncoded=assert(Codec.encode(service)); assert(equal(service,assert(Codec.decode(serviceEncoded))),'safe service queue roundtrip')
 invalid=State.clone(service); invalid.queue[1].lines[1].amount=invalid.queue[1].lines[1].amount+1; assert(not Codec.encode(invalid),'basket totals checked')
 local files={}; local failure
 local disk={read=function(path) return files[path],files[path] and nil or 'Missing' end,
  write=function(path,data) if failure=='write' then return nil,'Injected write failure' end; files[path]=data; return true end,
  rename=function(from,to) if failure=='promote' and from:find('.tmp',1,true) then return nil,'Injected promotion failure' end; if not files[from] or files[to] then return nil,'Rename failed' end; files[to]=files[from]; files[from]=nil; return true end}
 local store=Save.new(disk,'saves/test-slot')
 assert(store.save(s)); local first=files['saves/test-slot']; s.drawer[100]=19; assert(store.save(s)); assert(files['saves/test-slot.bak']==first)
 local second=files['saves/test-slot']; failure='write'; s.drawer[100]=18; assert(not store.save(s)); assert(files['saves/test-slot']==second); failure=nil
 failure='promote'; assert(not store.save(s)); assert(equal(assert(store.load()).drawer,{[100]=19,[500]=12,[1000]=10,[2000]=10,[5000]=4,[10000]=4,[50000]=0,[100000]=0}),'promotion failure preserves latest good'); failure=nil
 assert(store.save(s)); files['saves/test-slot']='return error("EXECUTED")'; local recovered,message=store.load(); assert(recovered and recovered.drawer[100]==19 and message:find('backup'),'corrupt primary recovers last good backup')
 assert(store.save(s)); assert(assert(store.load()).drawer[100]==18)
 local before=files['saves/test-slot']; s.phase='service'; s.retail={id='pending'}; assert(not store.save(s)); assert(files['saves/test-slot']==before,'active transaction cannot save')
 files['saves/test-slot']='broken'; files['saves/test-slot.bak']='broken'; assert(not store.load())
end

