local fuelSystem = class("fuelSystem", vRP.Extension)

function changeFuel(veh, change)
    SetVehicleFuelLevel(veh, change);
    DecorSetFloat(veh, "customFuel", change)
end
function fuelSystem:__construct()
    vRP.Extension.__construct(self)
    self.cfg = module("fuelsystem", "config")
    self.stateReady = false
    self.inRefuel = false
    self.inGasStationMenu = false
    self.closestStation = nil
    DecorRegister("customFuel",1)

    async(function()
        while true do
            local vehicle;
            if IsPedSittingInAnyVehicle(GetPlayerPed(-1)) then
                vehicle = GetVehiclePedIsUsing(GetPlayerPed(-1));
                local fuel = GetVehicleFuelLevel(vehicle);
                if fuel > 100.0 then
                    fuel = 100.0
                end
                local coords1 = GetEntityCoords(vehicle);
                if not DecorExistOn(vehicle, "customFuel") then
                    DecorSetFloat(vehicle, "customFuel", fuel)
                    else
                fuel = DecorGetFloat(vehicle, "customFuel" )
                end
                Citizen.Wait(0);
                local coords2 = GetEntityCoords(vehicle);
                local dist = GetDistanceBetweenCoords(coords1, coords2, true)
                if(dist > 0 and fuel ~= 0 and GetIsVehicleEngineRunning(vehicle)) then
                        local class = GetVehicleClass(vehicle)
                        changeFuel(vehicle, fuel - (dist/270*self.cfg.specialUsage[class]));
                elseif dist == 0 and fuel ~= 0 and GetIsVehicleEngineRunning(vehicle) then
                        local class = GetVehicleClass(vehicle)
                        changeFuel(vehicle, fuel - (1/270*self.cfg.specialUsage[class]*0.2));
                end
            end;
            Citizen.Wait(0);
        end;
    end)

    async( function()
        while true do
            Citizen.Wait(0)
            if self.stateReady then

                local pedPos = GetEntityCoords(PlayerPedId(), 0)
                for k,v in pairs(self.cfg.gasStations) do
                    if GetDistanceBetweenCoords(pedPos.x, pedPos.y, pedPos.z, v[4], v[5], v[6], true) <= 2.0 and not IsPedSittingInAnyVehicle(GetPlayerPed(-1)) then
                        self.closestStation = k
                        vRP.EXT.GUI:DrawOnscreenText(0.01,0.1 , "Нажмите ~r~E~w~, чтобы открыть склад")
                        if IsControlJustReleased(0, 51) then
                            self.remote._openStationChest(self.closestStation)
                        end
                        elseif GetDistanceBetweenCoords(pedPos.x, pedPos.y, pedPos.z, v[1], v[2], v[3], true) <= 50.0 then
                        self.closestStation = k
                    end
                end
            end
        end
    end)

    async(function()
        while true do
            if self.inGasStationMenu == true then
                local pedPos = GetEntityCoords(PlayerPedId(), 0)
                    if GetDistanceBetweenCoords(pedPos.x, pedPos.y, pedPos.z, self.cfg.gasStations[self.closestStation][4], self.cfg.gasStations[self.closestStation][5],  self.cfg.gasStations[self.closestStation][6], 1 ) >= 2.0 then
                        self.remote._closeStationChest()
                    end
                end
            Citizen.Wait(100)
            end
        end)

    async(function()
        while true do
            Citizen.Wait(1)
            local ped = PlayerPedId()
            local vehicle = GetPlayersLastVehicle(ped)
            local vehCoords = GetEntityCoords(vehicle)
            local pedCoords = GetEntityCoords(ped)
            local dist = GetDistanceBetweenCoords(pedCoords, vehCoords,true)
            if self.closestStation ~= 0 and self.closestStation ~= nil and not IsPedInVehicle(ped, vehicle,false) and not IsPedInAnyVehicle(ped,false) and dist <= 2.0 then
                for i = 1, #self.cfg.pumpModels do
                    local closestPump = GetClosestObjectOfType(pedCoords, 1.5, self.cfg.pumpModels[i],false,false)
                    if closestPump ~= nil and closestPump ~= 0 and not self.inRefuel then
                        local coords = GetEntityCoords(closestPump)
                        vRP.EXT.GUI:DrawText3Ds(coords.x,coords.y, coords.z+1, "Нажмите ~r~E~w~, чтобы заправиться")
                        if IsControlJustReleased(0, 51) then
                            self.remote.startFueling(self.closestStation, GetVehicleFuelLevel(vehicle))
                        end
                    end
                end
            end
        end
    end)

end







function fuelSystem:setStateReady(flag)
    self.stateReady = flag
end

function fuelSystem:InitFueling(amount)
    local ped = PlayerPedId()
    local vehicle = GetPlayersLastVehicle(ped)
    local fuel = parseInt(GetVehicleFuelLevel(vehicle))
    local amount = amount + fuel
    FreezeEntityPosition(ped,true)
    FreezeEntityPosition(vehicle,false)
    while parseInt(GetVehicleFuelLevel(vehicle)) <= amount do
        Citizen.Wait(500)
        changeFuel(vehicle, GetVehicleFuelLevel(vehicle)+1)
    end
    Citizen.Wait(2000)
    FreezeEntityPosition(ped,false)
    FreezeEntityPosition(vehicle,false)
    self.remote._finishedFueling()
end

function fuelSystem:refuelFlag(flag)
    self.inRefuel = flag
end

function fuelSystem:menuFlag(flag)
    self.inGasStationMenu = flag
end


fuelSystem.tunnel = {}

fuelSystem.tunnel.menuFlag = fuelSystem.menuFlag
fuelSystem.tunnel.refuelFlag = fuelSystem.refuelFlag
fuelSystem.tunnel.InitFueling = fuelSystem.InitFueling
fuelSystem.tunnel.setStateReady = fuelSystem.setStateReady
fuelSystem.tunnel.shopFlag = fuelSystem.shopFlag


vRP:registerExtension(fuelSystem)