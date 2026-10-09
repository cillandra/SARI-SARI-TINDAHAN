-- Purpose: pure frontend color invariants. No economic or drawing state.
return function()
    local Color = require('src.ui.color')
    local original = {0.8,0.4,0.2,0.6}
    local dark = Color.darken(original,0.25)
    assert(dark ~= original and original[1] == 0.8 and original[4] == 0.6, 'color math never changes the palette')
    assert(math.abs(dark[1]-0.6)<0.000001 and math.abs(dark[2]-0.3)<0.000001 and math.abs(dark[3]-0.15)<0.000001, 'darken preserves hue through proportional RGB scaling')
    assert(dark[4] == 0.6, 'alpha is retained')
    local shade = Color.shade(original)
    for i=1,3 do assert(shade[i] >= 0 and shade[i] < original[i], 'outline shade is darker and in normalized range') end
    assert(shade[4] == original[4])
    local black = Color.darken(original,2)
    assert(black[1] == 0 and black[2] == 0 and black[3] == 0)
    local unchanged = Color.darken(original,-1)
    assert(unchanged[1] == original[1] and unchanged[2] == original[2])
    assert(Color.shade({0,0,0})[4] == 1, 'RGB colors gain an opaque alpha')
end