local Proxy = module("vrp", "lib/Proxy")

local vRP = Proxy.getInterface("vRP")

async(function()
    vRP.loadScript("fuelsystem", "server/server")
    vRP.loadScript("fuelsystem", "server/base")
end)
