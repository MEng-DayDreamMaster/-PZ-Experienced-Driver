require 'Items/SuburbsDistributions'
require 'Items/ProceduralDistributions'

-- SkillBooks
local bookData = {
	{name = "ExperiencedDriver.BookDriving1", weights = {10, 6, 1, 10, 1, 1, 10, 2}},
	{name = "ExperiencedDriver.BookDriving2", weights = {8, 4, 0.8, 8, 0.8, 0.8, 8, 1}},
	{name = "ExperiencedDriver.BookDriving3", weights = {6, 2, 0.6, 6, 0.6, 0.5, 6, 0.5}},
	{name = "ExperiencedDriver.BookDriving4", weights = {4, 1, 0.4, 4, 0.4, 0.1, 4, 0.1}},
	{name = "ExperiencedDriver.BookDriving5", weights = {2, 0.5, 0.2, 2, 0.2, 0.01, 2, 0.05}},
}

local targets = {
	"BookstoreBooks",
	"BookstoreOutdoors",
	"GarageMechanics",
	"CrateBooks",
	"LibraryOutdoors",
	"CrateBooksSchool",
	"LibraryBooks",
	"UniversityLibraryBooks"
}

for i, distribution in ipairs(targets) do
	local items = ProceduralDistributions["list"][distribution].items
	for _, book in ipairs(bookData) do
		table.insert(items, book.name)
		table.insert(items, book.weights[i])
	end
end

-- VHS Guarantee Spawn
local recordMediaUUID = "c546f657-9c40-4e99-9581-1c95c5de6e3d"
---@param cell IsoCell
local function vhsGuarantee(cell, _x, _y)
	if isClient() then return end
	local data = ModData.getOrCreate("ExpDriver")
	---@diagnostic disable-next-line: unnecessary-if
	if data.generated then return end

	local targetX = 8001
	local targetY = 11659		-- 罗斯伍德驾校教室的左下角
	local targetSquare = getCell():getGridSquare(targetX, targetY, 0)
	local targetCell = targetSquare:getCell()

	if cell == nil or targetSquare == nil or cell ~= targetCell then return end

	local objects = targetSquare:getObjects()
	for i = 0, objects:size() - 1 do
		local object = objects:get(i)
		local sprite = object:getSprite()

		if sprite ~= nil and sprite:getID() == 149017 then
			local container = object:getContainer()
			if container ~= nil then
				local item = container:AddItem("Base.VHS_Retail")
				if item ~= nil then
					local mediaData = getZomboidRadio():getRecordedMedia():getMediaData(recordMediaUUID)
					if mediaData ~= nil then	
						---@diagnostic disable-next-line: need-check-nil	
						item:setRecordedMediaData(mediaData)
						data.generated = true
						return
					end
				end
			end
		end
	end
end

Events.OnPostMapLoad.Add(vhsGuarantee)