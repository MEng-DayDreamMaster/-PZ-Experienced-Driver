if isClient() then return end

local MODULE = "ExperiencedDriver"

-- 原始车辆噪声比例接近 1 / 2.7
local LOUDNESS_SCALE = 2.7

---@param player IsoPlayer
function ExperiencedDriver.initVehicleServer(player)
    local playerData = ExperiencedDriver.getData(player)
    if playerData == nil then return end

    local vehicle = player:getVehicle()
    if vehicle == nil or not vehicle:isDriver(player) then return end
    vehicle:updatePartStats()

    local originalBrakingForce = vehicle:getBrakingForce()
    local originalMaxSpeed = vehicle:getMaxSpeed()
    local originalEngineLoudness = vehicle:getEngineLoudness() * LOUDNESS_SCALE

    local vehicleData = ExperiencedDriver.getData(vehicle)
    local level = player:getPerkLevel(Perks.Driving)    

    if playerData.unlocked then 
        if level ~= 0 then 
            if SandboxVars.ExperiencedDriver.Brakepower then
                
                local setting = SandboxVars.ExperiencedDriver["Brakepower" .. level] or 0
            
                if isServer() then                            
                    sendServerCommand(
                        MODULE,
                        "SetBrakingForce",
                        { value = originalBrakingForce * (1 + setting) }
                    )
                else
                    triggerEvent(
                        "OnServerCommand",
                        MODULE,
                        "SetBrakingForce",
                        { value = originalBrakingForce * (1 + setting) }
                    )      
                end       
            end

            if SandboxVars.ExperiencedDriver.SpeedBonus then
                local setting = SandboxVars.ExperiencedDriver["SpeedBonus" .. level] or 0

                if isServer() then
                    sendServerCommand(
                        MODULE,
                        "SetMaxSpeed",
                        { value = originalMaxSpeed * (1 + setting) }
                    )
                else
                    triggerEvent(
                        "OnServerCommand",
                        MODULE,
                        "SetMaxSpeed",
                        { value = originalMaxSpeed * (1 + setting) }
                    )
                end
            end

            if SandboxVars.ExperiencedDriver.NoiseReduction then
                local setting = SandboxVars.ExperiencedDriver["NoiseReduction" .. level] or 0
                local target = math.ceil(originalEngineLoudness * (1 - setting))

                if isServer() then
                    sendServerCommand(
                        MODULE,
                        "SetEngineNoise",
                        { value = math.ceil(target) }
                        )
                else
                        triggerEvent(
                            "OnServerCommand",
                            MODULE,
                            "SetEngineNoise",
                            { value = math.ceil(target) }
                        )
                end
            end

            if SandboxVars.ExperiencedDriver.DamageReduction then
                local parts = {}
                local vehicleData = ExperiencedDriver.getData(vehicle)

                for i = 0, vehicle:getPartCount() - 1 do
                    local part = vehicle:getPartByIndex(i)
                    -- parts 表格式如: parts["Engine"] = ...
                    parts[tostring(part:getId())] = part:getCondition()
                end

                vehicleData.Parts = vehicleData.Parts or parts
            end
        end
    end

    vehicleData.brakingForce = originalBrakingForce
    vehicleData.maxSpeed = originalMaxSpeed
    vehicleData.engineNoise = math.ceil(originalEngineLoudness)   

    playerData.vehicleID = vehicle:getId()
    if isServer() then
        vehicleData.driver = player:getOnlineID()

        player:transmitModData()
        vehicle:transmitModData()
    else        
        vehicleData.driver = player:getID()
    end
end


local second = 0.0
local function reduceDamageServer()
    if not SandboxVars.ExperiencedDriver.DamageReduction then return end

    local delta = getGameTime():getRealworldSecondsSinceLastUpdate()
    second = second + delta
    if second >= 1 then
        second = 0.0
        
        local players = {}
        if isServer() then
            players = getOnlinePlayers()
        else
            players = IsoPlayer:getPlayers()
        end

        for i = 0, players:size() - 1 do
            local player = players:get(i)
            if player ~= nil then 
                local level = player:getPerkLevel(Perks.Driving)

                if level ~= 0 and SandboxVars.ExperiencedDriver["DamageReduction" .. level] ~= 0 then
                    local vehicle = player:getVehicle()

                    if vehicle ~= nil and vehicle:isDriver(player) then 
                        local vehicleData = ExperiencedDriver.getData(vehicle)
                        if vehicleData.Parts ~= nil then
                            for j = 0, vehicle:getPartCount() - 1 do
                                local part = vehicle:getPartByIndex(j)
                                local partId = tostring(part:getId())

                                if vehicleData.Parts[partId] ~= nil then
                                    local previous = vehicleData.Parts[partId]
                                    local now = part:getCondition()
                        
                                    if now < previous then
                                        local damage = previous - now
                                        local amount = previous - math.ceil(damage * (1 - SandboxVars.ExperiencedDriver["DamageReduction" .. level]))
                                        vehicleData.Parts[partId] = amount

                                        if isServer() then
                                            vehicle:transmitModData() 
                                            sendServerCommand(
                                                MODULE,
                                                "SetNewCondition",
                                                {
                                                    id = partId,
                                                    amount = amount
                                                }
                                            )
                                        else
                                            triggerEvent(
                                                "OnServerCommand",
                                                MODULE,
                                                "SetNewCondition",
                                                {
                                                    id = partId,
                                                    amount = amount
                                                }
                                            )
                                        end     -- 11 都怪Lua不给我用 continue; 害我写 end 楼梯                                 
                                    end     -- 10
                                end     -- 9
                            end     -- 8
                        end     -- 7                        
                    end     -- 6     
                end     -- 5
            end     -- 4
        end     -- 3
    end     -- 2
end     -- 1

Events.OnTick.Add(reduceDamageServer)
