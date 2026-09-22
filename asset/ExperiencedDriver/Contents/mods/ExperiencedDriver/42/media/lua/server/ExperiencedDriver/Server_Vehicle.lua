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

ExperiencedDriver.OverrideBackup.Vehicles.Update.GasTank = Vehicles.Update.GasTank
---@overload fun(vehicle: BaseVehicle, part: VehiclePart, elapsedMinutes: number): void
function Vehicles.Update.GasTank(vehicle, part, elapsedMinutes)
	local invItem = part:getInventoryItem()
	if not invItem then return end
	local amount = part:getContainerContentAmount()
	if elapsedMinutes > 0 and amount > 0 and vehicle:isEngineRunning() then
        -- Experienced Driver
        local vehicleData = ExperiencedDriver.getData(vehicle)
        local originalMaxSpeed = vehicleData.maxSpeed
        local isIdle = false

		local amountOld = amount
		-- calcul how much gas is used, based mainly on engine speed, engine quality & mass.
		local gasMultiplier = 90000
		-- heater consume more gas
		local heater = vehicle:getHeater()
		if heater and heater:getModData().active then
			gasMultiplier = gasMultiplier - 5000
		end
		-- if quality is 60, we do: 100 - 60 = 40; 40/2 = 20; 20/100=0.2; 0.2+1 = 1.2 : our multiplier;
		local qualityMultiplier = ((100 - vehicle:getEngineQuality()) / 200) + 1
		local massMultiplier =  ((math.abs(1000 - vehicle:getScript():getMass())) / 300) + 1
		-- the closer we are to change shift, the less we consume gas

        -- 在这里强行干预原版的油耗获取，因为原版的油耗曲线过于极端
		-- local speedToNextTransmission = ((vehicle:getMaxSpeed() / vehicle:getScript():getGearRatioCount()) * 0.71) * vehicle:getTransmissionNumber()
        local speedToNextTransmission = ((originalMaxSpeed / vehicle:getScript():getGearRatioCount()) * 0.71) * vehicle:getTransmissionNumber()

		local speedMultiplier = (speedToNextTransmission - vehicle:getCurrentSpeedKmHour()) * 350
		-- if vehicle is stopped, we half the value of gas consummed
		if math.floor(vehicle:getCurrentSpeedKmHour()) > 0 then
            ---@diagnostic disable-next-line: assign-type-mismatch
			gasMultiplier = gasMultiplier / qualityMultiplier / massMultiplier
		else
            ---@diagnostic disable-next-line: assign-type-mismatch
			gasMultiplier = (gasMultiplier / qualityMultiplier) * 2
			speedMultiplier = 1
            isIdle = true
		end
		-- we're at max gear, cap general gas consumption
		if speedMultiplier < 800 and speedMultiplier ~= 1 then
			speedMultiplier = 800
		end

        if speedMultiplier == 1 then -- we're idling, need to increase the fuel consumption still
            speedMultiplier = 300
        end

		local newAmount = (speedMultiplier / gasMultiplier)  * SandboxVars.CarGasConsumption
		newAmount =  newAmount * (vehicle:getEngineSpeed() / 2500.0)

        -- Experienced Driver
        -- 在这里简单粗暴地修改一下新扣除的油量是原始速度的比率
        local ratio = vehicle:getMaxSpeed() / originalMaxSpeed
        if not isIdle then
            newAmount = newAmount * ratio
        end

		amount = amount - elapsedMinutes * newAmount

		-- if your gas tank is in bad condition, you can simply lose fuel
		if part:getCondition() < 70 then
			if ZombRand(part:getCondition() * 2) == 0 then
				amount = amount - 0.01
			end
		end
	
		part:setContainerContentAmount(amount, false, true)
		amount = part:getContainerContentAmount()
		local precision = (amount < 0.5) and 2 or 1
		if VehicleUtils.compareFloats(amountOld, amount, precision) then
			vehicle:transmitPartModData(part)
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