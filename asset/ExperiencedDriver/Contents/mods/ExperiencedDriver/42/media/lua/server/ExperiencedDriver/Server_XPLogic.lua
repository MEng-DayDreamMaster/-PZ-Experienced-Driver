-- OnTick 会被服务器和服务器 Client 重复注册
-- 不允许服务器客户端加载这个文件
if isClient() then return end

local MODULE = "ExperiencedDriver"
local GetEffectiveLevel = nil
local AddStoredXP = nil

local function addBeyondTenFunction()
    if ExperiencedDriver.CompatibleList["BeyondTen"] then
        ---@diagnostic disable-next-line: need-check-nil
        if type(ExperiencedDriver.BeyondTen.GetEffectiveLevel) == "function" then
            ---@diagnostic disable-next-line: need-check-nil
            GetEffectiveLevel = ExperiencedDriver.BeyondTen.GetEffectiveLevel
        end

        ---@diagnostic disable-next-line: need-check-nil
        if type(ExperiencedDriver.BeyondTen.AddStoredXP) == "function" then
            ---@diagnostic disable-next-line: need-check-nil
            AddStoredXP = ExperiencedDriver.BeyondTen.AddStoredXP
        end
    end
end

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
                level = GetEffectiveLevel(player, Perks.Driving)

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
    local amount = SandboxVars.ExperiencedDriver.XPValue or 1.0
    if amount == 0 then return end

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
                    local xpIndicator = SandboxVars.ExperiencedDriver.XPIndicator or false
                    local xpObject = player:getXp()
                    local beforeXP = xpObject:getXP(Perks.Driving)
                    
                    -- BeyondTen
                    if level >= 10 and ExperiencedDriver.CompatibleList["BeyondTen"] then
                        local _level = 0
                        
                        ---@diagnostic disable-next-line: need-check-nil
                        _level, beforeXP = GetEffectiveLevel(player, Perks.Driving)
                    end

                    xpObject:AddXP(
                        Perks.Driving,
                        amount,
                        true,
                        false
                    )

                    local afterXP = xpObject:getXP(Perks.Driving)
                    
                    -- BeyondTen
                    if level >= 10 and ExperiencedDriver.CompatibleList["BeyondTen"] then
                        ExperiencedDriver.AddXPBeyondTen(player, amount)

                        local afterLevel = 0
                        ---@diagnostic disable-next-line: need-check-nil
                        afterLevel, afterXP = GetEffectiveLevel(player, Perks.Driving)

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
                            HaloTextHelper.addGoodText(player, getText("IGUI_perks_Driving") .. " +" .. display .. "XP")
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

Events.OnGameBoot.Add(addBeyondTenFunction)
Events.OnTick.Add(addXPServer)
Events.LevelPerk.Add(levelPerk)