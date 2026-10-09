-- Purpose: catalog contract regression suite. API: returned test function. Dependencies: data modules.
-- Catches missing products, inaccessible demand, bad physical units and cabinet collisions.
return function()
    local ok, products = pcall(require, "data.products")
    assert(ok, "catalog module must exist: " .. tostring(products))
    assert(#products.list == 36, "exactly 36 products")
    local ids, slots, counts = {}, {}, {}
    local expectedIds = "rice_regular rice_premium cooking_oil sugar salt flour mongo_beans pancit_canton soup_noodles sardines tuna corned_beef meat_loaf canned_beans candy chewing_gum crackers biscuits chips peanuts bottled_water cola orange_soda powdered_juice instant_coffee coffee_mix powdered_milk shampoo conditioner bath_soap toothpaste detergent dishwashing eggs candles matches"
    local required = {}; for id in expectedIds:gmatch("%S+") do required[id]=true end
    local expected = {staples=7, canned=7, snacks=6, drinks=7, household=6, essentials=3}
    local units = {g=true, ml=true, piece=true}
    for _, p in ipairs(products.list) do
        assert(not ids[p.id] and products.byId[p.id] == p, "unique indexed ID")
        assert(required[p.id], "kit product ID"); ids[p.id] = true
        assert(expected[p.category], "known category")
        counts[p.category] = (counts[p.category] or 0) + 1
        for _, value in ipairs({p.cost, p.price, p.priceQuantity, p.shelfLifeDays}) do
            assert(value > 0 and value % 1 == 0, "positive integer amounts")
        end
        assert(units[p.stockUnit] and units[p.saleUnit], "known units")
        local expectedUnit = p.category == "staples" and (p.id == "cooking_oil" and "ml" or "g") or "piece"
        assert(p.stockUnit == expectedUnit and p.saleUnit == expectedUnit, "product physical unit")
        assert(p.unlock.buyDay == 1, "all buyable day 1")
        local active = false
        for day=1,10 do assert(type(p.demandByDay[day]) == "number" and p.demandByDay[day] >= 0); active = active or p.demandByDay[day] > 0 end
        assert(active, "demand active by day 10")
        assert(#p.portionSizes > 0, "portion sizes")
        for _, size in ipairs(p.portionSizes) do assert(size > 0 and size % 1 == 0) end
        assert(p.cabinet.section >= 1 and p.cabinet.section <= 6 and p.cabinet.slot >= 1 and p.cabinet.slot <= 8)
        assert(p.cabinet.section % 1 == 0 and p.cabinet.slot % 1 == 0, "integer cabinet coordinates")
        local key = p.cabinet.section .. ":" .. p.cabinet.slot
        assert(not slots[key], "cabinet collision"); slots[key] = true
        local asset = require("data.assets").byId[p.icon]
        assert(asset, "icon manifest key")
        assert(asset.path == "assets/img/icon/icon_" .. p.id .. ".png", "kit icon path")
        assert(asset.designSize and asset.designSize.w == 256 and asset.designSize.h == 256 and asset.scale2x == true, "kit 2x icon manifest")
        assert(asset.anchor and asset.anchor.x == 0.5 and asset.anchor.y == 1, "icon anchor")
    end
    for category, count in pairs(expected) do assert(counts[category] == count, category .. " count") end
    local days = require("data.days")
    assert(#days.list == 10 and days.list[9].walletOutage and days.list[10].milestone)
    local customers = require("data.customers")
    assert(#customers.archetypes == 6 and #customers.named >= 2)
end



