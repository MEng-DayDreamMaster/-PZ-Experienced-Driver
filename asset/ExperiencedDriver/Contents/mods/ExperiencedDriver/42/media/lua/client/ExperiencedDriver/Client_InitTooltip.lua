require "XpSystem/ISUI/ISSkillProgressBar"

local originalUpdateTooltip = ISSkillProgressBar.updateTooltip
local originalRenderPerkRect = ISSkillProgressBar.renderPerkRect

function ISSkillProgressBar:updateTooltip(lvlSelected)

    originalUpdateTooltip(self, lvlSelected)

    if self.perk:getName() == "Driving" then
        local player = self.char
        local data = ExperiencedDriver.getData(player)

        if not data.unlocked then
            self.message =
                self.perk:getName()
                .. " <LINE> "
                .. getText("IGUI_XP_Locked")
                .. " <LINE><LINE> "
                .. getText("IGUI_ExperiencedDriver_LockedDescription")
        end
    end
end

function ISSkillProgressBar:renderPerkRect()
    if self.perk:getName() == "Driving" then
        local data = ExperiencedDriver.getData(self.char)

        if not data.unlocked then
            -- 复制源文件的定义，保证render长度一致
            local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
            local SKILL_POINT_HGT = math.floor((FONT_HGT_SMALL + 6)/2)
            local SKILL_POINT_SPACING = getCore():getOptionFontSizeReal()
            local x = 0
            local y = 0

            -- 原始 i = self.level + 1, 9
            for _i = 0, 9 do
		        self:drawTextureScaled(self.SkillUnitBorder, x, y, SKILL_POINT_HGT, SKILL_POINT_HGT, 1, 0.2, 0.2, 0.2)
		        x = x + SKILL_POINT_HGT + SKILL_POINT_SPACING
	        end

            return
        end
    end

    originalRenderPerkRect(self)
end