local Check={}
function Check.run()
 local App=require('src.app')
 local ok,err=require('src.ui.navigation').validate(App.availableViews(),require('data.tuning').features)
 if not ok then print('NAVIGATION FAIL '..err); return 1 end
 print('NAVIGATION PASS four ordered props; keys 1-5; Day2 phone enabled; deferred destinations disabled')
 return 0
end
return Check
