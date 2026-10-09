-- Canonical measured goods remain stock sales, including mixed wallet baskets and saves.
return function()
    local State = require('src.model.state')
    local Cmd = require('src.commands')
    local Retail = require('src.systems.retail')
    local Portions = require('src.systems.portions')
    local Customers = require('src.systems.customers')
    local Inventory = require('src.systems.inventory')
    local Cash = require('src.systems.cash')
    local Wallet = require('src.systems.tindapay')
    local Codec = require('src.persistence.codec')
    local Order = require('src.systems.order')
    local failures = {}
    local function same(a,b)
        if type(a)~=type(b) then return false end
        if type(a)~='table' then return a==b end
        for key,value in pairs(a) do if not same(value,b[key]) then return false end end
        for key in pairs(b) do if a[key]==nil then return false end end
        return true
    end
    local function expect(ok, label) if not ok then failures[#failures+1] = label end end
    local fixtures = {
        {'weigh', 'rice_regular', 250, 1400, 1125},
        {'repack', 'sugar', 250, 2000, 1600},
        {'pour', 'cooking_oil', 100, 1000, 800},
    }
    for _, fixture in ipairs(fixtures) do
        local kind, pid, quantity, amount, cost = unpack(fixture)
        local s = State.new(1); s.day = 5
        assert(Cmd.execute(s, 'prepareDay')); assert(Cmd.execute(s, 'openDay'))
        local c = s.queue[1]
        c.lines = {
            {type=kind, productId=pid, quantity=quantity, amount=amount,
                measured=true, requestMode='quantity', requestValue=quantity},
            {type='item', productId='candy', quantity=1, amount=100,
                measured=false, requestMode='quantity', requestValue=1},
            {type='cash_out', principal=5000, fee=1000, amount=1000,
                reference='transfer:'..kind, recipient='store',
                transfer={reference='transfer:'..kind, amount=5000, recipient='store', status='confirmed'}},
        }
        c.total = amount + 1100
        expect(Codec.encode(s) ~= nil, kind .. ': queued canonical save must encode')
        for _, legacy in ipairs({'item','missing'}) do
            local old=State.clone(s)
            old.queue[1].lines[1].type=legacy=='item' and 'item' or nil
            expect(Codec.decode(assert(Codec.encode(old)))~=nil, kind .. ': legacy measured '..legacy..' save')
        end
        for _, damage in ipairs({'unknown', 'wrong unit', 'unmeasured'}) do
            local bad=State.clone(s);local line=bad.queue[1].lines[1]
            if damage=='unknown' then line.type='cashin'
            elseif damage=='wrong unit' then line.productId=kind=='pour' and 'rice_regular' or 'cooking_oil'
            else line.measured=false end
            expect(not Codec.encode(bad),kind .. ': schema rejects '..damage)
        end
        local beforeCash, beforeWallet, beforeStock = Cash.total(s), s.wallet.balance, Inventory.available(s,pid)
        assert(Retail.begin(s,c.id)); assert(Portions.target(s,c.id,pid,quantity))
        expect(s.retail.lines[1].type == kind, kind .. ': staged goods must retain canonical type')
        assert(Portions.adjust(s,c.id,1,quantity)); assert(Portions.confirm(s,c.id,1))
        assert(Retail.add(s,c.id,'candy',1)); assert(Wallet.add(s,c.id,3,c.lines[3].transfer))
        expect(Cash.total(s)==beforeCash and s.wallet.balance==beforeWallet, kind .. ': money remains staged')
        local mismatched=State.clone(s)
        mismatched.retail.lines[1].type=kind=='weigh' and 'repack' or 'weigh'
        expect(not Customers.payment(mismatched),kind .. ': payment rejects wrong staged type')
        assert(Retail.stageTender(mismatched,c.id,{[10000]=1}))
        local correct_change=assert(Cash.plan(mismatched,assert(Retail.changeDue(mismatched,c.id)),mismatched.retail.tender))
        local frozen=State.clone(mismatched)
        expect(not Retail.commit(mismatched,c.id,correct_change),kind .. ': commit rejects wrong staged type')
        expect(same(mismatched,frozen),kind .. ': wrong type rejection preserves full staged state')
        expect(mismatched.retail and #mismatched.histories.retail==0 and Cash.total(mismatched)==beforeCash
            and mismatched.wallet.balance==beforeWallet,kind .. ': wrong type cannot commit money')
        local tender, reason = Customers.payment(s)
        expect(tender ~= nil, kind .. ': payment must recognize complete goods: ' .. tostring(reason))
        if tender then
            assert(Retail.stageTender(s,c.id,tender))
            local change=assert(Cash.plan(s,assert(Retail.changeDue(s,c.id)),tender))
            local ok, err=Retail.commit(s,c.id,change)
            expect(ok, kind .. ': mixed commit must settle goods: ' .. tostring(err))
            if ok then
                expect(Inventory.available(s,pid)==beforeStock-quantity, kind .. ': consume actual stock')
                expect(Cash.total(s)==beforeCash+amount+1100-5000 and s.wallet.balance==beforeWallet+5000, kind .. ': wallet and drawer arithmetic')
                expect(s.ledger.costOfGoods==cost+80 and s.ledger.retailRevenue==amount+100 and s.ledger.serviceFees==1000, kind .. ': FIFO and revenue classification')
                expect(Codec.decode(assert(Codec.encode(s)))~=nil, kind .. ': completed canonical save roundtrip')
                assert(Retail.commit(s,c.id,change))
                expect(#s.histories.retail==1 and Inventory.available(s,pid)==beforeStock-quantity, kind .. ': exactly once')
            end
        end
        -- Releasing unopened canonical goods must not invoke wallet handling.
        local cancelled=State.new(2); cancelled.phase='service'
        assert(Retail.begin(cancelled,'cancel:'..kind)); assert(Portions.target(cancelled,'cancel:'..kind,pid,quantity))
        cancelled.retail.lines[1].type=kind
        expect(Retail.cancel(cancelled,'cancel:'..kind), kind .. ': stock cancellation')
        expect(not cancelled.retail and next(cancelled.reservations)==nil, kind .. ': release reservations')
    end
    assert(Order.is_goods({}) and Order.is_goods({type='item'}), 'Legacy/item classification')
    for _, kind in ipairs({'weigh','repack','pour'}) do assert(Order.is_goods({type=kind}) and not Order.is_wallet({type=kind})) end
    for _, kind in ipairs({'cash_in','cash_out'}) do assert(Order.is_wallet({type=kind}) and not Order.is_goods({type=kind})) end
    assert(not Order.is_goods({type='cashin'}) and not Order.is_wallet({type='cashin'}), 'Unknown names cannot become wallet or goods')
    assert(#failures==0,table.concat(failures,'\n'))
end
