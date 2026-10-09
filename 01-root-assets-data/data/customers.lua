-- Purpose: archetype/named suki data. API: archetypes/named. Dependencies: none.
-- Patience is seconds; tender denominations are centavos. Data only, no spawning.
return {
    archetypes={
        {id="kid",minLines=1,maxLines=2,patience=90,tenders={100,500,1000,2000},loyalty=1,creditEligible=false},
        {id="nanay",minLines=1,maxLines=3,patience=150,tenders={2000,5000,10000},loyalty=2,creditEligible=false},
        {id="tambay",minLines=1,maxLines=2,patience=140,tenders={1000,2000,5000},loyalty=1,creditEligible=false},
        {id="suki",minLines=1,maxLines=3,patience=180,tenders={5000,10000},loyalty=3,creditEligible=true},
        {id="haggler",minLines=1,maxLines=3,patience=160,tenders={2000,5000,10000},loyalty=1,creditEligible=false},
        {id="hurried",minLines=1,maxLines=2,patience=80,tenders={5000,10000},loyalty=1,creditEligible=false}},
    named={
        {id="lola_rosa",name="Lola Rosa",archetype="suki",initialTrust=20,creditCap=20000},
        {id="mang_tomas",name="Mang Tomas",archetype="suki",initialTrust=15,creditCap=15000}}
}

