-- Catch missing scene extension and accidental source trimming.
return function()
    assert(love.filesystem.getInfo('src/ui/full_bleed.lua'), 'D1 full-window layer geometry missing')
    local B = require('src.ui.full_bleed')
    local cases = {{1024,768,0,120},{1280,720,0,0},{1920,1080,0,0},{2560,1080,640/3,0}}
    for _, c in ipairs(cases) do
        local r = B.coverage(c[1], c[2])
        assert(math.abs(r.x + c[3]) < .001 and math.abs(r.y + c[4]) < .001)
        assert(math.abs(r.w - 1280 - 2*c[3]) < .001)
        assert(math.abs(r.h - 720 - 2*c[4]) < .001)
    end
    local rules = require('src.ui.asset_rules')
    local spec = {id='scene_counter_fg',width=2560,height=1440,fullBleed=true}
    local plan = assert(rules.plan(spec, {width=8000,height=4500,bounds={x=0,y=3130,w=8000,h=1369}}))
    assert(plan.x == 0 and plan.y == 0 and plan.scale == .32, 'Full bleed must retain the entire source canvas')
    local manifest = require('data.assets')
    for _, id in ipairs({'scene_counter_bg_street','scene_counter_bg_interior','scene_counter_fg'}) do
        assert(manifest.byId[id].fullBleed, 'Scene layer requires fullBleed: '..id)
    end
end
