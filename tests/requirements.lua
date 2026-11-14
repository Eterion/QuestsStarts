return function(ns,check)
    local saved={C_SkillInfo=C_SkillInfo,C_Reputation=C_Reputation,C_Spell=C_Spell,
        GetNumSkillLines=GetNumSkillLines,GetSkillLineInfo=GetSkillLineInfo,
        GetFactionInfoByID=GetFactionInfoByID,GetSpellInfo=GetSpellInfo}
    local scans,repCalls=0,0
    local lines={{name='Professions',isHeader=true,isCollapsed=false},
        {name='Localized Smithing',skillID=164,rank=75}}
    C_SkillInfo={GetNumSkillLines=function()scans=scans+1 return #lines end,
        GetSkillLineInfo=function(i)return lines[i] end,
        ExpandSkillHeader=function()error('must not change skill header preferences')end}
    C_Reputation={GetFactionDataByID=function(id)
        repCalls=repCalls+1
        if id==1 then return {currentStanding=3000,currentReactionThreshold=3000} end
        if id==2 then return {currentStanding=-500} end
    end}
    C_Spell=nil GetSpellInfo=nil
    local skill,rep=ns.ReadRequirementState()
    check(skill(164)==75 and skill(171)==0 and scans==1,'modern IDs read trained skills and establish missing professions from a complete list once')
    check(rep(1)==3000 and rep(1)==3000 and repCalls==1,'reputation uses absolute standing and caches faction reads')
    check(rep(2)==-500 and rep(3)==nil,'negative standing is retained and missing factions stay unknown')
    local state={level=60,holidays={},skill=skill,reputation=rep,
        completed=function()return false end,active=function()return false end}
    local function available(q)return ns.IsAvailable(1,{[1]=q},state)end
    check(available({requiredSkill={164,75}})==true,'profession skill minimum is inclusive')
    local ok,why=available({requiredSkill={164,76}})
    check(ok==false and why=='profession skill','insufficient trained skill is known unavailable')
    ok,why=available({requiredSkill={171,0}})
    check(ok==false and why=='profession','profession itself is required even at a zero skill threshold')
    check(available({requiredMinRep={1,3000}})==true,'minimum reputation is inclusive')
    check(available({requiredMinRep={1,3001}})==false,'minimum reputation rejects one point below')
    check(available({requiredMaxRep={1,3001}})==true,'maximum reputation permits one point below')
    ok,why=available({requiredMaxRep={1,3000}})
    check(ok==false and why=='maximum reputation','maximum reputation is exclusive at the exact threshold')
    check(available({requiredMinRep={2,-500},requiredMaxRep={2,0}})==true,'negative reputation bounds use raw standing')
    check(available({requiredMinRep={3,3000}})==nil,'unknown faction is not assumed neutral')
    check(available({requiredMinRep={3,3000},requiredSkill={164,100}})==false,'known skill failure wins over another unknown requirement')
    check(available({requiredSkill={99999,1}})==nil,'unsupported skill IDs remain unverified')
    check(available({requiredSkill=true})==nil and available({requiredMaxRep={1}})==nil,'malformed requirement pairs stay unverified without crashing')
    local data={maps={[1]={{quests={1}}}},quests={[1]={requiredSkill={164,76}}}}
    check(#ns.BuildGroups(data,1,state,true)==0,'unverified-pickups filter cannot reveal a known profession failure')
    data.quests[1]={requiredMinRep={3,3000}}
    check(#ns.BuildGroups(data,1,state,false)==0 and ns.BuildGroups(data,1,state,true)[1].quests[1].uncertain,'missing faction data retains opt-in uncertainty')
    lines[1].isCollapsed=true
    skill=ns.ReadRequirementState()
    check(skill(164)==75 and skill(171)==nil,'collapsed headers retain visible learned ranks but cannot establish absent skills')
    C_SkillInfo=nil
    GetNumSkillLines=function()return 2 end
    GetSkillLineInfo=function(i)if i==1 then return 'Professions',true,true end return 'Forge locale',false,nil,125,50,25 end
    C_Spell={GetSpellName=function(id)if id==2018 then return 'Forge locale' elseif id==2259 then return 'Alchemy locale' end end}
    C_Reputation=nil
    GetFactionInfoByID=function(id)if id==1 then return 'Faction','',5,3000,9000,3500 end end
    skill,rep=ns.ReadRequirementState()
    check(skill(164)==125 and skill(171)==0,'legacy skills match localized client spell names and use base rank without temporary bonuses')
    check(skill(182)==nil,'legacy Herb Gathering spell name is not mistaken for an absent Herbalism profession')
    check(rep(1)==3500 and rep(3)==nil,'legacy reputation reads absolute standing from the sixth return')
    GetSkillLineInfo=function()return 'Professions',true,false end
    skill=ns.ReadRequirementState()
    check(skill(164)==nil,'collapsed legacy list remains unknown without expanding the UI')
    GetNumSkillLines=nil GetSkillLineInfo=nil GetFactionInfoByID=nil
    skill,rep=ns.ReadRequirementState()
    check(skill(164)==nil and rep(1)==nil,'unavailable client APIs preserve uncertainty')
    C_SkillInfo=saved.C_SkillInfo C_Reputation=saved.C_Reputation C_Spell=saved.C_Spell
    GetNumSkillLines=saved.GetNumSkillLines GetSkillLineInfo=saved.GetSkillLineInfo
    GetFactionInfoByID=saved.GetFactionInfoByID GetSpellInfo=saved.GetSpellInfo
end
