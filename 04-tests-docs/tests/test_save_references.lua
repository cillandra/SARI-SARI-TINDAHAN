-- Regression: checkpoint references must preserve exactly-once customer settlement.
return function()
    local State = require('src.model.state')
    local Cmd = require('src.commands')
    local Retail = require('src.systems.retail')
    local Codec = require('src.persistence.codec')
    local s = State.new(1)
    assert(Cmd.execute(s, 'prepareDay'))
    assert(Cmd.execute(s, 'openDay'))
    local customer = s.queue[1]
    customer.lines = {{type='item', productId='candy', quantity=1, amount=100,
        measured=false, requestMode='quantity', requestValue=1}}
    customer.total = 100
    local queued = State.clone(customer)
    assert(Retail.begin(s, customer.id))
    assert(Retail.add(s, customer.id, 'candy', 1))
    assert(Retail.stageTender(s, customer.id, {[100]=1}))
    assert(Retail.commit(s, customer.id, {}))
    assert(Codec.decode(assert(Codec.encode(s))), 'Valid completed sale must round-trip')
    local valid = assert(Codec.encode(s))
    local corrupt, replacements = valid:gsub('s4:costn80;', 's4:costn81;', 1)
    assert(replacements == 1, 'Fixture must have the hand-checked candy FIFO cost')
    assert(not Codec.decode(corrupt), 'Divergent persisted sale must fail decoding')
    local disk = require('tests.support.memory_disk').new()
    disk.files.checkpoint, disk.files['checkpoint.bak'] = corrupt, valid
    local store = require('src.persistence.save').new(disk, 'checkpoint')
    local recovered, warning = store.load()
    assert(recovered and warning:find('Recovered last good backup', 1, true),
        'Conflicting primary must recover the valid backup')
    local cases = {
        {'completed queued customer', function(b) b.queue={queued} end},
        {'cancelled queued customer', function(b)
            b.completedReferences={}; b.histories.retail={}
            b.cancelledRetail={[queued.id]=true}; b.queue={queued}
        end},
        {'duplicate sale history', function(b)
            b.histories.retail[2]=State.clone(b.histories.retail[1]);b.ids.nextTransaction=3
        end},
        {'missing completed reference', function(b) b.completedReferences[queued.id]=nil end},
        {'missing sale history', function(b) b.histories.retail={} end},
        {'divergent completed record', function(b)
            b.completedReferences[queued.id].cost=b.completedReferences[queued.id].cost+1
        end},
        {'completed and cancelled reference', function(b) b.cancelledRetail={[queued.id]=true} end},
    }
    for _,case in ipairs(cases) do
        local bad=State.clone(s);case[2](bad)
        local encoded,err=Codec.encode(bad)
        assert(not encoded and type(err)=='string', 'Reject '..case[1])
    end
end
