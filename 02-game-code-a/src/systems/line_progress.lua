-- Once-only patience rewards keyed by immutable requested line index.
local Config=require('data.config')
local Levels=require('data.levels')
local Progress={}
function Progress.complete(state,id,index)
 local customer=state.queue[1]
 if not state.mvp or not customer or customer.id~=id or not index or not customer.lines[index] then return end
 customer.lineBonuses=customer.lineBonuses or {}
 if customer.lineBonuses[index] then return end
 customer.lineBonuses[index]=true
 local start=customer.initialPatience or Levels.get(state.day).patience
 customer.patience=math.min(start,customer.patience+Config.line_bonus)
end
return Progress
