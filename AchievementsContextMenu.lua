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

local addonName, acTable = ...
local L = acTable.L 

acTable.CustomLists = acTable.CustomLists or {}

-- 1. Criação do menu de contexto
-- Função auxiliar para verificar se um ID já existe em uma tabela
local function TableContains(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then
            return true
        end
    end
    return false
end

local function ShowMyCustomContextMenu(anchorFrame, achievementID)
    if not achievementID then return end

    MenuUtil.CreateContextMenu(anchorFrame, function(owner, rootDescription)
        rootDescription:CreateTitle(L["Achievement_Options"] .. " (" .. achievementID .. ")")
        
        -- Copiar código da conquista
        rootDescription:CreateButton(L["Copy_Achievement_ID"], function()
            if StaticPopupDialogs["HIDDEN_ACHIEVEMENTS_COPY_ID"] == nil then
                StaticPopupDialogs["HIDDEN_ACHIEVEMENTS_COPY_ID"] = {
                    text = L["Copy_Achievement_ID_Message"],
                    button1 = L["button_Close"],
                    hasEditBox = true,
                    editBoxWidth = 200,
                    OnShow = function(self, data)
                        if self.EditBox then
                            self.EditBox:SetText(tostring(data))
                            self.EditBox:HighlightText()
                        end
                    end,
                    timeout = 0,
                    whileDead = true,
                    hideOnEscape = true,
                    preferredIndex = 3,
                }
            end
            StaticPopup_Show("HIDDEN_ACHIEVEMENTS_COPY_ID", nil, nil, achievementID)
        end)
        
        -- Salvar para lista personalizada
        local subMenu = rootDescription:CreateButton(L["Add_To_Custom_List"])
        
        if acTable and acTable.DB and acTable.DB.CustomLists then
            for presetKey, presetData in pairs(acTable.DB.CustomLists) do
                local presetName = presetData.name or presetKey
                
                subMenu:CreateButton(presetName, function()
                    if not presetData.ids then
                        presetData.ids = {}
                    end

                    AchievementsLists = AchievementsLists or {}
                    AchievementsLists[presetKey] = presetData.ids
                    
                    if not TableContains(presetData.ids, achievementID) then
                        table.insert(presetData.ids, achievementID)
                        print(string.format(string.format("|cff00ff00[%s]|r %s ", L["AddonName_Interface"], L["Added_Achievement_Message"]), achievementID, presetName))

                        acTable.DB = acTable.DB or {}
                        acTable.DB.CustomLists = acTable.DB.CustomLists or {}
                        acTable.DB.CustomLists[presetKey] = acTable.DB.CustomLists[presetKey] or { name = presetName, ids = {} }
                        acTable.DB.CustomLists[presetKey].ids = presetData.ids

                        AchievementsCollector:UpdateSettings()
                    else
                        print(L["Achievement_Already_On_List"])
                    end

                    if acTable.RefreshMainTrackerUI then acTable:RefreshMainTrackerUI() end
                    if LibStub and LibStub("AceConfigRegistry-3.0", true) then
                        LibStub("AceConfigRegistry-3.0"):NotifyChange("CustomAchievementTracker_AddLists")
                    end
                end)
            end
        else
            subMenu:CreateButton(L["No_List_Found"], function() end)
        end

        -- Remover da lista personalizada
        local removeSubMenu = rootDescription:CreateButton(L["Remove_From_Custom_List"])
        local hasAnyPreset = false

        if acTable and acTable.DB and acTable.DB.CustomLists then
            for presetKey, presetData in pairs(acTable.DB.CustomLists) do
                if presetData.ids and TableContains(presetData.ids, achievementID) then
                    hasAnyPreset = true
                    removeSubMenu:CreateButton((presetData.name or presetKey), function()
                        for i, id in ipairs(presetData.ids) do
                            if id == achievementID then
                                table.remove(presetData.ids, i)
                                print(L["Achievement_Removed_From_List"])
                                AchievementsCollector:UpdateSettings()
                                break
                            end
                        end
                    
                        if acTable.RefreshMainTrackerUI then acTable:RefreshMainTrackerUI() end
                        if LibStub and LibStub("AceConfigRegistry-3.0", true) then
                            LibStub("AceConfigRegistry-3.0"):NotifyChange("CustomAchievementTracker_AddLists")
                        end
                    end)
                end
            end
        end

        if not hasAnyPreset then
            removeSubMenu:CreateButton(L["Not_in_a_List"], function() end)
        end

    end)
end

-- 2. Atualização do gatilho do botão para repassar o ID capturado para o menu
local function HookAchievementButton(frame)
    if frame.hasMyOverlay then return end
    
    if not frame:IsObjectType("Button") and not frame:IsObjectType("Frame") then 
        return 
    end
    
    if not frame:IsShown() then return end

    if frame.HookScript then
        frame:HookScript("OnMouseUp", function(self, buttonName)
            if buttonName == "RightButton" then
                local achievementID = frame.id or frame.achievementID or (frame.element and frame.element.id)
                if not achievementID and frame.GetParent then
                    local parent = frame:GetParent()
                    achievementID = parent.id or parent.achievementID
                end

                if achievementID then
                    ShowMyCustomContextMenu(self, achievementID)
                end
            end
        end)
    end

    frame.hasMyOverlay = true
end

local function DeepScanAchievementFrames(parentFrame)
    if not parentFrame or not parentFrame.GetChildren then return end
    
    local children = { parentFrame:GetChildren() }
    for _, child in ipairs(children) do
        if child:IsShown() then
            local hasAchievementData = child.id or child.achievementID or (child.element and child.element.id)
            local hasIcon = child.icon or (child.Icon and child.Icon.GetTexture and child.Icon:GetTexture())
            
            if hasAchievementData or hasIcon then
                HookAchievementButton(child)
            end
            
            DeepScanAchievementFrames(child)
        end
    end
end

local function RunScan()
    if AchievementFrame and AchievementFrame:IsShown() then
        DeepScanAchievementFrames(AchievementFrame)
        
        if AchievementFrameAchievementsContainer and AchievementFrameAchievementsContainer.buttons then
            for _, btn in ipairs(AchievementFrameAchievementsContainer.buttons) do
                HookAchievementButton(btn)
            end
        end
    end
end

-- Gerenciador de ciclo de vida
local ticker = nil
local function StartChecking()
    if ticker then return end
    ticker = C_Timer.NewTicker(0.2, RunScan)
end

local function StopChecking()
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon == "Blizzard_AchievementUI" then
        if AchievementFrame then
            AchievementFrame:HookScript("OnShow", StartChecking)
            AchievementFrame:HookScript("OnHide", StopChecking)
            
            if AchievementFrame:IsShown() then
                StartChecking()
            end
        end
    end
end)