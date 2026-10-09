-- Purpose: independent serializable state regression suite. API: returned test function. Dependencies: src.model.state.
-- Catches shared mutable runs/clones, unsupported seeds and non-data model values.
return function()
    local ok, State = pcall(require, "src.model.state")
    assert(ok, "state module must exist: " .. tostring(State))
    local a, b = State.new(42), State.new(42)
    assert(a.seed == 42 and a.rng.state == b.rng.state and a.day == 1 and a.phase == "preparation")
    assert(a.morningSnapshot.morningSnapshot == nil, "finite morning snapshot")
    a.morningSnapshot.inventory.rice_regular[1].quantity = 2
    assert(a.inventory.rice_regular[1].quantity == 5000, "snapshot independent")
    local c = State.clone(a)
    c.drawer[100] = 0
    assert(a.drawer[100] > 0 and b.drawer[100] > 0)
    c.inventory.rice_regular[1].quantity = 1
    assert(a.inventory.rice_regular[1].quantity > 1)
    c.shelfLayout.rice_regular.slot = 8
    assert(a.shelfLayout.rice_regular.slot == 1)
    c.relationships.lola_rosa.trust = 99
    assert(a.relationships.lola_rosa.trust ~= 99)
    c.histories.retail[1] = {amount=100}
    assert(#a.histories.retail == 0)
    local seen = {}
    local function data(value)
        local kind = type(value)
        assert(kind == "table" or kind == "number" or kind == "string" or kind == "boolean", "serializable value")
        if kind == "number" then assert(value == value and value ~= math.huge and value ~= -math.huge) end
        if kind == "table" then
            assert(not seen[value] and getmetatable(value) == nil, "acyclic plain tables")
            seen[value] = true
            for k,v in pairs(value) do assert(type(k)=="string" or type(k)=="number"); data(v) end
        end
    end
    data(a)
    for _, bad in ipairs({-1, 0.5, math.huge, "42"}) do assert(not pcall(State.new, bad), "invalid seed rejected") end
    assert(State.new().seed == 1 and State.new(0).seed == 0)
    local total = 0
    for denomination,count in pairs(a.drawer) do assert(count >= 0 and count % 1 == 0); total=total+denomination*count end
    assert(total > 0 and a.wallet.balance > 0 and a.wallet.balance % 1 == 0)
    for _, batches in pairs(a.inventory) do for _, batch in ipairs(batches) do assert(batch.quantity > 0 and batch.quantity % 1 == 0 and batch.totalCost % 1 == 0) end end
end


