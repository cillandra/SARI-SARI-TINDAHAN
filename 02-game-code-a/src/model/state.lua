-- Purpose: serializable run construction. API: State.new/clone. Dependencies: data.products/tuning/customers.
-- Renderer-independent, plain serializable run data. No live transactions are created here.
local Products = require("data.products")
local Tuning = require("data.tuning")
local Customers = require("data.customers")
local Config=require('data.config')
local State = {}
-- Args: valid acyclic plain state/data; returns a recursively independent copy.
function State.clone(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = State.clone(item) end
    return result
end
-- Args: optional integer seed; returns independent run state; asserts invalid seeds.
function State.new(seed)
    if seed == nil then seed = Tuning.defaultSeed end
    assert(type(seed)=="number" and seed%1==0 and seed>=0 and seed<=Tuning.maxSeed, "seed must be an integer from 0 to "..Tuning.maxSeed)
    local state = {schemaVersion=Tuning.schemaVersion,seed=seed,rng={state=seed},day=1,phase="preparation",
        time={elapsed=0,spawnCountdown=Tuning.spawnIntervalSeconds,closing=false},inventory={},
        drawer=State.clone(Config.startingDrawer),wallet={balance=Config.startingWallet},
        debts={},relationships={},completedReferences={},ledger={retailRevenue=0,serviceFees=0,costOfGoods=0,
            operatingCosts=0,spoilage=0,changeLosses=0,cashFlow=0,walletTransfers=0},
        histories={retail={},wallet={},days={},debts={}},shelfLayout={},prices={},queue={},
        reputation=Tuning.startingReputation,ice=false,luckClaimed=false,
        ids={nextBatch=1,nextCustomer=1,nextTransaction=1},
        settings={difficulty=Tuning.difficulty,reducedMotion=Tuning.reducedMotion,textScale=Tuning.textScale,volume=Tuning.volume}}
    for _, product in ipairs(Products.list) do
        state.inventory[product.id]={}
        state.prices[product.id]=product.price
        state.shelfLayout[product.id]=State.clone(product.cabinet)
        local quantity = Tuning.startingStock[product.id]
        if quantity then
            state.inventory[product.id][1]={id="batch:"..state.ids.nextBatch,quantity=quantity,
                totalCost=math.floor(product.cost*quantity/product.priceQuantity+0.5),receivedDay=1,
                expiresDay=1+product.shelfLifeDays,prepared=false}
            state.ids.nextBatch=state.ids.nextBatch+1
        end
    end
    for _, customer in ipairs(Customers.named) do
        state.relationships[customer.id]={trust=customer.initialTrust,visits=0,lastVisitDay=0}
        state.debts[customer.id]={balance=0,entries={}}
    end
    -- Snapshot has the same run fields except morningSnapshot, preventing recursive data.
    state.morningSnapshot=State.clone(state)
    return state
end
return State


