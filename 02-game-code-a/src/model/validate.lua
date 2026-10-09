-- Purpose: shared safe integer and projected money guards.
-- API: nonnegative(n), positive(n), signed(n), string(s) -> boolean;
-- monetaryTotals(ledger,drawerTotal,walletBalance) -> true or nil,error.
-- Dependencies: none.
local Validate = {}
local MAX_SAFE_INTEGER = 9007199254740991

function Validate.nonnegative(n)
    return type(n) == 'number' and n == n and n >= 0
        and n <= MAX_SAFE_INTEGER and n % 1 == 0
end

function Validate.positive(n)
    return Validate.nonnegative(n) and n > 0
end

function Validate.signed(n)
    return type(n) == 'number' and Validate.nonnegative(math.abs(n))
end

function Validate.string(s)
    return type(s) == 'string' and #s > 0
end

-- Validate projected amounts before economic commands publish their changes.
function Validate.monetaryTotals(ledger, drawerTotal, walletBalance)
    if not Validate.nonnegative(drawerTotal) or not Validate.nonnegative(walletBalance) then
        return nil, 'Projected balance exceeds safe integer range'
    end
    for field, value in pairs(ledger) do
        local valid
        if field == 'cashFlow' or field == 'walletTransfers' then
            valid = Validate.signed(value)
        else
            valid = Validate.nonnegative(value)
        end
        if not valid then
            return nil, 'Projected ' .. field .. ' exceeds safe integer range'
        end
    end
    return true
end

return Validate
