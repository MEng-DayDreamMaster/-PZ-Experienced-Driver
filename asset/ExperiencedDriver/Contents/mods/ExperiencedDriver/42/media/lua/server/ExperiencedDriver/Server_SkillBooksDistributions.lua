require 'Items/SuburbsDistributions'
require 'Items/ProceduralDistributions'

local bookData = {
	{name = "ExperiencedDriver.BookDriving1", weights = {10, 6, 1, 10, 1, 2, 10, 2, 10}},
	{name = "ExperiencedDriver.BookDriving2", weights = {8, 4, 0.8, 8, 0.8, 1, 8, 1, 8}},
	{name = "ExperiencedDriver.BookDriving3", weights = {6, 2, 0.6, 6, 0.6, 0.5, 6, 0.5, 6}},
	{name = "ExperiencedDriver.BookDriving4", weights = {4, 1, 0.4, 4, 0.4, 0.1, 4, 0.1, 4}},
	{name = "ExperiencedDriver.BookDriving5", weights = {2, 0.5, 0.2, 2, 0.2, 0.01, 2, 0.05, 2}},
}

local targets = {
	"BookstoreBooks",
	"CrateBooks",
	"GarageFirearms",
	"GunStoreLiterature",
	"HuntingLockers",
	"SurvivalGear",
	"BookstoreOutdoors",
	"CampingLockers",
	"CampingStoreBooks",
}

for i, distribution in ipairs(targets) do
	local items = ProceduralDistributions["list"][distribution].items
	for _, book in ipairs(bookData) do
		table.insert(items, book.name)
		table.insert(items, book.weights[i])
	end
end
