local MODULE = "ExperiencedDriver"

---@param player IsoPlayer
---@param args table
function ExperiencedDriver.unlockSkillServer(player, args)
    local data = ExperiencedDriver.getData(player)
    if data == nil then return end

    if args.guid ~= ExperiencedDriver.INTERACTION_GUID then return end
    
    if player:isKnownMediaLine(args.guid) then
        data.unlocked = true
        if isServer() then
            player:transmitModData()
            sendServerCommand(player, MODULE, "Unlocked", {})            
        else
            triggerEvent(
                "OnServerCommand",
                MODULE,
                "Unlocked",
                {}
            )
        end
    end    
end