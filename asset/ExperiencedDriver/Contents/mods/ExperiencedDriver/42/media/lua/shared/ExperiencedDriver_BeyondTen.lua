ExperiencedDriver = _G.ExperiencedDriver or {}
ExperiencedDriver.CompatibleList = _G.ExperiencedDriver.CompatibleList or {}

-- Compatible Mod List
ExperiencedDriver.BeyondTen = nil

local function addCompatibleMod()
    ExperiencedDriver.BeyondTen = _G.BeyondTen
    ExperiencedDriver.CompatibleList["BeyondTen"] = type(ExperiencedDriver.BeyondTen) == "table" or false
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

Events.OnGameStart.Add(addCompatibleMod)