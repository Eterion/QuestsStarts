return function(ns,check)
    local savedMap=WorldMapFrame
    WorldMapFrame=setmetatable({}, {__newindex=function()error('native map fields must never be overwritten for story rendering')end})
    local shown,info=false,nil
    local frame={page={Show=function(_,value)info=value end},Show=function()shown=true end}
    local selectedMap,entry,foundOn,locked,pending=1,{},1,false,false
    local places={
        L={NOT_DISCOVERED='Locked',MAP_LORE_FOR_FMT='Lore for %s'},
        GetDisplayedMapID=function()return selectedMap end,GetMapName=function(_,id)return 'Map '..id end,
        ViewMap=function(_,id)return id end,PlaceLine=function()return 'Caption'end,
        GetLoreWithFallback=function()return entry,foundOn end,
        IsLocked=function()return locked end,IsPending=function()return pending end,
        LoreText=function(_,id,key)return 'Text '..id..'/'..tostring(key)end,
        ResolveAreaKey=function()return 'area'end,StoryPlace=function()return 2 end,
        ClearSubzone=function(self)self.selected=nil end,
    }
    ns.RefreshFullscreenStory(frame,places)
    check(shown and info.title=='Map 1' and info.text=='Text 1/nil' and info.audio[1]==1,
        'fullscreen lore renders through public APIs without writing native map fields')
    locked=true ns.RefreshFullscreenStory(frame,places)
    check(info.text=='Locked' and not info.audio,'undiscovered story content remains locked')
    locked=false pending=true ns.RefreshFullscreenStory(frame,places)
    check(info.contribute[1]==1 and not info.audio,'pending story pages retain contribution behavior without narration')
    pending=false foundOn=2 ns.RefreshFullscreenStory(frame,places)
    check(info.subtitle=='Lore for Map 2' and info.audio[1]==2,'fallback narration retains the actual lore owner')
    entry=nil ns.RefreshFullscreenStory(frame,places)
    check(info.contribute[1]==1 and not info.lore,'missing lore renders a contribution page')
    entry={} foundOn=1
    places.selected={mapID=1,areaName='Area',entry={name='Area'}}
    ns.RefreshFullscreenStory(frame,places)
    check(info.title=='Area' and info.audio[1]==2 and info.audio[2]=='area','subzone selection retains canonical narration targets')
    info.onSubtitle()
    check(places.selected==nil,'the subzone subtitle returns to the zone story')
    local external={title='External',text='External lore'}
    ns.SetFullscreenExternalStory(1,external)
    ns.RefreshFullscreenStory(frame,places)
    check(info==external,'external map stories remain supported in fullscreen')
    ns.ClearFullscreenExternalStory(2)
    ns.RefreshFullscreenStory(frame,places)
    check(info==external,'clearing a different map does not discard the active external story')
    selectedMap=3 foundOn=3 ns.RefreshFullscreenStory(frame,places)
    check(info~=external and info.title=='Map 3','navigation discards stale external stories')
    ns.ClearFullscreenExternalStory()
    WorldMapFrame=savedMap
end
