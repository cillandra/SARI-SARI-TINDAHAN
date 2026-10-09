return function()
 local Shadow=require('src.ui.contact_shadow')
 assert(type(Shadow.opacity)=='function','Contact shadow must expose a soft radial falloff')
 local peak=require('data.tuning').ui.shadowOpacity
 assert(Shadow.opacity(0)==peak and Shadow.opacity(1)==0 and Shadow.opacity(2)==0)
 assert(Shadow.opacity(.5)>0 and Shadow.opacity(.5)<peak)
 local Support=require('src.ui.shader_support')
 local result,reason=Support.create(function() error('unsupported shader') end,'source')
 assert(result==false and reason:find('unsupported shader',1,true))
 assert(Support.create(function(source) return source end,'compiled')=='compiled')
end
