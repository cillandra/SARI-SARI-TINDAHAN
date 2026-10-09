-- Purpose: reject malformed consumer-facing checkpoint profiles. API: suite function. Dependencies: real codec/day/customer modules.
return function()
    local State=require('src.model.state')
    local Days=require('src.systems.days')
    local Customers=require('src.systems.customers')
    local Codec=require('src.persistence.codec')
    local s=State.new(31)
    s.day=3
    assert(Days.prepare(s))
    local valid=assert(Codec.encode(s))
    local loaded=assert(Codec.decode(valid))
    assert(Days.open(loaded))
    for _,line in ipairs(loaded.queue[1].lines) do assert(line.type=='cash_in' or line.type=='cash_out' or require('data.products').byId[line.productId],'Valid profile generates unlocked goods or wallet services after decode') end
    assert(Customers.spawn(loaded),'Loaded profile must support another customer arrival')
    for _,snapshot in ipairs({false,true}) do
        local function reject(field,value,label)
            local bad=State.clone(s)
            local target=snapshot and bad.morningSnapshot or bad
            target.dayProfile[field]=value
            local data,err=Codec.encode(bad)
            assert(data==nil and type(err)=='string',label..' must reject in '..(snapshot and 'snapshot' or 'run'))
        end
        reject('preferred',7,'Numeric preferred profile')
        reject('preferred','rice_regular','String preferred profile')
        reject('preferred',{'unknown_product'},'Unknown preferred product')
        reject('preferred',{7},'Nonstring preferred product')
        reject('preferred',{[2]='rice_regular'},'Sparse preferred array')
        reject('name',7,'Numeric profile name')
        reject('name','','Empty profile name')
        reject('name',nil,'Missing profile name')
        reject('hint',7,'Numeric profile hint')
        for _,flag in ipairs({false,'true'}) do
            local bad=State.clone(s)
            local target=snapshot and bad.morningSnapshot or bad
            target.mvp=flag
            assert(not Codec.encode(bad),'Unsupported run mode must reject')
        end
        local bad=State.clone(s)
        local target=snapshot and bad.morningSnapshot or bad
        target.mvp=nil
        assert(not Codec.encode(bad),'Missing run mode must reject')
    end
    local function replace(data,old,new)
        local first,last=assert(data:find(old,1,true))
        return data:sub(1,first-1)..new..data:sub(last+1)
    end
    assert(not Codec.decode(replace(valid,'s9:preferredt1:n1;s12:rice_regular','s9:preferredn7;')),'Malformed preferred value must reject at decode')
    assert(not Codec.decode(replace(valid,'s3:mvpb1','s3:mvpb0')),'Unsupported run mode must reject at decode')
    local optional=State.clone(s)
    optional.dayProfile.preferred=nil
    optional.dayProfile.hint=nil
    assert(Codec.encode(optional),'Optional hint/preferred fields may be absent')
    assert(not Codec.encode(State.new(31)),'Unprepared run is not a supported application checkpoint')
end
