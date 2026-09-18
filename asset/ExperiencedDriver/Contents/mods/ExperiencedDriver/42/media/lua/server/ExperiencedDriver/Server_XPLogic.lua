local MODULE = "ExperiencedDriver"

---@param num number
local function formatNumber(num)
    local truncated = math.floor(num * 100) / 100

    if truncated % 1 == 0 then
        return string.format("%d", truncated)
    end

    return string.format("%.2f", truncated):gsub("0+$", "")
end

---@param player IsoPlayer
---@return boolean, number
local function isPlayerQualified(player)
    local vehicle = player:getVehicle()
    local playerData = ExperiencedDriver.getData(player)
    local level = player:getPerkLevel(Perks.Driving)
    
    if playerData ~= nil and vehicle ~= nil then
        if playerData.unlocked and vehicle:isDriver(player) and player:isDriving() then
            if level < 10 then
                return true, level
            
            -- BeyondTen
            elseif ExperiencedDriver.CompatibleList["BeyondTen"] then
                ---@diagnostic disable-next-line: need-check-nil
                local GetEffectiveLevel = ExperiencedDriver.BeyondTen.GetEffectiveLevel
                if type(GetEffectiveLevel) == "function" then
                    level = GetEffectiveLevel(player, Perks.Driving)
                end

                ---@diagnostic disable-next-line: need-check-nil
                if level < ExperiencedDriver.BeyondTen.MAX_LEVEL then
                    ---@diagnostic disable-next-line: return-type-mismatch
                    return true, level
                end
            end
        end
    end

    return false, 0
end

local second = 0.0
local function addXPServer()
    -- OnTick 会被服务器和服务器 Client 重复注册
    if isClient() then return end
    
    local amount = SandboxVars.ExperiencedDriver.XPValue or 1.0

    local interval = SandboxVars.ExperiencedDriver.TimeInterval or 40
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
                local isQualified, level = isPlayerQualified(player)
                if isQualified then
                    local GetEffectiveLevel = nil
                    local xpIndicator = SandboxVars.ExperiencedDriver.XPIndicator or false
                    local xpObject = player:getXp()
                    local beforeXP = xpObject:getXP(Perks.Driving)
                    
                    -- BeyondTen
                    if level >= 10 and ExperiencedDriver.CompatibleList["BeyondTen"] then
                        local _level = 0
                        
                        ---@diagnostic disable-next-line: need-check-nil
                        GetEffectiveLevel = ExperiencedDriver.BeyondTen.GetEffectiveLevel
                        if type(GetEffectiveLevel) == "function" then
                            _level, beforeXP = GetEffectiveLevel(player, Perks.Driving)
                        end
                    end
                        
                    -- 原始 1.0 经验在不获取倍率会变成 0.25
                    -- XPBoost +3 后三级会初始得到 6.6 经验
                    if player:hasTrait(ExperiencedDriver.ACEDRIVER) then
                        if level < 4 then
                            amount = amount * 2.5
                        elseif level < 6 then
                            amount = amount * 2.75
                        elseif level < 8 then
                            amount = amount * 3.0
                        else
                            amount = amount * 3.25
                        end
                    else
                        amount = amount * 4.0
                    end

                    xpObject:AddXP(
                        Perks.Driving,
                        amount,
                        false,
                        true,
                        false,
                        false
                    )

                    local afterXP = xpObject:getXP(Perks.Driving)
                    
                    -- BeyondTen
                    if level >= 10 and ExperiencedDriver.CompatibleList["BeyondTen"] then
                        local afterLevel = 0
                        if type(GetEffectiveLevel) == "function" then
                            afterLevel, afterXP = GetEffectiveLevel(player, Perks.Driving)
                        end

                        if afterLevel > level then
                            triggerEvent(
                                "LevelPerk",
                                player,
                                Perks.Driving,
                                afterLevel,
                                true
                            )
                        end
                    end

                    if afterXP ~= beforeXP then
                        ---@diagnostic disable-next-line: need-check-nil
                        local display = formatNumber(afterXP - beforeXP)
                        
                        if xpIndicator then
                            HaloTextHelper.addGoodText(player, Translator.getText("IGUI_perks_Driving") .. " +" .. display .. "XP")
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
            character,
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