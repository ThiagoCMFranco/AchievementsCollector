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

AchievementsCatalog = {}

local name, acTable = ...
local L = acTable.L 

local LibSerialize = LibStub:GetLibrary("LibSerialize")
local LibDeflate = LibStub:GetLibrary("LibDeflate")

function AchievementsCatalog:SaveToGlobalProfile(databaseTable, variableToSave)
    if type(databaseTable) ~= "table" then
        print(L["exportFail"])
        return
    end
    
    local serializedData = LibSerialize:Serialize(databaseTable)
    local compressedData = LibDeflate:CompressDeflate(serializedData)
    local exportString = LibDeflate:EncodeForPrint(compressedData)
    
    if variableToSave.GlobalProfile == nil then
        variableToSave.GlobalProfile = {}
    end

    variableToSave.GlobalProfile = exportString

    print(L["AddonName"] .. " - " .. L["GlobalExportSuccess"])
end


function AchievementsCatalog:LoadFromCatalog(databaseCallback, variableToLoad, targetTable)

        local luaTable = nil

        local success, result = pcall(function()
            local compressedData = LibDeflate:DecodeForPrint(variableToLoad)
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
            databaseCallback(luaTable)
        else
            print(L["AddonName"] .. " - " .. L["GlobalImportFail"])
        end
end