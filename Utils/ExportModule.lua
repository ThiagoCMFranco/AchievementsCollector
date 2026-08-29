--------------------------------------------------------------------------------
--[[ Achievements Collector ]]--
--
-- by ThiagoCMFranco <https://github.com/ThiagoCMFranco>
--
--Copyright (C) 2026  Thiago de C. M. Franco
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU General Public License as published by
--the Free Software Foundation, either version 3 of the License, or
--(at your option) any later version.
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU General Public License for more details.
--
--You should have received a copy of the GNU General Public License
--along with this program.  If not, see <https://www.gnu.org/licenses/>.
--
--------------------------------------------------------------------------------

ACLExportModule = {}

local name, acTable = ...
local L = acTable.L 

local LibSerialize = LibStub:GetLibrary("LibSerialize")
local LibDeflate = LibStub:GetLibrary("LibDeflate")

-------------------------------------------------------------------------------
-- CRIAÇÃO DA INTERFACE GRÁFICA (UI)
-------------------------------------------------------------------------------
local frame = nil

local function CreateExportWindow()
    if frame then return frame end

    frame = CreateFrame("Frame", "WoWAddonExportFrame", UIParent, "BackdropTemplate")
    frame:SetSize(450, 350)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(100)

    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.8)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -10)
    title:SetText(L["buttonExportSettings"])

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -35)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -35, 15)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetMaxLetters(999999) -- Limite alto para suportar DBs grandes
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetWidth(380)
    
    editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
    
    scrollFrame:SetScrollChild(editBox)
    
    frame.editBox = editBox

    return frame
end

-------------------------------------------------------------------------------
-- FUNÇÃO PÚBLICA PARA EXPORTAR
-------------------------------------------------------------------------------
function ACLExportModule:ShowExportWindow(databaseTable)
    if type(databaseTable) ~= "table" then
        print(L["exportFail"])
        return
    end

    local f = CreateExportWindow()
    
    local serializedData = LibSerialize:Serialize(databaseTable)
    local compressedData = LibDeflate:CompressDeflate(serializedData)
    local exportString = LibDeflate:EncodeForPrint(compressedData)
    
    f.editBox:SetText(exportString)
    f:Show()
    
    f.editBox:HighlightText()
    f.editBox:SetFocus()
end

function ACLExportModule:Export(databaseTable)
    if type(databaseTable) ~= "table" then
        print(L["exportFail"])
        return
    end

    local serializedData = LibSerialize:Serialize(databaseTable)
    local compressedData = LibDeflate:CompressDeflate(serializedData)
    local exportString = LibDeflate:EncodeForPrint(compressedData)
    
    return exportString
end