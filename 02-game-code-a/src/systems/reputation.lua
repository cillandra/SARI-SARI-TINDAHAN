-- Purpose: bounded reputation. API: adjust(s,integer delta) -> true or nil,error. Dependencies: tuning/validate.
local T=require('data.tuning'); local V=require('src.model.validate'); local P={}
function P.adjust(s,d) if type(d)~='number' or not V.nonnegative(math.abs(d)) then return nil,'Invalid reputation delta' end; s.reputation=math.max(T.reputationMin,math.min(T.reputationMax,s.reputation+d)); return true end
return P
