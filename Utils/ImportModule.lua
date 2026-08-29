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

ACLImportModule = {}

local name, acTable = ...
local L = acTable.L 

local LibSerialize = LibStub:GetLibrary("LibSerialize")
local LibDeflate = LibStub:GetLibrary("LibDeflate")

-------------------------------------------------------------------------------
-- CRIAÇÃO DA INTERFACE GRÁFICA (UI)
-------------------------------------------------------------------------------
local frame = nil

local function CreateImportWindow()
    if frame then return frame end

    -- Janela Principal
    frame = CreateFrame("Frame", "WoWAddonImportFrame", UIParent, "BackdropTemplate")
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
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.8)

    -- Título
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -10)
    title:SetText(L["ImportListDescription"])

    -- Botão Fechar
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

    -- Caixa de Rolagem
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -35)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -35, 50)

    -- Campo de Texto (EditBox) vazia para colar
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetMaxLetters(999999)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetWidth(380)
    editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
    scrollFrame:SetScrollChild(editBox)
    frame.editBox = editBox

    -- Botão Salvar / Importar / Recarregar
    local importButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    importButton:SetSize(160, 25)
    importButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 15)
    importButton:SetText(L["buttonSaveApply"])
    
    frame.importButton = importButton

    importButton:SetScript("OnClick", function(self)
        if self.isReadyToReload then
            frame:Hide()
            ReloadUI()
            return
        end

        local text = frame.editBox:GetText()
        if text then text = text:trim() end 
        
        if text and text ~= "" then
            if frame.callback then
                frame.callback(text)
            end
        else
            frame:Hide()
        end
    end)

    return frame
end

-------------------------------------------------------------------------------
-- FUNÇÃO PÚBLICA PARA IMPORTAR
-------------------------------------------------------------------------------
function ACLImportModule:ShowImportWindow(databaseCallback)
    
    local f = CreateImportWindow()
    f:Show()
    f.editBox:SetText("") 
    f.editBox:SetFocus()  
    
    f.importButton.isReadyToReload = false
    f.importButton:SetText(L["buttonSaveApply"])
    f.editBox:SetEnabled(true)
    
    f.callback = function(encodedText)
        local luaTable = nil

        local success, result = pcall(function()
            local compressedData = LibDeflate:DecodeForPrint(encodedText)
            if not compressedData then return nil end

            local serializedData = LibDeflate:DecompressDeflate(compressedData)
            if not serializedData then return nil end

            local successDeserialize, decodedTable = LibSerialize:Deserialize(serializedData)
            if successDeserialize then
                return decodedTable
            end
            return nil
        end)

        if success and result then
            luaTable = result
        end
        
        if luaTable and type(luaTable) == "table" then
            -- Passa os dados salvos para o seu Core
            databaseCallback(luaTable)
            
            -- Feedback Visual de Sucesso
            print(L["importSuccess"])
            
            f.editBox:SetEnabled(false)
            f.importButton.isReadyToReload = true
            f.importButton:SetText(L["buttonReloadUI"])
        else
            print(L["importFail"])
            f:Hide()
        end
    end
end

function ACLImportModule:Import(encodedText, targetTable)
    if not encodedText or type(encodedText) ~= "string" or encodedText == "" then
        print(L["importFail"])
        return false
    end

    local success, luaTable = pcall(function()
        local compressedData = LibDeflate:DecodeForPrint(encodedText)
        if not compressedData then return nil end

        local serializedData = LibDeflate:DecompressDeflate(compressedData)
        if not serializedData then return nil end

        local successDeserialize, decodedTable = LibSerialize:Deserialize(serializedData)
        if successDeserialize and type(decodedTable) == "table" then
            wipe(decodedTable) -- Opcional: limpa dados residuais se necessário
            return decodedTable
        end
        
        return nil
    end)

    if success and luaTable and type(luaTable) == "table" then
        if targetTable and type(targetTable) == "table" then
            table.wipe(targetTable)
            for k, v in pairs(luaTable) do
                targetTable[k] = v
            end
        end

        print(L["importSuccess"])
        return true
    else
        print(L["importFail"])
        return false
    end
end