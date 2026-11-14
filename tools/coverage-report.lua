-- Source coverage is not a claim of complete live quest availability.
local input,output=assert(arg[1]),assert(arg[2])
local ns={}
UnitClass=function()return 'Warrior','WARRIOR',1 end
assert(loadfile(input))('QuestsStarts',ns)
local maps,locations,nonempty,quests,itemLocations={},0,0,0,0
for id,name in pairs(ns.Data.mapNames)do
    local count=#ns.Data.maps[id]
    maps[#maps+1]={id=id,name=name,count=count}
    locations=locations+count
    for _,starter in ipairs(ns.Data.maps[id]) do if starter.kind=='Item' then itemLocations=itemLocations+1 end end
    if count>0 then nonempty=nonempty+1 end
end
for _ in pairs(ns.Data.quests)do quests=quests+1 end
table.sort(maps,function(a,b)return a.name<b.name end)
local file=assert(io.open(output,'wb'))
file:write('# Quest-start map coverage\n\nGenerated from QuestieDB `'..ns.Data.revision..'` with the documented local corrections.\n\n')
file:write(string.format('%d configured world-zone/city maps, %d with candidate pickup locations, %d locations total (%d NPC/object givers and %d item sources), and %d quest records including dependencies.\n\n',#maps,nonempty,locations,locations-itemLocations,itemLocations,quests))
file:write('Counts precede player eligibility filters and do not establish live completeness. Alliance-only quests remain excluded for Horde at runtime. Empty maps have no valid pickup coordinates in this export; they must not be mistaken for completed or level-filtered quests. Item sources use one recorded spawn per creature/object per map, not a drop-area center or guaranteed drop. Vendors, unrecorded sources, and phased or invalid coordinates remain outside this coverage.\n\n')
file:write('| Map | Map ID | Source pickup locations |\n| --- | --- | ---: |\n')
for _,map in ipairs(maps)do
    file:write('| '..map.name..' | '..map.id..' | '..(map.count>0 and tostring(map.count) or '0 (source gap)')..' |\n')
end
file:close()
print(string.format('Coverage report: %d populated maps, %d source gaps, %d pickup locations.',nonempty,#maps-nonempty,locations))
