-- Measured lines reserve targets until adjusted; confirmation never consumes stock.
local Inventory = require('src.systems.inventory')
local Retail = require('src.systems.retail')
local State = require('src.model.state')
local Validate = require('src.model.validate')
local Products = require('data.products')
local Cash = require('src.systems.cash')
local Progress=require('src.systems.line_progress')
local Levels=require('data.levels')
local Tuning=require('data.tuning')
local Config=require('data.config')
local Actions=require('src.systems.measured_actions')
local Requests=require('src.systems.measured_requests')
local Portions = {}
function Portions.bounds(state,target)
 local tolerance=state.mvp and Levels.get(state.day).tolerance
 if not tolerance then return target,target+Tuning.portionTolerance end
 local radius=math.floor(target*tolerance)
 return math.max(1,target-radius),target+radius
end
local function line(state, id, index)
    if state.phase~='service' or state.paused then return nil,'Pour during unpaused service' end
    local sale = state.retail
    if not sale or sale.id ~= id or sale.tender then return nil, 'No editable sale' end
    local item = sale.lines[index]
    if not item or not item.measured or item.confirmed then return nil, 'No editable measured line' end
    if not Validate.positive(item.targetQuantity) or not Validate.nonnegative(item.actualQuantity) then
        return nil, 'Measured quantities are inconsistent'
    end
    local reservation, err = Inventory.check_reservation(state, item.reservation,
        item.productId, math.max(item.targetQuantity, item.actualQuantity))
    if not reservation then return nil, err end
    return item
end
function Portions.target(state, id, productId, value, mode)
    local product = Products.byId[productId]
    if not product or product.saleUnit == 'piece' or not Validate.positive(value) then return nil, 'Invalid measured target' end
    mode = mode or 'quantity'
    if mode ~= 'quantity' and mode ~= 'peso' then return nil, 'Unknown target mode' end
    local price = state.prices[productId]
    local quantity, why = Requests.resolve(price,product,value,mode)
    if not quantity then return nil,why end
    -- A saved customer keeps the original quoted target even if prices later differ.
    if state.mvp and state.queue[1] and state.queue[1].id==id then
        for _,request in ipairs(state.queue[1].lines) do
            if request.productId==productId then
                if (request.requestMode or 'quantity')~=mode
                    or (request.requestValue or request.quantity)~=value then
                    return nil,'Target must match the requested order'
                end
                quantity=request.quantity;break
            end
        end
    end
    local ok, err = Retail.add(state, id, productId, quantity)
    if not ok then return nil, err end
    local sale = state.retail
    local item = sale.lines[#sale.lines]
    if mode == 'peso' then
        local total = sale.total - item.amount + value
        if not Validate.nonnegative(total) then Retail.remove(state,id,#sale.lines); return nil,'Invalid quoted total' end
        sale.total = total
        item.amount = value
    end
    item.targetQuantity = quantity
    item.requestMode = mode
    item.requestValue = value
    item.actualQuantity = 0
    return true
end
function Portions.adjust(state, id, index, quantity, openedSpoilage)
    local item, err = line(state, id, index)
    if not item then return nil, err end
    if not Validate.nonnegative(quantity) or (openedSpoilage ~= nil and type(openedSpoilage) ~= 'boolean') then return nil, 'Invalid measured quantity' end
    if item.spillLocked then return true,'spilled' end
    local limit=item.targetQuantity+math.floor(item.targetQuantity*Config.pouring.spill_basis_points/10000)
    local spilling=state.mvp and item.productId=='cooking_oil' and quantity>limit and quantity>item.actualQuantity
    -- Stop at the first whole unit beyond the boundary, independent of frame size.
    local poured=spilling and limit+1 or quantity
    local reserved=math.max(item.targetQuantity,poured)
    local reservation=state.reservations[item.reservation]
    if reserved>reservation.quantity+Inventory.available(state,item.productId) then return nil,'Not enough stock' end
    if spilling then return Actions.spill(state,id,index,poured) end
    reservation.quantity = reserved
    item.actualQuantity = quantity
    item.openedSpoilage = item.openedSpoilage or openedSpoilage == true
    return true
end
function Portions.reset(state,id,index)
 local item,err=line(state,id,index);if not item then return nil,err end
 return Actions.reset(state,id,index)
end
function Portions.confirm(state, id, index)
    local item, err = line(state, id, index)
    if not item then return nil, err end
    local modern=state.mvp and Levels.get(state.day).tolerance~=nil
    local lower,upper=Portions.bounds(state,item.targetQuantity)
    if item.actualQuantity<lower then return nil,'Underfilled: reach the green range' end
    if modern and item.actualQuantity>upper then return nil,'Overfilled: return to the green range' end
    -- Confirmed reservations track actual stock; the quoted target and price never change.
    state.reservations[item.reservation].quantity=item.actualQuantity
    if modern then item.measuredWithTolerance=true end
    item.quantity = item.actualQuantity
    item.confirmed = true
    Progress.complete(state,id,item.requestIndex)
    return true
end
function Portions.prepack(state, reference, productId, quantity)
    if state.phase ~= 'preparation' then return nil, 'Prepack during preparation' end
    local product = Products.byId[productId]
    if not product or product.saleUnit == 'piece' or not Validate.string(reference) or not Validate.positive(quantity) then return nil,'Invalid prepack' end
    if state.completedReferences[reference] then return nil,'Reference already used' end
    local staged = State.clone(state)
    local reservation = 'prepack:' .. reference
    local ok, err = Inventory.reserve(staged,reservation,productId,quantity)
    if not ok then return nil,err end
    local consumed,cost,allocations = Inventory.consume(staged,reservation)
    if not consumed then return nil,cost end
    local packedBySource = {}
    for _, allocation in ipairs(allocations) do
        local source = allocation.batch
        local batch = {id='batch:'..staged.ids.nextBatch,quantity=allocation.quantity,totalCost=allocation.cost,
            receivedDay=source.receivedDay,expiresDay=source.expiresDay,prepared=true,prepackReference=reference}
        staged.ids.nextBatch = staged.ids.nextBatch + 1
        packedBySource[source.id] = batch
    end
        -- Keep each split next to its original FIFO position, including fully consumed sources.
    local rebuilt = {}
    local remainingById = {}
    for _,batch in ipairs(staged.inventory[productId]) do remainingById[batch.id]=batch end
    for _,source in ipairs(state.inventory[productId]) do
        if packedBySource[source.id] then rebuilt[#rebuilt+1]=packedBySource[source.id] end
        if remainingById[source.id] then rebuilt[#rebuilt+1]=remainingById[source.id] end
    end
    staged.inventory[productId]=rebuilt
    staged.completedReferences[reference] = {kind='prepack',id=reference,productId=productId,quantity=quantity,cost=cost,day=state.day}
    state.inventory = staged.inventory
    state.ids = staged.ids
    state.completedReferences = staged.completedReferences
    return true
end
-- Cancel one unfinished portion by its immutable reservation reference.
-- Opened contents become FIFO spoilage; every other line and the customer survive.
function Portions.discard(state, id, reference)
    local sale = state.retail
    if not sale or sale.id ~= id or sale.tender then return nil, 'No editable sale' end
    if not Validate.string(reference) then return nil, 'Portion reference required' end
    local index, item
    for n, candidate in ipairs(sale.lines) do
        if candidate.reservation == reference then index, item = n, candidate; break end
    end
    if not item or not item.measured or item.confirmed then return nil, 'No unfinished portion with that reference' end
    if not Validate.positive(item.targetQuantity) or not Validate.nonnegative(item.actualQuantity) then
        return nil, 'Measured quantities are inconsistent'
    end
    local reserved, err = Inventory.check_reservation(state, reference,
        item.productId, math.max(item.targetQuantity, item.actualQuantity))
    if not reserved then return nil, err end
    local staged = State.clone(state)
    if item.openedSpoilage and item.actualQuantity > 0 then
        staged.reservations[reference].quantity = item.actualQuantity
        local ok, cost = Inventory.consume(staged, reference)
        if not ok then return nil, cost end
        staged.ledger.spoilage = staged.ledger.spoilage + cost
    else
        Inventory.release(staged, reference)
    end
    staged.retail.total = staged.retail.total - item.amount
    if not Validate.nonnegative(staged.retail.total) then return nil, 'Invalid remaining basket total' end
    table.remove(staged.retail.lines, index)
    local cash, cashError = Cash.value(staged.drawer)
    if not cash then return nil, cashError end
    local valid, why = Validate.monetaryTotals(staged.ledger, cash, staged.wallet.balance)
    if not valid then return nil, why end
    state.inventory = staged.inventory
    state.reservations = staged.reservations
    state.ledger = staged.ledger
    state.retail = staged.retail
    return true
end
return Portions

