local addonName, addonTable = ...

-- Default Database
local defaultDB = {
    point = "CENTER",
    x = 0,
    y = 100,
    fontSize = 20,
    locked = true,
}

-- Frame Setup
local frame = CreateFrame("Frame", "sds_MainFrame", UIParent)
frame:SetSize(100, 40)
frame:SetMovable(true)
frame:SetClampedToScreen(true)
frame:EnableMouse(false)

-- Background for dragging (only shown when unlocked)
local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(frame)
bg:SetColorTexture(0, 0, 1, 0.3)
bg:Hide()

-- Text Setup
local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
text:SetPoint("CENTER")
text:SetTextColor(1, 1, 1) -- White color as requested
text:SetText("100%")

-- Helper to update visuals based on DB
local function UpdateFrameVisuals()
    if not SimpleDurabilityStatusDB then return end
    
    local db = SimpleDurabilityStatusDB
    frame:ClearAllPoints()
    frame:SetPoint(db.point, UIParent, db.point, db.x, db.y)
    
    -- Update Font
    local fontPath, _, fontFlags = text:GetFont()
    if fontPath then
        text:SetFont(fontPath, db.fontSize, "OUTLINE")
    end
    
    -- Update Lock State
    if db.locked then
        frame:EnableMouse(false)
        bg:Hide()
    else
        frame:EnableMouse(true)
        bg:Show()
    end
end

-- Durability Calculation
local function UpdateDurability()
    local totalCurrent = 0
    local totalMax = 0
    local hasDurability = false

    for slot = 1, 19 do
        local current, max = GetInventoryItemDurability(slot)
        if current and max then
            totalCurrent = totalCurrent + current
            totalMax = totalMax + max
            hasDurability = true
        end
    end

    if hasDurability and totalMax > 0 then
        local percent = math.floor((totalCurrent / totalMax) * 100)
        text:SetText(percent .. "%")
    else
        text:SetText("N/A")
    end
end

-- Dragging handlers
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self)
    if not SimpleDurabilityStatusDB.locked then
        self:StartMoving()
    end
end)

frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint()
    SimpleDurabilityStatusDB.point = point
    SimpleDurabilityStatusDB.x = x
    SimpleDurabilityStatusDB.y = y
end)

-- Events
frame:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ADDON_LOADED")

local function OnEvent(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Initialize DB
        if not SimpleDurabilityStatusDB then
            SimpleDurabilityStatusDB = {}
        end
        for k, v in pairs(defaultDB) do
            if SimpleDurabilityStatusDB[k] == nil then
                SimpleDurabilityStatusDB[k] = v
            end
        end
        UpdateFrameVisuals()
        UpdateDurability()
        self:UnregisterEvent("ADDON_LOADED")
        
    elseif event == "UPDATE_INVENTORY_DURABILITY" or event == "PLAYER_ENTERING_WORLD" then
        UpdateDurability()
    end
end

frame:SetScript("OnEvent", OnEvent)

-- Slash Commands
SLASH_SIMPLEDURABILITY1 = "/sds"
SlashCmdList["SIMPLEDURABILITY"] = function(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    cmd = cmd:lower()
    
    if cmd == "lock" then
        SimpleDurabilityStatusDB.locked = true
        UpdateFrameVisuals()
        print("|cff00ff00sds: Locked|r")
        
    elseif cmd == "unlock" then
        SimpleDurabilityStatusDB.locked = false
        UpdateFrameVisuals()
        print("|cff00ff00sds: Unlocked - Drag to move|r")
        
    elseif cmd == "size" then
        local newSize = tonumber(arg)
        if newSize and newSize > 0 then
            SimpleDurabilityStatusDB.fontSize = newSize
            UpdateFrameVisuals()
            print("|cff00ff00sds: Font size set to " .. newSize .. "|r")
        else
            print("|cffff0000sds: Usage: /sds size <number>|r")
        end
        
    else
        print("|cffffff00sds Commands:|r")
        print("  /sds lock - Lock frame position")
        print("  /sds unlock - Unlock frame position")
        print("  /sds size <number> - Set font size")
    end
end
