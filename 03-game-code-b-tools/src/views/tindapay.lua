-- Screenshot/store comparison and actions; decisions and economics live in systems.
local W=require('src.ui.widgets');local T=require('src.ui.theme');local F=require('src.ui.format')
local H=require('src.views.helpers');local O=require('src.ui.draw.outline');local Customers=require('src.systems.customers')
local V={}
local function pending(a,c,kind)
 if not c then return end
 local quote=a:quote();local staged={}
 for _,line in ipairs(quote and quote.lines or {}) do if line.requestIndex then staged[line.requestIndex]=true end end
 for index,line in ipairs(c.lines) do if line.type==kind and not staged[index] then return line,index end end
end
local function evidence(x,title,record)
 O.rect(x,202,368,245,T.paper,10);W.text(title,x+15,215,23,T.maroon,338)
 local rows={{'Amount',F.money(record.amount)},{'Recipient',record.recipient},{'Reference',record.reference},{'Status',record.status}}
 for i,row in ipairs(rows) do W.text(row[1]..': '..row[2],x+15,251+(i-1)*44,18,T.ink,338) end
end
function V.draw(a)
 local c=Customers.current(a.state);local first
 if c then for _,line in ipairs(c.lines) do if line.type=='cash_in' or line.type=='cash_out' then first=line.type;break end end end
 local tab=a.walletTab or first or 'cash_in'
 W.button('cash_in',328,133,294,52,function() a.walletTab='cash_in' end,tab=='cash_in' and T.mustard or T.paper)
 W.button('cash_out',642,133,294,52,function() a.walletTab='cash_out' end,tab=='cash_out' and T.mustard or T.paper)
 local line,index=pending(a,c,tab)
 if line then
  evidence(32,'Customer screenshot',line.receipt or line.transfer);evidence(432,'Shop transfer record',line.transfer)
  O.rect(832,202,416,245,T.paper,10)
  W.text('Service: '..tab,848,220,22,T.maroon,384);W.text('Principal  '..F.money(line.principal),848,265,22,T.ink,384)
  W.text('Fee  '..F.money(line.fee),848,307,20,T.ink,384)
  local history=a.state.histories.wallet;local last=history[#history]
  W.text(last and ('Recent: '..last.type..' '..F.money(last.principal)) or 'No completed transfers yet.',848,359,18,T.ink,384)
  W.button('I-verify at Tanggapin',432,474,368,52,function() a:addWalletLine(index) end,T.sage)
  W.button('Tanggihan',832,474,416,52,function() a:rejectWalletLine(index) end,T.blush)
 else W.text('No pending '..tab..' request.',350,252,23,T.ink,564,'center');W.text('Verified services remain staged until payment.',350,303,18,T.ink,564,'center') end
 W.text('Hindi sapat ang screenshot lang. Tingnan ang papasok na transfer.',32,536,16,T.maroon,1216,'center')
 W.button('Receive payment >',398,566,484,52,function() a:receive() end,T.mustard)
 H.back(a);H.header(a,'TindaPay','')
end
return V
