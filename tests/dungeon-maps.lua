return function(ns, check, loadAddon, root)
    local previousMap, previousCreate = WorldMapFrame, CreateFrame
    local previousHook, previousInstance, previousAddButton = hooksecurefunc, GetInstanceInfo, NavBar_AddButton
    local previousBestMap, previousSubzone = C_Map.GetBestMapForUnit, GetMinimapZoneText
    local queueRefresh = ns.QueueRefresh
    local previousOpen = ns.OpenDungeons
    local openedDungeon
    ns.OpenDungeons = function(id)
        openedDungeon = id
        ns.ShowDungeonMap(id)
    end
    local frames, scripts = {}, {}
    local instanceType, instanceID, mapID = 'none', 0, 1413
    local playerMapID, subzone
    local zoomResets, refreshed = 0, 0
    local function region()
        local object = {}
        function object:SetAllPoints(relative) self.relative = relative end
        function object:SetFrameLevel(level) self.level = level end
        function object:SetAlpha(alpha) self.alpha = alpha end
        function object:GetAlpha() return self.alpha end
        function object:SetShown(shown) self.shown = shown end
        function object:SetPoint(...) self.point = {...} end
        function object:SetSize(w,h) self.width,self.height = w,h end
        function object:SetTexture(file) self.file = file end
        function object:SetTexCoord(...) self.crop = {...} end
        function object:SetColorTexture() end
        return object
    end
    CreateFrame = function(kind, _, parent)
        local frame = region()
        frame.kind, frame.parent, frame.scripts, frame.textures = kind, parent, {}, {}
        function frame:IsShown() return self.shown == true end
        function frame:Show() self.shown = true if self.scripts.OnShow then self.scripts.OnShow(self) end end
        function frame:Hide() self.shown = false if self.scripts.OnHide then self.scripts.OnHide(self) end end
        function frame:RegisterForClicks(click) self.click = click end
        function frame:SetIgnoreParentAlpha(ignore) self.ignoreParentAlpha = ignore end
        function frame:EnableMouseWheel(enabled) self.wheel = enabled end
        function frame:RegisterEvent() end
        function frame:SetScript(event, listener) self.scripts[event] = listener end
        function frame:GetSize() return 1003, 668 end
        function frame:CreateTexture()
            local texture = region()
            self.textures[#self.textures+1] = texture
            return texture
        end
        frames[#frames+1] = frame
        return frame
    end
    hooksecurefunc = function(target, method, callback)
        local original = target[method]
        target[method] = function(...)
            original(...)
            callback(...)
        end
    end
    GetInstanceInfo = function() return 'Ragefire Chasm', instanceType, nil, nil, nil, nil, nil, instanceID end
    C_Map.GetBestMapForUnit = function() return playerMapID end
    GetMinimapZoneText = function() return subzone end
    NavBar_AddButton = function(nav, leaf)
        nav.trail[#nav.trail+1] = leaf.name
        nav.leaf = leaf
    end
    local input = {}
    local scrollAlpha = 1
    local scroll = {
        GetFrameLevel = function() return 4 end,
        GetEffectiveAlpha = function() return scrollAlpha end,
        OnMouseWheel = function(_, delta) input.wheel=delta end,
        OnMouseDown = function(_, button) input.down=button end,
        OnMouseUp = function(_, button) input.up=button end,
    }
    local canvas = region()
    canvas:SetAlpha(0.85)
    local toggle = region()
    toggle:SetFrameLevel(10)
    function toggle:GetFrameLevel() return self.level end
    WorldMapFrame = {
        SidePanelToggle = toggle,
        NavBar = {Refresh = function(self) self.trail = {'World','Kalimdor','Orgrimmar'} end},
        ScrollContainer = scroll,
        GetCanvas = function() return canvas end,
        GetMapID = function() return mapID end,
        SetMapID = function(_, id) mapID=id end,
        HookScript = function(_, event, listener) scripts[event]=listener end,
        IsShown = function() return false end,
        ResetZoom = function() zoomResets=zoomResets+1 end,
    }
    ns.QueueRefresh = function() refreshed=refreshed+1 end
    loadAddon('DungeonMapData.lua')
    loadAddon('DungeonMaps.lua')
    ns.InstallDungeonMaps()
    scripts.OnShow()
    check(not ns.IsDungeonMapShown() and mapID==1413, 'opening outside RFC leaves the world map alone')
    instanceType,instanceID='party',389
    scripts.OnShow()
    check(ns.IsDungeonMapShown() and mapID==1454 and openedDungeon==2437, 'RFC opens with its dungeon quests')
    check(table.concat(WorldMapFrame.NavBar.trail,' / ')=='World / Kalimdor / Orgrimmar / Ragefire Chasm',
        'RFC appends its name to the native city breadcrumb')
    local panel,art=frames[2],frames[3]
    check(toggle:GetFrameLevel()>panel.level,'the native quest-panel toggle is above RFC mouse input')
    check(panel.relative==scroll and art.relative==canvas and panel.wheel and panel.click=='RightButtonUp',
        'RFC uses the native viewport for input and the scroll canvas for art')
    check(canvas:GetAlpha()==0 and art.parent==canvas and art.ignoreParentAlpha and art:IsShown(),
        'dungeon art uses native scroll clipping without inheriting the hidden outdoor alpha')
    scrollAlpha=0.5
    panel.scripts.OnUpdate(panel,0.1)
    check(art:GetAlpha()==0.5,'dungeon art follows native movement fade')
    check(#art.textures==13 and art.textures[13].width==235 and art.textures[13].height==156,
        'RFC crops the right and bottom tiles to the full canvas without extra markers')
    for i=1,12 do
        local tile=assert(io.open(root..'/addon/QuestsStarts/Maps/RagefireChasm/RFC_'..i..'.tga','rb'))
        check(#tile:read(18)==18 and art.textures[i+1].file:find('QuestsStarts',1,true),
            'RFC tile is present and resolves from the addon folder')
        tile:close()
    end
    panel.scripts.OnMouseWheel(panel,1)
    panel.scripts.OnMouseDown(panel,'LeftButton')
    panel.scripts.OnMouseUp(panel,'LeftButton')
    check(input.wheel==1 and input.down=='LeftButton' and input.up=='LeftButton',
        'RFC forwards wheel and drag input to the native controller')
    local previousResets = zoomResets
    panel.scripts.OnClick()
    check(toggle:GetFrameLevel()==10,'leaving RFC restores the native quest-panel toggle level')
    check(not ns.IsDungeonMapShown() and canvas:GetAlpha()==0.85 and mapID==1454 and zoomResets==previousResets+1
        and #WorldMapFrame.NavBar.trail==3,'right-click restores Orgrimmar, its breadcrumb, and default zoom')
    scripts.OnHide()
    scripts.OnShow()
    check(ns.IsDungeonMapShown(),'reopening the map inside RFC shows dungeon art again')
    WorldMapFrame:SetMapID(1454)
    check(not ns.IsDungeonMapShown(),'clicking the current native Orgrimmar breadcrumb dismisses the dungeon')
    scripts.OnShow()
    WorldMapFrame:SetMapID(1414)
    check(not ns.IsDungeonMapShown() and mapID==1414,'native parent navigation remains intact')
    instanceType,instanceID,playerMapID='party',289,307
    scripts.OnShow()
    local function usesScholoFloor(index)
        return art.textures[2].file:find('Scholomance'..index..'_1.tga',1,true) ~= nil
    end
    check(mapID==1422 and openedDungeon==2057 and usesScholoFloor(2),'Scholomance opens on the player floor')
    local floors=WorldMapFrame.NavBar.leaf.listFunc()
    check(#floors==4 and floors[3].text=='The Upper Study','dungeon breadcrumb lists its floors')
    floors[1].func(nil,floors[1].id)
    panel.scripts.OnUpdate(panel,0.5)
    check(usesScholoFloor(1),'manual floor remains visible while the player stays on the same floor')
    playerMapID=309
    panel.scripts.OnUpdate(panel,0.5)
    check(usesScholoFloor(4),'physical floor change supersedes manual browsing')
    playerMapID,subzone=nil,'The Great Ossuary'
    frames[1].scripts.OnEvent()
    check(usesScholoFloor(2),'known subzone identifies the floor when no player map ID is available')
    subzone='Unknown subzone'
    frames[1].scripts.OnEvent()
    check(usesScholoFloor(2),'unknown location preserves the last floor')
    panel.scripts.OnClick()
    check(mapID==1422 and not ns.IsDungeonMapShown(),'right click returns to the selected dungeon’s outdoor parent')
    scripts.OnShow()
    instanceType,instanceID='none',0
    frames[1].scripts.OnEvent()
    check(not ns.IsDungeonMapShown() and refreshed>0,'leaving a dungeon dismisses the overlay and refreshes ordinary pins')
    ns.ShowDungeonMap(2437)
    frames[1].scripts.OnEvent()
    check(ns.IsDungeonMapShown(),'RFC can be previewed outside the instance')
    ns.ShowDungeonMap(16611)
    check(ns.GetDisplayedDungeonMapID()==16611 and mapID==1458
        and art.textures[2].file:find('RuinsOfLordaeron',1,true) and art.textures[13].shown,
        'Lordaeron loads the illustrated surface at native Classic dimensions')
    for i=1,12 do
        local asset=assert(io.open(root..'/addon/QuestsStarts/Maps/RuinsOfLordaeron/Surface_'..i..'.tga','rb'))
        local header=asset:read(18)
        asset:close()
        check(header:byte(3)==2 and header:byte(13)==0 and header:byte(14)==1
            and header:byte(15)==0 and header:byte(16)==1,
            'illustrated tile uses a 256x256 uncompressed TGA')
    end
    check(#frames==3,'Lordaeron symbols are baked into the tiles rather than allocated as frames')
    ns.ShowDungeonMap(2437)
    check(art.textures[13].shown and art.textures[13].width==235,
        'returning to a Classic dungeon restores its art')
    instanceType,instanceID='party',2999
    WorldMapFrame:SetMapID(1458)
    scripts.OnShow()
    check(openedDungeon==16611 and ns.GetDisplayedDungeonMapID()==16611,
        'opening the map inside Ruins of Lordaeron selects the dungeon tiles')
    instanceType,instanceID='none',0
    for _,id in ipairs({16919,16732,16544,2970,3039,2994,2974,3001}) do
        local definition=ns.DungeonMaps[id]
        ns.ShowDungeonMap(id)
        check(ns.GetDisplayedDungeonMapID()==id and mapID==definition.parent,
            'Forever dungeon opens on its entrance map')
        local files=definition.floors[1].minimap.files
        local tileCount=0
        for index,file in ipairs(files) do
            if file then
                local tile=art.textures[index+1]
                check(tile.shown and tile.file==file and tile.width>0 and tile.height>0,
                    'Forever tile grid displays native textures in their indexed positions')
                tileCount=tileCount+1
            else
                check(not art.textures[index+1].shown and not art.textures[index+1].file,
                    'missing terrain tiles leave a gap without leaking old art')
            end
        end
        local unused=art.textures[#files+2]
        check(tileCount>0 and (not unused or not unused.shown),'smaller grids hide previously used textures')
    end
    local worldEntries=ns.ListDungeons(ns.Data,{level=60,completed=function()return false end,active=function()return false end})
    local alcaz
    for _,entry in ipairs(worldEntries) do if entry.id==2994 then alcaz=entry end end
    check(alcaz and alcaz.mapOnly and not alcaz.total,'a dungeon without quest data is browsable without fake quest progress')
    local localEntries=ns.ListDungeons(ns.Data,{level=60},2548)
    check(#localEntries==1 and localEntries[1].id==3039,'map-only card follows outdoor zone scope')
    check(ns.DungeonFromNativePin({pinTemplate='DungeonEntrancePinTemplate',name='Blackmaw Hold'})==2974,
        'native Forever portal can open a map-only dungeon')
    WorldMapFrame:SetMapID(1414)
    WorldMapFrame,CreateFrame=previousMap,previousCreate
    hooksecurefunc,GetInstanceInfo,NavBar_AddButton=previousHook,previousInstance,previousAddButton
    C_Map.GetBestMapForUnit,GetMinimapZoneText=previousBestMap,previousSubzone
    ns.QueueRefresh=queueRefresh
    ns.OpenDungeons=previousOpen
end
