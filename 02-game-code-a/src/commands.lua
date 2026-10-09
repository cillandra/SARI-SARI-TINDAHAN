-- Purpose: sole future view mutation gateway and last-200 diagnostic ring. API: execute(s,name,...) -> true or nil,error; history(s) -> copy. Dependencies: domain systems/state/validate/products.
local R=require('src.systems.retail'); local I=require('src.systems.inventory'); local P=require('src.systems.reputation'); local V=require('src.model.validate'); local S=require('src.model.state'); local Products=require('data.products'); local Commands={}
local Portions=require('src.systems.portions'); local Days=require('src.systems.days'); local Customers=require('src.systems.customers')
local Actions=require('src.systems.service_actions')
local handlers={resetPortion=Portions.reset,exchangeBarya=require('src.systems.restock').exchange,wrongItem=Actions.wrong_item,acceptWallet=Actions.accept,rejectWallet=Actions.reject,confirmPayment=require('src.systems.payment').confirm,stageWallet=require('src.systems.tindapay').add,discardPortion=Portions.discard,targetPortion=Portions.target,adjustPortion=Portions.adjust,confirmPortion=Portions.confirm,prepack=Portions.prepack,prepareDay=Days.prepare,openDay=Days.open,closeDay=Days.close,nextDay=Days.next,retryDay=Days.retry,beginRetail=R.begin,addRetail=R.add,removeRetail=R.remove,stageTender=R.stageTender,commitRetail=R.commit,cancelRetail=R.cancel,purchase=I.purchase,adjustReputation=P.adjust}
handlers.setPrice=function(s,id,price)
 if s.phase~='preparation' then return nil,'Price changes require preparation' end
 if not Products.byId[id] or not V.positive(price) then return nil,'Invalid product or price' end
 s.prices[id]=price; return true
end
handlers.setPaused=function(s,value) if type(value)~='boolean' then return nil,'Pause must be boolean' end; s.paused=value; return true end
handlers.newRun=function(s,seed) local ok,fresh=pcall(S.new,seed); if not ok then return nil,fresh end; for key in pairs(s) do s[key]=nil end; for key,value in pairs(fresh) do s[key]=value end; return Days.prepare(s) end
handlers.purchasePlanned=function(s,id,quantity)
 local quote,errorMessage=I.purchaseQuote(s,id,quantity)
 if not quote then return nil,errorMessage end
 local payment,why=require('src.systems.cash').plan(s,quote.cost)
 if not payment then return nil,why end
 return I.purchase(s,id,quantity,payment)
end
handlers.stepPrice=function(s,id,delta)
 if not V.signed(delta) or not Products.byId[id] or not V.positive(s.prices[id]) then return nil,'Invalid price adjustment' end
 return handlers.setPrice(s,id,s.prices[id]+delta)
end
handlers.cancelCurrentCustomer=function(s,id)
 if not s.queue[1] or s.queue[1].id~=id or not s.retail or s.retail.id~=id then return nil,'No active sale for the current customer' end
 local ok,err=R.cancel(s,id)
 if not ok then return nil,err end
 table.remove(s.queue,1)
 s.serviceOutcomes.timedOut=s.serviceOutcomes.timedOut+1
 return true
end
function Commands.execute(s,name,...)
 local args={...}; local handler=handlers[name]; local ok,err
 if handler then ok,err=handler(s,unpack(args)) else err='Unknown command: '..tostring(name) end
 s.commandHistory=s.commandHistory or {}; local h=s.commandHistory; h[#h+1]={name=tostring(name),args=S.clone(args),day=s.day,time=s.time.elapsed,success=ok==true,error=err}; if #h>200 then table.remove(h,1) end
 return ok,err
end
function Commands.history(s) return S.clone(s.commandHistory or {}) end
return Commands


