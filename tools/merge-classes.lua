-- Compile one shared dataset plus only the quest rows changed by each class.
local output,revision,exportRoot=assert(arg[1]),assert(arg[2]),assert(arg[3])
local serialize=dofile(assert(arg[0]:match('^(.*[\\/])'))..'serialize.lua')
local profiles={{1,'WARRIOR'},{2,'PALADIN'},{3,'HUNTER'},{4,'ROGUE'},{5,'PRIEST'},
    {7,'SHAMAN'},{8,'MAGE'},{9,'WARLOCK'},{11,'DRUID'}}
local function read(name)
    local ns={}
    assert(loadfile(exportRoot..'/'..name..'.lua'))('QuestsStarts',ns)
    assert(ns.Data.revision==revision,'Class export revision mismatch')
    return ns.Data
end
local baseline=read('WARRIOR')
local overrides={}
for _,profile in ipairs(profiles) do
    local data=read(profile[2])
    -- Coordinates, pickup associations and other shared fields must still match.
    -- A difference here needs an explicit design, not an arbitrary class choice.
    for key,value in pairs(baseline) do
        if key~='quests' then assert(serialize(value)==serialize(data[key]),'Class-specific '..key..' data is unsupported') end
    end
    for key in pairs(data) do assert(baseline[key]~=nil,'Unexpected class data field: '..key) end
    local delta,count={},0
    for id,row in pairs(baseline.quests) do
        if not data.quests[id] then delta[id]=false count=count+1
        elseif serialize(row)~=serialize(data.quests[id]) then delta[id]=data.quests[id] count=count+1 end
    end
    for id,row in pairs(data.quests) do if not baseline.quests[id] then delta[id]=row count=count+1 end end
    if count>0 then overrides[profile[1]]=delta end
    -- Verify the reconstructed dataset is byte-equivalent to the full export.
    local merged={}
    for id,row in pairs(baseline.quests) do merged[id]=row end
    for id,row in pairs(delta) do merged[id]=row or nil end
    assert(serialize(merged)==serialize(data.quests),'Class reconstruction failed: '..profile[2])
    print(profile[2]..': verified shared data and '..count..' class-specific quest rows')
end
local file=assert(io.open(output,'wb'))
file:write('-- Generated from Questie/QuestieDB@'..revision..'. See THIRD_PARTY_NOTICES.md.\nlocal _, ns = ...\nns.Data = '..serialize(baseline)..'\n')
file:write('-- Apply the current class delta; the other temporary deltas are discarded.\nlocal overrides='..serialize(overrides)..'\n')
file:write("local _,_,classID=UnitClass('player')\nfor id,row in pairs(overrides[classID] or {}) do ns.Data.quests[id]=row or nil end\n")
file:close()
