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
    -- Do NOT use `addon.GetDB(...) or default`: that collapses false → default,
    -- breaking any boolean option whose stored value is false.
    if not addon.GetDB then return default end
    return addon.GetDB(key, default)
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
-- PREVIEW WIDGET (options dashboard)
-- ============================================================================

local PREVIEW_HEIGHT     = 110
local PREVIEW_PORTRAIT_W = 110

function addon.Presence.CreateTalkingHeadPreviewWidget(parent)
    if not parent then return nil end

    local L = addon.L

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(PREVIEW_HEIGHT)

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    bg:SetColorTexture(0.05, 0.05, 0.07, 0.92)

    if addon.CreateBorder then
        addon.CreateBorder(frame, { 0.18, 0.18, 0.24, 0.95 })
    end

    -- Plain Frame container for the portrait area. We show/hide this rather than
    -- the PlayerModel directly: PlayerModel:SetShown(false) can be overridden when
    -- the model finishes loading asynchronously, whereas hiding a plain parent
    -- Frame makes all its children effectively invisible regardless of their own state.
    local portraitArea = CreateFrame("Frame", nil, frame)
    portraitArea:SetWidth(PREVIEW_PORTRAIT_W)
    portraitArea:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    portraitArea:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)

    local portraitBg = portraitArea:CreateTexture(nil, "BACKGROUND", nil, -1)
    portraitBg:SetAllPoints(portraitArea)
    portraitBg:SetColorTexture(0.03, 0.03, 0.05, 0.95)

    local portrait = CreateFrame("PlayerModel", nil, portraitArea)
    portrait:SetPoint("TOPLEFT", portraitArea, "TOPLEFT", 2, -2)
    portrait:SetPoint("BOTTOMRIGHT", portraitArea, "BOTTOMRIGHT", -2, 2)
    portrait:SetUnit("player")
    portrait:SetCamDistanceScale(0.85)
    portrait:SetPortraitZoom(1)

    local sep = frame:CreateTexture(nil, "ARTWORK")
    sep:SetWidth(1)
    sep:SetPoint("TOP", frame, "TOP", 0, -6)
    sep:SetPoint("BOTTOM", frame, "BOTTOM", 0, 6)
    sep:SetPoint("LEFT", portraitArea, "RIGHT", 0, 0)
    sep:SetColorTexture(0.25, 0.28, 0.35, 0.8)

    local nameText = frame:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(FontPath("talkingHeadNameFontPath"), DEFAULTS.talkingHeadNameSize, "OUTLINE")
    nameText:SetPoint("TOPLEFT", frame, "TOPLEFT", PREVIEW_PORTRAIT_W + 12, -10)
    nameText:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetText(L["TALKING_HEAD_PREVIEW_NPC_NAME"] or "Thrall")

    local dialogueText = frame:CreateFontString(nil, "OVERLAY")
    dialogueText:SetFont(FontPath("talkingHeadTextFontPath"), DEFAULTS.talkingHeadTextSize, "OUTLINE")
    dialogueText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -8)
    dialogueText:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    dialogueText:SetJustifyH("LEFT")
    dialogueText:SetNonSpaceWrap(true)
    dialogueText:SetText(L["TALKING_HEAD_PREVIEW_DIALOGUE"] or "Azeroth needs heroes. Will you answer the call?")

    local function Refresh()
        local nameFont = FontPath("talkingHeadNameFontPath")
        local nameSize = tonumber(GetOption("talkingHeadNameSize", DEFAULTS.talkingHeadNameSize)) or DEFAULTS.talkingHeadNameSize
        nameText:SetFont(nameFont, nameSize, "OUTLINE")
        nameText:SetShadowOffset(1, -1)
        local nr = tonumber(GetOption("talkingHeadNameColorR", DEFAULTS.talkingHeadNameColorR)) or DEFAULTS.talkingHeadNameColorR
        local ng = tonumber(GetOption("talkingHeadNameColorG", DEFAULTS.talkingHeadNameColorG)) or DEFAULTS.talkingHeadNameColorG
        local nb = tonumber(GetOption("talkingHeadNameColorB", DEFAULTS.talkingHeadNameColorB)) or DEFAULTS.talkingHeadNameColorB
        nameText:SetTextColor(nr, ng, nb)

        local textFont = FontPath("talkingHeadTextFontPath")
        local textSize = tonumber(GetOption("talkingHeadTextSize", DEFAULTS.talkingHeadTextSize)) or DEFAULTS.talkingHeadTextSize
        dialogueText:SetFont(textFont, textSize, "OUTLINE")
        dialogueText:SetShadowOffset(1, -1)

        local showPortrait = GetOption("talkingHeadShowPortrait", DEFAULTS.talkingHeadShowPortrait)
        portraitArea:SetShown(showPortrait)
        sep:SetShown(showPortrait)
    end

    frame.Refresh = Refresh
    frame:SetScript("OnShow", Refresh)
    Refresh()

    return { frame = frame, Refresh = Refresh }
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
