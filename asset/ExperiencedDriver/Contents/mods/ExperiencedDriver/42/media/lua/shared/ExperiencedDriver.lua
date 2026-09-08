ExperiencedDriver = ExperiencedDriver or {}
ExperiencedDriver.CompatibleList = ExperiencedDriver.CompatibleList or {}

local myRegistries = require "ExperiencedDriver_registries"
local find = string.find

ExperiencedDriver.INTERACTION_GUID = "RM_14eaf741-67cb-4be8-93bd-bc6d35ccfe8b"
ExperiencedDriver.ACEDRIVER = myRegistries.traits.AceDriver


local function addMutuallyExclusive()
    if not ExperiencedDriver.ACEDRIVER then return end

    local exclusiveList = {
        CharacterTrait.AGORAPHOBIC,
        CharacterTrait.SUNDAY_DRIVER, 
        CharacterTrait.CLAUSTROPHOBIC
    }
    
    for _, v in pairs(exclusiveList) do
        CharacterTraitDefinition.getCharacterTraitDefinition(v):
            addMutuallyExclusive(ExperiencedDriver.ACEDRIVER)
    end 
end

local function addCompatibleMod()
    local BeyondTen = _G.BeyondTen
    if type(BeyondTen) == "table" then
        ExperiencedDriver.CompatibleList["BeyondTen"] = true
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

---@param partId string
---@return boolean
function ExperiencedDriver.isPartInclusive(partId)
    local inclusiveSet = {
        TrunkDoor = true,
        TruckBed = true,
        EngineDoor = true,
        Windshield = true,
        WindshieldRear = true,
        WindowFrontLeft = true,
        WindowFrontRight = true,
        WindowRearLeft = true,
        WindowRearRight = true,
        WindowBackLeft = true ,
        WindowBackRight = true,
        DoorFrontLeft = true,
        DoorFrontRight = true,
        DoorRear = true,
        DoorRearLeft = true,
        DoorRearRight = true,
        HeadlightLeft = true,
        HeadlightRight = true,
        HeadlightRearLeft = true,
        HeadlightRearRight = true,
        StorageLidLeft = true,
        StorageLidRight = true,
        DAMNBumperFront = true,
        DAMNBumperRear = true,
        DAMNWindshieldArmor = true,
        DAMNWindshieldRearArmor = true,
        DAMNFrontLeftArmor = true,
        DAMNFrontRightArmor = true,
        DAMNBackLeftArmor = true,
        DAMNBackRightArmor = true,
        DAMNRearLeftArmor = true,
        DAMNRearRightArmor = true,
        DAMNSideSteps = true
    }

    local isInclusive = inclusiveSet[partId]
    if isInclusive ~= nil then
        return isInclusive
    else
        local len = #partId
        if find(partId, "Armor", len - 4, true) == len - 4 then
            return true
        end

        return false
    end
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
                    tostring(player:getPerkLevel(Perks.Driving)))
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

        elseif key == Keyboard.KEY_NUMPAD2 then
            local player = getPlayer()
            if player ~= nil then             
                local vehicle = player:getVehicle()
                if vehicle ~= nil then
                    print("========Vehicle Parts========")
                    local counts = vehicle:getPartCount()
                    for i = 0, counts - 1 do
                        local part = vehicle:getPartByIndex(i)
                        if part ~= nil then
                            print(string.format("\"%s\": %d", part:getId(), part:getCondition()))
                        end
                    end
                end
            end

            print("=====[DEBUG END] Something went wrong if I appear alone=====")

        elseif key == Keyboard.KEY_NUMPAD3 then
            local player = getPlayer()
            if player ~= nil then
                print("========Beyond Ten Test========")
                ---@diagnostic disable-next-line: unnecessary-if
                if ExperiencedDriver.CompatibleList["BeyondTen"] then
                    local BeyondTen = _G.BeyondTen
                    print(BeyondTen.GetEffectiveLevel(player, Perks.Driving))
                end
            end
            print("=====[DEBUG END] Something went wrong if I appear alone=====")
        end
    end
end

Events.OnGameBoot.Add(addMutuallyExclusive)
Events.OnGameStart.Add(addCompatibleMod)
Events.OnKeyStartPressed.Add(ohMyPcccccccc)
