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

local ADDON_NAME, acTable = ...
local L = acTable.L 

local currentActiveListKey = nil

-- Instanciação da função principal do Addon
AchievementsCollector = AchievementsCollector or {}

if not AchievementsCollectorSharedDB then
    AchievementsCollectorSharedDB = {minimap = {hide = false}}
end
if not AchievementsCollectorDB then
    AchievementsCollectorDB = {}
end

AchievementsLists = {}

AchievementsListsNames = {}

AchievementsListsOrder = AchievementsListsOrder or {}

local Tracker = CreateFrame("Frame", "AchievementsCollectorFrame", UIParent, "BasicFrameTemplateWithInset")
Tracker:SetSize(770, 500)
Tracker:SetPoint("CENTER")
Tracker:Hide()

Tracker.TitleText:SetText(L["Main_Screen_Title"])

Tracker:SetMovable(true)
Tracker:EnableMouse(true)
Tracker:RegisterForDrag("LeftButton")
Tracker:SetScript("OnDragStart", function () if (not AchievementsCollectorDB.LockDragDrop) then Tracker:StartMoving() end end)
Tracker:SetScript("OnDragStop", function () if (not AchievementsCollectorDB.LockDragDrop) then Tracker:StopMovingOrSizing() end end)
Tracker:SetScript("OnShow", function () PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN) end)
Tracker:SetScript("OnHide", function () PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE) end)
Tracker:SetScript("OnDragStop", Tracker.StopMovingOrSizing)
Tracker:SetFrameStrata("LOW")

_G["ACTrackerFrameName"] = Tracker
tinsert(UISpecialFrames, "ACTrackerFrameName")

-- ============================================================================
-- 1. ESTRUTURA DE DADOS
-- ============================================================================

local function GetCustomAchievementInfo(achievementID)
    local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, tracked = GetAchievementInfo(achievementID)
    
    local isAccountWide = bit.band(flags, 0x20000) == 0x20000

    if not name or name == "" then
        local customData = acTable.DB and acTable.DB[achievementID]
        if customData then
            return {
                id = achievementID,
                name = customData.name,
                description = customData.description,
                icon = customData.icon or "Interface\\Icons\\Inv_misc_questionmark",
                points = customData.points or 10,
                completed = customData.completed or false,
                isSecret = true,
                tiers = customData.tiers or nil,
            }
        end
    end

    return {
        id = id,
        name = name,
        description = description,
        icon = icon,
        points = points,
        completed = completed,
        isSecret = false,
        tracked = tracked,
        isAccountWide = isAccountWide,
        wasEarnedByMe = wasEarnedByMe,
    }
end

-- ============================================================================
-- 2. CRIAÇÃO DA INTERFACE (MENU LATERAL + CONTEÚDO)
-- ============================================================================

Tracker.InsetBg:SetPoint("TOPLEFT", Tracker, "TOPLEFT", 4, -24)
Tracker.InsetBg:SetPoint("BOTTOMRIGHT", Tracker, "BOTTOMRIGHT", -4, 4)

-- --- PAINEL LATERAL ESQUERDO (Abas / Categorias) ---
local CategoryPanel = CreateFrame("Frame", nil, Tracker, "BackdropTemplate")
CategoryPanel:SetSize(230, 464)
CategoryPanel:SetPoint("TOPLEFT", Tracker.InsetBg, "TOPLEFT", 4, -4)
CategoryPanel:SetPoint("BOTTOMLEFT", Tracker.InsetBg, "BOTTOMLEFT", 4, 4)
CategoryPanel:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
CategoryPanel:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
CategoryPanel:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

local CategoryScrollFrame = CreateFrame("ScrollFrame", nil, CategoryPanel, "UIPanelScrollFrameTemplate")
CategoryScrollFrame:SetPoint("TOPLEFT", CategoryPanel, "TOPLEFT", 6, -6)
CategoryScrollFrame:SetPoint("BOTTOMRIGHT", CategoryPanel, "BOTTOMRIGHT", -26, 34)

local CategoryContent = CreateFrame("Frame", nil, CategoryScrollFrame)
CategoryContent:SetSize(142, 1)
CategoryScrollFrame:SetScrollChild(CategoryContent)

-- --- PAINEL PRINCIPAL (Lista de Conquistas) ---
local ContentScrollFrame = CreateFrame("ScrollFrame", nil, Tracker, "UIPanelScrollFrameTemplate")
ContentScrollFrame:SetPoint("TOPLEFT", CategoryPanel, "TOPRIGHT", 6, 0)
ContentScrollFrame:SetPoint("BOTTOMRIGHT", Tracker.InsetBg, "BOTTOMRIGHT", -24, 40)

local Content = CreateFrame("Frame", nil, ContentScrollFrame)
Content:SetSize(480, 1)
Content:SetFrameStrata("LOW")
Content:SetFrameLevel(10)
ContentScrollFrame:SetScrollChild(Content)

-- 1. Placeholder para quando não há listas criadas
local EmptyListsNotice = CreateFrame("Frame", nil, CategoryPanel)
EmptyListsNotice:SetPoint("TOPLEFT", CategoryPanel, "TOPLEFT", 10, -30)
EmptyListsNotice:SetPoint("BOTTOMRIGHT", CategoryPanel, "BOTTOMRIGHT", -10, 30)
EmptyListsNotice:Hide()

EmptyListsNotice.Text = EmptyListsNotice:CreateFontString(nil, "OVERLAY", "GameFontNormal")
EmptyListsNotice.Text:SetPoint("CENTER", EmptyListsNotice, "CENTER", 0, 0)
EmptyListsNotice.Text:SetPoint("LEFT", EmptyListsNotice, "LEFT", 5, 0)
EmptyListsNotice.Text:SetPoint("RIGHT", EmptyListsNotice, "RIGHT", -5, 0)
EmptyListsNotice.Text:SetJustifyH("CENTER")
EmptyListsNotice.Text:SetWordWrap(true)
EmptyListsNotice.Text:SetText(L["Empty_Lists_Notice"])
EmptyListsNotice.Text:SetTextColor(1, 0.82, 0)

--EmptyListsNotice.Button = CreateFrame("Button", nil, EmptyListsNotice, "UIPanelButtonTemplate")
--EmptyListsNotice.Button:SetSize(140, 24)
--EmptyListsNotice.Button:SetPoint("TOP", EmptyListsNotice.Text, "BOTTOM", 0, -10)
--EmptyListsNotice.Button:SetText(L["Open_Settings"])
--EmptyListsNotice.Button:SetScript("OnClick", function()
--    AchievementsCollector:ToggleSettingsFrame()
--    AchievementsCollector:SetToTab("A")
--end)

-- 2. Placeholder para quando a lista selecionada está vazia
local EmptyAchievementsNotice = CreateFrame("Frame", nil, Tracker)
EmptyAchievementsNotice:SetPoint("TOPLEFT", ContentScrollFrame, "TOPLEFT", 0, 0)
EmptyAchievementsNotice:SetPoint("BOTTOMRIGHT", ContentScrollFrame, "BOTTOMRIGHT", 0, 0)
EmptyAchievementsNotice:Hide()

EmptyAchievementsNotice.Icon = EmptyAchievementsNotice:CreateTexture(nil, "ARTWORK")
EmptyAchievementsNotice.Icon:SetSize(48, 48)
EmptyAchievementsNotice.Icon:SetPoint("CENTER", EmptyAchievementsNotice, "CENTER", 0, 35)
EmptyAchievementsNotice.Icon:SetAtlas("UI-Achievement-Shield-NoPoints")
EmptyAchievementsNotice.Icon:SetSize(64, 64)

EmptyAchievementsNotice.Text = EmptyAchievementsNotice:CreateFontString(nil, "OVERLAY", "GameFontNormal")
EmptyAchievementsNotice.Text:SetPoint("TOP", EmptyAchievementsNotice.Icon, "BOTTOM", 0, -10)
EmptyAchievementsNotice.Text:SetWidth(400)
EmptyAchievementsNotice.Text:SetJustifyH("CENTER")
EmptyAchievementsNotice.Text:SetWordWrap(true)

-- Botão 1: Abrir Configurações
EmptyAchievementsNotice.Button = CreateFrame("Button", nil, EmptyAchievementsNotice, "UIPanelButtonTemplate")
EmptyAchievementsNotice.Button:SetSize(120, 24)
EmptyAchievementsNotice.Button:SetPoint("TOP", EmptyAchievementsNotice.Text, "BOTTOM", 0, -15)
EmptyAchievementsNotice.Button:SetPoint("RIGHT", EmptyAchievementsNotice, "CENTER", -4, 0)
EmptyAchievementsNotice.Button:SetText(L["button_Add"])
EmptyAchievementsNotice.Button:SetScript("OnClick", function()
    PlaySound(808)
    if currentActiveListKey then
        OpenManageSingleListWindow(currentActiveListKey)
    end
end)

-- Botão 2: Importar Lista
EmptyAchievementsNotice.ImportButton = CreateFrame("Button", nil, EmptyAchievementsNotice, "UIPanelButtonTemplate")
EmptyAchievementsNotice.ImportButton:SetSize(120, 24)
EmptyAchievementsNotice.ImportButton:SetPoint("TOP", EmptyAchievementsNotice.Text, "BOTTOM", 0, -15)
EmptyAchievementsNotice.ImportButton:SetPoint("LEFT", EmptyAchievementsNotice, "CENTER", 4, 0)
EmptyAchievementsNotice.ImportButton:SetText(L["button_Import"])
EmptyAchievementsNotice.ImportButton:SetScript("OnClick", function()
    PlaySound(808)
    ACLImportModule:ShowImportWindow(function(importedTable)

        if not acTable.DB.CustomLists then
            acTable.DB.CustomLists = {}
        end
        
        if not acTable.DB.CustomLists[currentActiveListKey] then
            acTable.DB.CustomLists[currentActiveListKey] = {}
        end
        
        local targetList = acTable.DB.CustomLists[currentActiveListKey].ids
        
        -- 1. Limpa os dados antigos da lista selecionada
        table.wipe(targetList)
        
        -- 2. Insere o conteúdo importado para dentro da tabela
        for k, v in pairs(importedTable) do
            targetList[k] = v
        end
        
        AchievementsLists[currentActiveListKey] = targetList
    
        if Tracker and Tracker:IsShown() then
            Tracker:DisplayAchievements(currentActiveListKey)
        end
        
        if acTable.RefreshMainTrackerUI then
            acTable:RefreshMainTrackerUI()
        end
    end)
end)

local achievementButtons = {}
local tabButtons = {}
local COLLAPSED_HEIGHT = 70


local function UpdateLayout()
    local offsetY = -5
    for i, row in ipairs(achievementButtons) do
        if row:IsShown() then
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", Content, "TOPLEFT", 5, offsetY)
            offsetY = offsetY - (row:GetHeight() + 10)
        end
    end
    Content:SetHeight(math.abs(offsetY) + 20)
end

local function CreateAchievementRow(parent, index)
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    row:SetFrameStrata("LOW")
    row:SetSize(485, COLLAPSED_HEIGHT)
    
    row:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    row:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    row:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    row.isExpanded = false

    row.Icon = row:CreateTexture(nil, "ARTWORK")
    row.Icon:SetSize(56, 56)
    row.Icon:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -8)
    
    row.IconBorder = row:CreateTexture(nil, "OVERLAY")
    row.IconBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    row.IconBorder:SetSize(94, 94)
    row.IconBorder:SetPoint("CENTER", row.Icon, "CENTER", 0, 0)

    -- Botões de reordenação de conquistas
    row.MoveUpBtn = CreateFrame("Button", nil, row)
    row.MoveUpBtn:SetSize(20, 20)
    row.MoveUpBtn:SetPoint("TOPRIGHT", row, "TOPRIGHT", -28, -6)
    row.MoveUpBtn:SetNormalTexture("128-RedButton-ArrowUpGlow")
    row.MoveUpBtn:SetPushedTexture("128-RedButton-ArrowUpGlow-Pressed")
    row.MoveUpBtn:SetHighlightTexture("128-RedButton-ArrowUpGlow-Highlight", "ADD")
    
    row.MoveDownBtn = CreateFrame("Button", nil, row)
    row.MoveDownBtn:SetSize(20, 20)
    row.MoveDownBtn:SetPoint("TOPRIGHT", row, "TOPRIGHT", -28, -26)
    row.MoveDownBtn:SetNormalTexture("128-RedButton-ArrowDown")
    row.MoveDownBtn:SetPushedTexture("128-RedButton-ArrowUpGlow-Pressed")
    row.MoveDownBtn:SetHighlightTexture("128-RedButton-ArrowDown-Highlight", "ADD")

    row.ExpandButton = CreateFrame("Button", nil, row)
    row.ExpandButton:SetSize(20, 20)
    row.ExpandButton:SetPoint("TOPRIGHT", row, "TOPRIGHT", -6, -6)
    row.ExpandButton:SetNormalTexture("128-RedButton-Plus")
    row.ExpandButton:SetPushedTexture("128-RedButton-Plus-Pressed")
    row.ExpandButton:SetHighlightTexture("128-RedButton-Plus-Highlight", "ADD")

    row.Title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.Title:SetPoint("TOPLEFT", row.Icon, "TOPRIGHT", 12, 0)
    row.Title:SetPoint("RIGHT", row.MoveUpBtn, "LEFT", -5, 0)
    row.Title:SetJustifyH("LEFT")

    row.Desc = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.Desc:SetPoint("TOPLEFT", row.Title, "BOTTOMLEFT", 0, -2)
    row.Desc:SetPoint("RIGHT", row, "RIGHT", -52, 0)
    row.Desc:SetJustifyH("LEFT")
    row.Desc:SetWordWrap(true)

    row.DetailsText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.DetailsText:SetPoint("TOPLEFT", row.Desc, "BOTTOMLEFT", 0, -8)
    row.DetailsText:SetPoint("RIGHT", row, "RIGHT", -10, 0)
    row.DetailsText:SetJustifyH("LEFT")
    row.DetailsText:SetWordWrap(true)
    row.DetailsText:SetTextColor(0.8, 0.8, 0.8, 1)
    row.DetailsText:Hide()

    row.ProgressBar = CreateFrame("StatusBar", nil, row, "TextStatusBar")
    row.ProgressBar:SetSize(390, 10)
    row.ProgressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    row.ProgressBar:SetStatusBarColor(0, 0.8, 0)
    row.ProgressBar:SetMinMaxValues(0, 100)
    row.ProgressBar:SetValue(0)

    row.BorderFrame = CreateFrame("Frame", nil, row.ProgressBar, "BackdropTemplate")
    row.BorderFrame:SetPoint("TOPLEFT", row.ProgressBar, "TOPLEFT", -2, 2)
    row.BorderFrame:SetPoint("BOTTOMRIGHT", row.ProgressBar, "BOTTOMRIGHT", 2, -2)
    row.BorderFrame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    row.BorderFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)

    row.ProgressText = row.ProgressBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.ProgressText:SetPoint("CENTER", row.ProgressBar, "CENTER", 0, 0)
    row.ProgressText:SetText("0 / 0")

    local function RefreshRowHeight()
        if row.isExpanded then
            row.DetailsText:Show()
            local descH = row.Desc:GetHeight() or 15
            local detailsH = row.DetailsText:GetStringHeight() or 30
            local totalHeight = 12 + 15 + descH + 8 + detailsH + 12 + 16 + 12
            row:SetHeight(totalHeight)
            row.ProgressBar:ClearAllPoints()
            row.ProgressBar:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 74, 10)
        else
            row.DetailsText:Hide()
            row:SetHeight(COLLAPSED_HEIGHT)
            row.ProgressBar:ClearAllPoints()
            row.ProgressBar:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 74, 10)
        end
        UpdateLayout()
    end

    row.RefreshRowHeight = RefreshRowHeight

    row.ExpandButton:SetScript("OnClick", function()
        row.isExpanded = not row.isExpanded
        if row.isExpanded then
            row.ExpandButton:SetNormalTexture("128-RedButton-Minus")
            row.ExpandButton:SetPushedTexture("128-RedButton-Minus-Pressed")
            row.ExpandButton:SetHighlightTexture("128-RedButton-Minus-Highlight", "ADD")
            PlaySound(808)
        else
            row.ExpandButton:SetNormalTexture("128-RedButton-Plus")
            row.ExpandButton:SetPushedTexture("128-RedButton-Plus-Pressed")
            row.ExpandButton:SetHighlightTexture("128-RedButton-Plus-Highlight", "ADD")
            PlaySound(808)
        end
        RefreshRowHeight()
    end)

    return row
end

-- ============================================================================
-- 3. RENDERIZAÇÃO E SISTEMA DE ABAS LATERAIS
-- ============================================================================

local function MoveItemInTable(t, index, direction)
    local targetIndex = index + direction
    if targetIndex < 1 or targetIndex > #t then return end
    local temp = t[index]
    t[index] = t[targetIndex]
    t[targetIndex] = temp
end

local function SavePresetIds(listKey)
    if not listKey then return end
    acTable.DB = acTable.DB or {}
    acTable.DB.CustomLists = acTable.DB.CustomLists or {}
    acTable.DB.CustomLists[listKey] = acTable.DB.CustomLists[listKey] or {
        name = AchievementsListsNames[listKey] or listKey,
        ids = {}
    }
    acTable.DB.CustomLists[listKey].ids = AchievementsLists[listKey]
end

function Tracker:DisplayAchievements(listKey)
    if not AchievementsLists[listKey] then return end
    currentActiveListKey = listKey
    
    local achievementIDs = AchievementsLists[listKey]

    -- VERIFICAÇÃO DE CONQUISTAS VAZIAS NA LISTA ATUAL
    if not achievementIDs or #achievementIDs == 0 then
        local listName = AchievementsListsNames[listKey] or listKey
        EmptyAchievementsNotice.Text:SetText(string.format(L["Empty_List_Message"], listName))
        EmptyAchievementsNotice:Show()
        
        -- Oculta linhas antigas de conquistas caso existam
        for _, row in ipairs(achievementButtons) do
            row:Hide()
        end
        Content:SetHeight(1)

        for key, tabBtn in pairs(tabButtons) do
        
        if key == listKey then
            tabBtn:LockHighlight()
            tabBtn.Text:SetTextColor(1, 0.82, 0)
        else
            tabBtn:UnlockHighlight()
            tabBtn.Text:SetTextColor(1, 1, 1)
        end
    end

        return
    else
        EmptyAchievementsNotice:Hide()
    end

    for key, tabBtn in pairs(tabButtons) do
        
        if key == listKey then
            tabBtn:LockHighlight()
            tabBtn.Text:SetTextColor(1, 0.82, 0)
        else
            tabBtn:UnlockHighlight()
            tabBtn.Text:SetTextColor(1, 1, 1)
        end
    end

    for i, id in ipairs(achievementIDs) do
        local row = achievementButtons[i]
        if not row then
            row = CreateAchievementRow(Content, i)
            achievementButtons[i] = row
        end
        row:Show()

        row.achievementID = id
        row.assignedlistKey = listKey

        -- Configurar botões de mover conquista
        row.MoveUpBtn:SetScript("OnClick", function()
            PlaySound(808)
            MoveItemInTable(achievementIDs, i, -1)
            SavePresetIds(listKey)
            Tracker:DisplayAchievements(listKey)
            if LibStub and LibStub("AceConfigRegistry-3.0", true) then
                LibStub("AceConfigRegistry-3.0"):NotifyChange("AchievementsCollector_AddLists")
            end
        end)

        row.MoveDownBtn:SetScript("OnClick", function()
            PlaySound(808)
            MoveItemInTable(achievementIDs, i, 1)
            SavePresetIds(listKey)
            Tracker:DisplayAchievements(listKey)
            if LibStub and LibStub("AceConfigRegistry-3.0", true) then
                LibStub("AceConfigRegistry-3.0"):NotifyChange("AchievementsCollector_AddLists")
            end
        end)

        local data = GetCustomAchievementInfo(id)

        row.Title:SetText(data.name or L["Unknown_Achievement"])
        row.Desc:SetText(data.description or L["No_Description"])
        row.Icon:SetTexture(data.icon)

        local detailsStr = L["Achievement_Criteria"] .. "\n"
        local numCriteria = GetAchievementNumCriteria(id)
        if numCriteria and numCriteria > 0 then
            for c = 1, numCriteria do
                local criteriaString, _, completed = GetAchievementCriteriaInfo(id, c)
                local statusIcon = completed and "|cff00ff00" or "|cff999999"
                detailsStr = detailsStr .. string.format("%s %s|r\n", statusIcon, criteriaString or L["Criteria"] .. " " .. c)
            end
        else
            local completionMsg = data.completed and L["Achievement_Completed"] or L["Achievement_No_Criteria"]
            detailsStr = detailsStr .. completionMsg
        end
        row.DetailsText:SetText(detailsStr)

        if data.tiers then
            local currentTier = data.tiers.current or 1
            local maxTier = data.tiers.max or 1
            row.ProgressBar:SetMinMaxValues(0, maxTier)
            row.ProgressBar:SetValue(currentTier)
            row.ProgressText:SetText(string.format(L["Achievement_Tiers"], currentTier, maxTier))
        else
            if numCriteria and numCriteria > 0 then

                local _, _, _, quantity, reqQuantity = GetAchievementCriteriaInfo(id, 1)
        
                if numCriteria == 1 and reqQuantity and reqQuantity > 1 then
                    local currentVal = quantity or 0
                    local maxVal = reqQuantity

                    if data.completed then
                        row.ProgressBar:SetMinMaxValues(0, maxVal)
                        row.ProgressBar:SetValue(currentVal)
                        row.ProgressText:SetText(L["Finished"])
                    else
                        row.ProgressBar:SetMinMaxValues(0, maxVal)
                        row.ProgressBar:SetValue(currentVal)
                        row.ProgressText:SetText(currentVal .. " / " .. maxVal)
                    end
                else

                    local completedCriteria = 0
                    for c = 1, numCriteria do
                        local _, _, completed = GetAchievementCriteriaInfo(id, c)
                        if completed then completedCriteria = completedCriteria + 1 end
                    end
                
                    if data.completed then
                        row.ProgressBar:SetMinMaxValues(0, numCriteria)
                        row.ProgressBar:SetValue(numCriteria)
                        if completedCriteria < numCriteria then
                            row.ProgressText:SetText(L["Finished"] .. " (" .. completedCriteria .. " / " .. numCriteria .. ")")
                        else
                            row.ProgressText:SetText(L["Finished"])
                        end
                    else
                        row.ProgressBar:SetMinMaxValues(0, numCriteria)
                        row.ProgressBar:SetValue(completedCriteria)
                        row.ProgressText:SetText(completedCriteria .. " / " .. numCriteria)
                    end
                end
            else
                row.ProgressBar:SetMinMaxValues(0, 1)
                row.ProgressBar:SetValue(data.completed and 1 or 0)
                row.ProgressText:SetText(data.completed and L["Finished"] or L["Pending"])
            end
        end

        if data.completed then
            row.IconBorder:SetVertexColor(1, 0.82, 0)
            row.Title:SetTextColor(1, 0.82, 0)
        elseif data.isAccountWide then
            row.IconBorder:SetVertexColor(0.2, 0.6, 1)
            row.Title:SetTextColor(0.7, 0.9, 1)
        else
            row.IconBorder:SetVertexColor(0.5, 0.5, 0.5)
            row.Title:SetTextColor(1, 1, 1)
        end

        if data.isAccountWide then
            row:SetBackdropBorderColor(0.2, 0.6, 1, 1)
        else
            row:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        end

        if not data.wasEarnedByMe and data.completed then
            --row.Icon:SetDesaturation(1)
            row.ProgressText:SetText(L["Completed_Warband"])
        --else
            --row.Icon:SetDesaturation(0)            
        end

        local isCustomList = acTable.DB and acTable.DB.CustomLists and acTable.DB.CustomLists[listKey] ~= nil

        row.MoveUpBtn:SetShown(isCustomList)
        row.MoveDownBtn:SetShown(isCustomList)

        if isCustomList then
            row.MoveUpBtn:SetScript("OnClick", function()
                PlaySound(808)
                MoveItemInTable(achievementIDs, i, -1)
                SavePresetIds(listKey)
                Tracker:DisplayAchievements(listKey)
                if LibStub and LibStub("AceConfigRegistry-3.0", true) then
                    LibStub("AceConfigRegistry-3.0"):NotifyChange("AchievementsCollector_AddLists")
                end
            end)

            row.MoveDownBtn:SetScript("OnClick", function()
                PlaySound(808)
                MoveItemInTable(achievementIDs, i, 1)
                SavePresetIds(listKey)
                Tracker:DisplayAchievements(listKey)
                if LibStub and LibStub("AceConfigRegistry-3.0", true) then
                    LibStub("AceConfigRegistry-3.0"):NotifyChange("AchievementsCollector_AddLists")
                end
            end)
        else
            row.MoveUpBtn:SetScript("OnClick", nil)
            row.MoveDownBtn:SetScript("OnClick", nil)
        end

        row.RefreshRowHeight()
    end

    for i = #achievementIDs + 1, #achievementButtons do
        achievementButtons[i]:Hide()
    end

    UpdateLayout()
end

local function InitializeTabs()
    for _, tab in pairs(tabButtons) do
        if tab then tab:Hide() end
    end
    tabButtons = {}

    -- Organiza a lista de chaves aplicando a ordem customizada se existir
    local keys = {}
    for key in pairs(AchievementsListsNames) do
        table.insert(keys, key)
    end

    -- VERIFICAÇÃO DE LISTAS VAZIAS NO MENU LATERAL
    if #keys == 0 then
        EmptyListsNotice:Show()
        ContentScrollFrame:Hide()
        EmptyAchievementsNotice:Hide()
        currentActiveListKey = nil
        CategoryContent:SetHeight(1)
        return
    else
        EmptyListsNotice:Hide()
        ContentScrollFrame:Show()
    end
    
    table.sort(keys, function(a, b)
        local posA = AchievementsListsOrder[a] or 999
        local posB = AchievementsListsOrder[b] or 999
        if posA == posB then
            return a < b
        end
        return posA < posB
    end)

    local offsetY = -5
    for index, key in ipairs(keys) do
        local name = AchievementsListsNames[key]
        local tab = CreateFrame("Button", nil, CategoryContent, "BackdropTemplate")
        
        tab:SetSize(190, 24)
        tab:SetPoint("TOPLEFT", CategoryContent, "TOPLEFT", 3, offsetY)
        
        tab:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        
        tab:SetBackdropColor(0.2, 0.2, 0.2, 0.6)
        tab:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

        tab.Text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        tab.Text:SetPoint("LEFT", tab, "LEFT", 8, 0)
        tab.Text:SetPoint("RIGHT", tab, "RIGHT", -40, 0)
        tab.Text:SetPoint("RIGHT", tab, "RIGHT", -42, 0)
        tab.Text:SetJustifyH("LEFT")
        tab.Text:SetText(name)
        tab.Text:SetWordWrap(false)

        -- Botões de reordenação de Abas
        local upBtn = CreateFrame("Button", nil, tab)
        upBtn:SetSize(16, 16)
        upBtn:SetPoint("RIGHT", tab, "RIGHT", -22, 0)
        upBtn:SetNormalTexture("128-RedButton-ArrowUpGlow")
        upBtn:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
        upBtn:SetHighlightTexture("128-RedButton-ArrowUpGlow-Highlight", "ADD")
        upBtn:SetScript("OnClick", function()
            PlaySound(808)
            MoveItemInTable(keys, index, -1)
            for newIdx, k in ipairs(keys) do
                AchievementsListsOrder[k] = newIdx
            end
            if acTable.DB then acTable.DB.PresetOrder = AchievementsListsOrder end
            InitializeTabs()
        end)

        local downBtn = CreateFrame("Button", nil, tab)
        downBtn:SetSize(16, 16)        
        downBtn:SetPoint("RIGHT", tab, "RIGHT", -4, 0)
        downBtn:SetNormalTexture("128-RedButton-ArrowDown")
        downBtn:SetPushedTexture("128-RedButton-ArrowUpGlow-Pressed")
        downBtn:SetHighlightTexture("128-RedButton-ArrowDown-Highlight", "ADD")
        downBtn:SetScript("OnClick", function()
            PlaySound(808)
            MoveItemInTable(keys, index, 1)
            for newIdx, k in ipairs(keys) do
                AchievementsListsOrder[k] = newIdx
            end
            if acTable.DB then acTable.DB.PresetOrder = AchievementsListsOrder end
            InitializeTabs()
        end)

        tab:SetScript("OnClick", function()
            PlaySound(808)
            Tracker:DisplayAchievements(key)
            OnSwitchListButtonClicked(currentActiveListKey)
        end)
        
        tab:SetScript("OnEnter", function(self)
            tab:SetBackdropColor(0.3, 0.3, 0.4, 0.8)
        end)
        
        tab:SetScript("OnLeave", function(self)
            tab:SetBackdropColor(0.2, 0.2, 0.2, 0.6)
        end)

        tabButtons[key] = tab
        offsetY = offsetY - 28
    end
    CategoryContent:SetHeight(math.abs(offsetY) + 10)
end

function acTable:RefreshMainTrackerUI()
    InitializeTabs()
    if Tracker:IsShown() and currentActiveListKey then
        Tracker:DisplayAchievements(currentActiveListKey)
    end
end

-- ============================================================================
-- 4. INICIALIZAÇÃO SEGURA VIA EVENTO ADDON_LOADED
-- ============================================================================

local InitFrame = CreateFrame("Frame")
InitFrame:RegisterEvent("ADDON_LOADED")
InitFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == ADDON_NAME then
        AchievementsCollectorDB = AchievementsCollectorDB or {}
        acTable.DB = AchievementsCollectorDB
        acTable.DB.CustomLists = acTable.DB.CustomLists or {}

        if acTable.DB.PresetOrder then
            AchievementsListsOrder = acTable.DB.PresetOrder
        end

        if acTable.DB.CustomLists then
            for key, data in pairs(acTable.DB.CustomLists) do
                if data and data.name and data.ids then
                    AchievementsLists[key] = data.ids
                    AchievementsListsNames[key] = data.name
                end
            end
        end

        InitializeTabs()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

local function GetFirstCustomKey()
    if acTable.DB and acTable.DB.CustomLists then
        for k in pairs(acTable.DB.CustomLists) do return k end
    end
    return nil
end

SLASH_ACHIEVEMENTSCOLLECTOR1 = "/ac"
SLASH_ACHIEVEMENTSCOLLECTOR2 = "/ACHIEVEMENTSCOLLECTOR"
SlashCmdList["ACHIEVEMENTSCOLLECTOR"] = function(msg)
    msg = msg and msg:lower() or ""
    if msg == "config" then
        AchievementsCollector:ToggleSettingsFrame()
    elseif msg == "commands" then
        print(L["SlashCommands"])
    else
        if Tracker:IsShown() then
            Tracker:Hide()
        else
            Tracker:Show()
            local defaultKey = currentActiveListKey or GetFirstCustomKey()
        if defaultKey then Tracker:DisplayAchievements(defaultKey) end
        end
    end
end

function ToggleAchievementsFrame()
    if Tracker:IsShown() then
        Tracker:Hide()
    else
        Tracker:Show()
        local defaultKey = currentActiveListKey or GetFirstCustomKey()
        if defaultKey then Tracker:DisplayAchievements(defaultKey) end
    end
end

function AC_ToggleMinimapButton(_param)
    if _param then
        AchievementsCollectorMinimapButton:Hide("AchievementsCollector")
    else
        AchievementsCollectorMinimapButton:Show("AchievementsCollector")
    end
end

-- Adição do ícone de minimapa.
AchievementsCollectorMinimapButton = LibStub("LibDBIcon-1.0", true)

local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject("AchievementsCollector", {
    type = "data source",
    text = L["AddonName"],
    icon = "Interface\\AddOns\\AchievementsCollector\\ACIcon.png",
    OnClick = function(self, btn)
        if btn == "LeftButton" then
            ToggleAchievementsFrame()
        elseif btn == "RightButton" then
            PlaySound(808)
            AchievementsCollector:ToggleSettingsFrame()
        end
    end,

    OnTooltipShow = function(tooltip)
        if not tooltip or not tooltip.AddLine then
            return
        end
        if (AchievementsCollectorDB.HideDeveloperCreditOnTooltips) then
            tooltip:AddLine(L["AddonName_Interface"] .. "\n\n" .. L["LClickAction"] .. "\n" .. L["RClickAction"] .."", nil, nil, nil, nil)
        else
            tooltip:AddLine(L["AddonName_Interface"] .. "\n\n" .. L["LClickAction"] .. "\n" .. L["RClickAction"] .. "\n\n" .. L["DevelopmentTeamCredit"], nil, nil, nil, nil)
        end
    end,
})

AchievementsCollectorMinimapButton:Show(L["AddonName"])

local eventListenerFrame = CreateFrame("Frame", "AchievementsCollectorEventListenerFrame", UIParent)
eventListenerFrame:RegisterEvent("ADDON_LOADED")
eventListenerFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        local addonName = L["AddonName"]
        if name == addonName then
            AchievementsCollectorMinimapButton:Register(L["AddonName"], miniButton, AchievementsCollectorSharedDB.minimap)
        end
    end
end)

-- ===========================================================
-- Context menus para abas e linhas de conquista
-- ===========================================================
do
    local function GetPresetDisplayName(key)
        if acTable and acTable.DB and acTable.DB.CustomLists and acTable.DB.CustomLists[key] then
            return acTable.DB.CustomLists[key].name or AchievementsListsNames[key] or key
        end
        return AchievementsListsNames[key] or key
    end

    if StaticPopupDialogs["HAT_CONFIRM_DELETE_LIST"] == nil then
        StaticPopupDialogs["HAT_CONFIRM_DELETE_LIST"] = {
            text = L["Confirm_List_Remove"],
            button1 = L["button_Confirm"],
            button2 = L["button_Cancel"],
            OnAccept = function(self, data)
                local key = data
                if acTable and acTable.DB and acTable.DB.CustomLists and acTable.DB.CustomLists[key] then
                    acTable.DB.CustomLists[key] = nil
                    AchievementsLists[key] = nil
                    AchievementsListsNames[key] = nil
                    if AchievementsCollector and AchievementsCollector.UpdateSettings then
                        AchievementsCollector:UpdateSettings()
                    end
                    if acTable and acTable.RefreshMainTrackerUI then acTable:RefreshMainTrackerUI() end
                    if LibStub and LibStub("AceConfigRegistry-3.0", true) then
                        LibStub("AceConfigRegistry-3.0"):NotifyChange("AchievementsCollector_AddLists")
                    end
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end

    if StaticPopupDialogs["HAT_CONFIRM_REMOVE_ACH"] == nil then
        StaticPopupDialogs["HAT_CONFIRM_REMOVE_ACH"] = {
            text = L["Confirm_Remove_Message"],
            button1 = L["button_Confirm"],
            button2 = L["button_Cancel"],
            OnAccept = function(self, data)
                local achievementID, listKey = data[1], data[2]
                if listKey and acTable and acTable.DB and acTable.DB.CustomLists and acTable.DB.CustomLists[listKey] then
                    local ids = acTable.DB.CustomLists[listKey].ids
                    if ids then
                        for i = #ids, 1, -1 do
                            if ids[i] == achievementID then
                                table.remove(ids, i)
                                break
                            end
                        end
                        AchievementsLists[listKey] = acTable.DB.CustomLists[listKey].ids
                        if AchievementsCollector and AchievementsCollector.UpdateSettings then
                            AchievementsCollector:UpdateSettings()
                        end
                        if acTable and acTable.RefreshMainTrackerUI then acTable:RefreshMainTrackerUI() end
                        if LibStub and LibStub("AceConfigRegistry-3.0", true) then
                            LibStub("AceConfigRegistry-3.0"):NotifyChange("AchievementsCollector_AddLists")
                        end
                    end
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end

    -- Função auxiliar para verificar se um ID já existe em uma tabela
    local function TableContains(tbl, val)
        for _, v in ipairs(tbl) do
            if v == val then
                return true
            end
        end
        return false
    end

    local function ShowTabContextMenu(anchor, listKey)
        if not listKey then return end
        MenuUtil.CreateContextMenu(anchor, function(owner, root)
            root:CreateTitle(L["List_Options"])
            local isCustom = acTable and acTable.DB and acTable.DB.CustomLists and acTable.DB.CustomLists[listKey]
            local displayName = GetPresetDisplayName(listKey)
            if isCustom then

                root:CreateButton(L["List_Rename"], function()
                    if StaticPopupDialogs["HAT_RENAME_LIST"] == nil then
                        StaticPopupDialogs["HAT_RENAME_LIST"] = {
                            text = L["List_New_Name"],
                            button1 = L["button_Save"],
                            button2 = L["button_Cancel"],
                            hasEditBox = true,
                            maxLetters = 50,
                            editBoxWidth = 250,
                            OnShow = function(self, data)
                                if self.EditBox then
                                    self.EditBox:SetText(data.displayName or "")
                                    self.EditBox:HighlightText()
                                end
                            end,
                            OnAccept = function(self, data)
                                local newName = self.EditBox:GetText()
                                if newName and newName ~= "" then
                                    local key = data.listKey
                                    
                                    if AchievementsListsNames then
                                        AchievementsListsNames[key] = newName
                                    end
                                    
                                    if acTable and acTable.DB and acTable.DB.CustomLists and acTable.DB.CustomLists[key] then
                                        acTable.DB.CustomLists[key].name = newName
                                    end
                                    
                                    print(string.format(L["List_Renamed"], newName))
                                    
                                    if acTable.RefreshMainTrackerUI then acTable:RefreshMainTrackerUI() end
                                    if LibStub and LibStub("AceConfigRegistry-3.0", true) then
                                        LibStub("AceConfigRegistry-3.0"):NotifyChange("AchievementsCollector_AddLists")
                                        LibStub("AceConfigRegistry-3.0"):NotifyChange("AchievementsCollector_AddLists")
                                    end
                                end
                            end,
                            EditBoxOnEnterPressed = function(self)
                                -- Simula o clique no botão "Salvar" (button1)
                                local dialog = self:GetParent()
                                StaticPopup_OnClick(dialog, 1)
                            end,
                            EditBoxOnEscapePressed = function(self)
                                -- Fecha o popup ao apertar ESC dentro da caixa de texto
                                local dialog = self:GetParent()
                                dialog:Hide()
                            end,
                            timeout = 0,
                            whileDead = true,
                            hideOnEscape = true,
                            preferredIndex = 3,
                        }
                    end
                    
                    local dialog = StaticPopup_Show("HAT_RENAME_LIST", nil, nil, { listKey = listKey, displayName = displayName })
                    if dialog then
                        dialog:ClearAllPoints()
                        dialog:SetPoint("CENTER", Tracker, "CENTER", 0, 0)
                    end
                end)

                root:CreateButton(L["button_Delete_List"], function()
                    local dialog = StaticPopup_Show("HAT_CONFIRM_DELETE_LIST", displayName, nil, listKey)
                    if dialog then
                        dialog:ClearAllPoints()
                        dialog:SetPoint("CENTER", Tracker, "CENTER", 0, 0)
                    end
                end)
            else
                root:CreateButton("-", function() end)
            end
        end)
    end

    local function ShowAchievementContextMenu(anchor, achievementID, listKey)
        if not achievementID then return end
        local displayName = GetPresetDisplayName(listKey) or tostring(listKey)
        MenuUtil.CreateContextMenu(anchor, function(owner, root)
            root:CreateTitle(L["Achievement_Options"] .. " (" .. tonumber(achievementID) .. ")")
            root:CreateButton(L["Copy_Achievement_ID"], function()
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
            local subMenu = root:CreateButton(L["Add_To_Custom_List"])
            
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
            local removeSubMenu = root:CreateButton(L["Remove_From_Custom_List"])
            local hasAnyPreset = false

            if acTable and acTable.DB and acTable.DB.CustomLists then
                for presetKey, presetData in pairs(acTable.DB.CustomLists) do
                    if presetData.ids and TableContains(presetData.ids, achievementID) then
                        hasAnyPreset = true
                        removeSubMenu:CreateButton((presetData.name or presetKey), function()
                            for i, id in ipairs(presetData.ids) do
                                if id == achievementID then
                                    local dialog = StaticPopup_Show("HAT_CONFIRM_REMOVE_ACH", achievementID, presetData.name, {achievementID, presetKey})
                                    if dialog then
                                        dialog:ClearAllPoints()
                                        dialog:SetPoint("CENTER", Tracker, "CENTER", 0, 0)
                                    end
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

            local isCustom = listKey and acTable and acTable.DB and acTable.DB.CustomLists and acTable.DB.CustomLists[listKey]
            if isCustom then
                root:CreateButton(L["Remove_From_List"], function()
                    local dialog = StaticPopup_Show("HAT_CONFIRM_REMOVE_ACH", achievementID, displayName, {achievementID, listKey})
                    if dialog then
                        dialog:ClearAllPoints()
                        dialog:SetPoint("CENTER", Tracker, "CENTER", 0, 0)
                    end
                end)
            end
        end)
    end

    local originalInitializeTabs = InitializeTabs
    InitializeTabs = function()
        originalInitializeTabs()
        for key, tab in pairs(tabButtons) do
            if tab and not tab._hasContextHook then
                tab:HookScript("OnMouseUp", function(self, button)
                    if button == "RightButton" then
                        ShowTabContextMenu(self, key)
                    end
                end)
                tab._hasContextHook = true
            end
        end
    end

    local originalDisplay = Tracker.DisplayAchievements
    Tracker.DisplayAchievements = function(self, listKey)
        originalDisplay(self, listKey)

        local ids = AchievementsLists[listKey] or {}
        for i, id in ipairs(ids) do
            local row = achievementButtons[i]
            if row then
                row.achievementID = id
                row.assignedlistKey = listKey
            end
        end

        for i, row in ipairs(achievementButtons) do
            if row and row:IsShown() and not row._hasContextHook then
                row:HookScript("OnMouseUp", function(self, button)
                    if button == "RightButton" then
                        local achID = self.achievementID or self.id
                        local preset = self.assignedlistKey or listKey
                        if achID then
                            ShowAchievementContextMenu(self, achID, preset)
                        else
                            print(L["Unknown_Achievement"])
                        end
                    end
                end)
                row._hasContextHook = true
            elseif row and row:IsShown() then
                row.assignedlistKey = listKey
                row.achievementID = row.achievementID or ids[i]
            end
        end
    end
end

-- ============================================================================
-- ATALHO E POP-UP DE CRIAÇÃO RÁPIDA DE LISTAS (Via StaticPopup)
-- ============================================================================

-- 1. Registro do StaticPopup para criação de listas
StaticPopupDialogs["HAT_CREATE_NEW_LIST"] = {
    text = L["Create_New_List_Message"],
    button1 = L["button_Create"],
    button2 = L["button_Cancel"],
    hasEditBox = true,
    maxLetters = 50,
    editBoxWidth = 250,
    OnShow = function(self)
        if self.EditBox then
            self.EditBox:SetText("")
            self.EditBox:HighlightText()
        end
    end,
    OnAccept = function(self)
        local nameInput = self.EditBox:GetText()
        if not nameInput or nameInput == "" then return end
        
        local key = "CUSTOM_" .. string.upper(nameInput):gsub("%s+", "_"):gsub("[^%w_]", "")
        
        if not AchievementsLists[key] then
            AchievementsLists[key] = {}
            AchievementsListsNames[key] = nameInput
                
            acTable.DB = acTable.DB or {}
            acTable.DB.CustomLists = acTable.DB.CustomLists or {}
            acTable.DB.CustomLists[key] = {
                name = nameInput,
                ids = {}
            }
            
            print("|cff00ff00[" .. L["AddonName_Interface"] .. "]|r " .. string.format(L["List_Created_Message"], nameInput))
        end
        
        -- Atualiza a interface e notifica o painel de opções se ativo
        if acTable.RefreshMainTrackerUI then acTable:RefreshMainTrackerUI() end
        if LibStub and LibStub("AceConfigRegistry-3.0", true) then
            LibStub("AceConfigRegistry-3.0"):NotifyChange("AchievementsCollector_AddLists")
        end
        
        -- Seleciona automaticamente a nova lista criada
        if Tracker and Tracker.DisplayAchievements then
            Tracker:DisplayAchievements(key)
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local dialog = self:GetParent()
        StaticPopup_OnClick(dialog, 1)
    end,
    EditBoxOnEscapePressed = function(self)
        local dialog = self:GetParent()
        dialog:Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- 2. Botão Fixado no Rodapé da Caixa de Listas
local QuickAddButton = CreateFrame("Button", nil, CategoryPanel, "UIPanelButtonTemplate")
QuickAddButton:SetSize(214, 24)
QuickAddButton:SetPoint("BOTTOM", CategoryPanel, "BOTTOM", 0, 6)
QuickAddButton:SetText(L["button_New_List"])
QuickAddButton:SetScript("OnClick", function()
    local dialog = StaticPopup_Show("HAT_CREATE_NEW_LIST")
    if dialog then
        dialog:ClearAllPoints()
        dialog:SetPoint("CENTER", Tracker, "CENTER", 0, 0)
    end
end)

-- 2. Botão Fixado no Rodapé da Caixa de Conquistas
local CatalogButton = CreateFrame("Button", nil, Tracker, "UIPanelButtonTemplate")
CatalogButton:SetSize(140, 24)
CatalogButton:SetPoint("BOTTOMRIGHT", Tracker, "BOTTOMRIGHT", -12, 13)
CatalogButton:SetText(L["button_Catalog"])
CatalogButton:SetScript("OnClick", function()
    PlaySound(808)
    CatalogPanel:ToggleCatalog(Tracker)
end)

local QuickAddAchievementButton = CreateFrame("Button", nil, Tracker, "UIPanelButtonTemplate")
QuickAddAchievementButton:SetSize(140, 24)
QuickAddAchievementButton:SetPoint("BOTTOMRIGHT", Tracker, "BOTTOMRIGHT", -158, 13)
QuickAddAchievementButton:SetText(L["button_Add"])
QuickAddAchievementButton:SetScript("OnClick", function()
    PlaySound(808)
    if currentActiveListKey then
        OpenManageSingleListWindow(currentActiveListKey)
    end
end)

local QuickAddAchievementButton = CreateFrame("Button", nil, Tracker, "UIPanelButtonTemplate")
QuickAddAchievementButton:SetSize(140, 24)
QuickAddAchievementButton:SetPoint("BOTTOMRIGHT", Tracker, "BOTTOMRIGHT", -304, 13)
QuickAddAchievementButton:SetText(L["button_Export"])
QuickAddAchievementButton:SetScript("OnClick", function()
    PlaySound(808)
    if currentActiveListKey then
        ACLExportModule:ShowExportWindow(acTable.DB.CustomLists[currentActiveListKey].ids)
    end
end)

-- ============================================================================
-- JANELA DE GERENCIAMENTO DA LISTA SELECIONADA
-- ============================================================================

local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)

-- Função auxiliar local para mover itens em uma tabela (caso MoveTableItem não exista)
local function SafeMoveItem(tbl, currentIndex, targetIndex)
    if not tbl or not tbl[currentIndex] or not tbl[targetIndex] then return end
    local item = table.remove(tbl, currentIndex)
    table.insert(tbl, targetIndex, item)
end

local appName = "AchievementsCollector_ManageSingleList"

function OpenManageSingleListWindow(targetKey)
    
    if not targetKey or not AchievementsListsNames[targetKey] then
        print("|cffff0000[" .. L["AddonName_Interface"] .. "]|r " .. L["No_List_Selected"])
        return
    end

    local function GetOptionsTable()
        local listName = AchievementsListsNames[targetKey] or L["List"]
        
        local options = {
            name = L["Manage_List"] .. " " .. listName,
            type = "group",
            args = {
                manageGroup = {
                    name = "",
                    type = "group",
                    inline = true,
                    args = {
                        [targetKey] = {
                            name = listName,
                            type = "group",
                            args = {
                                addAchInput = {
                                    name = L["Label_Search_Achievement"],
                                    desc = L["Search_Achievement_Tooltip_Description"],
                                    type = "input",
                                    width = "double",
                                    set = function(_, v) 
                                        targetListKey = targetKey
                                        newAchSearchInput = v 
                                        previewAchievementID = tonumber(v)

                                        C_Timer.After(0.01, function ()
                                            AceConfigRegistry:RegisterOptionsTable(appName, GetOptionsTable)
                                            AceConfigDialog:Open(appName)

                                            local configWindow = AceConfigDialog.OpenFrames[appName]
                                            local f = configWindow.frame
                                            f:ClearAllPoints()
                                            f:SetPoint("TOPLEFT", Content, "TOPLEFT", 0, -10) 
                                        end)

                                    end,
                                    get = function(_) 
                                        if targetListKey == targetKey then return newAchSearchInput end
                                        return "" 
                                    end,
                                    order = 1,
                                },
                                previewHeader = {
                                    name = function()
                                        local previewName = L["Search"]
                                        local previewIcon = "Interface\\Icons\\Inv_misc_questionmark"
                                        local previewDesc = "-"

                                        if targetListKey == targetKey and previewAchievementID then
                                            local _, achName, _, _, _, _, _, achDesc, _, achIcon = GetAchievementInfo(previewAchievementID)
                                            if achName and achName ~= "" then
                                                previewName = "|cff00ff00" .. achName .. " (ID: " .. previewAchievementID .. ")|r"
                                                previewIcon = achIcon or "Interface\\Icons\\Inv_misc_questionmark"
                                                previewDesc = achDesc or L["No_Description"]
                                            else
                                                previewName = "|cffff0000" .. L["Achievement_Not_Found"] .. "|r"
                                            end
                                        end

                                        return string.format("\n|cff00ffff%s|r\n\n\n|T%s:36:36:0:9|t  %s\n%s %s\n\n", 
                                            L["Achievement_Preview"],
                                            previewIcon, 
                                            previewName, 
                                            L["Description"],
                                            previewDesc
                                        )
                                    end,
                                    type = "description",
                                    order = 2,
                                },
                                addAchBtn = {
                                    name = L["button_Confirm_Insert"],
                                    type = "execute",
                                    hidden = function()
                                        if targetListKey ~= targetKey or not previewAchievementID then return true end
                                        local _, achName = GetAchievementInfo(previewAchievementID)
                                        return not achName or achName == ""
                                    end,
                                    func = function()
                                        local achievementID = previewAchievementID
                                        AchievementsLists[targetKey] = AchievementsLists[targetKey] or {}
                                        
                                        local exists = false
                                        for _, id in ipairs(AchievementsLists[targetKey]) do
                                            if id == achievementID then exists = true break end
                                        end

                                        if not exists then
                                            table.insert(AchievementsLists[targetKey], achievementID)
                                            
                                            acTable.DB = acTable.DB or {}
                                            acTable.DB.CustomLists = acTable.DB.CustomLists or {}
                                            acTable.DB.CustomLists[targetKey] = acTable.DB.CustomLists[targetKey] or { name = listName, ids = {} }
                                            acTable.DB.CustomLists[targetKey].ids = AchievementsLists[targetKey]

                                            print(string.format(string.format("|cff00ff00[%s]|r %s ", L["AddonName_Interface"], L["Added_Achievement_Message"]), achievementID, listName))
                                        else
                                            print("|cffffcc00[" .. L["AddonName_Interface"] .. "]|r " .. L["Achievement_Already_On_List"])
                                        end

                                        newAchSearchInput = ""
                                        previewAchievementID = nil
                                        targetListKey = nil
                                        
                                        if acTable.RefreshMainTrackerUI then acTable:RefreshMainTrackerUI() end
                                        
                                        C_Timer.After(0.01, function ()
                                            AceConfigRegistry:RegisterOptionsTable(appName, GetOptionsTable)
                                            AceConfigDialog:Open(appName)
                                                    
                                            local configWindow = AceConfigDialog.OpenFrames[appName]
                                            local f = configWindow.frame
                                            f:ClearAllPoints()
                                            f:SetPoint("TOPLEFT", Content, "TOPLEFT", 0, -10) 
                                        end)

                                    end,
                                    order = 3,
                                    width = "normal",
                                },
                                achListHeader = {
                                    name = "\n" .. L["Achievements_Lists_Title"],
                                    type = "description",
                                    order = 4,
                                },
                            }
                        }
                    }
                }
            }
        }

        local achsInList = AchievementsLists[targetKey] or {}
        for index, achID in ipairs(achsInList) do
            local _, achName = GetAchievementInfo(achID)
            achName = achName or (L["Unknown_Achievement"] .. " (ID: " .. achID .. ")")

            options.args.manageGroup.args[targetKey].args["ach_group_" .. index] = {
                name = "• " .. achName .. " (ID: " .. achID .. ")",
                type = "group",
                inline = true,
                order = 5 + index,
                args = {
                    moveUpAch = {
                        name = L["button_Move_Up"],
                        type = "execute",
                        order = 1,
                        disabled = index == 1,
                        func = function()
                            if MoveTableItem then
                                MoveTableItem(AchievementsLists[targetKey], index, index - 1)
                            else
                                SafeMoveItem(AchievementsLists[targetKey], index, index - 1)
                            end

                            if acTable.DB and acTable.DB.CustomLists and acTable.DB.CustomLists[targetKey] then
                                acTable.DB.CustomLists[targetKey].ids = AchievementsLists[targetKey]
                            end
                            if acTable.RefreshMainTrackerUI then acTable:RefreshMainTrackerUI() end
                            
                            C_Timer.After(0.01, function ()
                                AceConfigRegistry:RegisterOptionsTable(appName, GetOptionsTable)
                                AceConfigDialog:Open(appName)

                                local configWindow = AceConfigDialog.OpenFrames[appName]
                                local f = configWindow.frame
                                f:ClearAllPoints()
                                f:SetPoint("TOPLEFT", Content, "TOPLEFT", 0, -10) 
                            end)

                        end,
                    },
                    moveDownAch = {
                        name = L["button_Move_Down"],
                        type = "execute",
                        order = 2,
                        disabled = index == #achsInList,
                        func = function()
                            if MoveTableItem then
                                MoveTableItem(AchievementsLists[targetKey], index, index + 1)
                            else
                                SafeMoveItem(AchievementsLists[targetKey], index, index + 1)
                            end

                            if acTable.DB and acTable.DB.CustomLists and acTable.DB.CustomLists[targetKey] then
                                acTable.DB.CustomLists[targetKey].ids = AchievementsLists[targetKey]
                            end
                            if acTable.RefreshMainTrackerUI then acTable:RefreshMainTrackerUI() end
                            
                            C_Timer.After(0.01, function ()
                                AceConfigRegistry:RegisterOptionsTable(appName, GetOptionsTable)
                                AceConfigDialog:Open(appName)

                                local configWindow = AceConfigDialog.OpenFrames[appName]
                                local f = configWindow.frame
                                f:ClearAllPoints()
                                f:SetPoint("TOPLEFT", Content, "TOPLEFT", 0, -10) 
                            end)
                        end,
                    },
                    removeAch = {
                        name = L["button_Remove_Achievement"],
                        type = "execute",
                        order = 3,
                        confirm = true,
                        confirmText = string.format(L["Confirm_Remove_Achievement"], achName),
                        func = function()
                            table.remove(AchievementsLists[targetKey], index)
                            if acTable.DB and acTable.DB.CustomLists and acTable.DB.CustomLists[targetKey] then
                                acTable.DB.CustomLists[targetKey].ids = AchievementsLists[targetKey]
                            end
                            print("|cffff0000[" .. L["AddonName_Interface"] .. "]|r " .. L["Achievement_Removed_From_List"])
                            if acTable.RefreshMainTrackerUI then acTable:RefreshMainTrackerUI() end
                            
                            C_Timer.After(0.01, function ()
                                AceConfigRegistry:RegisterOptionsTable(appName, GetOptionsTable)
                                AceConfigDialog:Open(appName)

                                local configWindow = AceConfigDialog.OpenFrames[appName]
                                local f = configWindow.frame
                                f:ClearAllPoints()
                                f:SetPoint("TOPLEFT", Content, "TOPLEFT", 0, -10) 
                            end)
                        end,
                    },
                },
            }
        end

        return options
    end

    AceConfigRegistry:RegisterOptionsTable(appName, GetOptionsTable)
    AceConfigDialog:SetDefaultSize(appName, 500, 415)
    if AceConfigDialog.OpenFrames[appName] then       
        AceConfigDialog:Close(appName)
    else
        AceConfigDialog:Open(appName)
    end

        local configWindow = AceConfigDialog.OpenFrames[appName]
    if configWindow and configWindow.frame and Content then
        local f = configWindow.frame

        -- Torna o frame filho da sua janela nativa (assim ele se move junto automaticamente)
        f:SetParent(Content)

        f:SetMovable(false)
        f:EnableMouse(true)

        -- Remove os scripts de arrastar da barra de título/cabeçalho do AceGUI para evitar o erro "Frame is not movable"
        if f.statusbg and f.statusbg.SetScript then
            f.statusbg:SetScript("OnMouseDown", nil)
            f.statusbg:SetScript("OnMouseUp", nil)
        end
        
        if f.statustext and f.statustext.GetParent then
            local titleBg = f.statustext:GetParent()
            if titleBg and titleBg.SetScript then
                titleBg:SetScript("OnMouseDown", nil)
                titleBg:SetScript("OnMouseUp", nil)
            end
        end
        
        -- Procura e limpa o script de OnMouseDown do cabeçalho de arrastar padrão do AceGUI Frame
        for _, child in ipairs({f:GetChildren()}) do
            if child.SetScript then
                child:SetScript("OnMouseDown", nil)
                child:SetScript("OnMouseUp", nil)
            end
        end

        if not f.myCustomBg then
            f.myCustomBg = f:CreateTexture(nil, "BACKGROUND", nil, -8)
            f.myCustomBg:SetAllPoints(f)
            f.myCustomBg:SetColorTexture(0.1, 0.1, 0.1, 1) 
        end

        f:ClearAllPoints()

        f:SetPoint("TOPLEFT", Content, "TOPLEFT", 0, -10) 
        f:SetFrameLevel(Content:GetFrameLevel() + 100)
    end
end

function OnSwitchListButtonClicked(newTargetKey)
    if appName and AceConfigDialog.OpenFrames[appName] then
        OpenManageSingleListWindow(newTargetKey)
    end
end