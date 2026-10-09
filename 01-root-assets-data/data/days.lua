-- Purpose: ten situations and rotation metadata. API: list/byId/endlessRotation. Dependencies: none.
-- Integer basis points express rates/multipliers; future systems interpret these flags.
local list = {
    {id="opening",name="Opening",hint="Stock a small mix and keep coins ready."},
    {id="school_rush",name="School rush",hint="Prepare small snacks and coins.",arrivalMultiplierBasisPoints=11500},
    {id="rice_tingi",name="Rice and tingi",hint="Prepare measured bags before opening."},
    {id="barya_shortage",name="Barya shortage",hint="Exchange coins and fund TindaPay.",cashIn=true,coinSupplyBasisPoints=5000},
    {id="utang",name="Utang",hint="Check trusted suki credit caps.",credit=true,repayment=true},
    {id="supplier_increase",name="Supplier price increase",hint="Review wholesale prices and cash-out funds.",cashOut=true,supplierMultiplierBasisPoints=11000},
    {id="payday",name="Payday",hint="Prepare larger baskets and wallet funds.",repayment=true,walletDemandBasisPoints=2000,maxLines=3},
    {id="rain",name="Rain",hint="Stock essentials; expect slower arrivals.",weather="rain",arrivalMultiplierBasisPoints=8500},
    {id="brownout",name="Brownout",hint="Buy ice for cold stock; wallet is unavailable.",weather="brownout",walletOutage=true,iceAvailable=true},
    {id="fiesta",name="Fiesta",hint="Prepare drinks and snacks for the rush.",milestone=true,arrivalMultiplierBasisPoints=12000}
}
local byId = {}
for number, day in ipairs(list) do
    day.number=number; day.arrivalMultiplierBasisPoints=day.arrivalMultiplierBasisPoints or 10000
    day.supplierMultiplierBasisPoints=day.supplierMultiplierBasisPoints or 10000
    day.walletDemandBasisPoints=day.walletDemandBasisPoints or 1000
    day.ordinaryRetail=true; byId[day.id]=day
end
local mvpProfiles={
 {id='opening',name='Opening',hint='Stock a small mix and keep coins ready.',maxLines=1},
 {id='snacks',preferred={'candy','crackers','instant_coffee'},name='Snacks',hint='Serve small snack orders.',maxLines=2},
 {id='rice',preferred={'rice_regular'},name='Rice',hint='Weigh rice to the requested amount.',maxLines=2},
 {id='repack',preferred={'cooking_oil','sugar'},name='Oil and sugar',hint='Prepare measured oil and sugar bags.',maxLines=2},
 {id='baskets',name='Larger baskets',hint='Serve up to three stocked items.',maxLines=3}
}
for _,profile in ipairs(mvpProfiles) do
 profile.arrivalMultiplierBasisPoints=10000
 profile.supplierMultiplierBasisPoints=10000
 profile.ordinaryRetail=true
end
return {mvpProfiles=mvpProfiles,list=list,byId=byId,endlessRotation={"opening","school_rush","rice_tingi","payday","rain","brownout","fiesta"}}



