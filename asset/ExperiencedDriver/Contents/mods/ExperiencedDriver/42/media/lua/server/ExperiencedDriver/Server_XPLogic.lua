local MODULE = "ExperiencedDriver"

---@param num number
local function formatNumber(num)
    local truncated = math.floor(num * 100) / 100

    if truncated % 1 == 0 then
        return string.format("%d", truncated)
    end

    return string.format("%.2f", truncated):gsub("0+$", "")
end

local second = 0.0
local function addXPServer()
    -- OnTick 会被服务器和服务器 Client 重复注册
    if isClient() then return end
    
    local amount = 8.0
    if SandboxVars.ExperiencedDriver.XPValue ~= nil then
        amount = SandboxVars.ExperiencedDriver.XPValue * 4
    end

    local interval = SandboxVars.ExperiencedDriver.TimeInterval or 60
    local delta = getGameTime():getRealworldSecondsSinceLastUpdate()
    second = second + delta
    if second >= interval then
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
                if level == 10 then return end
                
                local playerData = ExperiencedDriver.getData(player)
                if playerData ~= nil and playerData.unlocked then
                    local vehicle = player:getVehicle()
                    if vehicle ~= nil and player:isDriving() then
                        local xpIndicator = SandboxVars.ExperiencedDriver.XPIndicator or false
                        local xpObject = player:getXp()
                        local before = xpObject:getXP(Perks.Driving)                        
                        
                        xpObject:AddXP(
                            Perks.Driving,
                            amount,
                            false,
                            true,
                            false,
                            false
                        )

                        local after = xpObject:getXP(Perks.Driving)
                        local display = formatNumber(after - before)
                        if xpIndicator then
                            HaloTextHelper.addGoodText(player, "Driving +" .. display .. "XP")
                        end
                    end  
                end
            end            
        end             
    end
end

---@param character IsoPlayer
local function levelPerk(character, perk, _level, increased)
    if character == nil then return end
    if perk ~= Perks.Driving or not increased then return end

    local vehicle = character:getVehicle()
    if vehicle == nil or not vehicle:isDriver(character) then return end

    if isServer() then
        sendServerCommand(
            MODULE,
            "ResetVehicle",
            {}
        )
    else
        triggerEvent(
            "OnServerCommand",
            MODULE,
            "ResetVehicle",
            {}
        )
    end
    ExperiencedDriver.initVehicleServer(character)
end


Events.OnTick.Add(addXPServer)
Events.LevelPerk.Add(levelPerk)