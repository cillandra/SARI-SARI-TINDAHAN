-- Shared presentation for item and fictional wallet order lines; no price calculations.
local Products=require('data.products');local F=require('src.ui.format');local M={}
function M.wallet(line) return line.type=='cash_in' or line.type=='cash_out' end
function M.name(line)
 if M.wallet(line) then return line.type=='cash_in' and 'TindaPay cash_in' or 'TindaPay cash_out' end
 return Products.byId[line.productId].name
end
function M.request(line)
 if M.wallet(line) then return M.name(line)..' '..F.money(line.principal) end
 local p=Products.byId[line.productId]
 return (line.measured and (line.requestMode=='quantity' and line.quantity..' '..p.stockUnit..' ' or F.money(line.amount)..' of ') or line.quantity..' x ')..p.name
end
function M.quantity(line)
 if M.wallet(line) then return F.money(line.principal)..' OK' end
 local p=Products.byId[line.productId];return tostring(line.actualQuantity or line.quantity)..(p.saleUnit=='piece' and ' x' or ' '..p.saleUnit)
end
return M
