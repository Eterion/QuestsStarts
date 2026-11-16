return function(ns,check,root)
    local resolve=dofile(root..'/tools/item-sources.lua')
    local db={Item={name=function(id)return 'Item '..id end,
        npcDrops=function(id)if id==1 then return {11} end end,
        objectDrops=function(id)if id==1 then return {22} elseif id==2 then return {23} end end,
        itemDrops=function(id)if id==1 then return {2} elseif id==2 then return {1} end end},
        Npc={name=function()return 'Creature' end,spawns=function(id)
            check(id==11,'object drop IDs are never looked up as NPCs')
            return {[5]={{40,50},{20,30},{1,2,1},{-1,-1},{101,20}},[6]={{10,20}},[7]={{-1,-1}}}
        end},
        Object={name=function(id)return 'Object '..id end,spawns=function(id)
            if id==22 then return {[5]={{60,70}}} end
            return {[5]={{80,90}}}
        end}}
    local locations=resolve(db,1,{[5]=100,[6]=100},{[7]=200})
    check(#locations==4,'resolver handles NPC, object, nested container, and inside sources with a cycle guard')
    local outdoor,inside,container
    for _,loc in ipairs(locations)do
        if loc.sourceID==11 then if loc.mapID then outdoor=loc else inside=loc end end
        if loc.sourceID==23 then container=loc end
    end
    check(outdoor.x==.1 and outdoor.y==.2,'one deterministic recorded point per source/map excludes phased and invalid spawns')
    check(inside.insideDungeon==200 and not inside.mapID and not inside.x,'inside item drops have no invented outdoor waypoint')
    check(container.containedIn=='Item 2' and container.id==1,'nested item source retains the quest-starting item and container')
    check(#resolve(db,99,{}, {})==0,'unrecorded sources receive no fabricated point')
    local count,found,unique=0,nil,{}
    for _,starters in pairs(ns.Data.maps)do for _,s in ipairs(starters)do if s.kind=='Item' then
        count=count+1
        local key=s.mapID..':'..s.id..':'..s.sourceKind..':'..s.sourceID
        check(not unique[key],'only one map point per recorded item/source/map') unique[key]=true
        if s.id==2839 and s.mapID==1420 then found=s end
    end end end
    check(count==761 and found and found.droppedBy and found.quests[1]==361,'export includes A Letter to Yvette and the recorded world item sources')
    local fixture={maps={[1]={{kind='Item',id=2839,quests={1}}}},quests={[1]={}}}
    local state={level=10,holidays={},completed=function()return false end,active=function()return false end}
    check(#ns.BuildGroups(fixture,1,state,false)==1,'eligible item quest offers a drop-source pin')
    state.hasItem=function(id)return id==2839 end
    local groups,stats=ns.BuildGroups(fixture,1,state,true)
    check(#groups==0 and stats.hidden['quest item in bags']==1,'carrying the starter hides all its drop-source pins even with unverified pickups enabled')
    state.hasItem=function()return false end
    state.active=function()return true end
    check(#ns.BuildGroups(fixture,1,state,false)==0,'accepted item quest hides drop-source pins')
    state.active=function()return false end state.completed=function()return true end
    check(#ns.BuildGroups(fixture,1,state,false)==0,'completed item quest hides drop-source pins')
    state.completed=function()return false end
    check(#ns.BuildGroups(fixture,1,state,false,{[1]=true})==0,'native quest offer suppresses the duplicate item pin')
    local old=C_Item
    C_Item={GetItemCount=function(id,bank)check(id==2839 and bank==false,'inventory lookup checks carried items without bank contents')return 1 end}
    local player=ns.GetPlayerState()
    check(player.hasItem(2839) and player.hasItem(2839),'inventory lookup is cached for a refresh')
    C_Item=old
    local filterData={maps={[1]={{kind='Item',id=2839,quests={1}},{kind='Npc',id=1,quests={2}}}},quests={[1]={},[2]={}}}
    for _,choice in ipairs({{true,true,2},{true,false,1},{false,true,1},{false,false,0}}) do
        state.showQuestGivers=choice[1] state.showItemStarts=choice[2]
        local filtered=ns.BuildGroups(filterData,1,state,true)
        check(#filtered==choice[3],'giver/item map filters support all independent combinations')
        for _,group in ipairs(filtered) do
            check(group.starter.kind=='Item' and choice[2] or group.starter.kind=='Npc' and choice[1],'disabled source types cannot enter mixed clusters')
        end
    end
    filterData.maps[1][2].quests={2,3,4}
    filterData.quests[1].specialFlags=1
    filterData.quests[3]={specialFlags=1}
    filterData.quests[4]={specialFlags=1,questFlags=4096}
    state.showQuestGivers,state.showItemStarts,state.showRepeatable=true,true,false
    local filtered,filterStats=ns.BuildGroups(filterData,1,state,true)
    check(#filtered==2 and #filtered[1].quests==1 and #filtered[2].quests==2
        and filtered[2].quests[1].id==2 and filtered[2].quests[2].id==4
        and filterStats.hidden['repeatable quests hidden']==1,
        'repeatable filter removes only the repeatable offer from a mixed giver and retains item markers')
    state.showRepeatable=true
    filtered=ns.BuildGroups(filterData,1,state,true)
    check(#filtered[2].quests==3,'enabling repeatables restores the offer on a mixed giver')
    local oldTexture=C_Texture
    C_Texture={GetAtlasInfo=function()return {} end}
    local function texture()
        return {SetAtlas=function(self,a)self.atlas=a end,SetAlpha=function()end, SetDesaturated=function(self,v)self.desaturated=v end, SetVertexColor=function()end,
            Hide=function(self)self.shown=false end,Show=function(self)self.shown=true end,SetText=function()end}
    end
    local pin=CreateFromMixins(QuestsStartsPickupPinMixin)
    pin.Texture=texture() pin.ItemBadge=texture() pin.Count=texture()
    pin.SetPosition=function()end pin.SetMouseClickEnabled=function()end pin.SetMouseMotionEnabled=function()end
    local item={starter={kind='Item',x=.1,y=.2},quests={{id=1}}}
    local giver={starter={kind='Npc',x=.1,y=.2},quests={{id=1}}}
    pin:OnAcquired({starter=item.starter,groups={item}},1)
    check(pin.Texture.atlas=='VignetteLoot' and not pin.ItemBadge.shown,'item-only cluster uses native loot artwork')
    pin:OnAcquired({starter=giver.starter,groups={giver,item}},1)
    check(pin.Texture.atlas=='QuestNormal' and pin.ItemBadge.shown,'mixed cluster exposes both giver and item types')
    pin:OnAcquired({starter=giver.starter,groups={giver}},1)
    check(pin.Texture.atlas=='QuestNormal' and not pin.ItemBadge.shown,'recycled giver pin clears its previous item badge')
    local mangletooth={starter=giver.starter,quests={{id=5042}}}
    pin:OnAcquired({starter=giver.starter,groups={mangletooth}},1)
    check(pin.Texture.atlas=='QuestNormal' and pin.Texture.desaturated,'Mangletooth repeatable uses tinted quest artwork')
    ns.Data.quests[-1]={questFlags=4096,specialFlags=1}
    pin:OnAcquired({starter=giver.starter,groups={{starter=giver.starter,quests={{id=-1}}}}},1)
    check(pin.Texture.atlas=='QuestDaily' and not pin.Texture.desaturated,'daily flag takes priority and clears repeatable tint')
    ns.Data.quests[-1]=nil
    C_Texture=oldTexture
    local library={maps={[1]={{kind='Object',quests={79097,2}}}},
        quests={[97286]={preQuestSingle={79097}},[79097]={},[2]={}}}
    state.showQuestGivers=false
    state.showItemStarts=true
    local books=ns.BuildGroups(library,1,state,false)
    check(#books==1 and #books[1].quests==1 and books[1].quests[1].collection,
        'library books use the item filter even when sharing a source with a direct quest')
    state.showQuestGivers=true
    state.showItemStarts=false
    local direct=ns.BuildGroups(library,1,state,false)
    check(#direct==1 and #direct[1].quests==1 and direct[1].quests[1].id==2,
        'turning off item sources leaves direct object quests visible')
    local book=ns.Data.quests[79097]
    check(book.libraryBookItem==208800,'library turn-in exports the actual book item')
    library.quests[79097]={libraryBookItem=book.libraryBookItem,questLevel=1}
    state.showItemStarts=true
    state.showQuestGivers=false
    state.showLowLevel=false
    state.level=60
    state.hasItem=function(id,includeBank)return id==208800 and includeBank end
    books=ns.BuildGroups(library,1,state,false,{[79097]=true})
    check(books[1].quests[1].bookLocation=='bank','owned bank book is marked even if the pickup would be filtered')
    state.hasItem=function(id)return id==208800 end
    books=ns.BuildGroups(library,1,state,false)
    check(books[1].quests[1].bookLocation=='bags','carried book takes precedence over bank ownership')
    state.showTurnedInBooks=false
    check(#ns.BuildGroups(library,1,state,false)==1,'unfinished owned books still show when turned-in books are hidden')
    state.completed=function(id)return id==79097 end
    check(#ns.BuildGroups(library,1,state,true)==0,'turned-in books are hidden by default')
    state.showItemStarts=false
    state.showTurnedInBooks=true
    books=ns.BuildGroups(library,1,state,false,{[79097]=true})
    check(#books==1 and books[1].quests[1].turnedIn and not books[1].quests[1].bookLocation,
        'turned-in status overrides ownership and can show independently of item starts')
end
