local _, ns = ...
ns.EntrancePinTemplate='QuestsStartsEntrancePinTemplate'

function ns.SetDungeonIcon(texture)
    -- The Dungeon atlas includes a large baked halo. The native minimap texture
    -- is the same portal without that halo, suitable for both pins and rows.
    texture:SetTexture('Interface\\Minimap\\Dungeon')
    texture:SetTexCoord(0,1,0,1)
end

local function openEntranceDungeon(id)
    local story=ns.GetStorySurfaces()
    if story and story:IsShown() then
        ns.OpenDungeons(id)
    else
        ns.ShowDungeonMap(id)
    end
end

function ns.OpenEntranceDungeons(ids)
    if #ids==1 then openEntranceDungeon(ids[1]) return end
    GameTooltip:Hide()
    MenuUtil.CreateContextMenu(WorldMapFrame,function(_,root)
        root:CreateTitle(ns.L.dungeons)
        for _,id in ipairs(ids) do
            local target=id
            root:CreateButton(ns.Data.dungeons[id].name,function()openEntranceDungeon(target)end)
        end
    end)
end

local entrancePress
local function mapFocus()
    local focus=GetMouseFoci and (GetMouseFoci() or {})[1] or (GetMouseFocus and GetMouseFocus())
    ns.lastEntranceFocus=focus and ((focus.GetName and focus:GetName()) or focus.pinTemplate or 'unnamed map frame') or 'none'
    local current=focus
    while current do
        if current==WorldMapFrame then return true,focus end
        current=current.GetParent and current:GetParent()
    end
    return false
end
function ns.DungeonFromNativePin(pin)
    local current=pin
    while current and current~=WorldMapFrame do
        if current.pinTemplate=='DungeonEntrancePinTemplate' or current.pinTemplate=='AreaPOIPinTemplate' then
            local name=current.name or (current.poiInfo and current.poiInfo.name)
            if current.journalInstanceID and EJ_GetInstanceInfo then name=EJ_GetInstanceInfo(current.journalInstanceID) or name end
            for id,dungeon in pairs(ns.Data.dungeons or {}) do if name==dungeon.name then return id end end
            for id,definition in pairs(ns.DungeonMaps or {}) do
                if definition.levelLow and name==definition.name then return id end
            end
        end
        current=current.GetParent and current:GetParent()
    end
end
local function entranceUnderMouse()
    if ns.IsDungeonMapShown() then return end
    if not ns.Settings or not ns.Settings.showEntrances or not WorldMapFrame:IsShown() or not MouseIsOver then return end
    local insideMap,focus=mapFocus()
    if not insideMap then return end
    -- A shared visible entrance must retain its choice menu even when a native
    -- marker beneath it consumes the click for just one of those instances.
    for pin in WorldMapFrame:EnumeratePinsByTemplate(ns.EntrancePinTemplate) do
        if pin.dungeonIDs and #pin.dungeonIDs>1 and pin:IsShown() and MouseIsOver(pin) then return pin.dungeonID,pin end
    end
    local native=ns.DungeonFromNativePin(focus)
    if native then return native end
    for pin in WorldMapFrame:EnumeratePinsByTemplate(ns.EntrancePinTemplate) do
        if pin.dungeonID and pin:IsShown() and MouseIsOver(pin) then return pin.dungeonID,pin end
    end
end

function ns.HandleEntranceMouse(event,button)
    if button~='LeftButton' then return end
    if IsModifierKeyDown and IsModifierKeyDown() then entrancePress=nil return end
    if event=='GLOBAL_MOUSE_DOWN' then
        entrancePress=nil
        local id,pin=entranceUnderMouse()
        if id then
            local x,y=GetCursorPosition()
            entrancePress={id=id,ids=pin and pin.dungeonIDs or {id},mapID=WorldMapFrame:GetMapID(),x=x,y=y,count=ns.entranceClickCount or 0}
        end
    else
        local press=entrancePress entrancePress=nil
        if not press then return end
        local x,y=GetCursorPosition()
        local tolerance=6*(UIParent and UIParent:GetEffectiveScale() or 1)
        if (x-press.x)^2+(y-press.y)^2>tolerance^2 then return end
        C_Timer.After(0,function()
            if (ns.entranceClickCount or 0)~=press.count or WorldMapFrame:GetMapID()~=press.mapID then return end
            if IsModifierKeyDown and IsModifierKeyDown() then return end
            if entranceUnderMouse()~=press.id then return end
            ns.entranceClickCount=press.count+1
            ns.entranceFallbackCount=(ns.entranceFallbackCount or 0)+1
            ns.OpenEntranceDungeons(press.ids)
        end)
    end
end

function ns.ProjectEntrance(location,mapID,getRect)
    if location.mapID==mapID then return location.x,location.y end
    if not getRect then return end
    local minX,maxX,minY,maxY=getRect(location.mapID,mapID)
    if not minX or not maxX or not minY or not maxY or maxX<=minX or maxY<=minY then return end
    local x=minX+(maxX-minX)*location.x
    local y=minY+(maxY-minY)*location.y
    if x>=0 and x<=1 and y>=0 and y<=1 then return x,y end
end

QuestsStartsEntrancePinMixin=CreateFromMixins(MapCanvasPinMixin)
function QuestsStartsEntrancePinMixin:OnLoad()
    self:SetScalingLimits(1,1,1.2)
    self:UseFrameLevelType('PIN_FRAME_LEVEL_DUNGEON_ENTRANCE')
end
function QuestsStartsEntrancePinMixin:OnAcquired(dungeonID,x,y,dungeonIDs)
    self.dungeonID=dungeonID
    self.dungeonIDs=dungeonIDs or {dungeonID}
    self:SetPosition(x,y)
    ns.SetDungeonIcon(self.Texture)
    if self.Glow then self.Glow:Hide() end
    ns.ConfigurePinInput(self)
end
function QuestsStartsEntrancePinMixin:OnMouseEnter()
    local dungeon=ns.Data.dungeons[self.dungeonID]
    if not dungeon then return end
    if self.Glow then self.Glow:Show() end
    local multiple=#self.dungeonIDs>1
    GameTooltip:SetOwner(self,'ANCHOR_RIGHT') GameTooltip:SetText(multiple and ns.L.entrances or dungeon.name,1,.82,0)
    if multiple then for _,id in ipairs(self.dungeonIDs) do GameTooltip:AddLine(ns.Data.dungeons[id].name,1,1,1)end end
    GameTooltip:AddLine('Dungeon Entrance',1,1,1)
    GameTooltip:AddLine(multiple and 'Click to choose a dungeon.' or 'Click to view dungeon quests.',.65,.65,.65,true)
    GameTooltip:Show()
end
function QuestsStartsEntrancePinMixin:OnMouseLeave()
    if self.Glow then self.Glow:Hide() end
    if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
end
function QuestsStartsEntrancePinMixin:OnReleased()
    self:OnMouseLeave() self.dungeonID=nil self.dungeonIDs=nil
    MapCanvasPinMixin.OnReleased(self)
end
function QuestsStartsEntrancePinMixin:OnMouseClickAction(button)
    if button=='LeftButton' and self.dungeonID then
        ns.entranceClickCount=(ns.entranceClickCount or 0)+1
        ns.OpenEntranceDungeons(self.dungeonIDs or {self.dungeonID})
    end
end
-- Controller activation uses the same action as the map canvas click handler.
function QuestsStartsEntrancePinMixin:OnClick(button)
    self:OnMouseClickAction(button)
end
function ns.DrawDungeonEntrances(map,mapID)
    -- Map movement events also refresh quest state. Keep entrance frames alive
    -- on the same map so the pool cannot shuffle equal-level overlapping pins.
    local enabled=ns.Settings.showEntrances
    local previous=map.questsStartsEntrances
    if previous and previous.mapID==mapID and previous.enabled==enabled and previous.data==ns.Data then
        ns.lastEntranceCount=previous.count
        return
    end
    if map.RemoveAllPinsByTemplate then map:RemoveAllPinsByTemplate(ns.EntrancePinTemplate) end
    ns.lastEntranceCount=0
    map.questsStartsEntrances={mapID=mapID,enabled=enabled,data=ns.Data,count=0}
    if not enabled then return end
    local groups={}
    for id,dungeon in pairs(ns.Data.dungeons or {}) do
        for _,location in ipairs(dungeon.entrances or {}) do
            -- Like quest pickups, entrances belong to their recorded zone.
            -- Do not project them onto parent continent or world maps.
            local x,y
            if location.mapID==mapID then x,y=location.x,location.y end
            if x and y then
                local key=string.format('%.6f:%.6f',x,y)
                local group=groups[key]
                if not group then group={x=x,y=y,ids={},seen={}} groups[key]=group end
                if not group.seen[id] then group.ids[#group.ids+1]=id group.seen[id]=true end
            end
        end
    end
    local keys={}
    for key in pairs(groups) do keys[#keys+1]=key end
    table.sort(keys)
    for _,key in ipairs(keys) do
        local group=groups[key]
        table.sort(group.ids,function(a,b)return ns.Data.dungeons[a].name<ns.Data.dungeons[b].name end)
        map:AcquirePin(ns.EntrancePinTemplate,group.ids[1],group.x,group.y,group.ids)
        ns.lastEntranceCount=ns.lastEntranceCount+1
    end
    map.questsStartsEntrances.count=ns.lastEntranceCount
end
