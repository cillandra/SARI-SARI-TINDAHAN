-- Project-local verified temp writes, non-destructive backup rotation and recovery.
local Codec=require('src.persistence.codec')
local Schema=require('src.persistence.schema')
local Save={}
local Native={}
function Native.read(path)
 local file,err=io.open(path,'rb'); if not file then return nil,err end
 local data=file:read('*a'); local closed,why=file:close()
 if not data or not closed then return nil,why or 'Read failed' end
 return data
end
function Native.write(path,data)
 local file,err=io.open(path,'wb'); if not file then return nil,err end
 local written,why=file:write(data)
 if not written then file:close(); return nil,why end
 local flushed,flushError=file:flush()
 local closed,closeError=file:close()
 if not flushed or not closed then return nil,flushError or closeError end
 return true
end
function Native.rename(from,to) return os.rename(from,to) end
function Save.new(disk,path)
 disk=disk or Native
 local serial=0
 local store={canSave=Schema.canSave}
 local function call(name,...)
  local ok,result,err=pcall(disk[name],...)
  if not ok then return nil,tostring(result) end
  return result,err
 end
 local function unique(suffix)
  repeat serial=serial+1 until not call('read',path..suffix..serial)
  return path..suffix..serial
 end
 local function readValid(filename)
  local data,err=call('read',filename)
  if not data then return nil,err or 'Missing save' end
  return Codec.decode(data)
 end
 function store.load()
  local primary,primaryError=readValid(path)
  if primary then return primary end
  local backup,backupError=readValid(path..'.bak')
  if backup then return backup,'Recovered last good backup: '..tostring(primaryError) end
  return nil,'Cannot load checkpoint: '..tostring(primaryError)..'; backup: '..tostring(backupError)
 end
 function store.exists() return store.load()~=nil end
 function store.save(state)
  local data,err=Codec.encode(state); if not data then return nil,err end
  local temporary=unique('.tmp.')
  local written,writeError=call('write',temporary,data)
  if not written then return nil,'Cannot write temporary save: '..tostring(writeError) end
  local verified,verifyError=readValid(temporary)
  if not verified then return nil,'Cannot verify temporary save: '..tostring(verifyError) end
  local diskData=call('read',temporary)
  if diskData~=data then return nil,'Temporary save differs from requested checkpoint' end
  local oldData=call('read',path)
  local oldGood=oldData and Codec.decode(oldData)
  if oldData then
   if oldGood then
    if call('read',path..'.bak') then
     local rotated,rotationError=call('rename',path..'.bak',unique('.bak.archived.'))
     if not rotated then return nil,'Cannot rotate backup: '..tostring(rotationError) end
    end
    local backedUp,backupError=call('rename',path,path..'.bak')
    if not backedUp then return nil,'Cannot preserve previous save: '..tostring(backupError) end
   else
    local archived,archiveError=call('rename',path,unique('.corrupt.archived.'))
    if not archived then return nil,'Cannot preserve corrupt save: '..tostring(archiveError) end
   end
  end
  local promoted,promotionError=call('rename',temporary,path)
  if not promoted then
   if oldGood then call('rename',path..'.bak',path) end
   return nil,'Cannot replace checkpoint; previous good data retained: '..tostring(promotionError)
  end
  return true
 end
 store.write=store.save
 store.read=store.load
 return store
end
local defaultStore
local function default()
 if not defaultStore then
  local source=love and love.filesystem and love.filesystem.getSource() or '.'
  if source:lower():match('%.love$') then source=love.filesystem.getSourceBaseDirectory() end
  defaultStore=Save.new(Native,source..'/saves/checkpoint.tinda')
 end
 return defaultStore
end
Save.canSave=Schema.canSave
function Save.save(state) return default().save(state) end
function Save.load() return default().load() end
function Save.exists() return default().exists() end
Save.write=Save.save
Save.read=Save.load
return Save
