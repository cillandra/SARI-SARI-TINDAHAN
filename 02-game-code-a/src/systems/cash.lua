-- Purpose: denomination queries without mutations.
-- API: value(bundle), total(state), canPay(state,bundle,incoming?) -> values/feasibility;
-- available(state,incoming?) -> copied counts or nil,error; plan(state,amount,incoming?) -> exact counts or nil,error.
-- Dependencies: data.tuning, src.model.validate.
local Validate = require('src.model.validate')
local Denominations = require('data.tuning').denominations
local Cash = {}
local allowed = {}
for _, denomination in ipairs(Denominations) do allowed[denomination] = true end

function Cash.value(bundle)
    if type(bundle) ~= 'table' then return nil, 'Money must be denomination counts' end
    local total = 0
    for denomination, count in pairs(bundle) do
        if not allowed[denomination] or not Validate.nonnegative(count) or not Validate.nonnegative(denomination * count) then
            return nil, 'Invalid denomination or count'
        end
        total = total + denomination * count
    end
    if not Validate.nonnegative(total) then return nil, 'Money exceeds integer range' end
    return total
end

function Cash.total(state)
    local total = Cash.value(state.drawer)
    assert(total, 'Invalid drawer')
    return total
end

function Cash.canPay(state, bundle, incoming)
    local total, errorMessage = Cash.value(bundle)
    if not total then return false, errorMessage end
    if incoming then
        local received, why = Cash.value(incoming)
        if not received then return false, why end
    end
    for denomination, count in pairs(bundle) do
        if count > (state.drawer[denomination] or 0) + (incoming and incoming[denomination] or 0) then
            return false, 'Not enough ' .. denomination .. ' centavo pieces'
        end
    end
    return true
end

function Cash.available(state, incoming)
    local total, errorMessage = Cash.value(state.drawer)
    if not total then return nil, errorMessage end
    if incoming then
        local received, why = Cash.value(incoming)
        if not received then return nil, why end
    end
    local counts = {}
    for _, denomination in ipairs(Denominations) do
        counts[denomination] = (state.drawer[denomination] or 0) + (incoming and incoming[denomination] or 0)
    end
    local valid, why = Cash.value(counts)
    if not valid then return nil, why end
    return counts
end

local function gcd(a, b)
    while b ~= 0 do a, b = b, a % b end
    return a
end

function Cash.plan(state, amount, incoming)
    if not Validate.nonnegative(amount) then return nil, 'Payment must be integer centavos' end
    local counts, errorMessage = Cash.available(state, incoming)
    if not counts then return nil, errorMessage end
    if amount == 0 then return {} end
    if amount > Cash.value(counts) then return nil, 'Not enough drawer cash' end
    local denominations, suffixTotal, suffixGcd = {}, {}, {}
    for index = #Denominations, 1, -1 do denominations[#denominations + 1] = Denominations[index] end
    suffixTotal[#denominations + 1], suffixGcd[#denominations + 1] = 0, 0
    for index = #denominations, 1, -1 do
        local denomination = denominations[index]
        suffixTotal[index] = suffixTotal[index + 1] + denomination * counts[denomination]
        suffixGcd[index] = counts[denomination] > 0 and gcd(denomination, suffixGcd[index + 1]) or suffixGcd[index + 1]
    end
    local impossible = {}
    local function search(index, remaining)
        if remaining == 0 then return {} end
        if index > #denominations or remaining > suffixTotal[index] or suffixGcd[index] == 0 or remaining % suffixGcd[index] ~= 0 then return nil end
        local key = index .. ':' .. remaining
        if impossible[key] then return nil end
        local denomination = denominations[index]
        local maximum = math.min(counts[denomination], math.floor(remaining / denomination))
        local minimum = math.max(0, math.ceil((remaining - suffixTotal[index + 1]) / denomination))
        for count = maximum, minimum, -1 do
            local result = search(index + 1, remaining - count * denomination)
            if result then
                if count > 0 then result[denomination] = count end
                return result
            end
        end
        impossible[key] = true
        return nil
    end
    local result = search(1, amount)
    if not result then return nil, 'No exact denomination payment; change quantity or exchange coins' end
    return result
end
return Cash
