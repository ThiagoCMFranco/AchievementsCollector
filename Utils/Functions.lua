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

ACLFunctions = {}

local name, acTable = ...
local L = acTable.L 

local githubLink = "https://github.com/ThiagoCMFranco/AchievementsCollector"

-- Lista de versões que estão em fase de testes
local versoesEmTeste = {
    "1.60.1",
}

function ACLFunctions.VerificarVersaoDoJogo(silent)
    local gameVersion, build, date, tocVersion = GetBuildInfo()
    
    local exibirMensagem = false
    
    for _, versao in ipairs(versoesEmTeste) do
        if gameVersion == versao then
            exibirMensagem = true
            break
        end
    end
    
    if exibirMensagem then
        local mensagem = string.format(
            L["Version_Disclaimer"],
            L["AddonName_Interface"],
            githubLink
        )

        if silent then
            return "\n\n\n\n|cFFFFFF00" .. mensagem .. "|r\n\n"
        else
            print(mensagem)
        end

        return ""
    end

    return ""
end