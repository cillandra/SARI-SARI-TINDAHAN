-- Strict length-prefixed plain-data codec. Format is data, never Lua source.
local Schema=require('src.persistence.schema')
local Codec={}
local MAX_BYTES=4*1024*1024
local MAX_ENTRIES=100000
local function serialize(value)
 local kind=type(value)
 if kind=='number' then return 'n'..string.format('%.17g',value)..';' end
 if kind=='boolean' then return value and 'b1' or 'b0' end
 if kind=='string' then return 's'..#value..':'..value end
 local keys={}; for key in pairs(value) do keys[#keys+1]=key end
 table.sort(keys,function(a,b) if type(a)~=type(b) then return type(a)<type(b) end; return a<b end)
 local result={'t',tostring(#keys),':'}
 for _,key in ipairs(keys) do result[#result+1]=serialize(key); result[#result+1]=serialize(value[key]) end
 return table.concat(result)
end
function Codec.encode(state)
 local valid,err=Schema.validate(state); if not valid then return nil,err end
 local data='TINDA1\n'..serialize(state)
 if #data>MAX_BYTES then return nil,'Save exceeds size limit' end
 return data
end
function Codec.decode(data)
 if type(data)~='string' or #data>MAX_BYTES or data:sub(1,7)~='TINDA1\n' then return nil,'Invalid save data header or size' end
 local cursor=8; local entries=0
 local function length()
  local separator=data:find(':',cursor,true); if not separator then error('Truncated length',0) end
  local token=data:sub(cursor,separator-1)
  if not token:match('^%d+$') or #token>8 then error('Invalid length',0) end
  cursor=separator+1; return tonumber(token)
 end
 local function parse(depth)
  if depth>64 then error('Nesting limit',0) end
  local tag=data:sub(cursor,cursor); cursor=cursor+1
  if tag=='n' then
   local separator=data:find(';',cursor,true); if not separator then error('Truncated number',0) end
   local token=data:sub(cursor,separator-1); cursor=separator+1
   if #token>32 or not token:match('^[%d%+%-%.eE]+$') then error('Invalid number token',0) end
   local number=tonumber(token); if not number or number~=number or math.abs(number)>9007199254740991 then error('Invalid number',0) end
   return number
  elseif tag=='b' then
   local token=data:sub(cursor,cursor); cursor=cursor+1
   if token=='1' then return true elseif token=='0' then return false end
   error('Invalid boolean',0)
  elseif tag=='s' then
   local count=length(); if cursor+count-1>#data then error('Truncated string',0) end
   local result=data:sub(cursor,cursor+count-1); cursor=cursor+count; return result
  elseif tag=='t' then
   local count=length(); entries=entries+count; if entries>MAX_ENTRIES then error('Entry limit',0) end
   local result={}
   for _=1,count do
    local key=parse(depth+1)
    if type(key)~='string' and (type(key)~='number' or key%1~=0 or key<=0) then error('Invalid key',0) end
    if result[key]~=nil then error('Duplicate key',0) end
    result[key]=parse(depth+1)
   end
   return result
  end
  error('Unknown or truncated data token',0)
 end
 local ok,value=pcall(parse,0)
 if not ok then return nil,'Cannot parse save: '..tostring(value) end
 if cursor~=#data+1 then return nil,'Trailing data in save' end
 local valid,err=Schema.validate(value); if not valid then return nil,err end
 return value
end
return Codec
