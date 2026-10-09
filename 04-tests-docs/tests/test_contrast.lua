-- Catch incorrect sRGB luminance conversion in the screenshot metric.
return function()
    assert(love.filesystem.getInfo('tools/check_contrast.lua'),'D4 contrast checker missing')
    local C=require('tools.check_contrast')
    assert(math.abs(C.luminance(1,1,1)-1)<.000001)
    assert(C.luminance(0,0,0)==0)
    assert(math.abs(C.luminance(1,0,0)-.2126)<.000001)
    assert(math.abs(C.luminance(.5,.5,.5)-.21404114048)<.000001)
end
