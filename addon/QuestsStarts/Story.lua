local _,ns=...
local externalStory

function ns.SetFullscreenExternalStory(mapID,entry)
    externalStory=entry and {mapID=mapID,entry=entry} or nil
end

function ns.ClearFullscreenExternalStory(mapID)
    if not mapID or externalStory and externalStory.mapID==mapID then externalStory=nil end
end

-- Render through Spoken's public page/data API. Never spoof WorldMapFrame's
-- methods or state to bypass Spoken's windowed-only panel availability check.
function ns.RefreshFullscreenStory(frame,places)
    if not (frame.page and places.GetDisplayedMapID and places.GetLoreWithFallback) then return end
    local function render()
        local mapID=places:GetDisplayedMapID()
        if not mapID then return end
        local function show(info)frame.page:Show(info) frame:Show()end
        local selected=places.selected
        if externalStory and (externalStory.mapID~=mapID or selected) then externalStory=nil end
        if externalStory then show(externalStory.entry) return end
        if selected and selected.mapID~=mapID then
            if places.OpenMap and places:OpenMap() then mapID=selected.mapID
            else places.selected=nil selected=nil end
        end
        if not selected and places.ViewMap then mapID=places:ViewMap(mapID) end
        if selected and selected.map then selected=nil end
        local locale=places.L or {}
        local locked=locale.NOT_DISCOVERED or 'This place has not been discovered yet.'
        if selected then
            local name=selected.areaName or selected.entry.name or ''
            local key=places:ResolveAreaKey(selected.areaName,mapID)
            local story=places:StoryPlace(mapID,key)
            local info={title=name,subtitle=places:PlaceLine(story,key or name)}
            local zone=mapID
            info.onSubtitle=function()
                if places.OpenMap and places:OpenMap() then places:SelectMap(zone) else places:ClearSubzone() end
            end
            if places.IsLocked and places:IsLocked(story,key) then info.text=locked
            elseif places:IsPending(selected.entry) then info.contribute={story,name} info.lore={story,key}
            else
                info.text=places:LoreText(story,key,selected.entry)
                info.audio={story,key} info.report={story,key} info.lore={story,key}
            end
            show(info) return
        end
        local name=places:GetMapName(mapID) or ('uiMapID '..tostring(mapID))
        local entry,foundOn=places:GetLoreWithFallback(mapID)
        if not entry then show({title=name,contribute={mapID}}) return end
        local caption
        if foundOn~=mapID then
            caption=string.format(locale.MAP_LORE_FOR_FMT or 'Lore for %s',places:GetMapName(foundOn) or 'parent zone')
        else caption=places:PlaceLine(mapID) end
        local info={title=name,subtitle=caption}
        if places.IsLocked and places:IsLocked(foundOn) then info.text=locked
        elseif places:IsPending(entry) then info.contribute={foundOn} info.lore={foundOn}
        else
            info.text=places:LoreText(foundOn,nil,entry)
            info.audio={foundOn} info.report={foundOn} info.lore={foundOn}
        end
        show(info)
    end
    local ok,err=pcall(render)
    if not ok then geterrorhandler()(err) end
end
