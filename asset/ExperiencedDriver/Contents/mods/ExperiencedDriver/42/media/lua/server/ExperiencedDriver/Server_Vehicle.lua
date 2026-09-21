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

-- 必须确保传入的 originalEngineLoudness 是已经乘以 SCALE 的数值
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
            { value = value }
        )
    else
        triggerEvent(
            "OnServerCommand",
            MODULE,
            "SetEngineNoise",
            { value = value }
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
    local level = ExperiencedDriver.getLevel(player)    

    if playerData.unlocked then 
        if level ~= 0 then 
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

---@param vehicle BaseVehicle
local function forceUpdateVehicle(vehicle)
    local vehicleData = ExperiencedDriver.getData(vehicle)
    local player = getPlayer()
    if isServer() then
        player = getPlayerByOnlineID(vehicleData.driver)
    end

    if player ~= nil then
        local level = ExperiencedDriver.getLevel(player)

        sendClientBrakingForce(player, vehicleData.brakingForce, level)
        sendClientEngineLoudness(player, vehicleData.engineNoise, level)
        sendClientMaxSpeed(player, vehicleData.maxSpeed, level)
    end
end

--[[
    这是原版函数的硬重载
    如果其他作者需要读取原始的 Brakes 函数，应当为其创建备份
--]] 
ExperiencedDriver.OverrideBackup.Vehicles = ExperiencedDriver.OverrideBackup.Vehicles or {}
ExperiencedDriver.OverrideBackup.Vehicles.Update = ExperiencedDriver.OverrideBackup.Vehicles.Update or {}
ExperiencedDriver.OverrideBackup.Vehicles.Update.Brakes = Vehicles.Update.Brakes

---@overload fun(vehicle: BaseVehicle, part: VehiclePart, elapsedMinutes: number): void
function Vehicles.Update.Brakes(vehicle, part, elapsedMinutes)
    if vehicle:isEngineRunning() and vehicle:getBrakeSpeedBetweenUpdate() > 0 and part:getInventoryItem() then
		local speedMod = (math.min(80, vehicle:getBrakeSpeedBetweenUpdate()) / 20)
		if ZombRandFloat(0, 100) < speedMod then
			part:setCondition(part:getCondition() - 1)
			vehicle:transmitPartCondition(part)
			vehicle:updatePartStats()

            forceUpdateVehicle(vehicle)
		end
	end
end

ExperiencedDriver.OverrideBackup.Vehicles.LowerCondition = Vehicles.LowerCondition

---@overload fun(vehicle: BaseVehicle, part: VehiclePart, elapsedMinutes: number): number
function Vehicles.LowerCondition(vehicle, part, elapsedMinutes)
	if vehicle:isEngineRunning() and vehicle:getCurrentSpeedKmHour() > 10 and part:getInventoryItem() then
		local chance = part:getInventoryItem():getConditionLowerNormal() * Vehicles.newSystemConditionLowerMult
		if vehicle:isDoingOffroad() then chance = part:getInventoryItem():getConditionLowerOffroad() * Vehicles.newSystemConditionLowerMult / vehicle:getOffroadEfficiency() end
		
		-- will also depend on speed/current steering
		chance = chance + (vehicle:getCurrentSpeedKmHour() / 200)
		chance = chance + math.abs(vehicle:getCurrentSteering() / 2)
		
		if part:getCondition() > 0 and ZombRandFloat(0, 100) < chance then
			part:setCondition(part:getCondition() - 1)
			vehicle:transmitPartCondition(part)
			vehicle:updatePartStats()

            forceUpdateVehicle(vehicle)
		end
		return chance
	end
	return 0
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
                local level = ExperiencedDriver.getLevel(player)

                if level ~= 0 then
                    local vehicle = player:getVehicle()
                    if vehicle ~= nil and vehicle:isDriver(player) and player:isDriving() then
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