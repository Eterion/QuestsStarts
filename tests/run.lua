local root = arg[1] or '.'
local ns, checks = {}, 0
local function loadAddon(name) assert(loadfile(root..'/addon/QuestsStarts/'..name))('QuestsStarts', ns) end
local function check(value, message) checks=checks+1 assert(value, message) end
loadAddon('Events.lua')
loadAddon('Eligibility.lua')
loadAddon('Requirements.lua')
loadAddon('DungeonPlanner.lua')
loadAddon('Clusters.lua')
local done, active = {}, {}
local state = {level=10,raceMask=16,classMask=16,completed=function(id)return done[id] or false end,active=function(id)return active[id] or false end}
local function available(q) return ns.IsAvailable(1, {[1]=q}, state) end
check(available({}) == true, 'ordinary quest passes')
check(available({requiredLevel=11}) == false, 'minimum level')
check(available({requiredMaxLevel=9}) == false, 'maximum level')
check(available({requiredRaces=4294967373}) == false, 'Horde race excluded from Forever Alliance mask')
check(available({requiredRaces=8589934770}) == true, 'Horde race in high-bit faction mask')
state.raceMask=8589934592
check(available({requiredRaces=8589934770}) == true, 'Skyborne bit preserved above 32 bits')
check(available({requiredRaces=4294967373}) == false, 'opposite Skyborne bit excluded')
state.raceMask=16
check(available({requiredClasses=8}) == false, 'class gate')
check(available({questLevel=60,requiredLevel=1}) == false, 'high-level recommendation with low minimum stays hidden')
check(available({questLevel=15}) == true, 'nearby higher-level quest allowed')
check(available({questLevel=16}) == false, 'far higher-level quest hidden')
state.showLowLevel=false state.trivialRange=5
check(available({questLevel=4}) == false, 'native low-level filter hides trivial quests')
state.showLowLevel=true
check(available({questLevel=4}) == true, 'native low-level filter reveals trivial quests')
state.showLowLevel=nil
check(available({zoneOrSort=-366,questLevel=60}) == false, 'inactive holiday hidden')
state.holidays={lunar=true}
check(available({zoneOrSort=-366,questLevel=60}) == true, 'active holiday allows its low-minimum scaled quest')
check(available({zoneOrSort=-22}) == false, 'generic seasonal quest is never enabled by unrelated holiday')
check(ns.IsEventAvailable(ns.GetQuestEvent(8828,{}),{holidays={winter=true},monthDay=1224})==false,'Winter presents wait for December 25')
check(ns.IsEventAvailable(ns.GetQuestEvent(8828,{}),{holidays={winter=true},monthDay=1225})==true,'Winter presents open December 25')
check(ns.IsEventAvailable(ns.GetQuestEvent(8828,{}),{holidays={winter=true},monthDay=102})==true,'Winter presents cross year boundary')
check(ns.IsEventAvailable(ns.GetQuestEvent(8828,{}),{holidays={},monthDay=1225})==false,'calendar confirmation required even inside date window')
state.holidays=nil
local calendarOffset
C_DateAndTime={GetCurrentCalendarTime=function()return {year=2026,month=12,monthDay=25,hour=12,minute=0}end}
C_Calendar={
    GetMonthInfo=function()return {year=2026,month=11}end,
    GetNumDayEvents=function(offset,day)calendarOffset=offset return 2 end,
    GetHolidayInfo=function(_,_,index)
        if index==1 then return {name='Feast of Winter Veil',startTime={year=2026,month=12,monthDay=15},endTime={year=2027,month=1,monthDay=2}} end
        return {name="Hallow's End",startTime={year=2026,month=10,monthDay=18},endTime={year=2026,month=11,monthDay=2}}
    end,
}
local holidays,monthDay=ns.ReadHolidays()
check(calendarOffset==1 and monthDay==1225,'calendar lookup respects displayed month without changing it')
check(holidays.winter and not holidays.hallow,'only currently active holiday passes actual server time interval')
C_Calendar=nil C_DateAndTime=nil
done[1]=true check(available({}) == false, 'completed hidden') done[1]=nil
active[1]=true check(available({}) == false, 'accepted hidden') active[1]=nil
check(available({preQuestSingle={2,3}}) == false, 'OR prerequisites not fulfilled')
done[3]=true check(available({preQuestSingle={2,3}}) == true, 'OR prerequisite fulfilled')
check(available({preQuestGroup={2,3}}) == false, 'AND prerequisite incomplete')
done[2]=true check(available({preQuestGroup={2,3}}) == true, 'AND prerequisites fulfilled')
check(available({exclusiveTo={2}}) == false, 'exclusive completed quest')
check(available({parentQuest=4}) == false, 'parent must be active')
active[4]=true check(available({parentQuest=4}) == true, 'active parent')
check(available({disabledByQuest=4}) == false, 'active disabling quest')
check(available({availableStartingWith=4}) == true, 'active enabling quest')
check(available({availableUntilCompleted=3}) == false, 'completed disabling quest')
check(available({requiredSkill={164,50}}) == nil, 'unknown profession never presented as ready')
check(available({specialFlags=2}) == nil, 'event gated never presented as ready')
check(ns.IsAvailable(999, {}, state) == nil, 'missing data never presented as ready')
local data = {maps={[1420]={{name='Giver',quests={1,1,2,3}}}},quests={[1]={},[2]={requiredSkill={164,50}},[3]={requiredLevel=99}}}
done, active = {}, {}
local groups=ns.BuildGroups(data,1420,state,false)
check(#groups==1 and #groups[1].quests==1, 'grouping and duplicate removal')
groups=ns.BuildGroups(data,1420,state,true)
check(#groups[1].quests==2 and groups[1].quests[2].uncertain, 'uncertain opt-in is labelled')
check(#ns.BuildGroups(data,1420,state,false,{[1]=true})==0, 'native offer suppression')
check(#ns.BuildGroups(data,999,state,true)==0, 'unsupported map empty')
data.quests[2]={zoneOrSort=-404}
check(#ns.BuildGroups(data,1420,state,true)[1].quests==1,'uncertainty toggle cannot re-enable inactive holiday')
local nearby={{starter={x=.1,y=.1},quests={{id=1}}},{starter={x=.11,y=.1},quests={{id=2}}},{starter={x=.8,y=.8},quests={{id=3}}}}
local clusters=ns.ClusterGroups(nearby,1000,700,28)
check(#clusters==2 and #clusters[1].groups==2,'overlapping different givers share one pin')
check(#ns.ClusterGroups(nearby,4000,2800,28)==3,'zoom separates nearby givers')
check(#ns.ClusterGroups({},1000,700,28)==0,'empty map clusters safely')

-- Actual generated data, not a fixture of the exporter implementation.
UnitClass=function()return 'Priest','PRIEST',5 end
loadAddon('Data/Tirisfal.lua')
data=ns.Data
check(data.faction=='Horde' and data.maps[1420], 'correct faction and map')
check(data.maps[1411] and #data.maps[1411]==52,'Durotar pickup and recorded item-source data is included')
assert(loadfile(root..'/tests/coverage.lua'))()(ns,check,loadAddon)
assert(loadfile(root..'/tests/world-coverage.lua'))()(ns,check)
assert(loadfile(root..'/tests/source-update.lua'))()(ns,check)
state.level=1
check(ns.IsAvailable(363,data.quests,state)==true, 'Rude Awakening is available to a new Undead priest')
check(ns.IsAvailable(364,data.quests,state)==true, 'optional breadcrumb does not lock The Mindless Ones')
check(ns.IsAvailable(3901,data.quests,state)==false, 'Rattling the Rattlecages waits for its prerequisite')
done[364]=true
check(ns.IsAvailable(3901,data.quests,state)==true, 'Rattling the Rattlecages unlocks after The Mindless Ones')
check(ns.IsAvailable(363,data.quests,state)==false, 'completed follow-up hides its obsolete breadcrumb')
done[364]=nil
check(ns.IsAvailable(4641,data.quests,state)==true,'fresh Undead can pick up Your Place In The World in Durotar')
local durotarGroups,durotarStats=ns.BuildGroups(data,1411,state,false)
check(#durotarGroups>0 and durotarStats.eligible>0,'Durotar has real eligible pickups at level 1')
state.level=20 state.showLowLevel=false
durotarGroups,durotarStats=ns.BuildGroups(data,1411,state,false)
check(#durotarGroups==0 and (durotarStats.hidden['low-level filter'] or 0)>0,'high-level empty Durotar map explains low-level filtering')
state.showLowLevel=true
durotarGroups,durotarStats=ns.BuildGroups(data,1411,state,false)
check(#durotarGroups>0,'native low-level setting reveals unvisited starting-zone quests')
state.level=1 state.showLowLevel=nil
for _, id in ipairs({8652,8828,8861,8902,1657,8322}) do
    check(ns.IsAvailable(id,data.quests,state)==false,'actual inactive seasonal pickup stays hidden: '..id)
end
for _, starter in ipairs(data.maps[1420]) do
    check(starter.x>=0 and starter.x<=1 and starter.y>=0 and starter.y<=1, 'normalized map coordinates')
    for _, id in ipairs(starter.quests) do check(data.quests[id]~=nil,'pickup references a quest') end
end

-- Smoke-load runtime against client API doubles; exercises map lifecycle and native menu hookup.
CreateFromMixins=function(...)
    local out={} for i=1,select('#',...) do for k,v in pairs(select(i,...)) do out[k]=v end end return out
end
MapCanvasPinMixin={OnReleased=function()end}
MapCanvasDataProviderMixin={OnAdded=function(self,map)self.map=map end,GetMap=function(self)return self.map end}
local menuCallback, handler, timers, acquired, menuCount = nil,nil,{},0,0
Menu={ModifyMenu=function(tag,callback)check(tag=='MENU_WORLD_MAP_TRACKING','native map menu tag')menuCallback=callback end}
loadAddon('Locale.lua') loadAddon('Map.lua') loadAddon('Entrances.lua') loadAddon('Input.lua') loadAddon('DungeonUI.lua')
-- Shared-dock lifecycle is exercised with stateful native-template doubles below.
ns.InstallDungeonButton=function()end ns.SyncDock=function()end ns.QueueDock=function()end
ns.CloseDungeons=function()ns.DungeonsOpen=false if ns.DungeonFrame then ns.DungeonFrame:Hide()end end
CreateFrame=function(kind,name)return {SetScript=function(_,script,fn)if kind=='Frame' and name==nil and script=='OnEvent' then handler=fn end end,RegisterEvent=function()end,SetSize=function()end,SetPoint=function()end,SetText=function()end} end
C_Timer={After=function(_,fn)timers[#timers+1]=fn end}
WorldMapFrame={
    AddCanvasClickHandler=function(self,callback,priority)self.addonClickHandler=callback check(priority==100,'map input registered before default canvas navigation')end,
    AddDataProvider=function(self,provider)provider:OnAdded(self)end,
    RemoveAllPinsByTemplate=function()acquired=0 end,
    IsShown=function()return true end,GetMapID=function()return 1420 end,
    EnumeratePinsByTemplate=function()return function()end end,
    AcquirePin=function(_,template,cluster,map)if template==ns.PinTemplate then check(map==1420 and #cluster.groups>0,'cluster pin payload') acquired=acquired+1 end end,
    GetCanvas=function()return {GetWidth=function()return 1000 end,GetHeight=function()return 700 end}end,
    GetCanvasScale=function()return 1 end,GetGlobalPinScale=function()return 1 end,
}
UnitRace=function()return 'Undead','Scourge',5 end
UnitLevel=function()return 1 end
UnitFactionGroup=function()return 'Horde' end
C_QuestLog={IsQuestFlaggedCompleted=function(id)return done[id] or false end,IsOnQuest=function()return false end}
C_Map={}
local cvars={showQuestLevel=false,showQuestDifficultyColor=false,questPOI=true}
GetCVarBool=function(name)return cvars[name]end
C_Minimap={IsTrackingHiddenQuests=function()return false end}
SlashCmdList={}
loadAddon('Core.lua')
handler(nil,'ADDON_LOADED','QuestsStarts')
check(type(menuCallback)=='function','menu modification installed')
local menuButtons=0
local rootMenu={CreateDivider=function()end,CreateCheckbox=function(_,_,getter,setter)check(type(getter())=='boolean','filter state')menuCount=menuCount+1 end,CreateButton=function()menuButtons=menuButtons+1 end}
menuCallback(nil,rootMenu)
check(menuCount==5,'native menu includes an independent collected-books filter')
check(menuButtons==0,'map filter contains no redundant dungeon navigation item')
local pending=timers timers={} for _,fn in ipairs(pending)do fn()end
check(acquired>0,'real generated data produces map pins')
C_QuestLog.GetTitleForQuestID=function()end
GetQuestDifficultyColor=function()return {r=1,g=.5,b=0}end
local text,color=ns.QuestText({id=363})
check(not text:find('[',1,true) and color.r==1 and color.g==1,'native level and color toggles off')
cvars.showQuestLevel=true cvars.showQuestDifficultyColor=true
handler(nil,'CVAR_UPDATE','showQuestLevel')
pending=timers timers={} for _,fn in ipairs(pending)do fn()end
text,color=ns.QuestText({id=363})
check(text:find('[1]',1,true) and color.g==.5,'native level and color toggles update immediately')
cvars.questPOI=false
handler(nil,'CVAR_UPDATE','questPOI')
pending=timers timers={} for _,fn in ipairs(pending)do fn()end
check(acquired>0,'accepted-quest objective filter cannot hide independent pickup pins')
cvars.questPOI=true
SlashCmdList.QUESTSSTARTS('off')
pending=timers timers={} for _,fn in ipairs(pending)do fn()end
check(acquired==0,'turning filter off removes pins')
local printed={}
local oldPrint=print
print=function(message)printed[#printed+1]=message end
SlashCmdList.QUESTSSTARTS('on')
SlashCmdList.QUESTSSTARTS('')
print=oldPrint
check(table.concat(printed,'\n'):find('pass filters',1,true),'slash status explains candidate eligibility')
local mapGetter=WorldMapFrame.GetMapID
WorldMapFrame.GetMapID=function()return 947 end
printed={} print=function(message)printed[#printed+1]=message end
SlashCmdList.QUESTSSTARTS('')
print=oldPrint
check(table.concat(printed,'\n'):find('No pickup data for map 947',1,true),'unsupported map status explains coverage')
WorldMapFrame.GetMapID=function()return 2548 end
printed={} print=function(message)printed[#printed+1]=message end
SlashCmdList.QUESTSSTARTS('')
print=oldPrint
check(table.concat(printed,'\n'):find('No NPC or object pickup locations are recorded',1,true),'empty source map is distinguished from unsupported coverage and player filtering')
WorldMapFrame.GetMapID=mapGetter

-- Tooltip exposes every member and context menu routes each row to its own giver.
ns.Filters={showLevels=true,difficultyColor=false}
local lines,buttons,destination={},{},nil
GameTooltipText={GetFont=function()return 'body.ttf',12,'' end}
local headerFont={GetFont=function()return 'header.ttf',16,'' end}
local tooltipHooks,tooltipFonts={},{}
GameTooltip={
    SetOwner=function(self,owner)self.owner=owner end,
    IsOwned=function(self,owner)return self.owner==owner end,
    HookScript=function(_,event,fn)tooltipHooks[event]=fn end,
    ClearLines=function(self)if tooltipHooks.OnTooltipCleared then tooltipHooks.OnTooltipCleared(self)end lines={}end,
    SetText=function(_,s)lines[#lines+1]=s end,
    AddLine=function(_,s)
        lines[#lines+1]=s
        local index=#lines
        if not tooltipFonts[index] then
            local line={font=index==1 and headerFont or GameTooltipText}
            line.GetFontObject=function(self)return self.font end
            line.SetFontObject=function(self,font)self.font=font local _,size=font:GetFont() self.size=size end
            line.SetFont=function(self,_,size)self.size=size end
            line:SetFontObject(line.font)
            tooltipFonts[index]=line
        end
    end,
    NumLines=function()return #lines end,
    GetLeftLine=function(self,index)check(self~=GameTooltip,'shared Blizzard tooltip fonts are never modified')return tooltipFonts[index]end,
    Show=function(self)self.shown=true end,
    Hide=function(self)self.shown=false if tooltipHooks.OnHide then tooltipHooks.OnHide(self)end end,
}
C_Map={CanSetUserWaypointOnMap=function()return true end,SetUserWaypoint=function(point)destination=point end}
UiMapPoint={CreateFromCoordinates=function(map,x,y)return {map=map,x=x,y=y}end}
local giverMenus={}
MenuUtil={CreateContextMenu=function(_,generator)generator(nil,{
    CreateTitle=function(_,title)check(title==ns.L.starts,'pickup menu retains its navigation heading')end,
    CreateButton=function(_,label,callback)
        check(callback==nil,'giver is a submenu rather than a waypoint action')
        giverMenus[#giverMenus+1]=label
        return {CreateButton=function(_,_,action)buttons[#buttons+1]=action end}
    end,
})end}
local group1={starter={name='First giver',x=.1,y=.1},quests={{id=363}}}
local group2={starter={name='Second giver',x=.11,y=.1},quests={{id=364}}}
local pin=CreateFromMixins(QuestsStartsPickupPinMixin)
pin.cluster={starter=group1.starter,groups={group1,group2}} pin.mapID=1420
local oldTooltipCreate=CreateFrame
CreateFrame=function(kind,name,parent,template)
    check(kind=='GameTooltip' and name=='QuestsStartsPickupTooltip' and template=='GameTooltipTemplate','pickup tooltip uses its own native tooltip frame')
    return CreateFromMixins(GameTooltip)
end
pin:OnMouseEnter()
CreateFrame=oldTooltipCreate
local combined=table.concat(lines,'\n')
check(combined:find('First giver',1,true) and combined:find('Second giver',1,true),'combined hover exposes both overlapping givers')
check(lines[1]==' ' and lines[2]=='First giver' and lines[3]:sub(1,3)=='  [' and lines[4]==' ' and lines[5]=='Second giver','tooltip uses shallow quest indentation and a spacer above each giver')
check(tooltipFonts[1].size==6 and tooltipFonts[4].size==6,'giver spacers are half the normal text height, including the first row')
check(tooltipFonts[2].size==12 and tooltipFonts[5].size==12 and tooltipFonts[3].size==12 and tooltipFonts[6].size==12,'every giver and quest explicitly uses the same body text size')
pin:OnMouseUpAction('LeftButton')
check(ns.PickupTooltip~=GameTooltip and not ns.PickupTooltip.shown and next(tooltipHooks)==nil,'pickup tooltip hides without changing shared tooltip hooks')
check(#buttons==2,'cluster click opens individual quest choices')
check(giverMenus[1]=='First giver' and giverMenus[2]=='Second giver','menu nests quests under the same giver order as the tooltip')
buttons[2]()
check(destination.x==.11 and destination.map==1420,'chosen quest routes to exact second giver')
pin.cluster={starter=group1.starter,groups={group1}}
pin:OnMouseUpAction('LeftButton')
check(destination.x==.1,'single pickup retains direct click waypoint')
local twoQuests={starter=group1.starter,quests={{id=363},{id=364}}}
pin.cluster={starter=group1.starter,groups={twoQuests,group2}}
pin:OnMouseEnter()
check(tooltipFonts[4].size==12 and tooltipFonts[5].size==6 and tooltipFonts[6].size==12,'reused spacer becomes full-size quest text and reused text becomes a half-row spacer')
pin.cluster={starter=group1.starter,groups={group1,group2}}
pin:OnMouseEnter()
check(tooltipFonts[4].size==6 and tooltipFonts[5].size==12 and tooltipFonts[6].size==12,'changing group sizes again restores every reused quest and giver row')
pin:OnMouseLeave()
check(not ns.PickupTooltip.shown,'leaving a pickup hides its dedicated tooltip')
local itemStarter={kind='Item',id=2839,name='A Letter to Yvette',droppedBy='Rattlecage Soldier',x=.4,y=.5}
pin.cluster={starter=itemStarter,groups={{starter=itemStarter,quests={{id=361}}},group2}}
pin:OnMouseEnter()
check(lines[2]=='A Letter to Yvette (drops from Rattlecage Soldier)','item tooltip identifies the item and its drop source')
local before=#giverMenus
pin:OnMouseUpAction('LeftButton')
check(giverMenus[before+1]==lines[2],'item menu and tooltip use the same source heading')
pin:OnMouseLeave()
assert(loadfile(root..'/tests/item-sources.lua'))()(ns,check,root)
assert(loadfile(root..'/tests/requirements.lua'))()(ns,check)
assert(loadfile(root..'/tests/dungeons.lua'))()(ns,check,loadAddon)
assert(loadfile(root..'/tests/dungeon-expansion.lua'))()(ns,check)
assert(loadfile(root..'/tests/forever-dungeons.lua'))()(ns,check)
assert(loadfile(root..'/tests/endgame-dungeons.lua'))()(ns,check)
assert(loadfile(root..'/tests/input.lua'))()(ns,check)
print('Passed '..checks..' checks (offline; in-game appearance is not validated).')
