-- Presentation safeguards exercise real input registration, app commands and save storage.
return function()
    local W = require('src.ui.widgets')
    local App = require('src.app')
    local Save = require('src.persistence.save')
    local Disk = require('tests.support.memory_disk')
    local Cash = require('src.systems.cash')
    local Inventory = require('src.systems.inventory')
    local count = 0
    W.frame(-1,-1)
    W.hit(10,10,100,50,function() count=count+1 end,{disabledReason='Not ready'})
    W.hit(120,10,100,50,function() count=count+1 end)
    W.focus=1
    assert(W.activate(20,20),'Disabled control consumes the hit without passing through')
    W.key('return');W.key('space')
    assert(count==0,'Disabled mouse and keyboard actions must not call game commands')
    W.key('tab');W.key('return')
    assert(count==1,'Keyboard skips disabled control and activates the next enabled action')
    W.frame(-1,-1)

    local disk=Disk.new();local store=Save.new(disk,'presentation')
    local a=App.new(store);a:newRun()
    local before=Cash.total(a.state);local stock=Inventory.available(a.state,'candy')
    assert(a:restock('candy',5))
    local saved=assert(store.load())
    assert(Inventory.available(saved,'candy')==stock+5 and Cash.total(saved)==before-400,
        'Completed restock is automatically checkpointed with exact cost')
    before=Cash.total(a.state)
    assert(a:exchangeBarya())
    saved=assert(store.load())
    assert(Cash.total(saved)==before and saved.drawer[100]==a.state.drawer[100],
        'Barya exchange is conserved and checkpointed')
    disk.failure='write'
    before=Cash.total(a.state);stock=Inventory.available(a.state,'candy')
    local ok,outcome=a:restock('candy',5)
    assert(ok and outcome=='save_failed' and a.pendingCheckpoint,
        'Purchase success and save failure are reported separately')
    assert(Cash.total(a.state)==before-400 and Inventory.available(a.state,'candy')==stock+5)
    assert(a.toast:find('Save',1,true),'Save failure must explain retry')
    assert(not a:restock('candy',5) and not a:openStore(),
        'Pending save blocks duplicate purchase and opening')
    assert(Cash.total(a.state)==before-400 and Inventory.available(a.state,'candy')==stock+5)
    disk.failure=nil
    assert(a:save() and not a.pendingCheckpoint)
    saved=assert(store.load());assert(Inventory.available(saved,'candy')==stock+5)
    assert(a:openStore() and a.view=='counter')
    a.packQuantity=99;a.prepackProduct='sugar';a.pendingCheckpoint=true
    a:newRun()
    assert(a.packQuantity==0 and not a.prepackProduct and not a.pendingCheckpoint,
        'New game must clear old preparation fill and checkpoint flags')
    assert(a:preparePortion('cooking_oil'))
    local model=require('src.ui.timbangan_model').model(a)
    assert(a.view=='timbangan' and model.mode=='pour' and model.target==50,
        'Oil preparation starts in pour mode at a supported bottle size')
    a:adjust(20)
    assert(not a:preparePortion('sugar') and a.portionSwitch,
        'Opening another preparation bin preserves existing fill until discard')
    assert(a:resolveTimbanganSwitch('continue') and a.packQuantity==20)
    assert(a:resetPour());assert(a:preparePortion('sugar'))
    assert(a.timbanganMode=='repack' and a.packSize==250)
    local Meter=require('src.ui.pour_meter')
    for _,args in ipairs({{nil,0,.1},{0,nil,.1},{0,0,nil}}) do
        local good,result=pcall(Meter.advance,args[1],args[2],args[3])
        assert(good and not result,'Malformed timing must refuse instead of crashing')
    end
    print('PRESENTATION READINESS PASS disabled input, restock checkpoint/retry, barya, oil mode and safe timing')
end
