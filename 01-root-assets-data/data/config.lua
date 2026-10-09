-- Diagnostic logging and TindaPay initial resources; never refill on day/load.
local Tuning=require('data.tuning')
return {pouring={base=80,acceleration=40,cap=160,spill_basis_points=1500,spill_penalty=100},event_effects={rain_interval=.7,payday_wallet_weight=2,brownout_patience=.8,brownout_dim=.10},debug=false,patience_max=50,queue_max=3,queue_wait_rate=.5,line_bonus=4,timeout_penalty=8,change_penalty=3,wrong_item_penalty=3,valid_reject_penalty=3,scam_penalty=5,perfect_bonus=2,tip_min_pesos=5,tip_max_pesos=10,
 barya_bundle={[100]=10,[500]=4,[1000]=2},barya_low_keep={[100]=4,[500]=1},restock_quantities={unit=5,loose=1000},
 arrival_start=14,arrival_min=8,arrival_last_day=10,startingWallet=Tuning.startingWallet,startingDrawer=Tuning.startingDrawer,
 tindapay={principalSizes={5000,10000,20000},fee=Tuning.walletFee,storeAccount='store'}}
