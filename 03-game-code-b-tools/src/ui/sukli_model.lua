-- Presentation queries only. The receipt deliberately exposes no change due.
local Cash=require('src.systems.cash')
local TindaPay=require('src.systems.tindapay')
local Retail=require('src.systems.retail')
local M={}
function M.model(a)
 local q=a:quote();local counts=Cash.available(a.state,q and q.tender) or {}
 for d,n in pairs(a.change) do counts[d]=counts[d]-n end
 local selected=Cash.value(a.change) or 0;local due=q and Retail.changeDue(a.state,q.id)
 return {correct=due~=nil and selected==due,receipt={total=q and q.total or 0,tender=q and q.tenderAmount or 0},payout=TindaPay.summary(q).payout,counts=counts,selected=Cash.value(a.change) or 0}
end
return M
