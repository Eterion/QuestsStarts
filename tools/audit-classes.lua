-- Run from the pinned QuestieDB checkout, like export.lua.
local root,classFile,classID=assert(arg[1]),assert(arg[2]),assert(tonumber(arg[3]))
local client=dofile('emulator/client.lua')
client.install({expansion='Forever',faction='Horde',raceName='Undead',raceFile='Scourge',raceId=5,classFile=classFile,classId=classID})
local db=dofile('emulator/metadata.lua').loadAddon('QuestieDB.toc','QuestieDB')
local corrections=dofile(root..'/tools/forever-overrides.lua')
local ns={}
assert(loadfile(root..'/addon/QuestsStarts/Data/Tirisfal.lua'))('QuestsStarts',ns)
local sorts=db.Enum.sortKeys
local classSort={}
for _,name in ipairs({'WARRIOR','PALADIN','HUNTER','ROGUE','PRIEST','SHAMAN','MAGE','WARLOCK','DRUID'}) do classSort[sorts[name]]=name end
local total,restricted,gaps=0,0,0
for id,q in pairs(ns.Data.quests) do
    total=total+1
    local source=db.Quest.requiredClasses(id) or 0
    local localFields=corrections[id] and corrections[id].fields
    if localFields and localFields.requiredClasses~=nil then source=localFields.requiredClasses end
    assert((q.requiredClasses or 0)==source,'Class restriction lost in export: '..id)
    if source~=0 then restricted=restricted+1 end
    if classSort[q.zoneOrSort] and source==0 then
        gaps=gaps+1
        if classID==1 then print(string.format('REVIEW %d: %s (%s category; source has no class restriction)',id,q.name,classSort[q.zoneOrSort])) end
    end
end
print(string.format('%s: %d quest rows checked against source; %d explicit class restrictions preserved; %d category/mask review candidates',classFile,total,restricted,gaps))
