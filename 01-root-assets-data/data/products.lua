-- Purpose: 36-product catalog. API: list/byId. Dependencies: none.
-- Catalog quantities are base units; cost/price apply to priceQuantity base units.
local Products = {list = {}, byId = {}}
local groups = {
    {"staples", {
        {"rice_regular","Luntian Regular Rice","g",4500,5500,1000,180},
        {"rice_premium","Mayumi Premium Rice","g",5600,7000,1000,180},
        {"cooking_oil","Sinag Cooking Oil","ml",8000,10000,1000,180},
        {"sugar","Ligaya Sugar","g",6400,8000,1000,365},
        {"salt","Dagat Salt","g",2400,3000,1000,365},
        {"flour","Ulap Flour","g",4800,6000,1000,180},
        {"mongo_beans","Bukid Mongo Beans","g",9600,12000,1000,180}}},
    {"canned", {
        {"pancit_canton","Habi Pancit Canton", "piece",1200,1500,1,180},
        {"soup_noodles","Init Soup Noodles", "piece",1000,1300,1,180},
        {"sardines","Alon Sardines", "piece",2000,2500,1,730},
        {"tuna","Layag Tuna", "piece",3200,4000,1,730},
        {"corned_beef","Pista Corned Beef", "piece",4000,5000,1,730},
        {"meat_loaf","Salo Meat Loaf", "piece",2400,3000,1,730},
        {"canned_beans","Ani Canned Beans", "piece",2400,3000,1,730}}},
    {"snacks", {
        {"candy","Kislap Candy", "piece",80,100,1,180},
        {"chewing_gum","Sipa Chewing Gum", "piece",160,200,1,180},
        {"crackers","Lutong Crackers", "piece",600,800,1,180},
        {"biscuits","Merienda Biscuits", "piece",800,1000,1,180},
        {"chips","Saya Chips", "piece",1200,1500,1,180},
        {"peanuts","Kanto Peanuts", "piece",800,1000,1,90}}},
    {"drinks", {
        {"bottled_water","Batis Bottled Water", "piece",1200,1500,1,365},
        {"cola","Siklab Cola", "piece",1600,2000,1,180},
        {"orange_soda","Dalandan Orange Soda", "piece",1600,2000,1,180},
        {"powdered_juice","Kulayan Powdered Juice", "piece",1600,2000,1,365},
        {"instant_coffee","Gising Instant Coffee", "piece",400,500,1,365},
        {"coffee_mix","Umaga Coffee Mix", "piece",800,1000,1,365},
        {"powdered_milk","Duyan Powdered Milk", "piece",800,1000,1,365}}},
    {"household", {
        {"shampoo","Ambon Shampoo", "piece",600,800,1,730},
        {"conditioner","Haplos Conditioner", "piece",600,800,1,730},
        {"bath_soap","Bango Bath Soap", "piece",2000,2500,1,730},
        {"toothpaste","Ngiti Toothpaste", "piece",800,1000,1,730},
        {"detergent","Linis Detergent", "piece",600,800,1,730},
        {"dishwashing","Kusina Dishwashing", "piece",600,800,1,730}}},
    {"essentials", {
        {"eggs","Pugad Eggs", "piece",800,1000,1,14},
        {"candles","Ilaw Candles", "piece",800,1000,1,3650},
        {"matches","Sindihan Matches", "piece",240,300,1,3650}}}
}
local timbangan = {
    rice_regular={slot=1,mode="weigh",label="Bigas"},
    flour={slot=2,mode="repack",label="Harina"},
    sugar={slot=3,mode="repack",label="Asukal"},
    salt={slot=4,mode="repack",label="Asin"},
    cooking_oil={slot=5,mode="pour",label="Mantika"}
}
local looseOrders = {
 rice_regular={min_g=100,max_g=1000,step_g=50},
 flour={min_g=100,max_g=500,step_g=50},
 sugar={min_g=100,max_g=500,step_g=50},
 salt={min_g=50,max_g=250,step_g=50},
 cooking_oil={min_g=50,max_g=1000,step_g=50}
}
for section, group in ipairs(groups) do
    for slot, row in ipairs(group[2]) do
        local measured = row[3] ~= "piece"
        local demand = {}
        for day=1,10 do demand[day] = 1 end
        if measured then demand[3] = 3 end
        if section == 3 then demand[2] = 3; demand[10] = 3 end
        if section == 4 then demand[10] = 3 end
        if section == 6 then demand[8] = 3; demand[9] = 3 end
        local cold = row[1] == "bottled_water" or row[1] == "cola" or row[1] == "orange_soda"
        local p = {id=row[1], name=row[2], category=group[1], icon="product_"..row[1],
            stockUnit=row[3], saleUnit=row[3], cost=row[4], price=row[5], priceQuantity=row[6],
            shelfLifeDays=row[7], portionSizes=measured and {100,250,500,1000} or {1,2,3},
            pesoPortions=measured and {500,1000,2000} or {}, demandByDay=demand,
            unlock={buyDay=1, demandDay=1}, cabinet={section=section,slot=slot},
            timbangan=timbangan[row[1]], cold=cold, brownoutLossBasisPoints=cold and 2500 or 0}
        local order=looseOrders[p.id]
        if order then p.min_g=order.min_g;p.max_g=order.max_g;p.step_g=order.step_g end
        if p.timbangan then p.pesoPortions={1000,2000} end
        if p.timbangan and p.timbangan.mode=='repack' then p.requestSizes={250,500} end
        if p.id=='cooking_oil' then p.portionSizes={50,100};p.requestSizes={50,100} end
        Products.list[#Products.list+1] = p
        Products.byId[p.id] = p
    end
end
return Products

