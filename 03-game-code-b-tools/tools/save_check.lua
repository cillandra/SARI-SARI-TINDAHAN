-- Purpose: fresh-process native checkpoint verification in a dedicated project save folder. API: run(args) -> exit code. Dependencies: real App/Save/domain; no graphics.
local Check={}
function Check.run(args)
    local mode,id
    for i,value in ipairs(args) do
        if value=='--save-check' then mode=args[i+1]; id=args[i+2] end
    end
    assert(type(id)=='string' and id:match('^%d+$'),'Numeric verification ID required')
    local root=love.filesystem.getSource():gsub('\\','/')
    if root:lower():match('%.love$') then root=love.filesystem.getSourceBaseDirectory():gsub('\\','/') end
    local path=root..'/saves/verification-'..id..'/checkpoint.tinda'
    local App=require('src.app')
    local Save=require('src.persistence.save')
    local Cash=require('src.systems.cash')
    local Customers=require('src.systems.customers')
    local Inventory=require('src.systems.inventory')
    local store=Save.new(nil,path)
    local a=App.new(store)
    if mode=='write' then
        assert(a:command('newRun',1));a:go('preparation')
        assert(a:command('stepPrice','candy',100))
        assert(a:command('purchasePlanned','candy',5))
        assert(a:command('openDay'))
        local customer=assert(a.state.queue[1])
        -- Deliberately retain a legacy measured-item checkpoint to verify old saves.
        customer.lines={{type='item',productId='sugar',measured=true,quantity=250,amount=2000,
            requestMode='quantity',requestValue=250}}
        customer.total=2000;customer.tender={[5000]=1}
        assert(#customer.lines==1 and customer.lines[1].productId=='sugar','Literal sale fixture changed')
        a:pick('sugar')
        local line=a:quote().lines[1]
        assert(line.targetQuantity==250)
        a:adjust(250)
        a:confirmPortion(1)
        a:receive()
        assert(a.view=='drawer' and a:quote().tenderAmount==5000)
        a.change={[1000]=3};a:commit()
        assert(Cash.total(a.state)==99600+(a.state.ledger.tips or 0) and a.state.ledger.retailRevenue==2000 and Inventory.available(a.state,'sugar')==1750)
        assert(a:command('setPaused',true))
        local ok,err=a:save()
        assert(ok,err)
        assert(a:command('adjustReputation',1))
        ok,err=a:save()
        assert(ok,err)
        print('NATIVE SAVE WRITE PASS cash_centavos='..Cash.total(a.state)..' tips='..(a.state.ledger.tips or 0)..' sugar_g=1750 sold=1 primary_reputation='..a.state.reputation..' backup_reputation='..(a.state.reputation-1))
    elseif mode=='load' or mode=='recover' then
        local ok,warning=a:load()
        assert(ok,warning)
        assert(a.view=='counter' and a.state.paused and a.state.day==1)
        assert(Cash.total(a.state)==99600+(a.state.ledger.tips or 0) and Inventory.available(a.state,'candy')==35 and Inventory.available(a.state,'sugar')==1750)
        assert(a.state.prices.candy==200 and a.state.ledger.retailRevenue==2000 and #a.state.histories.retail==1)
        assert(a.state.reputation==(mode=='recover' and 52 or 53))
        assert(a:command('commitRetail','customer:1',{}),'Completed reference remains idempotent after reload')
        assert(Cash.total(a.state)==99600+(a.state.ledger.tips or 0) and #a.state.histories.retail==1,'Reload must not enable duplicate commit')
        if mode=='recover' then assert(warning and a.toast:find('backup',1,true)) end
        print('NATIVE SAVE '..mode:upper()..' PASS day=1 cash_centavos='..Cash.total(a.state)..' tips='..(a.state.ledger.tips or 0)..' reputation='..a.state.reputation..' sugar_g=1750 history=1 paused=true duplicate_commit_unchanged=true')
        if warning then print('RECOVERY WARNING '..warning) end
    else error('Unknown save-check mode') end
    print('VERIFIED SLOT '..path)
    return 0
end
return Check
