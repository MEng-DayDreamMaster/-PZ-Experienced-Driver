local MyRegistries = require "ExperiencedDriver_registries"

local function onNewGame(player, _square)
    if not player then return end

    if not MyRegistries or not MyRegistries.traits or MyRegistries.traits == {} then return end

    if player:hasTrait(MyRegistries.traits.AceDriver) then
        local data = ExperiencedDriver.getData(player)
        player:addKnownMediaLine(ExperiencedDriver.INTERACTION_GUID)
        data.unlocked = true

        if isMultiplayer() then
            player:transmitModData()
        end
    end
end

Events.OnNewGame.Add(onNewGame)