local addon = _G._HorizonSuite_Loading or _G.HorizonSuiteBeta or _G.HorizonSuite
if not addon then return end

addon.Presence = addon.Presence or {}

-- ============================================================================
-- DEFAULTS — single source of truth for all TalkingHead option defaults
-- ============================================================================

local DEFAULTS = {
    talkingHeadEnabled      = true,
    talkingHeadShowPortrait = true,
    talkingHeadBackground   = false,
    talkingHeadCloseButton  = false,
    talkingHeadMuteVoice    = false,
    talkingHeadScale        = 1.0,
    talkingHeadNameSize     = 13,
    talkingHeadNameColorR   = 0.55,
    talkingHeadNameColorG   = 0.65,
    talkingHeadNameColorB   = 0.75,
    talkingHeadTextSize     = 14,
}
addon.Presence.TalkingHeadDefaults = DEFAULTS

-- ============================================================================
-- HELPERS
-- ============================================================================

local function GetOption(key, default)
    return addon.GetDB and addon.GetDB(key, default) or default
end

local FONT_USE_GLOBAL = "__global__"

local function FontPath(dbKey)
    local raw = GetOption(dbKey, FONT_USE_GLOBAL)
    if raw == FONT_USE_GLOBAL or not raw or raw == "" then
        raw = addon.GetDB and addon.GetDB("fontPath", nil) or nil
    end
    if raw and raw ~= "" and raw ~= FONT_USE_GLOBAL then
        return (addon.ResolveFontPath and addon.ResolveFontPath(raw)) or raw
    end
    return (addon.GetDefaultFontPath and addon.GetDefaultFontPath()) or "Fonts\\FRIZQT__.TTF"
end

-- ============================================================================
-- VISUAL MODES
-- ============================================================================

-- Custom fonts, sizes, and name colour on top of Blizzard's frame
local function ApplyTalkingHeadContent(frame)
    if not frame then return end

    local textFont = FontPath("talkingHeadTextFontPath")
    local textSize = tonumber(GetOption("talkingHeadTextSize", DEFAULTS.talkingHeadTextSize)) or DEFAULTS.talkingHeadTextSize
    if frame.TextFrame and frame.TextFrame.Text then
        local t = frame.TextFrame.Text
        t:SetFont(textFont, textSize, "OUTLINE")
        t:SetShadowOffset(1, -1)
    end

    local nameFont = FontPath("talkingHeadNameFontPath")
    local nameSize = tonumber(GetOption("talkingHeadNameSize", DEFAULTS.talkingHeadNameSize)) or DEFAULTS.talkingHeadNameSize
    local nr = tonumber(GetOption("talkingHeadNameColorR", DEFAULTS.talkingHeadNameColorR)) or DEFAULTS.talkingHeadNameColorR
    local ng = tonumber(GetOption("talkingHeadNameColorG", DEFAULTS.talkingHeadNameColorG)) or DEFAULTS.talkingHeadNameColorG
    local nb = tonumber(GetOption("talkingHeadNameColorB", DEFAULTS.talkingHeadNameColorB)) or DEFAULTS.talkingHeadNameColorB
    if frame.NameFrame and frame.NameFrame.Name then
        local n = frame.NameFrame.Name
        n:SetFont(nameFont, nameSize, "OUTLINE")
        n:SetShadowOffset(1, -1)
        n:SetTextColor(nr, ng, nb)
    end
end

-- Frame-level toggles: portrait, background, close button, scale
local function ApplyTalkingHeadFrame(frame)
    if not frame then return end
    if frame.MainFrame and frame.MainFrame.Model then
        frame.MainFrame.Model:SetShown(GetOption("talkingHeadShowPortrait", DEFAULTS.talkingHeadShowPortrait))
    end
    if frame.BackgroundFrame then
        frame.BackgroundFrame:SetAlpha(GetOption("talkingHeadBackground", DEFAULTS.talkingHeadBackground) and 1 or 0)
    end
    if frame.MainFrame and frame.MainFrame.CloseButton then
        frame.MainFrame.CloseButton:SetShown(GetOption("talkingHeadCloseButton", DEFAULTS.talkingHeadCloseButton))
    end
    local scale = math.max(0.5, math.min(2.0, tonumber(GetOption("talkingHeadScale", DEFAULTS.talkingHeadScale)) or DEFAULTS.talkingHeadScale))
    frame:SetScale(scale)
end

local function ApplyCurrent(frame)
    ApplyTalkingHeadContent(frame)
    ApplyTalkingHeadFrame(frame)
end

-- ============================================================================
-- hooksecurefunc HOOKS — permanent post-hooks on TalkingHeadFrame methods
-- ============================================================================
--
-- Why hooksecurefunc on PlayCurrent instead of HookScript("OnShow"):
--   Blizzard's PlayCurrent resets the text FontString's font on every dialogue
--   line, so a skin applied in OnShow is immediately overwritten. Hooking
--   PlayCurrent fires once per line AFTER Blizzard has written its values,
--   which is the only reliable point to override them. It also fires on
--   mid-sequence lines (not just the first show) so skin persists throughout.

local _hooksInstalled = false

-- Fires after Blizzard's PlayCurrent has set dialogue text/fonts for this line.
local function OnPlayCurrent(frame)
    if addon.IsModuleEnabled and not addon:IsModuleEnabled("presence") then return end

    local enabled = GetOption("talkingHeadEnabled", DEFAULTS.talkingHeadEnabled)
    if not enabled then
        frame:CloseImmediately()
        return
    end

    ApplyCurrent(frame)

    if GetOption("talkingHeadMuteVoice", DEFAULTS.talkingHeadMuteVoice) and frame.voHandle then
        StopSound(frame.voHandle)
    end
end

local function InstallHooks(frame)
    if _hooksInstalled then return end
    _hooksInstalled = true
    hooksecurefunc(frame, "PlayCurrent", OnPlayCurrent)
    -- Late-install catch: first dialogue already showing when hooks were wired
    if frame:IsShown() then
        if GetOption("talkingHeadEnabled", DEFAULTS.talkingHeadEnabled) then
            ApplyCurrent(frame)
        else
            frame:CloseImmediately()
        end
    end
end

-- ============================================================================
-- SETUP — TalkingHeadFrame is created lazily on the first TALKINGHEAD_REQUESTED;
-- there is no separate Blizzard addon to listen for, so we hook on that event.
-- ============================================================================

local _setupFrame = CreateFrame("Frame")
_setupFrame:RegisterEvent("TALKINGHEAD_REQUESTED")
_setupFrame:SetScript("OnEvent", function(self)
    local frame = _G.TalkingHeadFrame
    if frame then
        InstallHooks(frame)
        self:UnregisterEvent("TALKINGHEAD_REQUESTED")
    end
end)

-- Immediate check in case TalkingHeadFrame already exists (e.g. after /reload)
if _G.TalkingHeadFrame then
    InstallHooks(_G.TalkingHeadFrame)
    _setupFrame:UnregisterEvent("TALKINGHEAD_REQUESTED")
end

-- ============================================================================
-- INIT / UPDATE (public API)
-- ============================================================================

function addon.Presence.InitTalkingHead()
    local frame = _G.TalkingHeadFrame
    if frame then InstallHooks(frame) end
end

function addon.Presence.UpdateTalkingHead()
    local frame = _G.TalkingHeadFrame
    if not frame then return end
    InstallHooks(frame)

    local enabled = GetOption("talkingHeadEnabled", DEFAULTS.talkingHeadEnabled)
    if not enabled then
        if frame:IsShown() then frame:CloseImmediately() end
        return
    end

    -- Only update a visible frame; never force-show (Blizzard owns visibility)
    if frame:IsShown() then
        ApplyCurrent(frame)
    end
end
