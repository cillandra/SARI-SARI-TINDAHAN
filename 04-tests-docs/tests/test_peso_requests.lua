-- Real generated peso requests, immutable service quotes and stock/payment/save accounting.
return function()
    local State = require('src.model.state')
    local Days = require('src.systems.days')
    local Customers = require('src.systems.customers')
    local Products = require('data.products')
    local App = require('src.app')
    local Save = require('src.persistence.save')
    local Codec = require('src.persistence.codec')
    local Inventory = require('src.systems.inventory')
    local Cash = require('src.systems.cash')
    local seen = {}
    local s = State.new(17)
    s.day = 5
    assert(Days.prepare(s))
    for _, p in ipairs(Products.list) do
        if p.timbangan then
            s.inventory[p.id] = {{id='batch:'..s.ids.nextBatch,quantity=10000,
                totalCost=p.cost*10,receivedDay=1,expiresDay=100,prepared=false}}
            s.ids.nextBatch = s.ids.nextBatch + 1
        end
    end
    s.phase = 'service'
    for number=1,200 do
        s.queue = {assert(Customers.generate(s))}
        for _, line in ipairs(s.queue[1].lines) do
            if line.type=='repack' or line.type=='pour' then
                if line.requestMode=='peso' then
                    assert(line.requestValue==1000 or line.requestValue==2000)
                    assert(line.amount==line.requestValue,'Peso request must quote the requested pesos')
                    local expected = ({sugar={[1000]=125,[2000]=250},
                        flour={[1000]=167,[2000]=333},salt={[1000]=333,[2000]=667},
                        cooking_oil={[1000]=100,[2000]=200}})[line.productId]
                    assert(line.quantity==expected[line.requestValue],'Fresh target uses the product price')
                    seen[line.type..line.requestValue] = true
                else
                    assert(line.type=='pour' and (line.quantity==50 or line.quantity==100)
                        or line.type=='repack' and (line.quantity==250 or line.quantity==500))
                end
            end
        end
    end
    assert(seen.repack1000 and seen.repack2000 and seen.pour1000 and seen.pour2000,
        'Generated orders must include both P10/P20 bags and bottles')
    local loaded = assert(Codec.decode(assert(Codec.encode(s))))
    s.queue={assert(Customers.generate(s))};loaded.queue={assert(Customers.generate(loaded))}
    assert(Codec.encode(s)==Codec.encode(loaded),'Peso requests preserve saved RNG continuation')

    local function app(pid,kind,value,quantity)
        local a=App.new(Save.new(require('tests.support.memory_disk').new(),'peso'))
        a.state=State.new(1);a.state.day=5
        assert(a:command('prepareDay'));assert(a:command('openDay'))
        local c=a.state.queue[1]
        c.lines={{type=kind,productId=pid,quantity=quantity,amount=value,
            measured=true,requestMode='peso',requestValue=value}}
        c.total=value;c.tender=nil
        a:pick(pid)
        return a,c.id
    end
    local a,id=app('sugar','repack',2000,250)
    assert(a:command('cancelRetail',id))
    assert(a:command('beginRetail',id)==nil,'Cancelled retail reference remains protected')
    a,id=app('sugar','repack',2000,250)
    -- Remove the unopened line through the actual editable basket operation.
    assert(a:command('removeRetail',id,1))
    local frozen=State.clone(a.state)
    assert(not a:command('targetPortion',id,'sugar',1999,'peso'),
        'A nearly equal peso value must not overwrite the customer quote')
    assert(a.state.retail.total==0 and #a.state.retail.lines==0 and a.state.retail.nextLine==frozen.retail.nextLine
        and next(a.state.reservations)==nil and Cash.total(a.state)==Cash.total(frozen)
        and Inventory.available(a.state,'sugar')==Inventory.available(frozen,'sugar'),
        'Wrong peso request refuses without stock or receipt mutation')
    a.state.prices.sugar=10000
    assert(a:command('targetPortion',id,'sugar',2000,'peso'))
    assert(a:quote().lines[1].targetQuantity==250 and a:quote().total==2000,
        'Saved customer target is not recomputed from later prices')
    a,id=app('sugar','repack',2000,250)
    local before=Cash.total(a.state);local stock=Inventory.available(a.state,'sugar')+250
    assert(a:choosePackOption('peso',2000))
    assert(a.packSize==250 and a:quote().total==2000 and a:quote().lines[1].targetQuantity==250,
        'Choosing peso capacity cannot rewrite a service quote')
    assert(not a:choosePackOption('peso',1000),'Too-small peso bag must be refused')
    assert(not a:choosePackOption('peso',1500),'Unknown peso choice must be refused')
    assert(a:choosePackSize(500) and a:quote().total==2000)
    a:adjust(250);assert(a:confirmTimbangan())
    a:receive()
    if a.view=='drawer' then
        local q=a:quote();a.change=assert(Cash.plan(a.state,q.tenderAmount-q.total,q.tender));a:commit()
    end
    local record=assert(a.state.completedReferences[id])
    assert(record.total==2000 and a.state.ledger.retailRevenue==2000)
    assert(Inventory.available(a.state,'sugar')==stock-250 and a.state.ledger.costOfGoods==1600)
    assert(Cash.total(a.state)==before+2000+(record.tip or 0))
    local encoded=assert(Codec.encode(a.state));assert(Codec.decode(encoded))
    a:commit();assert(Codec.encode(a.state)==encoded,'Peso settlement commits only once')
    a,id=app('cooking_oil','pour',2000,200)
    assert(a:choosePackOption('peso',2000) and a.packSize==200)
    a:adjust(200);assert(a:confirmTimbangan() and a:quote().total==2000)
    a.state.paused=true;assert(not a:choosePackOption('peso',1000))
    a:newRun();a.prepackProduct='sugar';a:go('timbangan')
    assert(a:choosePackOption('peso',1000) and a.packSize==125)
    a:adjust(100);assert(not a:choosePackOption('peso',2000),'Opened prep bag cannot change target')
    assert(a:resetPour());assert(a:choosePackOption('peso',2000) and a.packSize==250)
    a:adjust(250);assert(a:confirmTimbangan())
    local ready=false
    for _,b in ipairs(a.state.inventory.sugar) do if b.prepared and b.quantity==250 then ready=true end end
    assert(ready,'Peso preparation seals the resolved integer stock quantity')
    print('PESO REQUEST PASS P10/P20 generated bags/bottles, quote locking, stock/cash/FIFO, save/RNG and prep')
end
