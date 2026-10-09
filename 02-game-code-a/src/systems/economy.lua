-- Purpose: nonmutating reports/recovery. API: report(s), needsRecovery(s). Dependencies: cash/inventory/products.
local T=require('data.tuning'); local C=require('src.systems.cash'); local I=require('src.systems.inventory'); local E={}
function E.report(s)
 local l=s.ledger; local r={}; for k,v in pairs(l) do r[k]=v end
 r.tips=l.tips or 0;r.scamLosses=l.scamLosses or 0
 r.profit=r.tips+l.retailRevenue+l.serviceFees-l.costOfGoods-l.operatingCosts-l.spoilage-l.changeLosses-r.scamLosses; r.cash=C.total(s); r.wallet=s.wallet.balance; r.unpaidCredit=0
 for _,d in pairs(s.debts) do r.unpaidCredit=r.unpaidCredit+d.balance end; return r
end
local Levels=require('data.levels')
local State=require('src.model.state')
local Validate=require('src.model.validate')
local function decorate(state,report)
 local day=report.day or state.day;local level=Levels.get(day)
 report.day=day;report.goal=level.goal
 -- The money goal measures real sales and service fees, excluding tips and wallet principal.
 report.earned=report.retailRevenue+report.serviceFees
 report.mistakes=report.mistakes or 0;report.suki=report.suki or state.reputation
 report.losses=report.spoilage+report.changeLosses+(report.scamLosses or 0)
 if not Validate.positive(report.goal) or not Validate.nonnegative(report.earned) or not Validate.nonnegative(report.losses) or not Validate.signed(report.profit) then return nil,'Report totals exceed integer range' end
 report.stars=report.earned<report.goal and 1 or report.mistakes>0 and 2 or 3
 report.nextWarning=Levels.get(day+1).warning
 return report
end
function E.day_report(state)
 local report=E.report(state);local outcomes=state.serviceOutcomes or {}
 report.served=outcomes.served or 0;report.timedOut=outcomes.timedOut or 0
 report.mistakes=outcomes.mistakes or 0;report.scams=outcomes.scams or 0
 return decorate(state,report)
end
function E.summary(state)
 if state.dayReport and (state.phase=='report' or state.phase=='recovery') then
  local report=State.clone(state.dayReport);report.tips=report.tips or 0;report.scamLosses=report.scamLosses or 0
  return decorate(state,report)
 end
 return E.day_report(state)
end
function E.needsRecovery(s)
 if C.total(s)>0 or (not s.mvp and s.wallet.balance>=T.walletConversionCharge+T.denominations[1]) then return false end
 for _,p in ipairs(require('data.products').list) do if I.available(s,p.id)>0 then return false end end; return true
end
return E


