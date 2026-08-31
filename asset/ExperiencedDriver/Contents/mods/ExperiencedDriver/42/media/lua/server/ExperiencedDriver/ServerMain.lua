local MODULE = "ExperiencedDriver"

local function onClientCommand(module, command, player, args)
    if module ~= MODULE then return end

    if not player then return end

    if isServer() then
        if args == nil or not args.onlineID or 
            player:getOnlineID() ~= args.onlineID then return end
    end

    -- 响应命令
    if command == "UnlockRequest" then
        local playerData = ExperiencedDriver.getData(player)
        if playerData.unlocked then return end 

        ExperiencedDriver.unlockSkillServer(player, args)

    elseif command == "InitVehicleRequest" then
        ExperiencedDriver.initVehicleServer(player) 

    elseif command == "TEST" then
        -- local perk = Perks.Driving

        -- print("SERVER Type = " .. tostring(perk:getType()))
        -- print("SERVER Name = " .. tostring(perk:getName()))
    end
end

Events.OnClientCommand.Add(onClientCommand)
