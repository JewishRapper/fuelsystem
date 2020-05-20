local fuelSystemBase = class("fuelSystemBase", vRP.Extension)


function fuelSystemBase:__construct()
    vRP.Extension.__construct(self)
    self.cfg = module("fuelsystem", "config")


vRP:prepare('baseFuel',[[
			CREATE TABLE IF NOT EXISTS `gasstations` (
			  `id` int(11) NOT NULL,
			  `fuel` int(11),
			  `price` DECIMAL(10,2),
			  `owner` int(11) NOT NULL,
			  `money` DECIMAL(10,2) NOT NULL,
			  PRIMARY KEY (`id`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8;

]])
async(function()
    vRP:execute("baseFuel")
end)

vRP:prepare("setGasStations","REPLACE INTO gasstations (`id`, `fuel`, `price`, `owner`,  `money`) VALUES(@id, @fuel, @price, @owner,  @money)")

function isExisting()
    vRP:prepare("vRP/isExisting","SELECT id FROM gasstations LIMIT 1")
    return vRP:query("vRP/isExisting")[1]
end

async(function ()
    if isExisting()  == nil then
        for k,v in pairs(self.cfg.gasStations) do
            vRP:execute("setGasStations", {
                id = k,
                fuel = self.cfg.defaultFuel,
                price = self.cfg.defaultFuelPrice,
                owner = 0,
                money = 0
            })
        end
    else
        for k,v in pairs(self.cfg.gasStations) do
            if self.getOwner(self,k) == 0 then
                vRP:execute("setGasStations", {
                    id = k,
                    fuel = self.cfg.defaultFuel,
                    price = self.cfg.defaultFuelPrice,
                    owner = 0,
                    money = 0
                })
            end
        end
    end
end)


vRP:prepare("getGasStations","SELECT * FROM gasstations WHERE `id` = @id")
end


function fuelSystemBase:getFuel(id)
    return vRP:query("getGasStations", {
        id = id
    })[1]["fuel"]
end

function fuelSystemBase:getPrice(id)
    return vRP:query("getGasStations", {
        id = id
    })[1]["price"]
end

function fuelSystemBase:getOwner(id)
    return vRP:query("getGasStations", {
        id = id
    })[1]["owner"]
end

function fuelSystemBase:getMoney(id)
    return vRP:query("getGasStations", {
        id = id
    })[1]["money"]
end

function fuelSystemBase:setFuel(id, fuel)
    vRP:prepare("setFuel", "UPDATE gasstations SET fuel = @fuel WHERE id = @id")
    vRP:execute("setFuel", {
        id = id,
        fuel = fuel
    })
end

function fuelSystemBase:setPrice(id, price)
    vRP:prepare("setPrice", "UPDATE gasstations SET price = @price WHERE id = @id")
    vRP:execute("setPrice", {
        id = id,
        price = price
    })
end

function fuelSystemBase:initOwner(id, owner)
    vRP:prepare("initOwner", "REPLACE INTO gasstations(id,owner,fuel,price) VALUES(@id,@owner,@fuel,@price)")
    vRP:execute("initOwner", {
        id = id,
        owner = owner,
        fuel = 0,
        price = 0,
    })
end

function fuelSystemBase:setOwner(id, owner)
    vRP:prepare("setOwner","UPDATE gasstations SET owner = @owner WHERE id = @id")
    vRP:execute("setOwner", {
        id = id,
        owner = owner,
    })
end

function fuelSystemBase:setMoney(id, money)
    vRP:prepare("setMoney", "UPDATE gasstations SET money = @money WHERE id = @id")
    vRP:execute("setMoney", {
        id = id,
        money = money
    })
end

fuelSystemBase.tunnel = {}

fuelSystemBase.tunnel.getFuel = fuelSystemBase.getFuel
fuelSystemBase.tunnel.getPrice = fuelSystemBase.getPrice
fuelSystemBase.tunnel.getOwner = fuelSystemBase.getOwner
fuelSystemBase.tunnel.getMoney = fuelSystemBase.getMoney
fuelSystemBase.tunnel.setFuel = fuelSystemBase.setFuel
fuelSystemBase.tunnel.setPrice = fuelSystemBase.setPrice
fuelSystemBase.tunnel.initOwner = fuelSystemBase.initOwner
fuelSystemBase.tunnel.setOwner = fuelSystemBase.setOwner
fuelSystemBase.tunnel.setMoney = fuelSystemBase.setMoney


vRP:registerExtension(fuelSystemBase)