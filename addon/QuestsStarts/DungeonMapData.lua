local _, ns = ...

local function native(folder, stem)
    return "Interface\\WorldMap\\" .. folder .. "\\" .. stem
end

local function bundled(folder, stem)
    return "Interface\\AddOns\\QuestsStarts\\Maps\\" .. folder .. "\\" .. stem
end

-- Floor UiMapIDs use the original Classic maps in QuestieDB's UiMap-to-area table.
-- Subzone names cover clients that report a shared dungeon map ID for multiple floors.
local function floor(mapID, name, texture, subzones, extension)
    return { mapID=mapID, name=name, texture=texture, subzones=subzones, extension=extension or ".blp" }
end

-- FileDataIDs come from the wowdev community listfile's world/minimaps paths.
local function terrain(name, columns, left, top, width, height, files)
    return { name=name, minimap={
        files=files, columns=columns, tileSize=512,
        left=left, top=top, width=width, height=height,
    } }
end

ns.DungeonMaps = {
    [16919] = { instanceID=3065, parent=1455, floors={
        -- Minimap grid (31,30) to (32,32).
        terrain("The Hall of Thanes", 2, 192, 360, 710, 860, {
            7726086, 7726092,
            7726140, 7726146,
            7726194, 7726200,
        }),
    } },
    [16732] = { instanceID=2998, parent=1437, floors={
        -- Minimap grid (33,36) to (39,41).
        terrain("Excavation Site: Wetlands", 7, 360, 490, 3130, 2530, {
            false, false, false, false, false, 7474475, 7474477,
            7473414, 7473448, 7473454, 7473456, 7473458, 7474479, 7474481,
            7473416, 7287260, 7287262, 7287264, 7473476, 7474483, 7474485,
            7473418, 7287266, 7287268, 7287270, 7473482, 7474511, 7474513,
            7473432, 7287272, 7287274, 7287276, 7473484, 7474515, 7474517,
            7473434, 7473503, 7473509, 7473511, 7473486, 7474519, 7474521,
        }),
    } },
    [16544] = { instanceID=2959, parent=1416, floors={
        -- Minimap grid (30,30) to (32,32).
        terrain("City of Dalaran", 3, 318, 413, 790, 775, {
            6982326, 6982322, 6982391,
            6982332, 6982328, 6982395,
            6982439, 6982441, 6982489,
        }),
    } },
    [2970] = { instanceID=2970, parent=1434, name="The Drowned City", levelLow=35, levelHigh=40, art=7963741, floors={
        -- Minimap grid (25,56) to (28,57).
        terrain("The Drowned City", 4, 188, 48, 1550, 960, {
            7557517, 7557519, 7557521, 7557587,
            7557523, 7557525, 7557527, 7557591,
        }),
    } },
    [3039] = { instanceID=3039, parent=2548, name="Krol'dok Stronghold", levelLow=40, levelHigh=45, art=7963780, floors={
        -- Minimap grid (38,44) to (41,46).
        terrain("Krol'dok Stronghold", 4, 305, 220, 1280, 1210, {
            7540085, 7540087, 7540089, 7540091,
            7540093, 7540095, 7540097, 7540099,
            7540101, 7540103, 7540105, 7540107,
        }),
    } },
    [2994] = { instanceID=2994, parent=1445, name="Alcaz Prison", levelLow=48, levelHigh=53, art=7963734, floors={
        -- Minimap grid (26,48) to (26,48).
        terrain("Alcaz Prison", 1, 165, 165, 244, 233, {
            7250238,
        }),
    } },
    [2974] = { instanceID=2974, parent=1447, name="Blackmaw Hold", levelLow=55, levelHigh=60, art=7963784, floors={
        -- Minimap grid (24,24) to (27,26).
        terrain("Blackmaw Hold", 4, 18, 165, 1840, 1180, {
            7011727, 7011733, 7011739, 7011745,
            7011757, 7011763, 7011769, 7011775,
            7011787, 7011793, 7011799, 7011805,
        }),
    } },
    [3001] = { instanceID=3001, parent=1449, name="The Shaper's Terrace", levelLow=58, levelHigh=60, art=7963783, floors={
        -- Minimap grid (32,41) to (35,44).
        terrain("The Shaper's Terrace", 4, 0, 410, 2015, 1130, {
            7636501, false, false, false,
            7525267, 7352814, 7352816, 7352818,
            7525269, 7352820, 7352822, 7352824,
            false, 7352826, 7352828, 7352830,
        }),
    } },
    [16611] = { instanceID=2999, parent=1458, floors={
        -- Outdoor tiles (31,28) to (32,29), cropped to the ruins.
        terrain("Surface", 2, 8, 158, 580, 670, {
            7255736, 7255742,
            7255754, 7255760,
        }),
    } },
    [2437] = { instanceID=389, parent=1454, floors={
        floor(213, "Ragefire Chasm", bundled("RagefireChasm", "RFC_"), nil, ".tga"),
    } },
    [718] = { instanceID=43, parent=1413, floors={
        floor(279, "Wailing Caverns", native("WailingCaverns", "WailingCaverns1_")),
    } },
    [209] = { instanceID=33, parent=1421, floors={
        floor(310, "The Courtyard", native("ShadowfangKeep", "ShadowfangKeep1_")),
        floor(311, "Dining Hall", native("ShadowfangKeep", "ShadowfangKeep2_")),
        floor(316, "The Wall Walk", native("ShadowfangKeep", "ShadowfangKeep7_")),
        floor(312, "The Vacant Den", native("ShadowfangKeep", "ShadowfangKeep3_")),
        floor(313, "Lower Observatory", native("ShadowfangKeep", "ShadowfangKeep4_")),
        floor(314, "Upper Observatory", native("ShadowfangKeep", "ShadowfangKeep5_")),
        floor(315, "Lord Godfrey's Chamber", native("ShadowfangKeep", "ShadowfangKeep6_")),
    } },
    [719] = { instanceID=48, parent=1440, floors={
        floor(221, "The Pool of Ask'Ar", native("BlackfathomDeeps", "BlackfathomDeeps1_"), {"The Drowned Sacellum"}),
        floor(222, "Moonshrine Sanctum", native("BlackfathomDeeps", "BlackfathomDeeps2_"), {"Moonshrine Ruins", "Aku'mai's Lair"}),
        floor(223, "The Forgotten Pool", native("BlackfathomDeeps", "BlackfathomDeeps3_")),
    } },
    [491] = { instanceID=47, parent=1413, floors={
        floor(301, "Razorfen Kraul", bundled("RazorfenKraul", "RFK_"), nil, ".tga"),
    } },
    [721] = { instanceID=90, parent=1426, floors={
        floor(226, "The Hall of Gears", native("Gnomeregan", "Gnomeregan1_"), {"The Clockwerk Run", "The Clean Zone"}),
        floor(227, "The Dormitory", native("Gnomeregan", "Gnomeregan2_")),
        floor(228, "Launch Bay", native("Gnomeregan", "Gnomeregan3_"), {"Engineering Labs"}),
        floor(229, "Tinkers' Court", native("Gnomeregan", "Gnomeregan4_")),
    } },
    [722] = { instanceID=129, parent=1413, floors={
        floor(300, "Razorfen Downs", native("RazorfenDowns", "RazorfenDowns1_")),
    } },
    [796] = { instanceID=189, parent=1420, floors={
        floor(302, "Graveyard", native("ScarletMonastery", "ScarletMonastery1_"), {"Chamber of Atonement", "Forlorn Cloister", "Honor's Tomb"}),
        floor(303, "Library", native("ScarletMonastery", "ScarletMonastery2_"), {"Huntsman's Cloister", "Gallery of Treasures", "Athenaeum"}),
        floor(304, "Armory", native("ScarletMonastery", "ScarletMonastery3_"), {"Training Grounds", "Footman's Armory", "Crusader's Armory", "Hall of Champions"}),
        floor(305, "Cathedral", native("ScarletMonastery", "ScarletMonastery4_"), {"Chapel Gardens", "Crusader's Chapel"}),
    } },
    [1176] = { instanceID=209, parent=1446, floors={
        floor(219, "Zul'Farrak", native("ZulFarrak", "ZulFarrak")),
    } },
    [1337] = { instanceID=70, parent=1418, floors={
        floor(230, "Hall of the Keepers", native("Uldaman", "Uldaman1_"), {"Dig Two", "Map Chamber", "Echomok Cavern", "Dig Three", "Temple Hall", "The Stone Vault", "Hall of the Crafters"}),
        floor(231, "Khaz'Goroth's Seat", native("Uldaman", "Uldaman2_")),
    } },
    [1477] = { instanceID=109, parent=1435, floors={
        floor(220, "The Temple of Atal'Hakkar", native("TheTempleofAtalhakkar", "TheTempleofAtalHakkar1_")),
    } },
    [1583] = { instanceID=229, parent=1427, floors={
        floor(253, "Hall of Blackhand", native("BlackrockSpire", "BlackrockSpire4_"), {"Dragonspire Hall", "The Rookery"}),
        floor(252, "Hordemar City", native("BlackrockSpire", "BlackrockSpire3_")),
        floor(251, "Skitterweb Tunnels", native("BlackrockSpire", "BlackrockSpire2_")),
        floor(250, "Tazz'Alor", native("BlackrockSpire", "BlackrockSpire1_")),
        floor(254, "Halycon's Lair", native("BlackrockSpire", "BlackrockSpire5_"), {"The Storehouse"}),
        floor(255, "Chamber of Battle", native("BlackrockSpire", "BlackrockSpire6_")),
    } },
    [1584] = { instanceID=230, parent=1427, floors={
        floor(242, "Detention Block", native("BlackrockDepths", "BlackrockDepths1_"), {"Hall of Crafting", "Dark Iron Highway", "Halls of the Law"}),
        floor(243, "Shadowforge City", native("BlackrockDepths", "BlackrockDepths2_"), {"The Domicile", "East Garrison", "Ring of the Law", "The Manufactory", "The Grim Guzzler", "The Lyceum", "Mold Foundry", "Summoners' Tomb", "The Imperial Seat"}),
    } },
    [2017] = { instanceID=329, parent=1423, floors={
        floor(317, "Crusader's Square", native("Stratholme", "Stratholme1_"), {"Festival Lane", "King's Square", "Market Row", "The Hoard", "The Crimson Throne", "The Scarlet Bastion", "The Hall of Lights"}),
        floor(318, "The Gauntlet", native("Stratholme", "Stratholme2_"), {"Elders' Square", "Slaughter Square"}),
    } },
    [2057] = { instanceID=289, parent=1422, floors={
        floor(306, "The Reliquary", bundled("Scholomance", "Scholomance1_"), nil, ".tga"),
        floor(307, "Chamber of Summoning", bundled("Scholomance", "Scholomance2_"), {"The Great Ossuary", "The Viewing Room"}, ".tga"),
        floor(308, "The Upper Study", bundled("Scholomance", "Scholomance3_"), {"Hall of Secrets", "Hall of the Damned", "The Coven"}, ".tga"),
        floor(309, "Headmaster's Study", bundled("Scholomance", "Scholomance4_"), {"The Laboratory", "Vault of the Ravenian", "The Shadow Vault", "Barov Family Vault"}, ".tga"),
    } },
    [2100] = { instanceID=349, parent=1443, floors={
        floor(280, "Caverns of Maraudon", native("Maraudon", "Maraudon1_"), {"Foulspore Cavern", "The Noxious Hollow", "Poison Falls", "Vyletongue Seat", "The Wicked Grotto"}),
        floor(281, "Zaetar's Grave", native("Maraudon", "Maraudon2_"), {"Earth Song Falls"}),
    } },
    [2557] = { instanceID=429, parent=1444, floors={
        floor(235, "Gordok Commons", native("DireMaul", "DireMaul1_"), {"Halls of Destruction", "Gordok's Seat"}),
        floor(236, "Capital Gardens", native("DireMaul", "DireMaul2_")),
        floor(237, "Court of the Highborne", native("DireMaul", "DireMaul3_")),
        floor(238, "Prison of Immol'Thar", native("DireMaul", "DireMaul4_"), {"The Athenaeum"}),
        floor(239, "Warpwood Quarter", native("DireMaul", "DireMaul5_"), {"The Hidden Reach"}),
        floor(240, "The Shrine of Eldretharr", native("DireMaul", "DireMaul6_"), {"The Conservatory"}),
    } },
    [1581] = { instanceID=36, parent=1436, name="The Deadmines", floors={
        floor(291, "The Deadmines", native("TheDeadmines", "TheDeadmines1_"), {"Goblin Foundry"}),
        floor(292, "Ironclad Cove", native("TheDeadmines", "TheDeadmines2_")),
    } },
    [717] = { instanceID=34, parent=1453, name="The Stockade", floors={
        floor(225, "The Stockade", native("TheStockade", "TheStockade1_")),
    } },
}
