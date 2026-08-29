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

CatalogPanel = {}

-- =====================================================================
-- Identifica Versão do Jogo
-- =====================================================================
local version, build, date, tocversion = GetBuildInfo()

AchievementsCollector_TOCVersion = 0

if (tocversion >= 00000 and tocversion < 110000) then
	AchievementsCollector_Game_Flavor = "Classic"
	AchievementsCollector_TOCVersion = tocversion
elseif (tocversion >= 110000) then
    AchievementsCollector_Game_Flavor = "Retail"
	AchievementsCollector_TOCVersion = tocversion
else
	AchievementsCollector_Game_Flavor = "Other"
	AchievementsCollector_TOCVersion = tocversion
end

-- =====================================================================
-- COR DE FUNDO
-- =====================================================================
local CARD_BG_R, CARD_BG_G, CARD_BG_B = 0.1, 0.1, 0.1

-- =====================================================================
-- INTERFACE PRINCIPAL
-- =====================================================================
local activeListKey = nil
local selectedDicionaryKey = nil

local CatalogMainFrame = CreateFrame("Frame", "AchievementsCollectorCatalogMainFrame", UIParent, "BasicFrameTemplateWithInset")
CatalogMainFrame:SetSize(660, 480)
CatalogMainFrame:SetPoint("CENTER")
CatalogMainFrame:SetMovable(true)
CatalogMainFrame:EnableMouse(true)
CatalogMainFrame:RegisterForDrag("LeftButton")
CatalogMainFrame:SetScript("OnDragStart", function (self) if (not AchievementsCollectorDB.LockDragDrop) then self:StartMoving() end end)
CatalogMainFrame:SetScript("OnDragStop", function (self) if (not AchievementsCollectorDB.LockDragDrop) then self:StopMovingOrSizing() end end)
CatalogMainFrame:SetScript("OnShow", function () PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN) end)
CatalogMainFrame:SetScript("OnHide", function () PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE) end)
CatalogMainFrame:Hide()
CatalogMainFrame:SetFrameStrata("MEDIUM")
CatalogMainFrame:SetFrameLevel(20)

CatalogMainFrame.title = CatalogMainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
CatalogMainFrame.title:SetPoint("CENTER", CatalogMainFrame.TitleBg, "CENTER", 5, 0)
CatalogMainFrame.title:SetText(L["Catalog_Title"])

_G["ACCatalogFrameName"] = CatalogMainFrame
tinsert(UISpecialFrames, "ACCatalogFrameName")

-- =====================================================================
-- BARRA DE BUSCA SUPERIOR
-- =====================================================================
local searchBox = CreateFrame("EditBox", nil, CatalogMainFrame, "InputBoxTemplate")
searchBox:SetSize(240, 25)
searchBox:SetPoint("TOPLEFT", CatalogMainFrame.InsetBg, "TOPLEFT", 22, -12)
searchBox:SetAutoFocus(false)

local searchPlaceholder = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
searchPlaceholder:SetPoint("LEFT", searchBox, "LEFT", 6, 0)
searchPlaceholder:SetText(L["Filter_Lists"])

searchBox:SetScript("OnEditFocusGained", function() searchPlaceholder:Hide() end)
searchBox:SetScript("OnEditFocusLost", function() 
    if searchBox:GetText() == "" then searchPlaceholder:Show() end 
end)

-- =====================================================================
-- ÁREA DE ROLAGEM E GRID HORIZONTAL
-- =====================================================================
local scrollFrame = CreateFrame("ScrollFrame", nil, CatalogMainFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", CatalogMainFrame.InsetBg, "TOPLEFT", 10, -45)
scrollFrame:SetPoint("BOTTOMRIGHT", CatalogMainFrame.InsetBg, "BOTTOMRIGHT", -30, 10)

local contentContainer = CreateFrame("Frame", nil, scrollFrame)
contentContainer:SetSize(580, 400)
scrollFrame:SetScrollChild(contentContainer)

local cardPool = {}

local function GetAchievementIconSafe(achievementID)
    if not achievementID then return "Interface\\Icons\\Achievement_General" end
    if type(_G.GetAchievementInfo) == "function" then
        local _, _, _, _, _, _, _, _, _, texture = _G.GetAchievementInfo(achievementID)
        if texture then return texture end
    end
    return "Interface\\Icons\\Achievement_General"
end

local function RefreshCardGrid(filterText)
    for _, card in ipairs(cardPool) do
        card:Hide()
    end

    local index = 0
    local numColumns = 2
    local cardWidth, cardHeight = 285, 95
    local startX, startY = 5, -5
    local spacingX, spacingY = 10, 10

    filterText = filterText and filterText:trim():lower() or ""

    for key, idsArray in pairs(AchievementsListsDictionary) do
        local listName = AchievementsListsDictionaryNames[key] or key
        local listDesc = AchievementsListsDictionaryDetails[key] or L["No_Description"]
        local listVersion = AchievementsListsDictionaryGameVersion[key] or "Retail"

        local matchesFilter = (filterText == "") or 
                              (string.find(listName:lower(), filterText, 1, true) ~= nil) or 
                              (string.find(key:lower(), filterText, 1, true) ~= nil)

        if matchesFilter then
            local card = cardPool[index + 1]
            
            if not card then
                card = CreateFrame("Frame", nil, contentContainer, "BackdropTemplate")
                card:SetSize(cardWidth, cardHeight)
                
                card:SetBackdrop({
                    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = true, tileSize = 16, edgeSize = 14,
                    insets = { left = 3, right = 3, top = 3, bottom = 3 }
                })
                card:SetBackdropColor(CARD_BG_R, CARD_BG_G, CARD_BG_B, 1.0)
                
                card:SetScript("OnEnter", function(self)
                    self:SetBackdropBorderColor(1, 0.82, 0, 1)
                end)

                card:SetScript("OnLeave", function(self)
                    self:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
                end)

                -- 1. MÁSCARA DE CORTE
                card.clipFrame = CreateFrame("Frame", nil, card)
                card.clipFrame:SetPoint("TOPLEFT", card, "TOPLEFT", 4, -4)
                card.clipFrame:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -4, 4)
                card.clipFrame:SetClipsChildren(true)

                -- 2. MARCA D'ÁGUA
                card.watermark = card.clipFrame:CreateTexture(nil, "ARTWORK")
                card.watermark:SetSize(120, 120)
                card.watermark:SetPoint("RIGHT", card.clipFrame, "RIGHT", 15, 0)
                card.watermark:SetAlpha(0.70)

                -- 3. DEGRADÊ COM A MESMA TEXTURA E COR EXATA DO FUNDO DO CARTÃO
                card.fadeOverlay = card.clipFrame:CreateTexture(nil, "OVERLAY")
                card.fadeOverlay:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
                card.fadeOverlay:SetPoint("TOPLEFT", card.watermark, "TOPLEFT", 0, 0)
                card.fadeOverlay:SetPoint("BOTTOMRIGHT", card.watermark, "BOTTOMRIGHT", -25, 0)
                card.fadeOverlay:SetGradient("HORIZONTAL", CreateColor(CARD_BG_R, CARD_BG_G, CARD_BG_B, 1), CreateColor(CARD_BG_R, CARD_BG_G, CARD_BG_B, 0))

                -- 4. TEXTOS
                card.nameText = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                card.nameText:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -10)
                card.nameText:SetWidth(170)
                card.nameText:SetJustifyH("LEFT")

                card.descText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                card.descText:SetPoint("TOPLEFT", card.nameText, "BOTTOMLEFT", 0, -4)
                card.descText:SetWidth(170)
                card.descText:SetJustifyH("LEFT")
                card.descText:SetMaxLines(3)

                -- 5. BOTÃO CARREGAR
                card.loadButton = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
                card.loadButton:SetSize(75, 20)
                card.loadButton:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 6)
                card.loadButton:SetText(L["Load"])

                card.loadButton:SetScript("OnEnter", function()
                    card:SetBackdropBorderColor(1, 0.82, 0, 1) -- Mantém a borda dourada
                end)

                card.loadButton:SetScript("OnLeave", function()
                    -- Verifica se o mouse realmente saiu do card inteiro antes de remover o destaque
                    if not card:IsMouseOver() then
                        card:SetBackdropBorderColor(0.6, 0.6, 0.6, 1) -- Retorna à cor padrão da borda
                    end
                end)

                table.insert(cardPool, card)
            end

            card.nameText:SetText(listName)
            card.descText:SetText(listDesc)

            local coverId = AchievementsListsDictionaryCover[key]
            local iconTexture = GetAchievementIconSafe(coverId)
            card.watermark:SetTexture(iconTexture)

            card.loadButton:SetScript("OnClick", function(self)
    selectedDicionaryKey = key

    MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
        rootDescription:CreateTitle(L["Chose_Target_List"])

        local hasEmptyList = false

        if acTable and acTable.DB and acTable.DB.CustomLists then
            for listKey, data in pairs(acTable.DB.CustomLists) do
                -- Filtra apenas as listas cujo IDs estão vazios
                if not data.ids or #data.ids == 0 then
                    hasEmptyList = true
                    local listName = data.name or listKey

                    rootDescription:CreateButton(listName, function()
                        local currentActiveListKey = listKey
                        local currentList = AchievementsListsDictionary[selectedDicionaryKey]

                        if currentList then
                            local exportData = {}
                            for k, v in pairs(currentList) do
                                exportData[k] = v
                            end

                            local importData = ACLExportModule:Export(exportData)
                            TFDEBUG_ACHIEV_IMPORT = importData

                            AchievementsCatalog:LoadFromCatalog(function(novaTabela)
                                TFDEBUG_ACHIEV_NEW_TABLE = novaTabela
                                
                                if acTable.DB.CustomLists[currentActiveListKey] then
                                    TFDEBUG_ACHIEV_TARGET_TABLE = acTable.DB.CustomLists[currentActiveListKey].ids
                                    acTable.DB.CustomLists[currentActiveListKey].ids = novaTabela 
                                end
                                
                                AchievementsLists[currentActiveListKey] = novaTabela
                            end, importData)

                            if Tracker and Tracker:IsShown() then
                                Tracker:DisplayAchievements(currentActiveListKey)
                            end
                            
                            if acTable.RefreshMainTrackerUI then
                                acTable:RefreshMainTrackerUI()
                            end

                            if LibStub and LibStub("AceConfigRegistry-3.0", true) then
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("AchievementsCollector_AddLists")
                            end
                        end
                    end)
                end
            end
        end

        -- Se não houver nenhuma lista vazia disponível, exibe um aviso desativado
        if not hasEmptyList then
            rootDescription:CreateButton(L["No_Empty_List"], function() end):SetEnabled(false)
        end
    end)
end)

if AchievementsCollector_Game_Flavor == listVersion then 
            local col = index % numColumns
            local row = math.floor(index / numColumns)
            local posX = startX + (col * (cardWidth + spacingX))
            local posY = startY - (row * (cardHeight + spacingY))

            card:SetPoint("TOPLEFT", contentContainer, "TOPLEFT", posX, posY)
            card:Show()
            index = index + 1
end
        end
    end
    
    local totalRows = math.ceil(index / numColumns)
    contentContainer:SetHeight((totalRows * (cardHeight + spacingY)) + 10)
end

searchBox:SetScript("OnTextChanged", function(self)
    if self:GetText() == "" then searchPlaceholder:Show() else searchPlaceholder:Hide() end
    local text = self:GetText():trim():lower()
    
    if text == "" then
        searchPlaceholder:Show()
    else
        searchPlaceholder:Hide()
    end
    
    -- Chama a função que redesenha o grid passando o filtro atual
    if type(RefreshCardGrid) == "function" then
        RefreshCardGrid(text)
    end
end)

function CatalogPanel:ToggleCatalog(relativeTo)
    if relativeTo then
        CatalogMainFrame:ClearAllPoints()        
        CatalogMainFrame:SetPoint("CENTER", relativeTo, "CENTER", 0, 0)
    end
    if CatalogMainFrame:IsShown() then CatalogMainFrame:Hide()
    else CatalogMainFrame:Show(); RefreshCardGrid() end
end