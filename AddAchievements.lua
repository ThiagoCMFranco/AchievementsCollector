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

acTable.CustomLists = acTable.CustomLists or {}

local newListNameInput = ""
local targetListKey = nil
local newAchSearchInput = ""
local previewAchievementID = nil

-- Tabela para controlar quais listas estão expandidas (true) ou recolhidas (false)
local expandedLists = {}

local AddonName = "AchievementsCollector"
HiddenAchievementsApp = LibStub("AceAddon-3.0"):NewAddon(AddonName, "AceConsole-3.0", "AceEvent-3.0")

-- Função auxiliar para mover itens em tabelas (Reordenação)
local function MoveTableItem(t, oldIndex, newIndex)
    if newIndex < 1 or newIndex > #t then return end
    t[oldIndex], t[newIndex] = t[newIndex], t[oldIndex]
end

-- Função auxiliar para ordenar as chaves das listas usando a ordem personalizada
local function GetSortedListKeys()
    local keys = {}
    for key in pairs(AchievementsListsNames) do
        if string.match(key, "^CUSTOM_") or AchievementsListsNames[key] then
            table.insert(keys, key)
        end
    end
    
    table.sort(keys, function(a, b)
        local posA = AchievementsListsOrder and AchievementsListsOrder[a] or 999
        local posB = AchievementsListsOrder and AchievementsListsOrder[b] or 999
        if posA == posB then
            return a < b
        end
        return posA < posB
    end)
    
    return keys
end

function acTable:GetCustomListsOptions()
    local options = {
        name = L["Manage_Custom_Lists"],
        type = "group",
        args = {
            createGroup = {
                order = 1,
                name = L["Create_New_List"],
                type = "group",
                inline = true,
                args = {
                    nameInput = {
                        name = L["List_Name"],
                        desc = L["List_Name_Description"],
                        type = "input",
                        width = "double",
                        set = function(_, v) newListNameInput = v end,
                        get = function(_) return newListNameInput end,
                        order = 1,
                    },
                    createBtn = {
                        name =L["button_Add_List"],
                        type = "execute",
                        disabled = function() return not newListNameInput or newListNameInput == "" end,
                        func = function()
                            local key = "CUSTOM_" .. string.upper(newListNameInput):gsub("%s+", "_"):gsub("[^%w_]", "")
                            
                            if not AchievementsLists[key] then
                                AchievementsLists[key] = {}
                                AchievementsListsNames[key] = newListNameInput
                                expandedLists[key] = true -- Nova lista nasce expandida por padrão
                                
                                acTable.DB = acTable.DB or {}
                                acTable.DB.CustomLists = acTable.DB.CustomLists or {}
                                acTable.DB.CustomLists[key] = {
                                    name = newListNameInput,
                                    ids = {}
                                }
                                
                                print("|cff00ff00[" .. L["AddonName_Interface"] .. "]|r " .. string.format(L["List_Created_Message"], newListNameInput))
                            end
                            
                            newListNameInput = ""
                            if acTable.RefreshMainTrackerUI then acTable:RefreshMainTrackerUI() end
                            if LibStub and LibStub("AceConfigRegistry-3.0", true) then
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("CustomAchievementTracker_AddLists")
                            end
                        end,
                        order = 2,
                    },
                },
            },
            manageGroup = {
                order = 2,
                name = L["Lists_and_Achievements"],
                type = "group",
                inline = true,
                args = {},
            },
        },
    }

    if AchievementsListsNames then
        local sortedKeys = GetSortedListKeys()
        
        for listOrder, key in ipairs(sortedKeys) do
            local listName = AchievementsListsNames[key]
            
            if string.match(key, "^CUSTOM_") then
                if expandedLists[key] == nil then
                    expandedLists[key] = false
                end

                options.args.manageGroup.args[key] = {
                    name = listName,
                    type = "group",
                    order = listOrder,
                    args = {
                        toggleExpandBtn = {
                            name = expandedLists[key] and L["button_Collapse_List"] or L["button_Expand_List"],
                            type = "execute",
                            func = function()
                                expandedLists[key] = not expandedLists[key]
                                if LibStub and LibStub("AceConfigRegistry-3.0", true) then
                                    LibStub("AceConfigRegistry-3.0"):NotifyChange("CustomAchievementTracker_AddLists")
                                end
                            end,
                            order = 0.5,
                            width = "0.7",
                        },
                        moveListUp = {
                            name = L["button_Move_Up"],
                            type = "execute",
                            order = 0.6,
                            width = "0.6",
                            disabled = listOrder == 1,
                            func = function()
                                MoveTableItem(sortedKeys, listOrder, listOrder - 1)
                                AchievementsListsOrder = AchievementsListsOrder or {}
                                for newIdx, k in ipairs(sortedKeys) do
                                    AchievementsListsOrder[k] = newIdx
                                end
                                if acTable.DB then acTable.DB.PresetOrder = AchievementsListsOrder end
                                if acTable.RefreshMainTrackerUI then acTable:RefreshMainTrackerUI() end
                                if LibStub and LibStub("AceConfigRegistry-3.0", true) then
                                    LibStub("AceConfigRegistry-3.0"):NotifyChange("CustomAchievementTracker_AddLists")
                                end
                            end,
                        },
                        moveListDown = {
                            name = L["button_Move_Down"],
                            type = "execute",
                            order = 0.7,
                            width = "0.6",
                            disabled = listOrder == #sortedKeys,
                            func = function()
                                MoveTableItem(sortedKeys, listOrder, listOrder + 1)
                                AchievementsListsOrder = AchievementsListsOrder or {}
                                for newIdx, k in ipairs(sortedKeys) do
                                    AchievementsListsOrder[k] = newIdx
                                end
                                if acTable.DB then acTable.DB.PresetOrder = AchievementsListsOrder end
                                if acTable.RefreshMainTrackerUI then acTable:RefreshMainTrackerUI() end
                                if LibStub and LibStub("AceConfigRegistry-3.0", true) then
                                    LibStub("AceConfigRegistry-3.0"):NotifyChange("CustomAchievementTracker_AddLists")
                                end
                            end,
                        },
                        deleteListBtn = {
                            name = L["button_Delete_List"],
                            type = "execute",
                            confirm = true,
                            confirmText = L["Delete_List_Confirm"] .. "'" .. listName .. "'?",
                            func = function()
                                AchievementsLists[key] = nil
                                AchievementsListsNames[key] = nil
                                expandedLists[key] = nil
                                if acTable.DB and acTable.DB.CustomLists then
                                    acTable.DB.CustomLists[key] = nil
                                end
                                print("|cff00ff00[" .. L["AddonName_Interface"] .. "]|r " .. string.format(L["List_Removed_Message"], listName))
                                if acTable.RefreshMainTrackerUI then acTable:RefreshMainTrackerUI() end
                                if LibStub and LibStub("AceConfigRegistry-3.0", true) then
                                    LibStub("AceConfigRegistry-3.0"):NotifyChange("CustomAchievementTracker_AddLists")
                                end
                            end,
                            order = 1,
                            width = "0.7",
                        },
                    },
                }

                -- Renderiza os itens internos apenas se a lista estiver EXPANDIDA
                if expandedLists[key] then
                    options.args.manageGroup.args[key].args.spacer = {
                        name = "",
                        type = "description",
                        order = 2,
                    }
                    
                    options.args.manageGroup.args[key].args.addAchInput = {
                        name = L["Label_Search_Achievement"],
                        desc = L["Search_Achievement_Tooltip_Description"],
                        type = "input",
                        width = "double",
                        set = function(_, v) 
                            targetListKey = key
                            newAchSearchInput = v 
                            previewAchievementID = tonumber(v)
                        end,
                        get = function(_) 
                            if targetListKey == key then return newAchSearchInput end
                            return "" 
                        end,
                        order = 3,
                    }

                    local previewName = L["Search"]
                    local previewIcon = "Interface\\Icons\\Inv_misc_questionmark"
                    local previewDesc = "-"
                    local isValidAch = false

                    if targetListKey == key and previewAchievementID then
                        local _, achName, _, _, _, _, _, achDesc, _, achIcon = GetAchievementInfo(previewAchievementID)
                        
                        if achName and achName ~= "" then
                            previewName = "|cff00ff00" .. achName .. " (ID: " .. previewAchievementID .. ")|r"
                            previewIcon = achIcon or "Interface\\Icons\\Inv_misc_questionmark"
                            previewDesc = achDesc or "-"
                            isValidAch = true
                        else
                            previewName = "|cffff0000" .. L["Achievement_Not_Found"] .. "|r"
                        end
                    end

                    options.args.manageGroup.args[key].args.previewHeader = {
                        name = string.format("\n|cff00ffff%s|r\n\n\n|T%s:36:36:0:9|t  %s\n%s %s\n\n", 
                            L["Achievement_Preview"],
                            previewIcon, 
                            previewName, 
                            L["Description"],
                            previewDesc
                        ),
                        type = "description",
                        order = 3.1,
                    }
                    
                    if isValidAch then
                        options.args.manageGroup.args[key].args.addAchBtn = {
                            name = L["button_Confirm_Insert"],
                            type = "execute",
                            func = function()
                                local achievementID = previewAchievementID
                                AchievementsLists[key] = AchievementsLists[key] or {}
                                
                                local exists = false
                                for _, id in ipairs(AchievementsLists[key]) do
                                    if id == achievementID then exists = true break end
                                end

                                if not exists then
                                    table.insert(AchievementsLists[key], achievementID)
                                    
                                    acTable.DB = acTable.DB or {}
                                    acTable.DB.CustomLists = acTable.DB.CustomLists or {}
                                    acTable.DB.CustomLists[key] = acTable.DB.CustomLists[key] or { name = listName, ids = {} }
                                    acTable.DB.CustomLists[key].ids = AchievementsLists[key]
                                    
                                    print(string.format(string.format("|cff00ff00[%s]|r %s ", L["AddonName_Interface"], L["Added_Achievement_Message"]), achievementID, listName))
                                else
                                    print("|cffffcc00[" .. L["AddonName_Interface"] .. "]|r " .. L["Achievement_Already_On_List"])
                                end

                                newAchSearchInput = ""
                                previewAchievementID = nil
                                targetListKey = nil
                                if acTable.RefreshMainTrackerUI then acTable:RefreshMainTrackerUI() end
                                if LibStub and LibStub("AceConfigRegistry-3.0", true) then
                                    LibStub("AceConfigRegistry-3.0"):NotifyChange("CustomAchievementTracker_AddLists")
                                end
                            end,
                            order = 3.2,
                            width = "normal",
                        }
                    end

                    options.args.manageGroup.args[key].args.achListHeader = {
                        name = "\n" .. L["Achievements_Lists_Title"],
                        type = "description",
                        order = 4,
                    }

                    local achsInList = AchievementsLists[key] or {}
                    for index, achID in ipairs(achsInList) do
                        local _, achName = GetAchievementInfo(achID)
                        achName = achName or (L["Unknown_Achievement"] .. " (ID: " .. achID .. ")")

                        options.args.manageGroup.args[key].args["ach_group_" .. index] = {
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
                                        MoveTableItem(AchievementsLists[key], index, index - 1)
                                        if acTable.DB and acTable.DB.CustomLists and acTable.DB.CustomLists[key] then
                                            acTable.DB.CustomLists[key].ids = AchievementsLists[key]
                                        end
                                        if acTable.RefreshMainTrackerUI then acTable:RefreshMainTrackerUI() end
                                        if LibStub and LibStub("AceConfigRegistry-3.0", true) then
                                            LibStub("AceConfigRegistry-3.0"):NotifyChange("CustomAchievementTracker_AddLists")
                                        end
                                    end,
                                },
                                moveDownAch = {
                                    name = L["button_Move_Down"],
                                    type = "execute",
                                    order = 2,
                                    disabled = index == #achsInList,
                                    func = function()
                                        MoveTableItem(AchievementsLists[key], index, index + 1)
                                        if acTable.DB and acTable.DB.CustomLists and acTable.DB.CustomLists[key] then
                                            acTable.DB.CustomLists[key].ids = AchievementsLists[key]
                                        end
                                        if acTable.RefreshMainTrackerUI then acTable:RefreshMainTrackerUI() end
                                        if LibStub and LibStub("AceConfigRegistry-3.0", true) then
                                            LibStub("AceConfigRegistry-3.0"):NotifyChange("CustomAchievementTracker_AddLists")
                                        end
                                    end,
                                },
                                removeAch = {
                                    name = L["button_Remove_Achievement"],
                                    type = "execute",
                                    order = 3,
                                    confirm = true,
                                    confirmText = string.format(L["Confirm_Remove_Achievement"], achName),
                                    func = function()
                                        table.remove(AchievementsLists[key], index)
                                        
                                        if acTable.DB and acTable.DB.CustomLists and acTable.DB.CustomLists[key] then
                                            acTable.DB.CustomLists[key].ids = AchievementsLists[key]
                                        end

                                        print("|cffff0000[" .. L["AddonName_Interface"] .. "]|r " .. L["Achievement_Removed_From_List"])
                                        if acTable.RefreshMainTrackerUI then acTable:RefreshMainTrackerUI() end
                                        if LibStub and LibStub("AceConfigRegistry-3.0", true) then
                                            LibStub("AceConfigRegistry-3.0"):NotifyChange("CustomAchievementTracker_AddLists")
                                        end
                                    end,
                                },
                            },
                        }
                    end
                end
            end
        end
    end

    return options
end

function HiddenAchievementsApp:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("AchievementsCollectorDB", defaults, true)
    
    LibStub("AceConfig-3.0"):RegisterOptionsTable(AddonName, function() return acTable:GetCustomListsOptions() end)
end