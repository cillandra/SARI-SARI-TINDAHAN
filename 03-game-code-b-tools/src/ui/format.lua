-- Purpose: display formatting only. API: money(integerCentavos),quantity(integer,unit). Dependencies: none.
local F={}
local function currencyPrefix()
 if not love.graphics then return 'P' end
 local font=love.graphics.getFont()
 return font:hasGlyphs('₱') and '₱' or 'P'
end
function F.money(value) assert(type(value)=='number' and value%1==0,'Money display requires integer centavos'); local sign=value<0 and '-' or ''; value=math.abs(value); return sign..currencyPrefix()..math.floor(value/100)..'.'..string.format('%02d',value%100) end
function F.quantity(value,unit) return tostring(value)..' '..unit end
return F
