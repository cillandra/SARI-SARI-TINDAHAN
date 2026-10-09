-- Shared integer target conversion and data-backed bag/bottle choices; no mutations.
local Validate = require('src.model.validate')
local M = {}
local MAX_INTEGER = 9007199254740991

function M.resolve(price, product, value, mode)
    if not product or not Validate.positive(value) or not Validate.positive(price) then
        return nil, 'Invalid measured target'
    end
    if mode == 'quantity' then return value end
    if mode ~= 'peso' then return nil, 'Unknown target mode' end
    if value > math.floor(MAX_INTEGER / product.priceQuantity) then
        return nil, 'Measured target is too large'
    end
    local quantity = math.floor(value * product.priceQuantity / price + 0.5)
    if not Validate.positive(quantity) then return nil, 'Target is too small' end
    return quantity
end

function M.options(state, product, kind)
    local result = {}
    local price = state.prices[product.id]
    local function add(mode, value)
        local quantity = M.resolve(price, product, value, mode)
        if not quantity then return end
        local amount = mode == 'peso' and value
            or math.floor((price * quantity + product.priceQuantity * 50)
                / (product.priceQuantity * 100)) * 100
        if amount <= 0 then return end
        result[#result + 1] = {requestMode=mode,requestValue=value,
            quantity=quantity,amount=amount}
    end
    for _, value in ipairs(product.requestSizes or product.portionSizes) do
        add('quantity', value)
    end
    if kind == 'repack' or kind == 'pour' then
        for _, value in ipairs(product.pesoPortions) do add('peso', value) end
    end
    return result
end
return M
