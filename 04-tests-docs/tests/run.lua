local suite={'tests.test_presentation_readiness','tests.test_peso_requests','tests.test_pouring','tests.test_measured_tolerance','tests.test_events','tests.test_day_presentation','tests.test_service_actions','tests.test_payment_outcomes','tests.test_suki_loss','tests.test_customer_flow','tests.test_level_generation','tests.test_canonical_goods','tests.test_reservation_safety','tests.test_save_references','tests.test_corrupt_foreground','tests.test_held_input','tests.test_tindapay','tests.test_random_orders','tests.test_debug_overlay','tests.test_day_playthrough','tests.test_sukli','tests.test_cabinet','tests.test_smoke_selection','tests.test_timbangan','tests.test_order_card','tests.test_visual_fallback','tests.test_hud','tests.test_contrast','tests.test_full_bleed','tests.test_portion_discard','tests.test_pause_controls','tests.test_catalog','tests.test_state','tests.test_retail','tests.test_portions','tests.test_days','tests.test_prep','tests.test_save','tests.test_color','tests.test_save_schema','tests.test_save_app','tests.test_navigation','tests.test_counter_layout','tests.test_asset_rules'}
return function()
 local passed,failed=0,0
 for _,name in ipairs(suite) do
  local ok,err=pcall(function() require(name)() end)
  if ok then passed=passed+1; print('PASS '..name) else failed=failed+1; print('FAIL '..name..': '..tostring(err)) end
 end
 print(string.format('%d suites passed, %d failed',passed,failed))
 return failed==0 and 0 or 1
end
