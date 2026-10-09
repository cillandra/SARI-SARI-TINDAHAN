-- Independent retained headless regression for rejected aggregate-money overflow.
package.path='C:/04 Programming Language Lua/?.lua;'..package.path
local function equal(a,b)
 if type(a)~=type(b) then return false end
 if type(a)~='table' then return a==b end
 for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
 for k in pairs(b) do if a[k]==nil then return false end end
 return true
end
function love.load()
 local S=require('src.model.state'); local R=require('src.systems.retail'); local V=require('src.model.validate')
 local s=S.new(1); s.phase='service'; s.ledger.retailRevenue=9007199254740900
 assert(V.nonnegative(s.ledger.retailRevenue)); assert(R.begin(s,'overflow')); assert(R.add(s,'overflow','candy',1))
 assert(R.stageTender(s,'overflow',{[100]=1})); local before=S.clone(s)
 local ok,err=R.commit(s,'overflow',{})
 assert(ok==nil and type(err)=='string','overflow must return readable rejection')
 assert(V.nonnegative(s.ledger.retailRevenue),'original revenue must remain safe')
 assert(equal(s,before),'rejected direct retail command must preserve entire state')
 print('PASS independent overflow rejection: '..err..'; entire state unchanged')
 love.event.quit(0)
end
