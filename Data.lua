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
local L_Catalog_Titles = acTable.L_Catalog_Titles
local L_Catalog_Description = acTable.L_Catalog_Description

AchievementsListsDictionary = {
    ["MN-Season-2-Myth-Portals"] = {62439, 16640, 62443, 62444, 62441, 62437, 62440, 62438},
    ["MN-Season-2-Delves"] = {62889, 62890, 62891, 62892, 62893, 62894, 62895, 62897, 63436, 63437, 63170, 63171, 63434, 63435, 63326, 63332, 63333},
    ["MN-Season-2-AOTC-CE"] = {63650, 63651},
    ["MN-Season-2-Myth-Plus"] = {62445, 62446, 62447, 62448, 62449},
    ["MN-Season-2-Crests"] = {62410, 62411, 62412, 62414},
    ["MN-Season-2-PvP-General"] = {62926, 62951, 62927, 62952, 62928, 62911, 62929, 62931, 63099},
    ["MN-Season-2-PvP-Arenas"] = {62930, 62922},
    ["MN-Season-2-PvP-Solo-Shuffle"] = {62921, 61199, 62932, 62923},
    ["MN-Season-2-PvP-Battlegrounds-Blitz"] = {61200, 62950, 62924, 62925, 62953, 62954},
    ["MOP-Classic-Pandaria-Explorer"] = {6351, 6969, 6975, 6976, 6977, 6978, 6979, 6974},
    ["MOP-Classic-Pandaria-Lorewalker"] = {6300, 6301, 6535, 6537, 6539, 6540, 6541},
    ["MOP-Classic-Pandaria-Legendary-Cloak"] = {7533, 7534, 8008, 7535, 7536, 8325},
    
}

AchievementsListsDictionaryNames = {
    ["MN-Season-2-Myth-Portals"] = L_Catalog_Titles["MN-Season-2-Myth-Portals"],
    ["MN-Season-2-Delves"] = L_Catalog_Titles["MN-Season-2-Delves"],
    ["MN-Season-2-AOTC-CE"] = L_Catalog_Titles["MN-Season-2-AOTC-CE"],
    ["MN-Season-2-Myth-Plus"] = L_Catalog_Titles["MN-Season-2-Myth-Plus"],
    ["MN-Season-2-Crests"] = L_Catalog_Titles["MN-Season-2-Crests"],
    ["MN-Season-2-PvP-General"] = L_Catalog_Titles["MN-Season-2-PvP"],
    ["MN-Season-2-PvP-Arenas"] = L_Catalog_Titles["MN-Season-2-PvP-Arenas"],
    ["MN-Season-2-PvP-Solo-Shuffle"] = L_Catalog_Titles["MN-Season-2-PvP-Solo-Shuffle"],
    ["MN-Season-2-PvP-Battlegrounds-Blitz"] = L_Catalog_Titles["MN-Season-2-PvP-Battlegrounds-Blitz"],
    ["MOP-Classic-Pandaria-Explorer"] = L_Catalog_Titles["MOP-Classic-Pandaria-Explorer"],
    ["MOP-Classic-Pandaria-Lorewalker"] = L_Catalog_Titles["MOP-Classic-Pandaria-Lorewalker"],
    ["MOP-Classic-Pandaria-Legendary-Cloak"] = L_Catalog_Titles["MOP-Classic-Pandaria-Legendary-Cloak"],
    
}

AchievementsListsDictionaryDetails = {
    ["MN-Season-2-Myth-Portals"] = L_Catalog_Description["MN-Season-2-Myth-Portals"],
    ["MN-Season-2-Delves"] = L_Catalog_Description["MN-Season-2-Delves"],
    ["MN-Season-2-AOTC-CE"] = L_Catalog_Description["MN-Season-2-AOTC-CE"],
    ["MN-Season-2-Myth-Plus"] = L_Catalog_Description["MN-Season-2-Myth-Plus"],
    ["MN-Season-2-Crests"] = L_Catalog_Description["MN-Season-2-Crests"],
    ["MN-Season-2-PvP-General"] = L_Catalog_Description["MN-Season-2-PvP"],
    ["MN-Season-2-PvP-Arenas"] = L_Catalog_Description["MN-Season-2-PvP-Arenas"],
    ["MN-Season-2-PvP-Solo-Shuffle"] = L_Catalog_Description["MN-Season-2-PvP-Solo-Shuffle"],
    ["MN-Season-2-PvP-Battlegrounds-Blitz"] = L_Catalog_Description["MN-Season-2-PvP-Battlegrounds-Blitz"],
    ["MOP-Classic-Pandaria-Explorer"] = L_Catalog_Description["MOP-Classic-Pandaria-Explorer"],
    ["MOP-Classic-Pandaria-Lorewalker"] = L_Catalog_Description["MOP-Classic-Pandaria-Lorewalker"],
    ["MOP-Classic-Pandaria-Legendary-Cloak"] = L_Catalog_Description["MOP-Classic-Pandaria-Legendary-Cloak"],
    
}

AchievementsListsDictionaryCover = {
    ["MN-Season-2-Myth-Portals"] = 62441,
    ["MN-Season-2-Delves"] = 62889,
    ["MN-Season-2-AOTC-CE"] = 63650,
    ["MN-Season-2-Myth-Plus"] = 62449,
    ["MN-Season-2-Crests"] = 62414,
    ["MN-Season-2-PvP-General"] = 62926,
    ["MN-Season-2-PvP-Arenas"] = 62930,
    ["MN-Season-2-PvP-Solo-Shuffle"] = 62930,
    ["MN-Season-2-PvP-Battlegrounds-Blitz"] = 62950,
    ["MOP-Classic-Pandaria-Explorer"] = 6351,
    ["MOP-Classic-Pandaria-Lorewalker"] = 6974,
    ["MOP-Classic-Pandaria-Legendary-Cloak"] = 7533,
    
}

AchievementsListsDictionaryGameVersion = {
    ["MN-Season-2-Myth-Portals"] = "Retail",
    ["MN-Season-2-Delves"] = "Retail",
    ["MN-Season-2-AOTC-CE"] = "Retail",
    ["MN-Season-2-Myth-Plus"] = "Retail",
    ["MN-Season-2-Crests"] = "Retail",
    ["MN-Season-2-PvP-General"] = "Retail",
    ["MN-Season-2-PvP-Arenas"] = "Retail",
    ["MN-Season-2-PvP-Solo-Shuffle"] = "Retail",
    ["MN-Season-2-PvP-Battlegrounds-Blitz"] = "Retail",
    ["MOP-Classic-Pandaria-Explorer"] = "Classic",
    ["MOP-Classic-Pandaria-Lorewalker"] = "Classic",
    ["MOP-Classic-Pandaria-Legendary-Cloak"] = "Classic",
    
}