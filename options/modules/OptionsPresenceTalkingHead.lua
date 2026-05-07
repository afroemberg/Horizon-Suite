--[[
    Horizon Suite - Presence - Talking Head options category
    Self-registers into addon.OptionCategories after OptionsData.lua runs.
]]

local addon = _G._HorizonSuite_Loading or _G.HorizonSuiteBeta or _G.HorizonSuite
if not addon or not addon.OptionCategories then return end

local L = addon.L
local D = addon.Presence.TalkingHeadDefaults

local function getDB(k, d) return addon.OptionsData_GetDB(k, d) end
local function setDB(k, v) addon.OptionsData_SetDB(k, v) end

local function updateTalkingHead()
    if addon.Presence and addon.Presence.UpdateTalkingHead then
        addon.Presence.UpdateTalkingHead()
    end
end

local FONT_USE_GLOBAL = "__global__"

local function GetFontOptions(dbKey)
    if addon.RefreshFontList then addon.RefreshFontList() end
    local list = (addon.GetFontList and addon.GetFontList()) or {}
    local out = { { L["FOCUS_GLOBAL_FONT"] or "Use global font", FONT_USE_GLOBAL } }
    for i = 1, #list do out[#out + 1] = list[i] end
    local saved = getDB(dbKey, FONT_USE_GLOBAL)
    if saved == FONT_USE_GLOBAL then return out end
    for _, o in ipairs(out) do
        if o[2] == saved then return out end
    end
    out[#out + 1] = { L["FOCUS_CUSTOM"] or "Custom", saved }
    return out
end

local function DisplayFont(v)
    if v == FONT_USE_GLOBAL then return L["FOCUS_GLOBAL_FONT"] or "Use global font" end
    return addon.GetFontNameForPath and addon.GetFontNameForPath(v) or v
end

local category = {
    key       = "PresenceTalkingHead",
    name      = L["TALKING_HEAD"] or "Talking Head",
    desc      = L["TALKING_HEAD_CATEGORY_DESC"] or "Configure the appearance and behavior of the Talking Head.",
    moduleKey = "presence",
    options   = {
        { type = "section", name = L["AXIS_GENERAL"] or "General" },
        {
            type  = "toggle",
            name  = L["TALKING_HEAD_ENABLE"] or "Enable Talking Head",
            desc  = L["TALKING_HEAD_ENABLE_DESC"] or "Show the Talking Head frame during NPC dialogue.",
            dbKey = "talkingHeadEnabled",
            get   = function() return getDB("talkingHeadEnabled", D.talkingHeadEnabled) end,
            set   = function(value) setDB("talkingHeadEnabled", value); updateTalkingHead() end,
        },
        {
            type  = "toggle",
            name  = L["TALKING_HEAD_MUTE_VOICE"] or "Mute Voice",
            desc  = L["TALKING_HEAD_MUTE_VOICE_DESC"] or "Silence the NPC voice-over when a Talking Head appears.",
            dbKey = "talkingHeadMuteVoice",
            get   = function() return getDB("talkingHeadMuteVoice", D.talkingHeadMuteVoice) end,
            set   = function(value) setDB("talkingHeadMuteVoice", value) end,
        },
        { type = "section", name = L["TALKING_HEAD_FRAME_CONTENT"] or "Content" },
        {
            type              = "dropdown",
            name              = L["TALKING_HEAD_NAME_FONT"] or "Name Font",
            desc              = L["TALKING_HEAD_NAME_FONT_DESC"] or "Font family for the NPC name.",
            dbKey             = "talkingHeadNameFontPath",
            searchable        = true,
            options           = function() return GetFontOptions("talkingHeadNameFontPath") end,
            get               = function() return getDB("talkingHeadNameFontPath", FONT_USE_GLOBAL) end,
            set               = function(v) setDB("talkingHeadNameFontPath", v); updateTalkingHead() end,
            displayFn         = DisplayFont,
            fontPreviewInList = true,
        },
        {
            type  = "slider",
            name  = L["TALKING_HEAD_NAME_SIZE"] or "Name Font Size",
            desc  = L["TALKING_HEAD_NAME_SIZE_DESC"] or "Font size for the NPC name (10–20).",
            dbKey = "talkingHeadNameSize",
            min   = 10,
            max   = 20,
            get   = function() return math.max(10, math.min(20, tonumber(getDB("talkingHeadNameSize", D.talkingHeadNameSize)) or D.talkingHeadNameSize)) end,
            set   = function(v) setDB("talkingHeadNameSize", math.max(10, math.min(20, v))); updateTalkingHead() end,
        },
        {
            type    = "color",
            name    = L["TALKING_HEAD_NAME_COLOUR"] or "Name Colour",
            desc    = L["TALKING_HEAD_NAME_COLOUR_DESC"] or "Colour of the NPC name text.",
            dbKey   = "talkingHeadNameColor",
            default = { D.talkingHeadNameColorR, D.talkingHeadNameColorG, D.talkingHeadNameColorB },
            get     = function() return getDB("talkingHeadNameColorR", D.talkingHeadNameColorR), getDB("talkingHeadNameColorG", D.talkingHeadNameColorG), getDB("talkingHeadNameColorB", D.talkingHeadNameColorB) end,
            set     = function(r, g, b) setDB("talkingHeadNameColorR", r); setDB("talkingHeadNameColorG", g); setDB("talkingHeadNameColorB", b); updateTalkingHead() end,
        },
        {
            type              = "dropdown",
            name              = L["TALKING_HEAD_TEXT_FONT"] or "Text Font",
            desc              = L["TALKING_HEAD_TEXT_FONT_DESC"] or "Font family for NPC dialogue text.",
            dbKey             = "talkingHeadTextFontPath",
            searchable        = true,
            options           = function() return GetFontOptions("talkingHeadTextFontPath") end,
            get               = function() return getDB("talkingHeadTextFontPath", FONT_USE_GLOBAL) end,
            set               = function(v) setDB("talkingHeadTextFontPath", v); updateTalkingHead() end,
            displayFn         = DisplayFont,
            fontPreviewInList = true,
        },
        {
            type  = "slider",
            name  = L["TALKING_HEAD_TEXT_SIZE"] or "Text Font Size",
            desc  = L["TALKING_HEAD_TEXT_SIZE_DESC"] or "Font size for NPC dialogue text (10–24).",
            dbKey = "talkingHeadTextSize",
            min   = 10,
            max   = 24,
            get   = function() return math.max(10, math.min(24, tonumber(getDB("talkingHeadTextSize", D.talkingHeadTextSize)) or D.talkingHeadTextSize)) end,
            set   = function(v) setDB("talkingHeadTextSize", math.max(10, math.min(24, v))); updateTalkingHead() end,
        },
        { type = "section", name = L["TALKING_HEAD_FRAME"] or "Frame" },
        {
            type  = "toggle",
            name  = L["TALKING_HEAD_SHOW_PORTRAIT"] or "Show NPC Portrait",
            desc  = L["TALKING_HEAD_SHOW_PORTRAIT_DESC"] or "Show the NPC 3D model in the frame.",
            dbKey = "talkingHeadShowPortrait",
            get   = function() return getDB("talkingHeadShowPortrait", D.talkingHeadShowPortrait) end,
            set   = function(value) setDB("talkingHeadShowPortrait", value); updateTalkingHead() end,
        },
        {
            type  = "toggle",
            name  = L["TALKING_HEAD_SHOW_BG"] or "Show Background",
            desc  = L["TALKING_HEAD_SHOW_BG_DESC"] or "Show the cinematic background art behind the portrait.",
            dbKey = "talkingHeadBackground",
            get   = function() return getDB("talkingHeadBackground", D.talkingHeadBackground) end,
            set   = function(value) setDB("talkingHeadBackground", value); updateTalkingHead() end,
        },
        {
            type  = "toggle",
            name  = L["TALKING_HEAD_SHOW_CLOSE"] or "Show Close Button",
            desc  = L["TALKING_HEAD_SHOW_CLOSE_DESC"] or "Show a close button to dismiss the Talking Head early.",
            dbKey = "talkingHeadCloseButton",
            get   = function() return getDB("talkingHeadCloseButton", D.talkingHeadCloseButton) end,
            set   = function(value) setDB("talkingHeadCloseButton", value); updateTalkingHead() end,
        },
        {
            type  = "slider",
            name  = L["TALKING_HEAD_SCALE"] or "Frame Scale",
            desc  = L["TALKING_HEAD_SCALE_DESC"] or "Scale of the entire Talking Head frame (0.5–2.0).",
            dbKey = "talkingHeadScale",
            min   = 0.5,
            max   = 2.0,
            step  = 0.1,
            get   = function() return math.max(0.5, math.min(2.0, tonumber(getDB("talkingHeadScale", D.talkingHeadScale)) or D.talkingHeadScale)) end,
            set   = function(v) setDB("talkingHeadScale", math.max(0.5, math.min(2.0, v))); updateTalkingHead() end,
        },
    },
}

-- Insert after the last Presence category to preserve sidebar order
local insertAt = #addon.OptionCategories + 1
for i, cat in ipairs(addon.OptionCategories) do
    if cat.moduleKey == "presence" then insertAt = i + 1 end
end
table.insert(addon.OptionCategories, insertAt, category)
