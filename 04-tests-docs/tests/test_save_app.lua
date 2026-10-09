-- Purpose: App checkpoint behavior through real codec/store and controlled disk I/O. API: suite function. Dependencies: App/Save/domain, test disk support.
return function()
    local App=require('src.app')
    local Save=require('src.persistence.save')
    local State=require('src.model.state')
    local Cash=require('src.systems.cash')
    local Customers=require('src.systems.customers')
    local disk=require('tests.support.memory_disk').new()
    local store=Save.new(disk,'checkpoint')
    local a=App.new(store)
    a:newRun()
    assert(a:save(),'App save must write a checkpoint through the injected real store')
    assert(a.hasCheckpoint and store.exists(),'Successful save enables checkpoint loading')
    assert(a:command('stepPrice','candy',100))
    assert(a:command('purchasePlanned','candy',5))
    assert(a:command('openDay'))
    a.state.paused=true
    assert(a:save())
    local saved=State.clone(a.state)
    a.packQuantity=234
    a.pourRemainder=.7
    a.pouring=true
    a.prepackProduct='sugar'
    a.change={[100]=1}
    assert(a:load(),'App must load the real checkpoint')
    assert(a.view=='counter' and a.state.paused,'Paused service checkpoint resumes at the paused counter')
    assert(Cash.total(a.state)==Cash.total(saved) and a.state.rng.state==saved.rng.state,'Load preserves exact money/RNG')
    assert(a.state.prices.candy==200 and a.state.inventory.candy[#a.state.inventory.candy].quantity==5,'Load preserves purchase and pricing')
    assert(not a.pouring and a.packQuantity==0 and a.pourRemainder==0 and not a.prepackProduct and next(a.change)==nil,'Load clears transient tool/cash selection')
    local primary=disk.files.checkpoint
    local c=Customers.current(a.state)
    a:pick(c.lines[1].productId)
    assert(type(a:saveDisabledReason())=='string','Active transaction has a save boundary explanation')
    assert(not a:save() and disk.files.checkpoint==primary,'Saving an incomplete transaction must retain checkpoint bytes')
    a:cancel()
    assert(a:save())
    disk.files.checkpoint='broken data'
    assert(a:load(),'Corrupt primary recovers through real store backup')
    assert(a.toast:find('backup',1,true),'App must display the backup recovery warning')
    local active=a.state
    disk.files.checkpoint='broken'
    disk.files['checkpoint.bak']='broken'
    assert(not a:load() and a.state==active,'Failed load leaves the current run intact')

    disk=require('tests.support.memory_disk').new()
    store=Save.new(disk,'day-checkpoint')
    a=App.new(store)
    a:newRun()
    assert(a:command('openDay'))
    assert(a:command('closeDay'))
    a.state.queue[1].patience=.001
    a:go('counter')
    a:update(.01)
    assert(a.view=='report' and store.exists(),'Entering the day report automatically checkpoints once')
    assert(assert(store.load()).phase=='report','Automatic checkpoint captures the closed day')
    local reportBytes=disk.files['day-checkpoint']
    local count=0
    for _ in pairs(disk.files) do count=count+1 end
    a:update(.1)
    local after=0
    for _ in pairs(disk.files) do after=after+1 end
    assert(count==after,'Untimed report frames must not repeatedly write checkpoints')
    disk.failure='write'
    assert(not a:nextMorning(),'Failed checkpoint blocks next-morning progression')
    assert(a.state.day==1 and a.state.phase=='report' and disk.files['day-checkpoint']==reportBytes,'Failed save leaves day and existing checkpoint intact')
    disk.failure=nil
    assert(a:nextMorning() and a.state.day==2 and a.view=='preparation','Next morning saves before advancing')
    assert(not a:nextMorning() and a.state.day==2,'Repeated next-morning action cannot advance twice')
    assert(assert(store.load()).day==1,'Stored report remains the safe pre-advance boundary')
end
