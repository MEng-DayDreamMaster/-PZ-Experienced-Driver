local MODULE = "ExperiencedDriver"

local function onServerCommand(module, command, args)
    if module ~= MODULE then return end
    local player = getPlayer()
    if player == nil then return end

    if command == "Unlocked" then
        local text = "* " .. getText("IGUI_PlayerText_Unlocked") .. " *"
        player:playSoundLocal("GainExperienceLevel")
        HaloTextHelper.addGoodText(player, text)

    elseif command == "ResetVehicle" then
        ExperiencedDriver.resetVehicle(player)

    elseif command == "SetBrakingForce" then
        local vehicle = player:getVehicle()
        if vehicle == nil then return end

        vehicle:setBrakingForce(args.value)
        vehicle:update()

    elseif command == "SetMaxSpeed" then
        local vehicle = player:getVehicle()
        if vehicle == nil then return end

        vehicle:setMaxSpeed(args.value)
        vehicle:update()
    
    elseif command == "SetEngineNoise" then
        local vehicle = player:getVehicle()
        if vehicle == nil then return end

        vehicle:setEngineFeature(
            vehicle:getEngineQuality(),
            args.value,
            math.floor(vehicle:getScript():getEngineForce())
        )
        vehicle:update()

    elseif command == "SetNewCondition" then
        local vehicle = player:getVehicle()
        if vehicle == nil or not vehicle:isDriver(player) then return end

        local part = vehicle:getPartById(args.id)
        if part ~= nil then
            part:setCondition(args.amount)
            vehicle:transmitPartCondition(part)
            -- vehicle:updatePartStats()
        end        
    end
end

Events.OnServerCommand.Add(onServerCommand)