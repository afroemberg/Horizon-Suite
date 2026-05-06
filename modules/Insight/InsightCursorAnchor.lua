--[[
    Horizon Suite - Insight Cursor Anchor
    Hook GameTooltip_SetDefaultAnchor and apply cursor-side or fixed positioning.
    No per-frame updates, no manual line clearing, no state tracking.
]]

local addon = _G.HorizonSuite

addon.Insight = addon.Insight or {}
local Insight = addon.Insight

local FIXED_POINT = Insight.FIXED_POINT
local FIXED_X     = Insight.FIXED_X
local FIXED_Y     = Insight.FIXED_Y

local function GetAnchorMode()
    return addon.GetDB("insightAnchorMode", Insight.DEFAULT_ANCHOR)
end

local function GetFixedPoint()
    return addon.GetDB("insightFixedPoint", FIXED_POINT)
end

local function GetFixedX()
    return tonumber(addon.GetDB("insightFixedX", FIXED_X)) or FIXED_X
end

local function GetFixedY()
    return tonumber(addon.GetDB("insightFixedY", FIXED_Y)) or FIXED_Y
end

local function GetCursorSide()
    return addon.GetDB("insightCursorSide", "center")
end

local function GetCursorOffsetX()
    return tonumber(addon.GetDB("insightCursorOffsetX", 0)) or 0
end

local function GetCursorOffsetY()
    return tonumber(addon.GetDB("insightCursorOffsetY", 0)) or 0
end

-- Owners parented under WorldMapFrame keep Blizzard's native anchor: re-anchoring inside
-- the map causes a one-frame jump and re-introduces taint on the same widget update.
local function OwnerIsUnderWorldMap(frame)
    local worldMap = _G.WorldMapFrame
    if not worldMap or not frame or not frame.GetParent then return false end
    local f = frame
    for _ = 1, 12 do
        if f == worldMap then return true end
        local ok, parent = pcall(f.GetParent, f)
        if not ok or not parent then return false end
        f = parent
    end
    return false
end

local pendingAnchorTimers = setmetatable({}, { __mode = "k" })

local function ApplyCursorAnchor(tooltip, parent)
    if not tooltip or not tooltip.SetOwner then return end
    if tooltip.IsForbidden and tooltip:IsForbidden() then return end
    if parent and parent.IsForbidden and parent:IsForbidden() then return end
    local side = GetCursorSide()
    if side == "left" then
        tooltip:SetOwner(parent, "ANCHOR_CURSOR_LEFT", GetCursorOffsetX(), GetCursorOffsetY())
    elseif side == "right" then
        tooltip:SetOwner(parent, "ANCHOR_CURSOR_RIGHT", GetCursorOffsetX(), GetCursorOffsetY())
    else
        tooltip:SetOwner(parent, "ANCHOR_CURSOR", 0, 0)
    end
end

local function ApplyFixedAnchor(tooltip)
    if not tooltip or not tooltip.ClearAllPoints or not tooltip.SetPoint then return end
    if tooltip.IsForbidden and tooltip:IsForbidden() then return end
    tooltip:ClearAllPoints()
    tooltip:SetPoint(GetFixedPoint(), UIParent, GetFixedPoint(), GetFixedX(), GetFixedY())
end

function Insight.HookCursorAnchor()
    GameTooltip:SetClampedToScreen(true)
    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
        if not Insight.IsInsightEnabled() then return end
        if not tooltip or not tooltip.SetOwner then return end
        if tooltip.IsForbidden and tooltip:IsForbidden() then return end
        if parent and parent.IsForbidden and parent:IsForbidden() then return end
        if OwnerIsUnderWorldMap(parent) then return end

        local mode = GetAnchorMode()
        if mode ~= "cursor" and mode ~= "fixed" then return end

        -- Defer to next tick so Blizzard's GameTooltip_AddWidgetSet can complete
        -- on a clean stack: mutating SetOwner/SetPoint synchronously in this hook
        -- taints widget-template width arithmetic (item display, map POIs, etc.)
        -- via the AsyncCallbackSystem fired from ContinuableContainer.
        local prev = pendingAnchorTimers[tooltip]
        if prev and prev.Cancel then prev:Cancel() end
        if not (C_Timer and C_Timer.NewTimer) then return end
        pendingAnchorTimers[tooltip] = C_Timer.NewTimer(0, function()
            pendingAnchorTimers[tooltip] = nil
            if not Insight.IsInsightEnabled() then return end
            if mode == "cursor" then
                ApplyCursorAnchor(tooltip, parent)
            else
                ApplyFixedAnchor(tooltip)
            end
        end)
    end)
end

-- Apply the user's Insight anchor mode to a tooltip being shown for a specific widget.
-- Callers (e.g. Focus OnEnter handlers) that would otherwise call GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
-- route through this so cursor/fixed anchor settings are honoured.
-- Falls back to the caller-supplied anchor (default "ANCHOR_RIGHT") when Insight is disabled or anchor
-- mode is neither "cursor" nor "fixed".
-- overrideCursorSide ("left" | "right" | "center"): forces the cursor side in cursor mode (used by
-- Focus so its tooltips open away from the tracker regardless of the user's global cursor-side pref).
function Insight.ApplyAnchor(tooltip, owner, fallbackAnchor, fallbackOffX, fallbackOffY, overrideCursorSide)
    if not tooltip or not tooltip.SetOwner then return end
    if not owner then return end
    if tooltip.IsForbidden and tooltip:IsForbidden() then return end
    if owner.IsForbidden and owner:IsForbidden() then return end

    fallbackAnchor = fallbackAnchor or "ANCHOR_RIGHT"
    fallbackOffX = fallbackOffX or 0
    fallbackOffY = fallbackOffY or 0

    if not Insight.IsInsightEnabled() then
        tooltip:SetOwner(owner, fallbackAnchor, fallbackOffX, fallbackOffY)
        return
    end

    local mode = GetAnchorMode()
    if mode == "cursor" then
        local side = overrideCursorSide or GetCursorSide()
        if side == "left" then
            tooltip:SetOwner(owner, "ANCHOR_CURSOR_LEFT", GetCursorOffsetX(), GetCursorOffsetY())
        elseif side == "right" then
            tooltip:SetOwner(owner, "ANCHOR_CURSOR_RIGHT", GetCursorOffsetX(), GetCursorOffsetY())
        else
            tooltip:SetOwner(owner, "ANCHOR_CURSOR", 0, 0)
        end
    elseif mode == "fixed" then
        tooltip:SetOwner(owner, "ANCHOR_NONE")
        tooltip:ClearAllPoints()
        tooltip:SetPoint(GetFixedPoint(), UIParent, GetFixedPoint(), GetFixedX(), GetFixedY())
    else
        tooltip:SetOwner(owner, fallbackAnchor, fallbackOffX, fallbackOffY)
    end
end
