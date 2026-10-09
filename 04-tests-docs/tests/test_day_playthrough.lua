return function()
 assert(love.filesystem.getInfo('tests/support/day_playthrough.lua'),'M3 requires an executable twelve-day scenario')
 local Play=require('tests.support.day_playthrough');local Save=require('src.persistence.save');local Codec=require('src.persistence.codec')
 local Memory=require('tests.support.memory_disk')
 for _,seed in ipairs({1,42}) do
  local uninterrupted=Play.run(Save.new(Memory.new(),'twelve-days'),seed,12,false)
  local resumed=Play.run(Save.new(Memory.new(),'resume-days'),seed,12,true)
  assert(#uninterrupted.reports==12 and #resumed.reports==12)
  assert(Codec.encode(uninterrupted.app.state)==Codec.encode(resumed.app.state),'Save/resume must preserve full state for seed '..seed)
  assert(uninterrupted.app.state.dayProfile.id=='ordinary_endless')
  assert(uninterrupted.app.state.dayProfile.arrivalMultiplierBasisPoints==12500)
  for _,result in ipairs({uninterrupted,resumed}) do
   assert(result.coverage.scams>0,'Twelve-day player must encounter and reject an actual generated scam')
   assert(result.coverage.exchanges>0 and result.coverage.coinDays==5,'Days8-12 must exercise coin scarcity and actual equal-value exchange')
   assert(result.coverage.events.rain and result.coverage.events.payday and result.coverage.events.fiesta,'Teaching events must occur during the continuous run')
   for _,kind in ipairs({'item','cash_in','cash_out','weigh','repack','pour'}) do
    assert(result.coverage.lineTypes[kind] and result.coverage.lineTypes[kind]>0,'Continuous play must exercise '..kind)
   end
  end
  print('PLAYTHROUGH SEED '..seed..' PASS twelve days; continuous/resumed state identical; scams='..uninterrupted.coverage.scams..'; exchanges='..uninterrupted.coverage.exchanges)
 end
end
