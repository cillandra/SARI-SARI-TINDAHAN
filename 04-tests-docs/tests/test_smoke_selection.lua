return function()
 local Smoke=require('tools.smoke')
 assert(type(Smoke.selectScenes)=='function','Smoke requires a validated optional scene filter')
 local all=Smoke.selectScenes({})
 assert(#all>=43 and all[1]=='menu')
 local selected=Smoke.selectScenes({'--smoke-scenes','counter,timbangan-large-bags'})
 assert(#selected==2 and selected[1]=='counter' and selected[2]=='timbangan-large-bags')
 for _,args in ipairs({{'--smoke-scenes'},{'--smoke-scenes',''},{'--smoke-scenes','no-such-scene'},{'--smoke-scenes','counter,counter'}}) do
  assert(not pcall(Smoke.selectScenes,args),'Invalid/missing/duplicate scenes must fail explicitly')
 end
 assert(#Smoke.selectScenes({})==#all,'Filtering cannot mutate the default scene list')
end
