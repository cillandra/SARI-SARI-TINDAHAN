-- Purpose: full-window scene geometry and cached four-pixel edge quads.
local M = {}
local quads = setmetatable({}, {__mode='k'})
function M.coverage(w,h)
    local scale=math.min(w/1280,h/720)
    local bx=(w/scale-1280)/2
    local by=(h/scale-720)/2
    return {x=-bx,y=-by,w=1280+2*bx,h=720+2*by}
end
local function edge_quads(image)
    if quads[image] then return quads[image] end
    local iw,ih=image:getDimensions()
    local g=love.graphics
    local q={left=g.newQuad(0,0,4,ih,iw,ih),right=g.newQuad(iw-4,0,4,ih,iw,ih),
        top=g.newQuad(0,0,iw,4,iw,ih),bottom=g.newQuad(0,ih-4,iw,4,iw,ih)}
    quads[image]=q;return q
end
function M.draw(record,y)
    local g=love.graphics
    local area=M.coverage(g.getDimensions())
    local image=record.image
    local iw,ih=image:getDimensions()
    local q=edge_quads(image)
    y=y or 0
    g.push('all');g.setColor(1,1,1,1)
    g.draw(image,0,y,0,1280/iw,720/ih)
    if area.x<0 then
        g.draw(image,q.left,area.x,y,0,-area.x/4,720/ih)
        g.draw(image,q.right,1280,y,0,-area.x/4,720/ih)
    end
    if area.y<y then g.draw(image,q.top,area.x,area.y,0,area.w/iw,(y-area.y)/4) end
    local bottom=y+720
    if area.y+area.h>bottom then
        g.draw(image,q.bottom,area.x,bottom,0,area.w/iw,(area.y+area.h-bottom)/4)
    end
    g.pop()
end
return M
