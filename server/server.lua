 local fuelSystem = class("fuelSystem", vRP.Extension)

local function menu_chest_gas_put(self)
    local function m_put_gas(menu, _table)
        local user = menu.user
        local fullid = _table.fullid
        local citem = vRP.EXT.Inventory:computeItem(fullid)
        local fuelAmount = parseInt(self.gasStations[menu.data.id].fuel)

        if citem then
            local i_amount = user:getItemAmount(fullid)
            local amount = parseInt(user:prompt(lang.inventory.chest.put.prompt({i_amount}), ""))
            local price = tonumber(user:prompt("Введите цену", ""))
            if amount >= 0 and amount <= i_amount and user:tryTakeItem(fullid, amount, true) then
                if string.find(fullid, "fuel") then
                    -- chest weight check
                    local items = {
                        ["fuel"] = fuelAmount
                    }
                    local new_amount = (fuelAmount or 0)+amount
                    local new_weight = vRP.EXT.Inventory:computeItemsWeight(items)+citem.weight*amount
                    if new_weight <= 5000 then
                        if new_amount > 0 then
                            fuelAmount = new_amount
                        else
                            fuelAmount = nil
                        end
                        if menu.data.cb_in then menu.data.cb_in(menu.data.id, fullid, amount) end

                        user:tryTakeItem(fullid, amount)
                        self.gasStations[_table.id].fuel = fuelAmount
                        self.gasStations[_table.id].price =  price
                        user:actualizeMenu()
                    else
                        vRP.EXT.Base.remote._notify(user.source,lang.inventory.chest.full())
                    end
                else
                    vRP.EXT.Base.remote._notify(user.source,"На заправке продается только бензин")
                end
            else
                vRP.EXT.Base.remote._notify(user.source,lang.common.invalid_value())
            end
        end
    end

    vRP.EXT.GUI:registerMenuBuilder("gas.chest.put", function(menu)
        menu.title = "Положить на склад"
        menu.css.header_color = "rgba(0,255,125,0.75)"

        -- add weight info
        local weight = menu.user:getInventoryWeight()
        local max_weight = menu.user:getInventoryMaxWeight()
        local hue = math.floor(math.max(125*(1-weight/max_weight), 0))
        menu:addOption("<div class=\"dprogressbar\" data-value=\""..string.format("%.2f",weight/max_weight).."\" data-color=\"hsl("..hue..",100%,50%)\" data-bgcolor=\"hsl("..hue..",100%,25%)\" style=\"height: 12px; border: 3px solid black;\"></div>", nil, lang.inventory.info_weight({string.format("%.2f",weight),max_weight}))

        -- add user items
        for fullid,amount in pairs(menu.user:getInventory()) do
            local citem = vRP.EXT.Inventory:computeItem(fullid)
            if citem then
                menu:addOption(htmlEntities.encode(citem.name), m_put_gas, lang.inventory.iteminfo({amount,citem.description,string.format("%.2f", citem.weight)}),{fullid = fullid, id = menu.data.id})
            end
        end
    end)
end


local function menu_chest_gas_take(self)
    local function m_take_gas(menu, table)
        local user = menu.user
        local i_amount = self.gasStations[table.id].fuel
        local amount = parseInt(user:prompt(lang.inventory.chest.take.prompt({i_amount}), ""))
        local weight = vRP.EXT.Inventory:computeItem(table.item).weight*amount
        if amount >= 0 and amount <= i_amount and weight < (user:getInventoryMaxWeight() - user:getInventoryWeight()) then
            user:tryGiveItem(table.item, amount)
            user:closeMenu()

            self.gasStations[table.id].fuel = i_amount - amount

        else
            vRP.EXT.Base.remote._notify(user.source,lang.common.invalid_value())
        end
    end

    vRP.EXT.GUI:registerMenuBuilder("gas.chest.take", function(menu)
        menu.title = "Взять со склада"
        menu.css.header_color = "rgba(0,255,125,0.75)"
        local items = {
            ["fuel"] = parseInt(vRP.EXT.fuelSystemBase:getFuel(menu.data.id)),
        }
        local weight = vRP.EXT.Inventory:computeItemsWeight(items)
        local hue = math.floor(math.max(125*(1-weight/5000), 0))
        menu:addOption("<div class=\"dprogressbar\" data-value=\""..string.format("%.2f",weight/5000).."\" data-color=\"hsl("..hue..",100%,50%)\" data-bgcolor=\"hsl("..hue..",100%,25%)\" style=\"height: 12px; border: 3px solid black;\"></div>", nil, lang.inventory.info_weight({string.format("%.2f",weight),5000}))

        -- add chest items
        for k, v in pairs(items) do
        local citem = vRP.EXT.Inventory:computeItem(k)
            if v > 0 then
                menu:addOption(htmlEntities.encode(citem.name), m_take_gas, citem.description.."<br><br>"..v.."<br><br>Вес: "..citem.weight, {id = menu.data.id, amount = v, item = k})
            end
        end
    end)
end

local function menu_chest_gas_take_money(self)
    local function m_take_gas_money(menu, table)
        local user = menu.user
        local i_amount = table.amount or 0
        local amount = parseInt(user:prompt(lang.inventory.chest.take.prompt({i_amount}), ""))
        if amount >= 0 and amount <= i_amount then
            user:tryGiveItem(table.item, amount)
            user:closeMenu()
            if table.item == "money" then
                local cents = parseInt((self.gasStations[table.id]["money"])%1*100)
                self.gasStations[table.id]["money"] = tonumber((i_amount - amount).."."..cents)
            elseif table.item == "cents" then
                local money = self.gasStations[table.id]["money"]
                self.gasStations[table.id]["money"] = tonumber(money.."."..(i_amount - amount))
            end
        else
            vRP.EXT.Base.remote._notify(user.source,lang.common.invalid_value())
        end
    end

    vRP.EXT.GUI:registerMenuBuilder("gas.chest.take.money", function(menu)
        menu.title = "Забрать выручку"
        menu.css.header_color = "rgba(0,255,125,0.75)"
        local items = {
            ["money"] = parseInt(menu.data.money),
            ["cents"] = parseInt((menu.data.money)%1*100)
        }
        -- add chest items
        for k, v in pairs(items) do
        local citem = vRP.EXT.Inventory:computeItem(k)
            if v > 0 then
                menu:addOption(htmlEntities.encode(citem.name), m_take_gas_money, citem.description.."<br>"..v, {id = menu.data.id, amount = v, item = k})
            end
        end
    end)
end

local function menu_gas_station(self)
    local function m_take_gas(menu)
        local smenu = menu.user:openMenu("gas.chest.take", menu.data) -- pass menu chest data
        menu:listen("remove", function(menu)
            menu.user:closeMenu(smenu)
        end)
    end
    local function m_take_money_gas(menu)
        local smenu = menu.user:openMenu("gas.chest.take.money", menu.data) -- pass menu chest data
        menu:listen("remove", function(menu)
            menu.user:closeMenu(smenu)
        end)
    end

    local function m_put_gas(menu)
        local smenu = menu.user:openMenu("gas.chest.put", menu.data) -- pass menu chest data
        menu:listen("remove", function(menu)
            menu.user:closeMenu(smenu)
        end)
    end
 
    vRP.EXT.GUI:registerMenuBuilder("gas.chest", function(menu)
        menu.title = "Склад Заправки"
        menu.css.header_color="rgba(0,255,125,0.75)"

        menu:addOption("Забрать деньги", m_take_money_gas, "Забрать выручку")
        menu:addOption("Взять со склада", m_take_gas, "Забрать бензин со склада")
        menu:addOption("Положить на склад", m_put_gas, "Выставить бензин на продажу")
    end)
end








function fuelSystem:__construct()
    vRP.Extension.__construct(self)
    self.cfg = module("fuelsystem", "config")
    self.updateInterval = 20
    menu_gas_station(self)
    menu_chest_gas_take_money(self)
    menu_chest_gas_take(self)
    menu_chest_gas_put(self)
    menu_chest_gas_put_from_trailer(self)
    self.gasStations = {}
    for i = 1, #self.cfg.gasStations do
        self.gasStations[i] = vRP.EXT.fuelSystemBase:getGasStations(i)
    end

    async(function()
        while true do
            Wait(self.updateInterval*1000)
            for k,v in pairs(self.gasStations) do
                vRP.EXT.fuelSystemBase:setGasStations(v.id,v.fuel,v.price,v.owner,v.money)
            end
        end
    end)
end



function fuelSystem:openStationChest(id)
    local user = vRP.users_by_source[source]
    if user.cid == self.gasStations[id]["owner"] then
        local amount = self.gasStations[id]["fuel"]
        local price = self.gasStations[id]["price"]
        local money = self.gasStations[id]["money"]

        user:openMenu("gas.chest", {id = id, amount = amount, price = price, money = money})
        self.remote._menuFlag(user.source, true)
    end
end

function fuelSystem:closeStationChest()
    local user = vRP.users_by_source[source]

    user:closeMenu()
    Wait(100)
    user:closeMenu()
    self.remote._menuFlag(user.source, false)
end


function fuelSystem:startFueling(id, fuel)
    local user = vRP.users_by_source[source]

    local fuelStationFuel = self.gasStations[id]["fuel"]
    local price = self.gasStations[id]["price"]
    local money = self.gasStations[id]["money"]
    local maxFuel = self.cfg.maxFuelLevel - parseInt(fuel)
    local max
    if maxFuel >= fuelStationFuel then
        max = parseInt(fuelStationFuel)
    elseif maxFuel <= fuelStationFuel then
        max = parseInt(maxFuel)
    end
    if max < 0 then
        max = 0
    end
    local amount = tonumber(user:prompt("Введите количество литров: (Макс:" ..max.." Литров), Цена за литр - "..price.." $", "")) or 0
    if amount <= 0 or amount > max or not user:tryPayment(amount*price,true) then
        vRP.EXT.Base.remote._notify(user.source,"Неверное количество")
    else
        local percent = vRP.EXT.business:getPercentFuel()/100
        local tresMoney = vRP.EXT.business.getMoney()
        user:tryPayment(amount*price)
        self.remote._InitFueling(user.source,amount)
        self.gasStations[id]["fuel"] = fuelStationFuel-amount
        self.gasStations[id]["money"] = money + (amount*price - (amount*price*percent))
        vRP.EXT.business:setMoney(tresMoney + (amount*price*percent))
        vRP.EXT.Base.remote._notify(user.source,lang.money.paid({amount*price}))
        vRP.EXT.Base.remote._playAnim(user.source, false, {{"timetable@gardener@filling_can", "gar_ig_5_filling_can", 1}}, true)
        self.remote._refuelFlag(user.source, true)
    end
end



function fuelSystem:finishedFueling()
    local user = vRP.users_by_source[source]
    vRP.EXT.Base.remote._stopAnim(user.source, false)
    self.remote._refuelFlag(user.source, false)
end

fuelSystem.tunnel = {}

fuelSystem.tunnel.finishedFueling = fuelSystem.finishedFueling
fuelSystem.tunnel.startFueling = fuelSystem.startFueling
fuelSystem.tunnel.openStationChest = fuelSystem.openStationChest
fuelSystem.tunnel.closeStationChest = fuelSystem.closeStationChest





fuelSystem.event = {}


function fuelSystem.event:playerStateLoaded(user, first_spawn)
    self.remote._setStateReady(user.source, true)
end

vRP:registerExtension(fuelSystem)
