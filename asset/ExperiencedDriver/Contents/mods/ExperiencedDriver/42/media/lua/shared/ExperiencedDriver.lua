ExperiencedDriver = ExperiencedDriver or {}

ExperiencedDriver.INTERACTION_GUID = "RM_14eaf741-67cb-4be8-93bd-bc6d35ccfe8b"

local myRegistries = require "ExperiencedDriver_registries"


local function addMutuallyExclusive()
    local myTrait = myRegistries.traits.AceDriver
    if not myTrait then return end

    local exclusiveList = {
        CharacterTrait.AGORAPHOBIC,
        CharacterTrait.SUNDAY_DRIVER, 
        CharacterTrait.CLAUSTROPHOBIC
    }
    
    for _, v in pairs(exclusiveList) do
        CharacterTraitDefinition.getCharacterTraitDefinition(v):
            addMutuallyExclusive(myTrait)
    end 
end

---@param object IsoObject
---@return table
function ExperiencedDriver.getData(object)
    if object ~= nil then
        local data = object:getModData()
        data.ExperiencedDriver = data.ExperiencedDriver or {}

        return data.ExperiencedDriver
    end

    return {}
end

-- Test Function
local function ohMyPcccccccc(key)
    if SandboxVars.ExperiencedDriver.DEBUG then
        if key == Keyboard.KEY_NUMPAD0 then
            local player = getPlayer()
            if player ~= nil then
                local playerData = ExperiencedDriver.getData(player)
                print("Wether Unlocked: " .. tostring(playerData.unlocked))
                print("Perk Level: " .. 
                    tostring(player:getPerkLevel(PerkFactory.getPerkFromName("Driving"))))
                print("Am I a driver: " .. tostring(playerData.vehicleID))                
                local vehicle = player:getVehicle()
                if vehicle ~= nil then
                    local vehicleData = ExperiencedDriver.getData(vehicle)
                    print("========Vehicle Info========")
                    print("BrakingForce: " .. tostring(vehicle:getBrakingForce()))
                    print("EngineNoise: " .. tostring(vehicle:getEngineLoudness()))
                    print("MaxSpeed: " .. tostring(vehicle:getMaxSpeed()))
                    if vehicleData.driver ~= nil then
                        print("Owner: " .. vehicleData.driver)
                    end
                end
            end

            print("=====[DEBUG END] Something went wrong if I appear alone=====")
        elseif key == Keyboard.KEY_NUMPAD1 then
            -- local player = getPlayer()
            -- local perk = Perks.Driving

            -- print("Perk = " .. tostring(perk))
            -- print("Type = " .. tostring(perk:getType()))
            -- print("Name = " .. tostring(perk:getName()))
            -- print("Text = " .. tostring(getText("IGUI_perks_" .. tostring(perk:getName()))))
            -- print("Desc = " .. tostring(getText("IGUI_perks_" .. tostring(perk:getName()) .. "_Description")))
            -- if player ~= nil then 
            --     sendClientCommand("ExperiencedDriver", "TEST", {onlineID = player:getOnlineID()})                 
            -- end

            -- print("=====[DEBUG END] Something went wrong if I appear alone=====")
        end
    end
end

Events.OnGameBoot.Add(addMutuallyExclusive)
Events.OnKeyStartPressed.Add(ohMyPcccccccc)


