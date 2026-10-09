-- LÖVE boot, rendering and input callbacks delegate to the application.
local app,smoke,runtimeCheck,globalCheck,globalSnapshot,loadingFrames
local function flag(name) for _,v in ipairs(arg or {}) do if v==name then return true end end; return false end
function love.load()
 local seed=os.time();love.math.setRandomSeed(seed);print('RANDOM SEED '..seed)
 if flag('--debug') then require('data.config').debug=true end
 if flag('--m3-check') then love.event.quit(require('tools.day_flow_check').run(arg)); return end
 if flag('--save-check') then love.event.quit(require('tools.save_check').run(arg)); return end
 if flag('--test') then love.event.quit(require('tests.run')()); return end
 if flag('--normalize') then love.event.quit(require('tools.normalize_assets').run()); return end
 if flag('--check-assets') then love.event.quit(require('tools.check_assets').run()); return end
 if flag('--check-contrast') then love.event.quit(require('tools.check_contrast').run(arg)); return end
 if flag('--check-navigation') then love.event.quit(require('tools.check_navigation').run()); return end
 if flag('--smoke') then globalCheck=require('tools.global_check'); globalSnapshot=globalCheck.capture() end
 loadingFrames=0
end
function love.update(dt)
 if loadingFrames then
  loadingFrames=loadingFrames+1
  if loadingFrames<3 then return end
  require('src.ui.assets').preload()
  require('src.ui.contact_shadow').preload()
  require('src.ui.prop_effects').preload()
  local store=flag('--verify-release') and require('src.app.runtime_check').persistence() or nil
  app=require('src.app').new(store)
  if flag('--smoke') then smoke=require('tools.smoke').new(app,arg); smoke.globalSnapshot=globalSnapshot end
  if flag('--verify-release') then runtimeCheck=require('src.app.runtime_check').new(app,arg) end
  loadingFrames=nil
 end
 if not app then return end
 if runtimeCheck then runtimeCheck:update(dt) elseif smoke then smoke:update() else app:check_held_input(); app:update(dt) end
end
function love.draw()
 if loadingFrames then require('src.ui.loading').draw(); return end
 if app then local started=love.timer.getTime(); app:draw(); if runtimeCheck then runtimeCheck:afterDraw(love.timer.getTime()-started) elseif smoke then smoke:afterDraw(); globalCheck.verify(globalSnapshot) end end
end
function love.mousepressed(x,y,b) if app and not smoke and not runtimeCheck then app:mousepressed(x,y,b) end end
function love.mousemoved(x,y) if app and not smoke and not runtimeCheck then app:mousemoved(x,y) end end
function love.mousereleased(x,y,b) if app and not smoke and not runtimeCheck then app:mousereleased(x,y,b) end end
function love.keypressed(key) if app and not smoke and not runtimeCheck then app:keypressed(key) end end
function love.keyreleased(key) if app and not smoke and not runtimeCheck then app:keyreleased(key) end end
function love.focus(focused) if app then app:focus(focused) end end
function love.mousefocus(focused) if app then app:focus(focused) end end
function love.resize(w,h) if app then app:resize(w,h) end end
function love.errorhandler(message)
 local trace=debug.traceback(tostring(message),2); print('ERROR '..trace)
 return function() return 1 end
end
