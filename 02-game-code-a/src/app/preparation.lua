-- Preparation coordinates committed commands, checkpoint retry and station entry.
-- Economic rules remain in systems; save failures never repeat a completed purchase.
local Station = require('src.app.portion_station')
local M = {}
local function ready(a)
    if a.state.phase ~= 'preparation' or a.state.paused then
        a:notify('Return to morning preparation first.')
        return nil
    end
    if a.pendingCheckpoint then
        a:notify('Use Save shop to retry before another purchase or opening.')
        return nil
    end
    return true
end
local function checkpoint_action(a, command, message, ...)
    if not ready(a) then return nil, 'Preparation is not ready' end
    local ok, err = a:command(command, ...)
    if not ok then return nil, err end
    local saved, why = a:save()
    if not saved then
        a.pendingCheckpoint = true
        a:notify(message .. ' Save failed: ' .. tostring(why)
            .. '. Use Save shop to retry; this action already completed.')
        return true, 'save_failed'
    end
    a:notify(message .. ' Shop saved.')
    return true
end
function M.restock(a, product_id, quantity)
    return checkpoint_action(a, 'purchasePlanned', 'Stock purchased.', product_id, quantity)
end
function M.barya(a)
    return checkpoint_action(a, 'exchangeBarya', 'Bills exchanged for barya.')
end
function M.open(a)
    if not ready(a) then return nil, 'Preparation is not ready' end
    local saved, why = a:save()
    if not saved then
        a.pendingCheckpoint = true
        a:notify('Save failed: ' .. tostring(why) .. '. Use Save shop before opening.')
        return nil, why
    end
    if not a:command('openDay') then return nil, 'Cannot open store' end
    return a:go('counter')
end
function M.portion(a, product_id)
    if not ready(a) then return nil end
    if not Station.select(a, product_id) then return nil end
    return a:go('timbangan')
end
return M
