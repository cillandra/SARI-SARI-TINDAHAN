-- Regression: focus loss and missed release stop held tools without changing a sale.
return function()
    local App = require('src.app')
    local Save = require('src.persistence.save')
    local store = Save.new(require('tests.support.memory_disk').new(), 'held-input')
    local app = App.new(store)
    assert(type(app.focus) == 'function', 'Focus loss must stop held input')
    app.pouring, app.pourRemainder = true, 0.75
    local balance = app.state.wallet.balance
    app:focus(false)
    assert(not app.pouring and app.pourRemainder == 0, 'Focus loss must discard fractional pouring')
    assert(app.state.wallet.balance == balance and not app.state.paused, 'Focus loss must not settle or pause a sale')
    app:focus(true)
    assert(not app.pouring, 'Focus gain must not restart a held tool')
    local mouse_down, keyboard_down = love.mouse.isDown, love.keyboard.isDown
    local mouse, key = false, false
    love.mouse.isDown = function() return mouse end
    love.keyboard.isDown = function() return key end
    local ok, err = pcall(function()
        assert(app:command('prepareDay'))
        assert(app:command('openDay'))
        local customer = app.state.queue[1]
        customer.lines = {{type='item', productId='candy', quantity=1, amount=100,
            measured=false, requestMode='quantity', requestValue=1}}
        customer.total = 100
        app:go('shelves')
        assert(app:beginCabinetPick('candy', 200, 200))
        app:check_held_input()
        app:update(0.5)
        assert(not app.state.retail, 'Missed release must not auto-pick cabinet stock')
        app.pouring, app.pourRemainder = true, 0.5
        app:check_held_input()
        assert(not app.pouring and app.pourRemainder == 0, 'Missed mouse release must stop pouring')
        mouse = true
        app.pouring = true
        app:check_held_input()
        assert(app.pouring, 'A held mouse must keep pouring')
        mouse, key = false, true
        app:check_held_input()
        assert(app.pouring, 'Keyboard hold must keep pouring')
        key = false
        app:check_held_input()
        assert(not app.pouring, 'Missed keyboard release must stop pouring')
    end)
    love.mouse.isDown, love.keyboard.isDown = mouse_down, keyboard_down
    assert(ok, err)
end
