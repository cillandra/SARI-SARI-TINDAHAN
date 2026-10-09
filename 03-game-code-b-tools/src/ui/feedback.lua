-- Purpose: cosmetic placement pop and optional quiet sound hook.
-- API: new() -> feedback with place(productId),update(dt),scale(productId,reducedMotion),setSound(optionalSource).
-- Dependencies: optional injected audio Source only. Never changes run state.
local Feedback = {}
function Feedback.new()
    local feedback = {remaining=0,productId=nil,sound=nil}
    -- A centralized media loader may inject an optional Source; absent media stays silent.
    function feedback:setSound(source)
        self.sound=nil
        if source then
            local ok=pcall(function() source:setVolume(0.18) end)
            if ok then self.sound=source end
        end
    end
    function feedback:place(productId)
        self.productId=productId
        self.remaining=0.24
        if self.sound then pcall(function() self.sound:stop(); self.sound:play() end) end
    end
    function feedback:update(dt) self.remaining=math.max(0,self.remaining-dt) end
    function feedback:scale(productId,reducedMotion)
        if reducedMotion or self.productId~=productId or self.remaining<=0 then return 1 end
        return 1+0.065*math.sin(math.pi*self.remaining/0.24)
    end
    return feedback
end
return Feedback