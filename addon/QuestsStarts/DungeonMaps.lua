local _, ns = ...
local WIDTH, HEIGHT, TILE = 1003, 668, 256
local definitions = ns.DungeonMaps
local byInstance = {}
for id, definition in pairs(definitions) do byInstance[definition.instanceID] = id end
local map
local overlay, art, tiles
local dungeonID, dungeonName, parentMapID
local floorIndex, trackedFloor, wasInside

function ns.IsDungeonMapShown()
    return overlay ~= nil and overlay:IsShown()
end

function ns.GetDisplayedDungeonMapID()
    if ns.IsDungeonMapShown() then return dungeonID end
end

local function HideInstanceMap()
    if ns.IsDungeonMapShown() then
        overlay:Hide()
        dungeonID, floorIndex, trackedFloor = nil, nil, nil
        map.NavBar:Refresh()
        ns.QueueRefresh()
    end
end

local function GetPlayerDungeon()
    local name, instanceType, _, _, _, _, _, instanceID = GetInstanceInfo()
    if instanceType == "party" then return byInstance[instanceID], name end
end

local function GetPlayerFloor(definition)
    if #definition.floors == 1 then return 1 end
    local subzone = GetMinimapZoneText and GetMinimapZoneText()
    local mapID = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local nativeFloor
    for index, entry in ipairs(definition.floors) do
        if mapID and entry.mapID == mapID then nativeFloor = index end
        if subzone == entry.name then return index end
        for _, alias in ipairs(entry.subzones or {}) do
            if subzone == alias then return index end
        end
    end
    return nativeFloor
end

local function LayoutArt()
    if not floorIndex then return end
    local floor = definitions[dungeonID].floors[floorIndex]
    local minimap = floor.minimap
    local width, height = art:GetSize()
    if width <= 0 or height <= 0 then return end
    local mapWidth, mapHeight = WIDTH, HEIGHT
    local tileSize, columns = TILE, 4
    local left, top, offsetX, offsetY = 0, 0, 0, 0
    local scaleX, scaleY = width / WIDTH, height / HEIGHT
    if minimap then
        mapWidth, mapHeight = minimap.width, minimap.height
        tileSize, columns = minimap.tileSize, minimap.columns
        left, top = minimap.left, minimap.top
        local scale = math.min(width / mapWidth, height / mapHeight)
        scaleX, scaleY = scale, scale
        offsetX, offsetY = (width - mapWidth * scale) / 2, (height - mapHeight * scale) / 2
    end
    for index, texture in ipairs(tiles) do
        local shown = minimap and not not minimap.files[index] or not minimap and index <= 12
        texture:SetShown(shown)
        if shown then
            local x = ((index - 1) % columns) * tileSize
            local y = math.floor((index - 1) / columns) * tileSize
            local x1, y1 = math.max(x, left), math.max(y, top)
            local x2 = math.min(x + tileSize, left + mapWidth)
            local y2 = math.min(y + tileSize, top + mapHeight)
            texture:SetTexCoord((x1 - x) / tileSize, (x2 - x) / tileSize, (y1 - y) / tileSize, (y2 - y) / tileSize)
            texture:SetPoint("TOPLEFT", art, "TOPLEFT", offsetX + (x1 - left) * scaleX, -offsetY - (y1 - top) * scaleY)
            texture:SetSize((x2 - x1) * scaleX, (y2 - y1) * scaleY)
        end
    end
end

local function ShowFloor(index)
    local floor = definitions[dungeonID].floors[index]
    if index == floorIndex then return end
    floorIndex = index
    local tileCount = floor.minimap and #floor.minimap.files or 12
    for i = #tiles + 1, tileCount do
        tiles[i] = art:CreateTexture(nil, "ARTWORK")
    end
    for i, texture in ipairs(tiles) do
        if floor.minimap then texture:SetTexture(floor.minimap.files[i] or nil)
        elseif i <= tileCount then texture:SetTexture(floor.texture .. i .. floor.extension)
        else texture:SetTexture(nil) end
    end
    LayoutArt()
    map:ResetZoom()
end

local function TrackFloor()
    local inside = GetPlayerDungeon() == dungeonID
    if not inside then
        if wasInside then HideInstanceMap() end
        return
    end
    wasInside = true
    local detected = GetPlayerFloor(definitions[dungeonID])
    if detected and detected ~= trackedFloor then
        trackedFloor = detected
        ShowFloor(detected)
    end
end

local function CreateOverlay()
    local scroll = map.ScrollContainer
    local panel = CreateFrame("Button", nil, map)
    panel:Hide()
    panel:SetAllPoints(scroll)
    local inputLevel = scroll:GetFrameLevel() + 20
    panel:SetFrameLevel(inputLevel)
    panel:RegisterForClicks("RightButtonUp")
    panel:SetScript("OnClick", function()
        local parent = parentMapID
        HideInstanceMap()
        map:SetMapID(parent)
        map:ResetZoom()
    end)

    -- Keep native scrolling and clipping while masking the outdoor canvas.
    local canvas = map:GetCanvas()
    art = CreateFrame("Frame", nil, canvas)
    art:SetAllPoints(canvas)
    art:SetIgnoreParentAlpha(true)
    art:Hide()

    panel:EnableMouseWheel(true)
    panel:SetScript("OnMouseWheel", function(_, delta)
        scroll:OnMouseWheel(delta)
    end)
    panel:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then scroll:OnMouseDown(button) end
    end)
    panel:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then scroll:OnMouseUp(button) end
    end)
    local toggle = map.SidePanelToggle
    local originalToggleLevel
    local originalCanvasAlpha
    panel:SetScript("OnShow", function()
        originalCanvasAlpha = canvas:GetAlpha()
        canvas:SetAlpha(0)
        art:SetAlpha(scroll:GetEffectiveAlpha())
        art:Show()
        if toggle and toggle:GetFrameLevel() <= inputLevel then
            originalToggleLevel = toggle:GetFrameLevel()
            toggle:SetFrameLevel(inputLevel + 1)
        end
    end)
    panel:SetScript("OnHide", function()
        art:Hide()
        for _, texture in ipairs(tiles) do texture:SetTexture(nil) end
        if originalCanvasAlpha then
            canvas:SetAlpha(originalCanvasAlpha)
            originalCanvasAlpha = nil
        end
        if originalToggleLevel then
            if toggle:GetFrameLevel() == inputLevel + 1 then toggle:SetFrameLevel(originalToggleLevel) end
            originalToggleLevel = nil
        end
    end)

    local background = art:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.14, 0.10, 0.07, 1)

    tiles = {}
    art:SetScript("OnShow", LayoutArt)
    art:SetScript("OnSizeChanged", LayoutArt)
    local elapsed = 0
    panel:SetScript("OnUpdate", function(_, delta)
        art:SetAlpha(scroll:GetEffectiveAlpha())
        elapsed = elapsed + delta
        if elapsed >= .5 then
            elapsed = 0
            TrackFloor()
        end
    end)
    return panel
end

function ns.ShowDungeonMap(id)
    local definition = definitions[id]
    if not definition or ns.GetDisplayedDungeonMapID() == id then return end
    local playerDungeon, name = GetPlayerDungeon()
    local inside = playerDungeon == id
    local parent = definition.parent
    local dungeon = ns.Data.dungeons[id]
    for _, entrance in ipairs(dungeon and dungeon.entrances or {}) do
        if entrance.mapID == map:GetMapID() then parent = entrance.mapID break end
    end
    if map:GetMapID() ~= parent then map:SetMapID(parent) end
    overlay = overlay or CreateOverlay()
    dungeonID, parentMapID, wasInside = id, parent, inside
    dungeonName = inside and name or (dungeon and dungeon.name or definition.name)
    trackedFloor = inside and GetPlayerFloor(definition) or nil
    floorIndex = nil
    ShowFloor(trackedFloor or 1)
    overlay:Show()
    map.NavBar:Refresh()
    ns.QueueRefresh()
end

local function ShowInstanceMap()
    local id = GetPlayerDungeon()
    if not id then return end
    if ns.Data.dungeons[id] then ns.OpenDungeons(id)
    else ns.ShowDungeonMap(id) end
end

function ns.InstallDungeonMaps()
    map = WorldMapFrame
    map:HookScript("OnShow", ShowInstanceMap)
    map:HookScript("OnHide", HideInstanceMap)

    -- Build the native outdoor hierarchy first, then add the dungeon and its floors.
    hooksecurefunc(map.NavBar, "Refresh", function(navBar)
        if ns.IsDungeonMapShown() and map:GetMapID() == parentMapID then
            local floors = definitions[dungeonID].floors
            NavBar_AddButton(navBar, { name = dungeonName, OnClick = function() end,
                listFunc = #floors > 1 and function()
                    local choices = {}
                    for index, entry in ipairs(floors) do
                        choices[index] = { text=entry.name, id=index, func=function(_, selected)
                            if ns.IsDungeonMapShown() and floors == definitions[dungeonID].floors then
                                ShowFloor(selected)
                            end
                        end }
                    end
                    return choices
                end or nil })
        end
    end)

    -- Native breadcrumb clicks go through SetMapID, even for the current city.
    hooksecurefunc(map, "SetMapID", HideInstanceMap)

    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    events:RegisterEvent("ZONE_CHANGED")
    events:RegisterEvent("ZONE_CHANGED_INDOORS")
    events:SetScript("OnEvent", function()
        if ns.IsDungeonMapShown() then TrackFloor() end
    end)

    if map:IsShown() then ShowInstanceMap() end
end
