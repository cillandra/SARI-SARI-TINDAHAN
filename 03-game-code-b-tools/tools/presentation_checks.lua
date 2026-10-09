-- Rendered presentation acceptance checks use real callbacks and isolated save I/O.
local W = require('src.ui.widgets')
local Layout = require('src.ui.layout')
local Cash = require('src.systems.cash')
local Inventory = require('src.systems.inventory')
local Save = require('src.persistence.save')
local Memory = require('tests.support.memory_disk')
local M = {}
local function click(a,x,y)
    a:mousepressed(Layout.x+x*Layout.scale,Layout.y+y*Layout.scale,1)
end
function M.run(a,fixture)
    local original_store=a.persistence
    local disk=Memory.new()
    a.persistence=Save.new(disk,'presentation-smoke')
    fixture('preparation-day2-large-text')
    a.state.settings.textScale=1;a.selected='candy';a:draw()
    local before=Cash.total(a.state)
    local stock=Inventory.available(a.state,'candy')
    click(a,890,551)
    assert(Cash.total(a.state)==before-400 and Inventory.available(a.state,'candy')==stock+5)
    assert(Inventory.available(assert(a.persistence.load()),'candy')==stock+5,
        'Rendered purchase writes its completed checkpoint')
    disk.failure='write';a:draw();click(a,890,551)
    assert(a.pendingCheckpoint,'Rendered save failure retains retry flag')
    local paid=Cash.total(a.state);local bought=Inventory.available(a.state,'candy')
    a:draw();click(a,890,551)
    for i,b in ipairs(W.items) do
        if b.x==803 and b.y==525 then W.focus=i;W.key('return');W.key('space') end
    end
    assert(Cash.total(a.state)==paid and Inventory.available(a.state,'candy')==bought,
        'Disabled purchase blocks mouse and keyboard without charging again')
    a:draw();click(a,1090,658)
    assert(a.state.phase=='preparation','Disabled open cannot bypass failed save')
    disk.failure=nil;a:draw();click(a,111,654)
    assert(not a.pendingCheckpoint,'Rendered Save retries only the checkpoint')
    a.selected='cooking_oil';a:draw();click(a,1119,551)
    local model=require('src.ui.timbangan_model').model(a)
    assert(a.view=='timbangan' and model.mode=='pour' and model.target==50,
        'Rendered oil prep enters bottle mode at 50ml')
    local amount=model.actual;a:draw();click(a,1040,666)
    assert(require('src.ui.timbangan_model').model(a).actual==amount and a.view=='timbangan',
        'Disabled confirm cannot seal an empty bottle')
    a:pause();a.pausePanel='settings';a:draw()
    for _,b in ipairs(W.items) do
        assert(not (b.y==258 or b.y==312),'Silent volume and inert difficulty expose no action')
    end
    a:pause();a.persistence=original_store;fixture('counter');a:draw()
    print('PRESENTATION UI CHECK PASS restock save/retry, disabled mouse/keyboard, oil bottle and honest settings')
end
return M
