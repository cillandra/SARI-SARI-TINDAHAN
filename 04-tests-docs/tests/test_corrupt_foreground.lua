-- Regression: a corrupt counter foreground must keep the procedural scene usable.
return function()
    local module_name = 'src.ui.counter_layout'
    local previous = package.loaded[module_name]
    local decode = love.image.newImageData
    local path = require('data.assets').byId.scene_counter_fg.path
    local corrupt = love.filesystem.newFileData('invalid PNG bytes', 'corrupt.png')
    love.image.newImageData = function(source, ...)
        if source == path then return decode(corrupt) end
        return decode(source, ...)
    end
    package.loaded[module_name] = nil
    local ok, layout = pcall(require, module_name)
    love.image.newImageData = decode
    package.loaded[module_name] = previous
    corrupt:release()
    assert(ok, 'Corrupt foreground must fall back instead of crashing: ' .. tostring(layout))
    assert(layout.COUNTER_TOP_Y == 470, 'Procedural counter edge must remain usable')
    assert(#layout.list() == 4, 'Fallback must keep all four prop targets')
end
