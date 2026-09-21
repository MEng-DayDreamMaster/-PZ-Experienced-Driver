if isClient() then return end

local MODULE = "ExperiencedDriver"

-- 原始车辆噪声比例接近 1 / 2.7
local LOUDNESS_SCALE = 2.7

---@param player IsoPlayer
local function sendClientBrakingForce(player, originalBrakingForce, level)
    local scale = 1.0 + ExperiencedDriver.getOptionValue("Brakepower", level)
    if scale > 2.0 then
        scale = 2.0
    end 

    local value = originalBrakingForce * scale
            
    if isServer() then                            
        sendServerCommand(
            player,
            MODULE,
            "SetBrakingForce",
            { value = value }
        )
    else
        triggerEvent(
            "OnServerCommand",
            MODULE,
            "SetBrakingForce",
            { value = value }
        )      
    end
end

---@param player IsoPlayer
local function sendClientMaxSpeed(player, originalMaxSpeed, level)
    local scale = 1.0 + ExperiencedDriver.getOptionValue("SpeedBonus", level)
    if scale > 1.6 then
        scale = 1.6
    end 

    local value = originalMaxSpeed * scale

    if isServer() then
        sendServerCommand(
            player,
            MODULE,
            "SetMaxSpeed",
            { value = value }
        )
    else
        triggerEvent(
            "OnServerCommand",
            MODULE,
            "SetMaxSpeed",
            { value = value }
        )
    end
end

---@param player IsoPlayer
local function sendClientEngineLoudness(player, originalEngineLoudness, level)
    local scale = 1.0 - ExperiencedDriver.getOptionValue("NoiseReduction", level)
    if scale < 0 then
        scale = 0
    end

    local value = math.ceil(originalEngineLoudness * scale)

    if isServer() then
        sendServerCommand(
            player,
            MODULE,
            "SetEngineNoise",
            { value = math.ceil(value) }
        )
    else
        triggerEvent(
            "OnServerCommand",
            MODULE,
            "SetEngineNoise",
            { value = math.ceil(value) }
        )
    end
end

---@param vehicle BaseVehicle
local function recordVehiclePartsData(vehicle)
    local parts = {}
    local vehicleData = ExperiencedDriver.getData(vehicle)

    for i = 0, vehicle:getPartCount() - 1 do
        local part = vehicle:getPartByIndex(i)
        -- parts 表格式如: parts["Engine"] = ...
        parts[tostring(part:getId())] = part:getCondition()
    end

    vehicleData.Parts = vehicleData.Parts or parts
end

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
            -- Beyond Ten
            if level >= 10 and ExperiencedDriver.CompatibleList["BeyondTen"] then
                ---@diagnostic disable-next-line: need-check-nil
                local GetEffectiveLevel = ExperiencedDriver.BeyondTen.GetEffectiveLevel
                if type(GetEffectiveLevel) == "function" then
                    level = GetEffectiveLevel(player, Perks.Driving)
                end
            end

            if SandboxVars.ExperiencedDriver.Brakepower then           
                sendClientBrakingForce(player, originalBrakingForce, level)      
            end

            if SandboxVars.ExperiencedDriver.SpeedBonus then
                sendClientMaxSpeed(player, originalMaxSpeed, level)
            end

            if SandboxVars.ExperiencedDriver.NoiseReduction then
                sendClientEngineLoudness(player, originalEngineLoudness, level)
            end

            if SandboxVars.ExperiencedDriver.DamageReduction then
                recordVehiclePartsData(vehicle)
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

---@param player IsoPlayer
---@param vehicle BaseVehicle
local function forceUpdateVehicle(player, vehicle, level)
    vehicle:updatePartStats()
    sendClientBrakingForce(player, vehicle:getBrakingForce(), level)
    sendClientEngineLoudness(player, vehicle:getEngineLoudness() * LOUDNESS_SCALE, level)
    sendClientMaxSpeed(player, vehicle:getMaxSpeed(), level)
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

                if level ~= 0 then
                    local vehicle = player:getVehicle()
                    if vehicle ~= nil and vehicle:isDriver(player) and player:isDriving() then
                        -- Beyond Ten
                        if level >= 10 and ExperiencedDriver.CompatibleList["BeyondTen"] then
                            ---@diagnostic disable-next-line: need-check-nil
                            local GetEffectiveLevel = ExperiencedDriver.BeyondTen.GetEffectiveLevel
                            if type(GetEffectiveLevel) == "function" then
                                level = GetEffectiveLevel(player, Perks.Driving)
                            end
                        end

                        -- forceUpdateVehicle(player, vehicle, level)

                        local scale = 1.0 - ExperiencedDriver.getOptionValue("DamageReduction", level)
                        if scale < 0 then
                            scale = 0
                        end

                        if scale ~= 1 then
                            local vehicleData = ExperiencedDriver.getData(vehicle)
                            if vehicleData.Parts ~= nil then
                                for j = 0, vehicle:getPartCount() - 1 do
                                    local part = vehicle:getPartByIndex(j)
                                    local partId = tostring(part:getId())

                                    if vehicleData.Parts[partId] ~= nil and ExperiencedDriver.isPartInclusive(partId) then
                                        local previous = vehicleData.Parts[partId]
                                        local now = part:getCondition()
                            
                                        if now < previous then
                                            local damage = previous - now
                                            local amount = previous - math.floor(damage * scale + 0.5)
                                            vehicleData.Parts[partId] = amount

                                            if isServer() then
                                                vehicle:transmitModData() 
                                            --     sendServerCommand(
                                            --         player,
                                            --         MODULE,
                                            --         "SetNewCondition",
                                            --         {
                                            --             id = partId,
                                            --             amount = amount
                                            --         }
                                            --     )
                                            -- else
                                            --     triggerEvent(
                                            --         "OnServerCommand",
                                            --         MODULE,
                                            --         "SetNewCondition",
                                            --         {
                                            --             id = partId,
                                            --             amount = amount
                                            --         }
                                            --     )
                                            end     -- 12 都怪Lua不给我用 continue; 害我写 end 楼梯  
                                            
                                            part:setCondition(amount)
                                            vehicle:transmitPartCondition(part)

                                        end     -- 11
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
