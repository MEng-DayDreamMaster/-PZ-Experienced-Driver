local MODULE = "ExperiencedDriver"

---@param player IsoPlayer
local function initVehicleRequest(player)
    if player == nil then return end

    local vehicle = player:getVehicle()
    if not vehicle or not vehicle:isDriver(player) then return end
    
    local vehicleData = ExperiencedDriver.getData(vehicle)
    if vehicleData ~= nil and vehicleData.driver ~= nil then
        local playerId = player:getID()
        if isClient() then playerId = player:getOnlineID() end

        if vehicleData.driver ~= playerId then
            ExperiencedDriver.resetVehicle(player)
        end
    end

    -- args 重要警告 
    if isClient() then
        -- OnVehicleEnter 事件会被服务器的 Client 发送两次
        -- 第一次没有拿到物理对象，第二次才是有数据的发送
        if vehicle:isLocalPhysicSim() then
            sendClientCommand(
                MODULE, 
                "InitVehicleRequest", 
                {onlineID = player:getOnlineID()}
            )
        end
    else
        sendClientCommand(
            MODULE, 
            "InitVehicleRequest", 
            {}
        )
    end
end

---@param player IsoPlayer
function ExperiencedDriver.resetVehicle(player)
    if player == nil then return end
    local playerData = ExperiencedDriver.getData(player)

    if playerData.vehicleID == nil then return end
    
    ---@diagnostic disable-next-line: param-type-mismatch
    local vehicle = getVehicleById(playerData.vehicleID)
    if vehicle == nil then return end

    local vehicleData = ExperiencedDriver.getData(vehicle)

    if vehicleData ~= nil then
        if vehicleData.brakingForce ~= nil then
            vehicle:setBrakingForce(vehicleData.brakingForce)
        end

        if vehicleData.maxSpeed ~= nil then
            vehicle:setMaxSpeed(vehicleData.maxSpeed)
        end

        if vehicleData.engineNoise ~= nil then
            vehicle:setEngineFeature(
                vehicle:getEngineQuality(),
                vehicleData.engineNoise,
                math.floor(vehicle:getScript():getEngineForce())
            )
        end

        vehicle:update()
        playerData.vehicleID = nil
        vehicleData.driver = nil

        if isMultiplayer() then
            player:transmitModData()
            vehicle:transmitModData()
        end
    end  
end

---@param player IsoPlayer
local function onSwitchVehicleSeat(player)
    if player == nil then return end

    local playerData = ExperiencedDriver.getData(player)
    if playerData == nil then return end

    local vehicle = player:getVehicle()
    if vehicle:isDriver(player) then
        if isClient() then
            sendClientCommand(
                MODULE, 
                "InitVehicleRequest", 
                {onlineID = player:getOnlineID()}
            )
        else
            sendClientCommand(
                MODULE, 
                "InitVehicleRequest", 
                {}
            )
        end
    else
        if playerData.vehicleID ~= nil and playerData.vehicleID == vehicle:getId() then 
            ExperiencedDriver.resetVehicle(player)
        end
    end
end

---@param player IsoPlayer
local function onPlayerDeath(player)
    if player == nil then return end

    local playerData = ExperiencedDriver.getData(player)
    if playerData ~= nil and playerData.vehicleID ~= nil then
        playerData.vehicleID = nil
    end

    if isClient() then player:transmitModData() end
end


Events.OnEnterVehicle.Add(initVehicleRequest)
Events.OnExitVehicle.Add(ExperiencedDriver.resetVehicle)
Events.OnSwitchVehicleSeat.Add(onSwitchVehicleSeat)
Events.OnPlayerDeath.Add(onPlayerDeath)