local function addCompatibleMod()
    ExperiencedDriver.BeyondTen = _G.BeyondTen
    ExperiencedDriver.CompatibleList["BeyondTen"] = type(ExperiencedDriver.BeyondTen) == "table"
end

-- BeyondTen
---@param option string
---@param level number
---@return number
function ExperiencedDriver.getOptionValue(option, level)
    if option == "Brakepower" or option == "DamageReduction" or
        option == "SpeedBonus" or option == "NoiseReduction" then
            if level > 0 and level <= 10 then
                return SandboxVars.ExperiencedDriver[tostring(option .. level)]
            
            -- BeyondTen
            elseif level > 10 and ExperiencedDriver.CompatibleList["BeyondTen"] then
                ---@diagnostic disable-next-line: need-check-nil
                if level <= ExperiencedDriver.BeyondTen.MAX_LEVEL then
                    local originalSetting = SandboxVars.ExperiencedDriver[option .. "10"]
                    
                    ---@diagnostic disable-next-line: need-check-nil
                    return level * 0.1 * originalSetting
                end
            end
    end

    return -1
end

---@param player IsoPlayer
---@return number
function ExperiencedDriver.getLevel(player)
    if player == nil then return 0 end
    local level = player:getPerkLevel(Perks.Driving)

    if level >= 10 and ExperiencedDriver.CompatibleList["BeyondTen"] then
        ---@diagnostic disable-next-line: need-check-nil
        local GetEffectiveLevel = ExperiencedDriver.BeyondTen.GetEffectiveLevel
        if type(GetEffectiveLevel) == "function" then
            level = GetEffectiveLevel(player, Perks.Driving)
        end 
    end

    return level
end

---@param player IsoPlayer
---@param amount number
function ExperiencedDriver.AddXPBeyondTen(player, amount)
    if player == nil or amount == 0 then return end

    if ExperiencedDriver.CompatibleList["BeyondTen"] then
        ---@diagnostic disable-next-line: need-check-nil
        local AddStoredXP = ExperiencedDriver.BeyondTen.AddStoredXP
        if type(AddStoredXP) == "function" then
            AddStoredXP(player, Perks.Driving, amount)
        end
    end
end

Events.OnGameBoot.Add(addCompatibleMod)