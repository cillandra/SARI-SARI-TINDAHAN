-- Regression: broken stock reservations must reject without crashes or partial mutation.
return function()
    local State = require('src.model.state')
    local Inventory = require('src.systems.inventory')
    local Portions = require('src.systems.portions')
    local Retail = require('src.systems.retail')
    local Customers = require('src.systems.customers')
    local failures = {}
    local function equal(a, b)
        if type(a) ~= type(b) then return false end
        if type(a) ~= 'table' then return a == b end
        for key, value in pairs(a) do if not equal(value, b[key]) then return false end end
        for key in pairs(b) do if a[key] == nil then return false end end
        return true
    end
    local function reject(label, state, action)
        local before = State.clone(state)
        local ran, result, reason = pcall(action)
        if not ran then failures[#failures+1] = label .. ': crashed: ' .. tostring(result)
        elseif result or type(reason) ~= 'string' then failures[#failures+1] = label .. ': must reject with reason'
        elseif not equal(state, before) then failures[#failures+1] = label .. ': changed state on failure' end
    end
    local function portion()
        local state = State.new(1)
        state.phase = 'service'
        assert(Retail.begin(state, 'portion'))
        assert(Portions.target(state, 'portion', 'sugar', 250))
        assert(Portions.adjust(state, 'portion', 1, 300, true))
        return state, state.retail.lines[1].reservation
    end
    for _, operation in ipairs({'adjust', 'confirm', 'cancel', 'discard'}) do
        for _, damage in ipairs({'missing', 'wrong product', 'short', 'negative', 'fractional', 'scalar', 'oversized'}) do
            local state, ref = portion()
            if damage == 'missing' then state.reservations[ref] = nil
            elseif damage == 'wrong product' then state.reservations[ref].productId = 'candy'
            elseif damage == 'short' then state.reservations[ref].quantity = 250
            elseif damage == 'negative' then state.reservations[ref].quantity = -1
            elseif damage == 'scalar' then state.reservations[ref] = 1
            elseif damage == 'oversized' then state.reservations[ref].quantity = 350
            else state.reservations[ref].quantity = 300.5 end
            reject(operation .. ' / ' .. damage, state, function()
                if operation == 'adjust' then return Portions.adjust(state, 'portion', 1, 310, true)
                elseif operation == 'confirm' then return Portions.confirm(state, 'portion', 1)
                elseif operation == 'discard' then return Portions.discard(state, 'portion', ref)
                else return Retail.cancel(state, 'portion') end
            end)
        end
    end
    local state, ref = portion()
    assert(Portions.confirm(state, 'portion', 1))
    assert(Retail.stageTender(state, 'portion', {[2000]=1}))
    state.reservations[ref].quantity = 250
    reject('commit mismatched confirmed quantity', state, function()
        return Retail.commit(state, 'portion', {})
    end)
    state, ref = portion()
    state.mvp = true
    state.queue = {{id='portion', patience=1, lines={}}}
    state.serviceOutcomes = {served=0, timedOut=0}
    state.reservations[ref] = nil
    reject('timeout broken opened reservation', state, function() return Customers.update(state, 2) end)
    state, ref = portion()
    state.reservations.other = 1
    reject('adjust with unrelated scalar reservation', state, function()
        return Portions.adjust(state, 'portion', 1, 310, true)
    end)
    for _, damage in ipairs({'missing inventory', 'unknown product', 'negative quantity', 'fractional quantity', 'missing inventory container', 'scalar reservations', 'invalid batch'}) do
        state = State.new(1)
        assert(Inventory.reserve(state, 'stock', 'candy', 1))
        if damage == 'missing inventory' then state.inventory.candy = nil
        elseif damage == 'unknown product' then state.reservations.stock.productId = 'unknown'
        elseif damage == 'negative quantity' then state.reservations.stock.quantity = -1
        elseif damage == 'missing inventory container' then state.inventory = nil
        elseif damage == 'scalar reservations' then state.reservations = 1
        elseif damage == 'invalid batch' then state.inventory.candy[1].totalCost = -1
        else state.reservations.stock.quantity = 1.5 end
        reject('consume / ' .. damage, state, function() return Inventory.consume(state, 'stock') end)
    end
    -- Valid timeout consumes only opened contents; tender and other customers survive.
    state, ref = portion()
    state.mvp = true
    state.queue = {{id='portion', patience=1, lines={}}, {id='waiting', patience=20, lines={}}}
    state.serviceOutcomes = {served=0, timedOut=0}
    local drawer = State.clone(state.drawer)
    local wallet = state.wallet.balance
    assert(Portions.confirm(state, 'portion', 1))
    -- Timeout begins after the confirmation bonus has been applied.
    state.queue[1].patience = 1
    assert(Retail.stageTender(state, 'portion', {[2000]=1}))
    assert(Customers.update(state, 2))
    assert(Inventory.available(state, 'sugar') == 1700 and state.ledger.spoilage == 1920)
    assert(equal(state.drawer, drawer) and state.wallet.balance == wallet)
    assert(#state.queue == 1 and state.queue[1].id == 'waiting' and state.queue[1].patience == 18.5)
    assert(state.serviceOutcomes.timedOut == 1 and state.serviceOutcomes.served == 0)
    assert(not state.retail and not state.reservations[ref] and state.cancelledRetail.portion)
    assert(#state.histories.retail == 0 and next(state.completedReferences) == nil)
    -- Successful confirmed overfill still consumes its full FIFO quantity exactly once.
    state, ref = portion()
    assert(Portions.confirm(state, 'portion', 1))
    assert(Retail.stageTender(state, 'portion', {[2000]=1}))
    assert(Retail.commit(state, 'portion', {}))
    assert(Retail.commit(state, 'portion', {}))
    assert(Inventory.available(state, 'sugar') == 1700 and state.ledger.costOfGoods == 1920)
    assert(#state.histories.retail == 1 and not state.reservations[ref])
    assert(#failures == 0, table.concat(failures, '\n'))
end
