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
        ExperiencedDriver.setBrakingForce(player, args)

    elseif command == "SetMaxSpeed" then
        ExperiencedDriver.setMaxSpeed(player, args)
    
    elseif command == "SetEngineNoise" then
        ExperiencedDriver.setEngineNoise(player, args)

    elseif command == "SetNewCondition" then
        ExperiencedDriver.setNewCondition(player, args)      
    end
end

Events.OnServerCommand.Add(onServerCommand)