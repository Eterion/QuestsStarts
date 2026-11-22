-- Reviewed local corrections; do not edit the pinned QuestieDB checkout.
-- Evidence and limitations: docs/data-corrections.md (rechecked 2026-11-08).
local overrides={
    [78270]={ -- Goblin Lockpicks: sparse Forever trace omitted the original rogue gates.
        -- Pinned Sod/sodBaseQuests.lua and Sod/sodQuestFixes.lua agree on the class;
        -- the latter records this as a subquest of The Horn of Xelthos.
        fields={requiredClasses=8,zoneOrSort=-162,parentQuest=78261},
    },
    [79095]={ -- Both source points describe the same shelf in Brill.
        duplicateObjectSpawns={[405879]={[85]={[59.4]={[52.3]=true}}}},
    },
    [96395]={ -- An Ancient Grudge: missing sort/starter, assumed Alliance-only.
        dungeonID=16919,
        fields={zoneOrSort=16919,requiredRaces=0,requiredLevel=10},
        pickups={{kind='Npc',id=265002,name='Ghostly Attendant',areaID=16919,insideDungeon=16919}},
    },
    [96403]={ -- Important Heirlooms: neutral Gadgetzan giver, both factions.
        fields={requiredRaces=0},allowAllianceStarter=true,
    },
    -- Objectives send the player inside Dalaran, despite an outdoor quest sort.
    [92459]={dungeonID=16544}, -- Friend of the Kirin Tor (Alliance).
    [97287]={dungeonID=16544}, -- Shrewd Negotiations (Horde).
    [95664]={ -- Titan Relic drop: source identifies the boss but has no spawn.
        pickups={{kind='Item',id=270866,name='Titan Relic',insideDungeon=16732,
            sourceKind='Npc',sourceID=260326,droppedBy='Relic Guardian'}},
    },
    [95682]={ -- Recorded outdoor giver; the prerequisite is confirmed by player reports.
        fields={preQuestSingle={95663}},
        pickups={{kind='Npc',id=13155,name='Deathstalker Agent',areaID=11,mapID=1437,x=.514,y=.592}},
    },
    [96987]={ -- Source identifies Rexxie near the sewer, but gives no exact point.
        pickups={{kind='Npc',id=268743,name='Rexxie Copperclutch',zoneMapID=1416,locationHint='near the sewer entrance'}},
    },
    [7508]={ -- Item step after the compendium turn-in, not an outdoor giver.
        pickups={{kind='Item',id=18513,name='A Dull and Flat Elven Blade',fromQuest=7507}},
    },
    [1318]={ -- Legacy alternate: the Classic giver is reported, this Forever variant is unconfirmed.
        fields={sourceUnverified=true},
        pickups={{kind='Npc',id=14325,name='Captain Kromcrush',insideDungeon=2557}},
    },
}
local root=assert(debug.getinfo(1,'S').source:sub(2):match('^(.*[\\/])'))
for _,review in pairs(dofile(root..'class-gate-reviews.lua')) do
    for _,id in ipairs(review.ids) do
        local entry=overrides[id] or {}
        entry.fields=entry.fields or {}
        for field,value in pairs(review.fields) do
            assert(entry.fields[field]==nil or entry.fields[field]==value,'Conflicting class review override: '..id)
            entry.fields[field]=value
        end
        overrides[id]=entry
    end
end
return overrides
