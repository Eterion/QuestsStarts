local _,ns=...
-- Localize legacy skill names through the client's own profession spells.
local professionSpells={[164]=2018,[165]=2108,[171]=2259,[182]=2366,[186]=2575,
    [185]=2550,[197]=3908,[202]=4036,[333]=7411,[356]=7620,[393]=8613,[129]=3273}

function ns.ReadRequirementState()
    local skills,reputations,readReputations={}, {}, {}
    local scanned,complete,idsComplete,byName=false,false,false,{}
    local function scanSkills()
        scanned=true
        local modern=C_SkillInfo and C_SkillInfo.GetNumSkillLines and C_SkillInfo.GetSkillLineInfo
        local count=modern and C_SkillInfo.GetNumSkillLines() or (GetNumSkillLines and GetNumSkillLines())
        if type(count)~='number' or count==0 then return end
        complete=true idsComplete=not not modern
        for index=1,count do
            local name,header,collapsed,rank,id
            if modern then
                local line=C_SkillInfo.GetSkillLineInfo(index)
                if line then name,header,collapsed,rank,id=line.name,line.isHeader,line.isCollapsed,line.rank,line.skillID
                else complete=false end
            elseif GetSkillLineInfo then
                local expanded
                name,header,expanded,rank=GetSkillLineInfo(index)
                collapsed=header and not expanded
            else complete=false end
            if header and collapsed then complete=false end
            if not header and type(rank)=='number' then
                if id then skills[id]=rank end
                if not id then idsComplete=false end
                if name then byName[name]=rank end
            elseif not header then complete=false end
        end
    end
    local function skill(id)
        if not scanned then scanSkills() end
        if skills[id]~=nil then return skills[id] end
        local spell=professionSpells[id]
        if not spell then return nil end
        if complete and idsComplete then return 0 end
        -- Herbalism's gathering spell can be named differently from its legacy
        -- skill line. Do not infer an absent profession from that name mismatch.
        if id==182 then return nil end
        local name
        if C_Spell and C_Spell.GetSpellName then name=C_Spell.GetSpellName(spell)
        elseif GetSpellInfo then name=GetSpellInfo(spell) end
        if name and byName[name]~=nil then return byName[name] end
        -- Hidden headers or missing API/name data cannot establish absence.
        if complete and (idsComplete or name) then return 0 end
    end
    local function reputation(id)
        if readReputations[id] then return reputations[id] end
        readReputations[id]=true
        local value
        if C_Reputation and C_Reputation.GetFactionDataByID then
            local faction=C_Reputation.GetFactionDataByID(id)
            value=faction and faction.currentStanding
        elseif GetFactionInfoByID then
            value=select(6,GetFactionInfoByID(id))
        end
        if type(value)=='number' then reputations[id]=value return value end
        -- Undiscovered factions need not start Neutral. Keep missing data unknown.
    end
    return skill,reputation
end
