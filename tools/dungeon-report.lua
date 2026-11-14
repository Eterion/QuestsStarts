-- Audit source records, including transitive dungeon prerequisites.
local ns={}
UnitClass=function()return 'Warrior','WARRIOR',1 end
assert(loadfile(assert(arg[1])))('QuestsStarts',ns)
local rows,total={},0
for id,dungeon in pairs(ns.Data.dungeons)do
    rows[#rows+1]={id=id,name=dungeon.name,count=#dungeon.quests}
    total=total+#dungeon.quests
end
table.sort(rows,function(a,b)return a.name<b.name end)
local file=assert(io.open(assert(arg[2]),'wb'))
file:write('# Dungeon source coverage\n\nGenerated from QuestieDB `'..ns.Data.revision..'` with reviewed local corrections. Counts include faction/class variants and repeatable steps before character filtering; they do not establish complete live Forever coverage.\n\n')
file:write('| Dungeon | Area ID | Source quest records |\n| --- | ---: | ---: |\n')
for _,row in ipairs(rows)do file:write('| '..row.name..' | '..row.id..' | '..row.count..' |\n')end
file:write('\n'..#rows..' dungeon groups, '..total..' membership records. Blackrock Spire and Dire Maul combine their wings.\n\n## Pickup gaps and qualifications\n\n')
local missing={}
local function horde(q)
    if not q or not q.requiredRaces then return true end
    for _,bit in ipairs({2,16,32,128,8589934592})do
        if math.floor(q.requiredRaces/bit)%2==1 then return true end
    end
    return q.requiredRaces==0
end
for id,locations in pairs(ns.Data.pickups)do
    if horde(ns.Data.quests[id]) and (not ns.Data.quests[id] or #locations==0) then missing[#missing+1]=id end
end
table.sort(missing)
file:write('This pickup audit covers Horde-compatible records and their dependencies; Alliance-only rows intentionally have no pickups in this Horde export.\n\n')
for _,id in ipairs(missing)do
    local q=ns.Data.quests[id]
    file:write('- '..id..': '..(q and q.name or 'quest record missing')..'; no supported pickup source.\n')
end
file:write('\nThe missing 2955 record is referenced by the upstream prerequisite alternatives for Gnomeregan quest 4604. It remains an unknown step; no replacement quest or position is inferred.\n\nRexxie Copperclutch (96987) has an Alterac Mountains sewer-entrance description, without exact coordinates or navigation. Legacy Dire Maul variant 1318 has a historically reported inside giver but remains explicitly unverified for Forever. Item steps and inside pickups are labeled by their actual source rather than assigned entrance waypoints. See [reviewed corrections](data-corrections.md).\n\nRiverglades, Mount Hyjal, and Deadwind Pass still lack reliable world-map pickup coordinates; see [the source audit](coverage-gaps.md). This build uses source-only data and adds no passive location capture. Other new Forever dungeons without sufficient source metadata remain unsupported.\n')
file:close()
print('Dungeon report: '..#rows..' groups; '..#missing..' missing quest/pickup records including dependencies.')
