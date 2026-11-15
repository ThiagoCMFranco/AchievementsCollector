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
    ["MN-Season-2-Delves"] = {62889, 62890, 62891, 62892, 62893, 62894, 62895, 62897, 63436, 63437, 63170, 63171, 63434, 63435, 63326, 63332, 63333, 63433},
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
    ["MN-Housing-Lumberjack"] = {62357, 62358, 62359, 62360, 62361, 62362, 62363, 62364, 62365, 62366, 62369, 62370,},
    ["MN-Professions"] = {62239, 42788, 62223, 62240, 42792, 62232, 62241, 42787, 62233, 62242, 42798, 62234, 62243, 42796, 62235, 62244, 42789, 62236, 62245, 42786, 62237, 62246, 42794, 62238, 62250, 42793, 62247, 62251, 42791, 62248, 62252, 42790, 62249, 42795, 42797, 61439,},
    ["FV-Legacy-Progression"] = {61499, 61500, 61501, 61997, 61998, 61999, 63990, 63991, 63992, 63975, 63976, 63977, 63987, 63988, 63989, 63975, 63976, 63977, 63972, 63973, 63974, 63978, 63979, 63980, 63984, 63985, 63986, 63993, 63994, 63995},
    ["FV-Legacy-Professions"] = {62028,62029,64013,62015,62016,64001,62024,64009,64010,62018,62019,62020,62012,62013,62014,62021,62022,62023},
    ["FV-Legacy-Exploration"] = {62053, 62353, 62355},
    ["FV-Legacy-Exploration-Dungeons"] = {64016, 64017, 64018},
    ["FV-Legacy-Exploration-Kalimdor"] = {845, 750, 848, 850, 849, 62356, 63684, 847, 842, 854, 852, 844, 728, 853, 855, 736, 856, 851, 846, 857},
    ["FV-Legacy-Exploration-Eastern-Kingdoms"] = {760, 765, 775, 627, 771, 772, 779, 62354, 769, 782, 770, 841, 761, 766, 777, 778, 776, 773, 780, 774, 781, 768, 802},
    ["MN-Season-2-Delves-Labyrinths"] = {63724, 63716, 63723, 63721, 63722, 63727, 63728, 63720, 63717, 63718, 63719, 63863, 63864, 63865, 63846, 63847, 63848, 63849, 63850, 63851, 63852, 63853, 63715, 64039, 64118}
    
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
    ["MN-Housing-Lumberjack"] = L_Catalog_Titles["MN-Housing-Lumberjack"],
    ["MN-Professions"] = L_Catalog_Titles["MN-Professions"],
    ["FV-Legacy-Progression"] = L_Catalog_Titles["FV-Legacy-Progression"],
    ["FV-Legacy-Professions"] = L_Catalog_Titles["FV-Legacy-Professions"],
    ["FV-Legacy-Exploration"] = L_Catalog_Titles["FV-Legacy-Exploration"],
    ["FV-Legacy-Exploration-Dungeons"] = L_Catalog_Titles["FV-Legacy-Exploration-Dungeons"],
    ["FV-Legacy-Exploration-Kalimdor"] = L_Catalog_Titles["FV-Legacy-Exploration-Kalimdor"],
    ["FV-Legacy-Exploration-Eastern-Kingdoms"] = L_Catalog_Titles["FV-Legacy-Exploration-Eastern-Kingdoms"],
    ["MN-Season-2-Delves-Labyrinths"] = L_Catalog_Titles["MN-Season-2-Delves-Labyrinths"],
    
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
    ["MN-Housing-Lumberjack"] = L_Catalog_Description["MN-Housing-Lumberjack"],
    ["MN-Professions"] = L_Catalog_Description["MN-Professions"],
    ["FV-Legacy-Progression"] = L_Catalog_Description["FV-Legacy-Progression"],
    ["FV-Legacy-Professions"] = L_Catalog_Description["FV-Legacy-Professions"],
    ["FV-Legacy-Exploration"] = L_Catalog_Description["FV-Legacy-Exploration"],
    ["FV-Legacy-Exploration-Dungeons"] = L_Catalog_Description["FV-Legacy-Exploration-Dungeons"],
    ["FV-Legacy-Exploration-Kalimdor"] = L_Catalog_Description["FV-Legacy-Exploration-Kalimdor"],
    ["FV-Legacy-Exploration-Eastern-Kingdoms"] = L_Catalog_Description["FV-Legacy-Exploration-Eastern-Kingdoms"],
    ["MN-Season-2-Delves-Labyrinths"] = L_Catalog_Description["MN-Season-2-Delves-Labyrinths"],

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
    ["MN-Housing-Lumberjack"] = 62357,
    ["MN-Professions"] = 61439,
    ["FV-Legacy-Progression"] = 0,
    ["FV-Legacy-Professions"] = 63999,
    ["FV-Legacy-Exploration"] = 62053,
    ["FV-Legacy-Exploration-Dungeons"] = 64018,
    ["FV-Legacy-Exploration-Kalimdor"] = 62355,
    ["FV-Legacy-Exploration-Eastern-Kingdoms"] =  62353,
    ["MN-Season-2-Delves-Labyrinths"] = 63716,
    
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
    ["MN-Housing-Lumberjack"] = "Retail",
    ["MN-Professions"] = "Retail",
    ["FV-Legacy-Progression"] = "Forever",
    ["FV-Legacy-Professions"] = "Forever",
    ["FV-Legacy-Exploration"] = "Forever",
    ["FV-Legacy-Exploration-Dungeons"] = "Forever",
    ["FV-Legacy-Exploration-Kalimdor"] = "Forever",
    ["FV-Legacy-Exploration-Eastern-Kingdoms"] = "Forever",
    ["MN-Season-2-Delves-Labyrinths"] = "Retail",
    
}