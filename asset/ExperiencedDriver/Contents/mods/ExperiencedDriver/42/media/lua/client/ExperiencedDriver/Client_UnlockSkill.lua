local MODULE = "ExperiencedDriver"

local function unlockSkillRequest(guid, _codes, x, y, z, _text, _device)
    if guid ~= ExperiencedDriver.INTERACTION_GUID then return end

    local player = getPlayer()
    if player == nil then return end

    local data = ExperiencedDriver.getData(player)
    if data == nil or data.unlocked then return end

    local ISRadioInteractions = ISRadioInteractions:getInstance()
    if ISRadioInteractions.playerInRange(player, x, y, z) then
        -- 特别警惕：如果 args 是 {}，接收方判空会得到 nil，不要给 args 加判空
        -- 只有确保 args 不为空的时候才可以直接使用引用传递
        local args = { guid = guid }
        
        if isClient() then
            args.onlineID = player:getOnlineID()            
        end

        sendClientCommand(
            MODULE, 
            "UnlockRequest", 
            args
        )        
    end 
end

Events.OnDeviceText.Add(unlockSkillRequest)



