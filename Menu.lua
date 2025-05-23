-------------------------------------------------------------------------------------------------
-- Utility Functions --
-------------------------------------------------------------------------------------------------
local function ConvertRGBToHex(r, g, b)
    return string.format("|c%.2x%.2x%.2x", zo_floor(r * 255), zo_floor(g * 255), zo_floor(b * 255))
end

local function ConvertHexToRGB(colourString)
    local r=tonumber(string.sub(colourString, 3, 4), 16) or 255
    local g=tonumber(string.sub(colourString, 5, 6), 16) or 255
    local b=tonumber(string.sub(colourString, 7, 8), 16) or 255
    return r/255, g/255, b/255
end

local function setFouthSkillIndexToReplace()
    for i=1, 4 do 
        if i ~= self.savedVariables.skillIndexToReplace[1] and i ~= self.savedVariables.skillIndexToReplace[2] and i ~= self.savedVariables.skillIndexToReplace[3] then
            self.savedVariables.skillIndexToReplace[4] = i
        end
    end
end

local function GetFormattedChampionSkillName(skillId)
    return ZO_CachedStrFormat(SI_CHAMPION_STAR_NAME, GetChampionSkillName(skillId))
end

local function refreshConflict(string)
    JackOfAllTrades.UpdateSkillSlots()
end

-------------------------------------------------------------------------------------------------
-- Lib Addon Menu Variables --
-------------------------------------------------------------------------------------------------
function JackOfAllTrades:InitMenu()
    local LAM = LibAddonMenu2
    -- If for whatever reason we can't find LAM then just don't initialize the menu 
    if LAM == nil then return end
    local panelName = "JackOfAllTradesSettings"
    local panelData = {
        type = "panel",
        name = "Jack of all Trades",
        displayName = string.format("%s%s|u5:0::Jack of all Trades|u", "|t32:32:esoui/art/champion/champion_points_stamina_icon-hud-32.dds|t", ""),
        author = string.format("%s@CyberOnEso|r", self.colours.author),
        --website = "https://www.esoui.com/forums/showthread.php?p=43242",
        version = self.version,
        slashCommand = "/jackofalltrades",
        registerForRefresh = true
    }

    local panel = LAM:RegisterAddonPanel(panelName, panelData)
    local optionsData = {
        {
            type = "description",
            text = SI_JACK_OF_ALL_TRADES_MENU_INTRO,
            --text = "Jack of all Trades will only modify your 3rd and 4th slots on your champion bar.\nThis is due to the new CP slotting cooldown implemented by ZOS, thus skills that need to be changed often like Gifted Rider will not automatically be slotted\nThis leaves you free to slot whatever you like in slots 1 and 2 as they will not be overwritten.\nI recommend you slot Steed's Blessing and Gifted Rider in slots 1 and 2."
        },
        {
            type = "header",
            name = SI_JACK_OF_ALL_TRADES_MENU_COOLDOWN,
            width = "full"
        },
        {
            type = "description",
            text = SI_JACK_OF_ALL_TRADES_MENU_COOLDOWN_DESC,
            width = "full"
        },
        {
            type = "checkbox",
            name = SI_JACK_OF_ALL_TRADES_MENU_COOLDOWN_ALERT,
            getFunc = function() return self.savedVariables.showCooldownError end,
            setFunc = function(value) self.savedVariables.showCooldownError = value end,
            tooltip = GetString(SI_JACK_OF_ALL_TRADES_MENU_TOOLTIP_CHANGES),
            width = "full"
        },
        {
            type = "checkbox",
            name = SI_JACK_OF_ALL_TRADES_MENU_SLOT_AFTER_CD,
            getFunc = function() return self.savedVariables.slotSkillsAfterCooldownEnds end,
            setFunc = function(value) self.savedVariables.slotSkillsAfterCooldownEnds = value end,
            width = "full"
        },
        {
            type = "checkbox",
            name = SI_JACK_OF_ALL_TRADES_MENU_ALTER_AFTER_CD,
            getFunc = function() return self.savedVariables.altertedAfterCooldownOver end,
            setFunc = function(value) 
                if self.savedVariables.altertedAlwaysAfterCooldownOver then self.savedVariables.altertedAfterCooldownOver = false return end
                if self.savedVariables.slotSkillsAfterCooldownEnds then self.savedVariables.altertedAfterCooldownOver = false return end
                self.savedVariables.altertedAfterCooldownOver = value end,
          tooltip = GetString(SI_JACK_OF_ALL_TRADES_MENU_TOOLTIP_CD_COMPLETE_CHAT),
            width = "full",
            disabled = function() return self.savedVariables.slotSkillsAfterCooldownEnds or self.savedVariables.altertedAlwaysAfterCooldownOver end,            
        },
        {
            type = "checkbox",
            name = SI_JACK_OF_ALL_TRADES_MENU_ALWAYS_ALERT_AFTER_CD,
            getFunc = function() return self.savedVariables.altertedAlwaysAfterCooldownOver end,
            setFunc = function(value) 
                if self.savedVariables.altertedAfterCooldownOver then self.savedVariables.altertedAlwaysAfterCooldownOver = false return end
                if self.savedVariables.altertedAfterCooldownOver then self.savedVariables.altertedAlwaysAfterCooldownOver = false end
                self.savedVariables.altertedAlwaysAfterCooldownOver = value end,
            tooltip = GetString(SI_JACK_OF_ALL_TRADES_MENU_TOOLTIP_CD_COMPLETE_ALWAYS),
            width = "full",
            disabled = function() return self.savedVariables.altertedAfterCooldownOver end,            
        },
        {
            type = "header",
            name = SI_JACK_OF_ALL_TRADES_MENU_NOTIFICATIONS,
            width = "full"
        },
        {
            type = "description",
            text = SI_JACK_OF_ALL_TRADES_MENU_NOTIFICATIONS_DESCRIPTION_GLOBAL,
            width = "full"
        },
        {   
            type = "checkbox",
            name = SI_JACK_OF_ALL_TRADES_MENU_NOTIFICATIONS_GLOBAL,
            -- If all nodes are true, set to True, else false
            getFunc = function() 
                        for node, state in pairs(self.savedVariables.notification) do 
                            if self.savedVariables.notification[node] == false then 
                                return false 
                            end 
                        end 
                        return true
                    end,
            -- Set all nodes to this value
            setFunc = function(value)
                        for node, state in pairs(self.savedVariables.notification) do 
                            self.savedVariables.notification[node] = value
                        end 
                    end,
            width = "full"
        },
        {   
            type = "submenu",
            name = SI_JACK_OF_ALL_TRADES_MENU_NOTIFICATIONS_INDIVIDUAL,
            controls = {
                {
                    type = "custom",
                    name = SI_JACK_OF_ALL_TRADES_MENU_HARVESTING,
                    --reference = "MyAddonCustomControl", -- unique name for your control to use as reference (optional)
                    createFunc = function(customControl) 
                        local wm = WINDOW_MANAGER
                        customControl.header = wm:CreateControlFromVirtual(nil, customControl, "ZO_Options_SectionTitleLabel")
                        local header = customControl.header
                        --header:SetAnchor(TOPLEFT, divider, BOTTOMLEFT)
                        header:SetAnchor(TOPLEFT)
                        header:SetFont("ZoFontHeader2")
                        header:SetText(GetString(SI_JACK_OF_ALL_TRADES_MENU_HARVESTING))
                    end, -- function to call when this custom control was created (optional)
                    refreshFunc = function(customControl) end, -- function to call when panel/controls refresh (optional)
                    width = "full", -- or "half" (optional)
                    minHeight = function() return 18 end, --or number for the minimum height of this control. Default: 26 (optional)
                    maxHeight = function() return 18 end, --or number for the maximum height of this control. Default: 4 * minHeight (optional)
                },
                {
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("masterGatherer")),
                    getFunc = function() return self.savedVariables.notification.masterGatherer end,
                    setFunc = function(value) self.savedVariables.notification.masterGatherer = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("masterGatherer"), 1000),
                    width = "half"
                },
                {
                    type = "custom",
                    name = SI_JACK_OF_ALL_TRADES_MENU_FISHING,
                    --reference = "MyAddonCustomControl", -- unique name for your control to use as reference (optional)
                    createFunc = function(customControl) 
                        local wm = WINDOW_MANAGER
                        customControl.header = wm:CreateControlFromVirtual(nil, customControl, "ZO_Options_SectionTitleLabel")
                        local header = customControl.header
                        --header:SetAnchor(TOPLEFT, divider, BOTTOMLEFT)
                        header:SetAnchor(TOPLEFT)
                        header:SetFont("ZoFontHeader2")
                        header:SetText(GetString(SI_JACK_OF_ALL_TRADES_MENU_FISHING))
                    end, -- function to call when this custom control was created (optional)
                    refreshFunc = function(customControl) end, -- function to call when panel/controls refresh (optional)
                    width = "full", -- or "half" (optional)
                    minHeight = function() return 18 end, --or number for the minimum height of this control. Default: 26 (optional)
                    maxHeight = function() return 18 end, --or number for the maximum height of this control. Default: 4 * minHeight (optional)
                },
                {
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("reelTechnique")),
                    getFunc = function() return self.savedVariables.notification.reelTechnique end,
                    setFunc = function(value) self.savedVariables.notification.reelTechnique = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("reelTechnique"), 1000),
                    width = "half"
                },
                {
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("anglersInstinct")),
                    getFunc = function() return self.savedVariables.notification.anglersInstinct end,
                    setFunc = function(value) self.savedVariables.notification.anglersInstinct = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("anglersInstinct"), 1000),
                    width = "half"
                },
                {
                    type = "custom",
                    name = SI_JACK_OF_ALL_TRADES_MENU_THIEVING,
                    --reference = "MyAddonCustomControl", -- unique name for your control to use as reference (optional)
                    createFunc = function(customControl) 
                        local wm = WINDOW_MANAGER
                        customControl.header = wm:CreateControlFromVirtual(nil, customControl, "ZO_Options_SectionTitleLabel")
                        local header = customControl.header
                        --header:SetAnchor(TOPLEFT, divider, BOTTOMLEFT)
                        header:SetAnchor(TOPLEFT)
                        header:SetFont("ZoFontHeader2")
                        header:SetText(GetString(SI_JACK_OF_ALL_TRADES_MENU_THIEVING))
                    end, -- function to call when this custom control was created (optional)
                    refreshFunc = function(customControl) end, -- function to call when panel/controls refresh (optional)
                    width = "full", -- or "half" (optional)
                    minHeight = function() return 18 end, --or number for the minimum height of this control. Default: 26 (optional)
                    maxHeight = function() return 18 end, --or number for the maximum height of this control. Default: 4 * minHeight (optional)
                },
                {
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("sustainingShadows")),
                    getFunc = function() return self.savedVariables.notification.sustainingShadows end,
                    setFunc = function(value) self.savedVariables.notification.sustainingShadows = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("sustainingShadows"), 1000),
                    width = "half"
                },
                {
                    type = "custom",
                    name = SI_JACK_OF_ALL_TRADES_MENU_RIDING,
                    --reference = "MyAddonCustomControl", -- unique name for your control to use as reference (optional)
                    createFunc = function(customControl) 
                        local wm = WINDOW_MANAGER
                        customControl.header = wm:CreateControlFromVirtual(nil, customControl, "ZO_Options_SectionTitleLabel")
                        local header = customControl.header
                        --header:SetAnchor(TOPLEFT, divider, BOTTOMLEFT)
                        header:SetAnchor(TOPLEFT)
                        header:SetFont("ZoFontHeader2")
                        header:SetText(GetString(SI_JACK_OF_ALL_TRADES_MENU_RIDING))
                    end, -- function to call when this custom control was created (optional)
                    refreshFunc = function(customControl) end, -- function to call when panel/controls refresh (optional)
                    width = "full", -- or "half" (optional)
                    minHeight = function() return 18 end, --or number for the minimum height of this control. Default: 26 (optional)
                    maxHeight = function() return 18 end, --or number for the maximum height of this control. Default: 4 * minHeight (optional)
                },
                {
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("giftedRider")),
                    getFunc = function() return self.savedVariables.notification.giftedRider end,
                    setFunc = function(value) self.savedVariables.notification.giftedRider = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("giftedRider"), 1000),
                    width = "half"
                },
                {
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("warMount")),
                    getFunc = function() return self.savedVariables.notification.warMount end,
                    setFunc = function(value) self.savedVariables.notification.warMount = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("warMount"), 1000),
                    width = "half"
                },
            },
        },
        {
            type = "colorpicker",
            name = zo_strformat(SI_JACK_OF_ALL_TRADES_TEXT_COLOUR, GetString(SI_JACK_OF_ALL_TRADES_NOTIFICATION)), -- or string id or function returning a string
            getFunc = function()
                        return ConvertHexToRGB(self.savedVariables.colour.notifications)
                    end, -- (alpha is optional)
            setFunc = function(r,g,b) 
                        self.savedVariables.colour.notifications = ConvertRGBToHex(r, g, b)
                    end, -- (alpha is optional)
            disabled = function() 
                        for node, state in pairs(self.savedVariables.notification) do 
                            if self.savedVariables.notification[node] == true then 
                                return false 
                            end 
                        end 
                        return true
                    end
        },
        {
            type = "checkbox",
            name = SI_JACK_OF_ALL_TRADES_MENU_ALERT_NOTIFICATION,
            getFunc = function() return self.savedVariables.alertNotification end,
            setFunc = function(value) self.savedVariables.alertNotification = value end,
            tooltip = SI_JACK_OF_ALL_TRADES_MENU_ALERT_NOTIFICATION_TOOLTIP,
            width = "full"
        },
        {
            type = "checkbox",
            name = SI_JACK_OF_ALL_TRADES_MENU_TEXTURE_NOTIFICATION,
            getFunc = function() return self.savedVariables.textureNotification end,
            setFunc = function(value) self.savedVariables.textureNotification = value end,
            tooltip = SI_JACK_OF_ALL_TRADES_MENU_TEXTURE_NOTIFICATION_TOOLTIP,
            width = "full"
        },
        {
            type = "header",
            name = SI_JACK_OF_ALL_TRADES_WARNING,
            width = "full"
        },
        {
            type = "description",
            text = SI_JACK_OF_ALL_TRADES_MENU_WARNING_DESCRIPTION,
            width = "full"
        },
        {   
            type = "checkbox",
            name = SI_JACK_OF_ALL_TRADES_MENU_NOTIFICATIONS_GLOBAL,
            -- If all nodes are true, set to True, else false
            getFunc = function() 
                        for node, state in pairs(self.savedVariables.warnings) do 
                            if self.savedVariables.warnings[node] == false then 
                                return false 
                            end 
                        end 
                        return true
                    end,
            -- Set all nodes to this value
            setFunc = function(value)
                        for node, state in pairs(self.savedVariables.warnings) do 
                            self.savedVariables.warnings[node] = value
                        end 
                    end,
            width = "full"
        },
        {   
            type = "submenu",
            name = SI_JACK_OF_ALL_TRADES_MENU_NOTIFICATIONS_INDIVIDUAL,
            controls = {
                {
                    type = "custom",
                    name = SI_JACK_OF_ALL_TRADES_MENU_CRAFTING,
                    --reference = "MyAddonCustomControl", -- unique name for your control to use as reference (optional)
                    createFunc = function(customControl) 
                        local wm = WINDOW_MANAGER
                        customControl.header = wm:CreateControlFromVirtual(nil, customControl, "ZO_Options_SectionTitleLabel")
                        local header = customControl.header
                        --header:SetAnchor(TOPLEFT, divider, BOTTOMLEFT)
                        header:SetAnchor(TOPLEFT)
                        header:SetFont("ZoFontHeader2")
                        header:SetText(GetString(SI_JACK_OF_ALL_TRADES_MENU_CRAFTING))
                    end, -- function to call when this custom control was created (optional)
                    refreshFunc = function(customControl) end, -- function to call when panel/controls refresh (optional)
                    width = "full", -- or "half" (optional)
                    minHeight = function() return 18 end, --or number for the minimum height of this control. Default: 26 (optional)
                    maxHeight = function() return 18 end, --or number for the maximum height of this control. Default: 4 * minHeight (optional)
                },
                {   
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("meticulousDisassembly")),
                    getFunc = function() return self.savedVariables.warnings.meticulousDisassembly end,
                    setFunc = function(value) self.savedVariables.warnings.meticulousDisassembly = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("meticulousDisassembly"), 1000),
                    width = "half"
                },
                {
                    type = "custom",
                    name = SI_JACK_OF_ALL_TRADES_MENU_HARVESTING,
                    --reference = "MyAddonCustomControl", -- unique name for your control to use as reference (optional)
                    createFunc = function(customControl) 
                        local wm = WINDOW_MANAGER
                        customControl.header = wm:CreateControlFromVirtual(nil, customControl, "ZO_Options_SectionTitleLabel")
                        local header = customControl.header
                        --header:SetAnchor(TOPLEFT, divider, BOTTOMLEFT)
                        header:SetAnchor(TOPLEFT)
                        header:SetFont("ZoFontHeader2")
                        header:SetText(GetString(SI_JACK_OF_ALL_TRADES_MENU_HARVESTING))
                    end, -- function to call when this custom control was created (optional)
                    refreshFunc = function(customControl) end, -- function to call when panel/controls refresh (optional)
                    width = "full", -- or "half" (optional)
                    minHeight = function() return 18 end, --or number for the minimum height of this control. Default: 26 (optional)
                    maxHeight = function() return 18 end, --or number for the maximum height of this control. Default: 4 * minHeight (optional)
                },
                {
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("masterGatherer")),
                    getFunc = function() return self.savedVariables.warnings.masterGatherer end,
                    setFunc = function(value) self.savedVariables.warnings.masterGatherer = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("masterGatherer"), 1000),
                    width = "half"
                },
                {
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("plentifulHarvest")),
                    getFunc = function() return self.savedVariables.warnings.plentifulHarvest end,
                    setFunc = function(value) self.savedVariables.warnings.plentifulHarvest = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("plentifulHarvest"), 1000),
                    width = "half"
                },
                {
                    type = "custom",
                    name = SI_JACK_OF_ALL_TRADES_MENU_LOOTING,
                    --reference = "MyAddonCustomControl", -- unique name for your control to use as reference (optional)
                    createFunc = function(customControl) 
                        local wm = WINDOW_MANAGER
                        customControl.header = wm:CreateControlFromVirtual(nil, customControl, "ZO_Options_SectionTitleLabel")
                        local header = customControl.header
                        --header:SetAnchor(TOPLEFT, divider, BOTTOMLEFT)
                        header:SetAnchor(TOPLEFT)
                        header:SetFont("ZoFontHeader2")
                        header:SetText(GetString(SI_JACK_OF_ALL_TRADES_MENU_LOOTING))
                    end, -- function to call when this custom control was created (optional)
                    refreshFunc = function(customControl) end, -- function to call when panel/controls refresh (optional)
                    width = "full", -- or "half" (optional)
                    minHeight = function() return 18 end, --or number for the minimum height of this control. Default: 26 (optional)
                    maxHeight = function() return 18 end, --or number for the maximum height of this control. Default: 4 * minHeight (optional)
                },
                {
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("treasureHunter")),
                    getFunc = function() return self.savedVariables.warnings.treasureHunter end,
                    setFunc = function(value) self.savedVariables.warnings.treasureHunter = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("treasureHunter"), 1000),
                    width = "half"
                },
                {
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("homemaker")),
                    getFunc = function() return self.savedVariables.warnings.homemaker end,
                    setFunc = function(value) self.savedVariables.warnings.homemaker = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("homemaker"), 1000),
                    width = "half"
                },
                {
                    type = "custom",
                    name = SI_JACK_OF_ALL_TRADES_MENU_FISHING,
                    --reference = "MyAddonCustomControl", -- unique name for your control to use as reference (optional)
                    createFunc = function(customControl) 
                        local wm = WINDOW_MANAGER
                        customControl.header = wm:CreateControlFromVirtual(nil, customControl, "ZO_Options_SectionTitleLabel")
                        local header = customControl.header
                        --header:SetAnchor(TOPLEFT, divider, BOTTOMLEFT)
                        header:SetAnchor(TOPLEFT)
                        header:SetFont("ZoFontHeader2")
                        header:SetText(GetString(SI_JACK_OF_ALL_TRADES_MENU_FISHING))
                    end, -- function to call when this custom control was created (optional)
                    refreshFunc = function(customControl) end, -- function to call when panel/controls refresh (optional)
                    width = "full", -- or "half" (optional)
                    minHeight = function() return 18 end, --or number for the minimum height of this control. Default: 26 (optional)
                    maxHeight = function() return 18 end, --or number for the maximum height of this control. Default: 4 * minHeight (optional)
                },
                {
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("reelTechnique")),
                    getFunc = function() return self.savedVariables.warnings.reelTechnique end,
                    setFunc = function(value) self.savedVariables.warnings.reelTechnique = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("reelTechnique"), 1000),
                    width = "half"
                },
                {
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("anglersInstinct")),
                    getFunc = function() return self.savedVariables.warnings.anglersInstinct end,
                    setFunc = function(value) self.savedVariables.warnings.anglersInstinct = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("anglersInstinct"), 1000),
                    width = "half"
                },
                {
                    type = "custom",
                    name = SI_JACK_OF_ALL_TRADES_MENU_THIEVING,
                    --reference = "MyAddonCustomControl", -- unique name for your control to use as reference (optional)
                    createFunc = function(customControl) 
                        local wm = WINDOW_MANAGER
                        customControl.header = wm:CreateControlFromVirtual(nil, customControl, "ZO_Options_SectionTitleLabel")
                        local header = customControl.header
                        --header:SetAnchor(TOPLEFT, divider, BOTTOMLEFT)
                        header:SetAnchor(TOPLEFT)
                        header:SetFont("ZoFontHeader2")
                        header:SetText(GetString(SI_JACK_OF_ALL_TRADES_MENU_THIEVING))
                    end, -- function to call when this custom control was created (optional)
                    refreshFunc = function(customControl) end, -- function to call when panel/controls refresh (optional)
                    width = "full", -- or "half" (optional)
                    minHeight = function() return 18 end, --or number for the minimum height of this control. Default: 26 (optional)
                    maxHeight = function() return 18 end, --or number for the maximum height of this control. Default: 4 * minHeight (optional)
                },
                {
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("infamous")),
                    getFunc = function() return self.savedVariables.warnings.infamous end,
                    setFunc = function(value) self.savedVariables.warnings.infamous = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("infamous"), 1000),
                    width = "half"
                },
                {
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("cutpursesArt")),
                    getFunc = function() return self.savedVariables.warnings.cutpursesArt end,
                    setFunc = function(value) self.savedVariables.warnings.cutpursesArt = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("cutpursesArt"), 1000),
                    width = "half"
                },
                {
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("sustainingShadows")),
                    getFunc = function() return self.savedVariables.warnings.sustainingShadows end,
                    setFunc = function(value) self.savedVariables.warnings.sustainingShadows = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("sustainingShadows"), 1000),
                    width = "half"
                },
                {
                    type = "custom",
                    name = SI_JACK_OF_ALL_TRADES_MENU_RIDING,
                    --reference = "MyAddonCustomControl", -- unique name for your control to use as reference (optional)
                    createFunc = function(customControl) 
                        local wm = WINDOW_MANAGER
                        customControl.header = wm:CreateControlFromVirtual(nil, customControl, "ZO_Options_SectionTitleLabel")
                        local header = customControl.header
                        --header:SetAnchor(TOPLEFT, divider, BOTTOMLEFT)
                        header:SetAnchor(TOPLEFT)
                        header:SetFont("ZoFontHeader2")
                        header:SetText(GetString(SI_JACK_OF_ALL_TRADES_MENU_RIDING))
                    end, -- function to call when this custom control was created (optional)
                    refreshFunc = function(customControl) end, -- function to call when panel/controls refresh (optional)
                    width = "full", -- or "half" (optional)
                    minHeight = function() return 18 end, --or number for the minimum height of this control. Default: 26 (optional)
                    maxHeight = function() return 18 end, --or number for the maximum height of this control. Default: 4 * minHeight (optional)
                },
                {
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("giftedRider")),
                    getFunc = function() return self.savedVariables.warnings.giftedRider end,
                    setFunc = function(value) self.savedVariables.warnings.giftedRider = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("giftedRider"), 1000),
                    width = "half"
                },
                {
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("warMount")),
                    getFunc = function() return self.savedVariables.warnings.warMount end,
                    setFunc = function(value) self.savedVariables.warnings.warMount = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("warMount"), 1000),
                    width = "half"
                },
                {
                    type = "custom",
                    name = SI_JACK_OF_ALL_TRADES_MENU_MISC,
                    --reference = "MyAddonCustomControl", -- unique name for your control to use as reference (optional)
                    createFunc = function(customControl) 
                        local wm = WINDOW_MANAGER
                        customControl.header = wm:CreateControlFromVirtual(nil, customControl, "ZO_Options_SectionTitleLabel")
                        local header = customControl.header
                        --header:SetAnchor(TOPLEFT, divider, BOTTOMLEFT)
                        header:SetAnchor(TOPLEFT)
                        header:SetFont("ZoFontHeader2")
                        header:SetText(GetString(SI_JACK_OF_ALL_TRADES_MENU_MISC))
                    end, -- function to call when this custom control was created (optional)
                    refreshFunc = function(customControl) end, -- function to call when panel/controls refresh (optional)
                    width = "full", -- or "half" (optional)
                    minHeight = function() return 18 end, --or number for the minimum height of this control. Default: 26 (optional)
                    maxHeight = function() return 18 end, --or number for the maximum height of this control. Default: 4 * minHeight (optional)
                },
                {
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("professionalUpkeep")),
                    getFunc = function() return self.savedVariables.warnings.professionalUpkeep end,
                    setFunc = function(value) self.savedVariables.warnings.professionalUpkeep = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("professionalUpkeep"), 1000),
                    width = "half"
                },
                {
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("rationer")),
                    getFunc = function() return self.savedVariables.warnings.rationer end,
                    setFunc = function(value) self.savedVariables.warnings.rationer = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("rationer"), 1000),
                    width = "half"
                },
                {
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("liquidEfficiency")),
                    getFunc = function() return self.savedVariables.warnings.liquidEfficiency end,
                    setFunc = function(value) self.savedVariables.warnings.liquidEfficiency = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("liquidEfficiency"), 1000),
                    width = "half"
                },
            },
        },
        {
            type = "colorpicker",
            name = zo_strformat(SI_JACK_OF_ALL_TRADES_TEXT_COLOUR, GetString(SI_JACK_OF_ALL_TRADES_WARNING)), -- or string id or function returning a string
            getFunc = function()
                        return ConvertHexToRGB(self.savedVariables.colour.warnings)
                    end, -- (alpha is optional)
            setFunc = function(r,g,b) 
                        self.savedVariables.colour.warnings = ConvertRGBToHex(r, g, b)
                    end, -- (alpha is optional)
            disabled = function() 
                        for node, state in pairs(self.savedVariables.warnings) do 
                            if self.savedVariables.warnings[node] == true then 
                                return false 
                            end 
                        end 
                        return true
                    end
        },
        {
            type = "checkbox",
            name = SI_JACK_OF_ALL_TRADES_MENU_ALERT_WARNING,
            getFunc = function() return self.savedVariables.alertWarning end,
            setFunc = function(value) self.savedVariables.alertWarning = value end,
            tooltip = SI_JACK_OF_ALL_TRADES_MENU_ALERT_WARNING_TOOLTIP,
            width = "full"
        },
        {
            type = "checkbox",
            name = SI_JACK_OF_ALL_TRADES_MENU_SLOT_HM_CORPSES,
            getFunc = function() return self.savedVariables.homemakerCorpses end,
            setFunc = function(value) self.savedVariables.homemakerCorpses = value end,
            tooltip = GetString(SI_JACK_OF_ALL_TRADES_MENU_TOOLTIP_HM_CORPSES) .. JackOfAllTrades.getHomemakerLootables(),
            width = "full"
        },
        {
            type = "checkbox",
            name = SI_JACK_OF_ALL_TRADES_MENU_SLOT_MD_WRITS,
            getFunc = function() return self.savedVariables.slotMdWhilstDoingWrits end,
            setFunc = function(value) self.savedVariables.slotMdWhilstDoingWrits = value end,
            tooltip = GetString(SI_JACK_OF_ALL_TRADES_MENU_TOOLTIP_MD_WRIT),
            width = "full"
        },
        {
            type = "checkbox",
            name = SI_JACK_OF_ALL_TRADES_MENU_SLOT_LE_TRASH_POTS,
            getFunc = function() return self.savedVariables.slotLeTrashPots end,
            setFunc = function(value) self.savedVariables.slotLeTrashPots = value end,
            width = "full"
        },
        {
            type = "checkbox",
            name = SI_JACK_OF_ALL_TRADES_MENU_SLOT_TH_DUNGEON,
            getFunc = function() return self.savedVariables.slotThInDungeon end,
            setFunc = function(value) self.savedVariables.slotThInDungeon = value end,
            tooltip = GetString(SI_JACK_OF_ALL_TRADES_MENU_TOOLTIP_TH_HM_PAIR_DUN),
            width = "full"
        },
        {
            type = "checkbox",
            name = SI_JACK_OF_ALL_TRADES_MENU_SLOT_RATIONER_IN_BRP,
            getFunc = function() return self.savedVariables.slotRationerInGrindSpot end,
            setFunc = function(value) self.savedVariables.slotRationerInGrindSpot = value end,
            tooltip = GetString(SI_JACK_OF_ALL_TRADES_MENU_TOOLTIP_RATIONER_NBRP),
            width = "full"
        },
        {
            type = "header",
            name = SI_JACK_OF_ALL_TRADES_MENU_TOGGLE,
            width = "full"
        },
        {
            type = "description",
            text = SI_JACK_OF_ALL_TRADES_MENU_TOGGLE_DESCRIPTION,
            width = "full"
        },
        {   
            type = "checkbox",
            name = SI_JACK_OF_ALL_TRADES_MENU_TOGGLE_GLOBAL,
            -- If all nodes are true, set to True, else false
            getFunc = function() 
                        for node, state in pairs(self.savedVariables.enable) do 
                            if self.savedVariables.enable[node] == false then 
                                return false 
                            end 
                        end 
                        return true
                    end,
            -- Set all nodes to this value
            setFunc = function(value)
                        for node, state in pairs(self.savedVariables.enable) do 
                            self.savedVariables.enable[node] = value
                        end 
                    end,
            width = "full"
        },
        {   
            type = "submenu",
            name = SI_JACK_OF_ALL_TRADES_MENU_TOGGLE_INDIVIDUAL,
            controls = {
                {
                    type = "custom",
                    name = SI_JACK_OF_ALL_TRADES_MENU_HARVESTING,
                    --reference = "MyAddonCustomControl", -- unique name for your control to use as reference (optional)
                    createFunc = function(customControl) 
                        local wm = WINDOW_MANAGER
                        customControl.header = wm:CreateControlFromVirtual(nil, customControl, "ZO_Options_SectionTitleLabel")
                        local header = customControl.header
                        --header:SetAnchor(TOPLEFT, divider, BOTTOMLEFT)
                        header:SetAnchor(TOPLEFT)
                        header:SetFont("ZoFontHeader2")
                        header:SetText(GetString(SI_JACK_OF_ALL_TRADES_MENU_HARVESTING))
                    end, -- function to call when this custom control was created (optional)
                    refreshFunc = function(customControl) end, -- function to call when panel/controls refresh (optional)
                    width = "full", -- or "half" (optional)
                    minHeight = function() return 18 end, --or number for the minimum height of this control. Default: 26 (optional)
                    maxHeight = function() return 18 end, --or number for the maximum height of this control. Default: 4 * minHeight (optional)
                },
                {
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("masterGatherer")),
                    getFunc = function() return self.savedVariables.enable.masterGatherer end,
                    setFunc = function(value) self.savedVariables.enable.masterGatherer = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("masterGatherer"), 1000),
                    width = "half"
                },
                {
                    type = "custom",
                    name = SI_JACK_OF_ALL_TRADES_MENU_FISHING,
                    --reference = "MyAddonCustomControl", -- unique name for your control to use as reference (optional)
                    createFunc = function(customControl) 
                        local wm = WINDOW_MANAGER
                        customControl.header = wm:CreateControlFromVirtual(nil, customControl, "ZO_Options_SectionTitleLabel")
                        local header = customControl.header
                        --header:SetAnchor(TOPLEFT, divider, BOTTOMLEFT)
                        header:SetAnchor(TOPLEFT)
                        header:SetFont("ZoFontHeader2")
                        header:SetText(GetString(SI_JACK_OF_ALL_TRADES_MENU_FISHING))
                    end, -- function to call when this custom control was created (optional)
                    refreshFunc = function(customControl) end, -- function to call when panel/controls refresh (optional)
                    width = "full", -- or "half" (optional)
                    minHeight = function() return 18 end, --or number for the minimum height of this control. Default: 26 (optional)
                    maxHeight = function() return 18 end, --or number for the maximum height of this control. Default: 4 * minHeight (optional)
                },
                {
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("reelTechnique")),
                    getFunc = function() return self.savedVariables.enable.reelTechnique end,
                    setFunc = function(value) self.savedVariables.enable.reelTechnique = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("reelTechnique"), 1000),
                    width = "half"
                },
                {
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("anglersInstinct")),
                    getFunc = function() return self.savedVariables.enable.anglersInstinct end,
                    setFunc = function(value) self.savedVariables.enable.anglersInstinct = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("anglersInstinct"), 1000),
                    width = "half"
                },
                {
                    type = "custom",
                    name = SI_JACK_OF_ALL_TRADES_MENU_THIEVING,
                    --reference = "MyAddonCustomControl", -- unique name for your control to use as reference (optional)
                    createFunc = function(customControl) 
                        local wm = WINDOW_MANAGER
                        customControl.header = wm:CreateControlFromVirtual(nil, customControl, "ZO_Options_SectionTitleLabel")
                        local header = customControl.header
                        --header:SetAnchor(TOPLEFT, divider, BOTTOMLEFT)
                        header:SetAnchor(TOPLEFT)
                        header:SetFont("ZoFontHeader2")
                        header:SetText(GetString(SI_JACK_OF_ALL_TRADES_MENU_THIEVING))
                    end, -- function to call when this custom control was created (optional)
                    refreshFunc = function(customControl) end, -- function to call when panel/controls refresh (optional)
                    width = "full", -- or "half" (optional)
                    minHeight = function() return 18 end, --or number for the minimum height of this control. Default: 26 (optional)
                    maxHeight = function() return 18 end, --or number for the maximum height of this control. Default: 4 * minHeight (optional)
                },
                {
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("sustainingShadows")),
                    getFunc = function() return self.savedVariables.enable.sustainingShadows end,
                    setFunc = function(value) self.savedVariables.enable.sustainingShadows = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("sustainingShadows"), 1000),
                    width = "half"
                },
                {
                    type = "custom",
                    name = SI_JACK_OF_ALL_TRADES_MENU_RIDING,
                    --reference = "MyAddonCustomControl", -- unique name for your control to use as reference (optional)
                    createFunc = function(customControl) 
                        local wm = WINDOW_MANAGER
                        customControl.header = wm:CreateControlFromVirtual(nil, customControl, "ZO_Options_SectionTitleLabel")
                        local header = customControl.header
                        --header:SetAnchor(TOPLEFT, divider, BOTTOMLEFT)
                        header:SetAnchor(TOPLEFT)
                        header:SetFont("ZoFontHeader2")
                        header:SetText(GetString(SI_JACK_OF_ALL_TRADES_MENU_RIDING))
                    end, -- function to call when this custom control was created (optional)
                    refreshFunc = function(customControl) end, -- function to call when panel/controls refresh (optional)
                    width = "full", -- or "half" (optional)
                    minHeight = function() return 18 end, --or number for the minimum height of this control. Default: 26 (optional)
                    maxHeight = function() return 18 end, --or number for the maximum height of this control. Default: 4 * minHeight (optional)
                },
                {
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("giftedRider")),
                    getFunc = function() return self.savedVariables.enable.giftedRider end,
                    setFunc = function(value) self.savedVariables.enable.giftedRider = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("giftedRider"), 1000),
                    width = "half"
                },
                {
                    type = "checkbox",
                    name = GetFormattedChampionSkillName(self.GetSkillId("warMount")),
                    getFunc = function() return self.savedVariables.enable.warMount end,
                    setFunc = function(value) self.savedVariables.enable.warMount = value end,
                    tooltip = GetChampionSkillDescription(self.GetSkillId("warMount"), 1000),
                    width = "half"
                },
            },
        },
        {   
            type = "submenu",
            name = SI_JACK_OF_ALL_TRADES_MENU_SLOT,
            controls = {
                {
                    type = "description",
                    text = SI_JACK_OF_ALL_TRADES_MENU_ADVANCED,
                    width = "full"
                },
                {   
                    type = "button",
                    name = SI_JACK_OF_ALL_TRADES_RESET_CATEGORIES,
                    func = function() JackOfAllTrades.resetSkillSlots() end,
                    width = "half"
                },
                {
                    type = "custom",
                    name = SI_JACK_OF_ALL_TRADES_MENU_HARVESTING,
                    --reference = "MyAddonCustomControl", -- unique name for your control to use as reference (optional)
                    createFunc = function(customControl) 
                        local wm = WINDOW_MANAGER
                        customControl.header = wm:CreateControlFromVirtual(nil, customControl, "ZO_Options_SectionTitleLabel")
                        local header = customControl.header
                        --header:SetAnchor(TOPLEFT, divider, BOTTOMLEFT)
                        header:SetAnchor(TOPLEFT)
                        header:SetFont("ZoFontHeader2")
                        header:SetText(GetString(SI_JACK_OF_ALL_TRADES_MENU_HARVESTING))
                    end, -- function to call when this custom control was created (optional)
                    refreshFunc = function(customControl) end, -- function to call when panel/controls refresh (optional)
                    width = "full", -- or "half" (optional)
                    minHeight = function() return 18 end, --or number for the minimum height of this control. Default: 26 (optional)
                    maxHeight = function() return 18 end, --or number for the maximum height of this control. Default: 4 * minHeight (optional)
                },
                {
                    type = "dropdown",
                    name = GetFormattedChampionSkillName(self.GetSkillId("masterGatherer")),
                    choices = {1,2,3,4},
                    getFunc = function() return self.savedVariables.slotIndex.masterGatherer end,
                    setFunc = function(value) self.savedVariables.slotIndex.masterGatherer = value refreshConflict("masterGatherer") end,
                    sort = "numeric-up",
                    width = "half"
                },
                {
                    type = "custom",
                    name = SI_JACK_OF_ALL_TRADES_MENU_FISHING,
                    --reference = "MyAddonCustomControl", -- unique name for your control to use as reference (optional)
                    createFunc = function(customControl) 
                        local wm = WINDOW_MANAGER
                        customControl.header = wm:CreateControlFromVirtual(nil, customControl, "ZO_Options_SectionTitleLabel")
                        local header = customControl.header
                        --header:SetAnchor(TOPLEFT, divider, BOTTOMLEFT)
                        header:SetAnchor(TOPLEFT)
                        header:SetFont("ZoFontHeader2")
                        header:SetText(GetString(SI_JACK_OF_ALL_TRADES_MENU_FISHING))
                    end, -- function to call when this custom control was created (optional)
                    refreshFunc = function(customControl) end, -- function to call when panel/controls refresh (optional)
                    width = "full", -- or "half" (optional)
                    minHeight = function() return 18 end, --or number for the minimum height of this control. Default: 26 (optional)
                    maxHeight = function() return 18 end, --or number for the maximum height of this control. Default: 4 * minHeight (optional)
                },
                {
                    type = "dropdown",
                    name = GetFormattedChampionSkillName(self.GetSkillId("reelTechnique")),
                    choices = {1,2,3,4},
                    getFunc = function() return self.savedVariables.slotIndex.reelTechnique end,
                    setFunc = function(value) self.savedVariables.slotIndex.reelTechnique = value refreshConflict("reelTechnique") end,
                    sort = "numeric-up",
                    width = "half"
                },
                {
                    type = "dropdown",
                    name = GetFormattedChampionSkillName(self.GetSkillId("anglersInstinct")),
                    choices = {1,2,3,4},
                    getFunc = function() return self.savedVariables.slotIndex.anglersInstinct end,
                    setFunc = function(value) self.savedVariables.slotIndex.anglersInstinct = value refreshConflict("anglersInstinct") end,
                    sort = "numeric-up",
                    width = "half"
                },
                {
                    type = "custom",
                    name = SI_JACK_OF_ALL_TRADES_MENU_THIEVING,
                    --reference = "MyAddonCustomControl", -- unique name for your control to use as reference (optional)
                    createFunc = function(customControl) 
                        local wm = WINDOW_MANAGER
                        customControl.header = wm:CreateControlFromVirtual(nil, customControl, "ZO_Options_SectionTitleLabel")
                        local header = customControl.header
                        --header:SetAnchor(TOPLEFT, divider, BOTTOMLEFT)
                        header:SetAnchor(TOPLEFT)
                        header:SetFont("ZoFontHeader2")
                        header:SetText(GetString(SI_JACK_OF_ALL_TRADES_MENU_THIEVING))
                    end, -- function to call when this custom control was created (optional)
                    refreshFunc = function(customControl) end, -- function to call when panel/controls refresh (optional)
                    width = "full", -- or "half" (optional)
                    minHeight = function() return 18 end, --or number for the minimum height of this control. Default: 26 (optional)
                    maxHeight = function() return 18 end, --or number for the maximum height of this control. Default: 4 * minHeight (optional)
                },
                {
                    type = "dropdown",
                    name = GetFormattedChampionSkillName(self.GetSkillId("sustainingShadows")),
                    choices = {1,2,3,4},
                    getFunc = function() return self.savedVariables.slotIndex.sustainingShadows end,
                    setFunc = function(value) self.savedVariables.slotIndex.sustainingShadows = value refreshConflict("sustainingShadows") end,
                    sort = "numeric-up",
                    width = "half"
                },
                {
                    type = "custom",
                    name = SI_JACK_OF_ALL_TRADES_MENU_RIDING,
                    --reference = "MyAddonCustomControl", -- unique name for your control to use as reference (optional)
                    createFunc = function(customControl) 
                        local wm = WINDOW_MANAGER
                        customControl.header = wm:CreateControlFromVirtual(nil, customControl, "ZO_Options_SectionTitleLabel")
                        local header = customControl.header
                        --header:SetAnchor(TOPLEFT, divider, BOTTOMLEFT)
                        header:SetAnchor(TOPLEFT)
                        header:SetFont("ZoFontHeader2")
                        header:SetText(GetString(SI_JACK_OF_ALL_TRADES_MENU_RIDING))
                    end, -- function to call when this custom control was created (optional)
                    refreshFunc = function(customControl) end, -- function to call when panel/controls refresh (optional)
                    width = "full", -- or "half" (optional)
                    minHeight = function() return 18 end, --or number for the minimum height of this control. Default: 26 (optional)
                    maxHeight = function() return 18 end, --or number for the maximum height of this control. Default: 4 * minHeight (optional)
                },
                {
                    type = "dropdown",
                    name = GetFormattedChampionSkillName(self.GetSkillId("giftedRider")),
                    choices = {1,2,3,4},
                    getFunc = function() return self.savedVariables.slotIndex.giftedRider end,
                    setFunc = function(value) self.savedVariables.slotIndex.giftedRider = value refreshConflict("giftedRider") end,
                    sort = "numeric-up",
                    width = "half"
                },
                {
                    type = "dropdown",
                    name = GetFormattedChampionSkillName(self.GetSkillId("warMount")),
                    choices = {1,2,3,4},
                    getFunc = function() return self.savedVariables.slotIndex.warMount end,
                    setFunc = function(value) self.savedVariables.slotIndex.warMount = value refreshConflict("warMount") end,
                    sort = "numeric-up",
                    width = "half"
                },
            },
        },
		{
            type = "header",
            name = SI_JACK_OF_ALL_TRADES_MENU_CATEGORY_ALLOCATING_POINTS,
            width = "full"
        },
		{
            type = "description",
            text = SI_JACK_OF_ALL_TRADES_MENU_ALLOCATING_POINTS_DESCRIPTION,
            width = "full"
        },
		{
            type = "checkbox",
            name = SI_JACK_OF_ALL_TRADES_MENU_ALLOCATING_POINTS_TOGGLE,
            getFunc = function() return self.savedVariables.automaticallyAllocatePoints end,
            setFunc = function(value) self.savedVariables.automaticallyAllocatePoints = value end,
            width = "full"
        },
        {
            type = "header",
            name = SI_JACK_OF_ALL_TRADES_DEBUG,
            width = "full"
        },
        {
            type = "checkbox",
            name = zo_strformat(SI_JACK_OF_ALL_TRADES_ENABLE_MODE, GetString(SI_JACK_OF_ALL_TRADES_DEBUG)),
            getFunc = function() return self.savedVariables.debug end,
            setFunc = function(value) self.savedVariables.debug = value end,
            width = "full"
        },
        {
        type = "button",
        name = SI_JACK_OF_ALL_TRADES_DEBUG_RESET, -- string id or function returning a string
        func = function() JackOfAllTrades.ResetSavedVariables() end,
        width = "half", -- or "half" (optional)
        },
        {
        type = "button",
        name = SI_JACK_OF_ALL_TRADES_DEBUG_RESET_SKILLS, -- string id or function returning a string
        func = function() 
                if self.savedVariables.oldSkill then 
                    for index, skill in pairs(self.savedVariables.oldSkill) do
                        self.savedVariables.oldSkill[index] = nil
                    end
                end
            end,
        width = "half", -- or "half" (optional
        },
        {
            type = "header",
            name = SI_JACK_OF_ALL_TRADES_THANKS,
            width = "full"
        },
        {
            type = "description",
            text = SI_JACK_OF_ALL_TRADES_THANKS_MSG,
            width = "full"
        },
    }
    
    LAM:RegisterOptionControls(panelName, optionsData)
end