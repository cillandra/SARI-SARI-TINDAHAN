-- Purpose: provisional game settings. API: returned tuning fields. Dependencies: none.
-- Starting settings are provisional balance values, not simulated balance claims.
return {
    features={utang=false,wallet=true,preparation=false,report_board=false,recovery_art=false,days_6_to_10=false},
    ui={walletPulseScale=.03,walletPulseHz=1, cabinetTooltipSeconds=.4,cabinetHoldSeconds=.35,cabinetDragDistance=8,popTint={default={brightness=1.05,saturation=1.08}},
        veilInterior=.45,veilStreet=.40,backgroundSaturation=.75,outlineWidth=2.5,
        poolOpacity=.35,poolRadius=.9,poolFalloff=2,vignetteOpacity=.14,breathScale=.015,breathHz=.6,
        contrastPass=.12,contrastWarn=.08,contrastRing=20,slotGap=28,counterSideInset=24,customerWidth=260,customerHeight=325,customerClearance=24,customerCounterOverlap=18,queuePortraitScale=.28,counterBandHeight=250,baselineOverlap=10,shadowFalloff=2,shadowOpacity=.35,shadowWidth=.90,shadowHeight=.14,navigationDebounceSeconds=.12,propHoverSeconds=.12,propHoverScale=1.08,propPressScale=.96,lockedOpacity=.55},
    schemaVersion=1, defaultSeed=1, maxSeed=2147483646,
    denominations={100,500,1000,2000,5000,10000,50000,100000},
    startingDrawer={[100]=20,[500]=12,[1000]=10,[2000]=10,[5000]=4,[10000]=4,[50000]=0,[100000]=0},
    startingWallet=50000, startingReputation=50, reputationMin=0, reputationMax=100,
    startingStock={rice_regular=5000,cooking_oil=2000,sugar=2000,pancit_canton=12,sardines=8,candy=30,
        crackers=12,bottled_water=12,instant_coffee=20,shampoo=12,eggs=12,matches=6},
    mvp={measuredQuantity=250,pesoAmount=2000,patienceSeconds=120,endlessSteps=5,rushStepBasisPoints=500},
    dayDurationSeconds=180, queueCap=6, spawnIntervalSeconds=25,
    walletName="TindaPay", walletFee=1000, walletConversionCharge=500,
    creditUnlockDay=5, cashInUnlockDay=2, cashOutUnlockDay=2,
    scoopGrams=50, pourMillilitersPerSecond=100, portionTolerance=5,
    iceCost=2000, iceBrownoutLossBasisPoints=0,
    endless={maxArrivalMultiplierBasisPoints=12500,maxSupplierMultiplierBasisPoints=12000},
    difficulty="normal", reducedMotion=false, textScale=1, volume=0.7
}



