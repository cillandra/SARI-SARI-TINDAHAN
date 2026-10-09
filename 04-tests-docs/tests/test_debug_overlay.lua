return function()
 local store=require('src.app.runtime_check').persistence()
 assert(not store.exists(),'Verification cannot observe player checkpoints')
 local ok,err=store.save({});assert(not ok and err=='Verification does not write saves')
 assert(not store.load(),'Verification cannot load player checkpoints')
 local App=require('src.app');local Save=require('src.persistence.save');local Codec=require('src.persistence.codec')
 local a=App.new(Save.new(require('tests.support.memory_disk').new(),'debug'));a:newRun()
 local before=assert(Codec.encode(a.state));local view=a.view
 a:keypressed('f1');assert(a.debugOverlay==true,'F1 must enable performance overlay')
 assert(a.view==view and Codec.encode(a.state)==before,'Debug toggle cannot change gameplay or saves')
 a:keypressed('f1');assert(a.debugOverlay==false)
 a:pause();before=assert(Codec.encode(a.state));a:keypressed('f1');assert(a.debugOverlay and Codec.encode(a.state)==before,'F1 remains available while paused')
end
