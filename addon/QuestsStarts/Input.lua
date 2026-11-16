local _,ns=...
local pendingEntrance, hookedPlaces

function ns.SetupSpokenEntranceInput(places)
    if not places or places==hookedPlaces or type(places.CursorArea)~='function' then return end
    hookedPlaces=places
    local cursorArea=places.CursorArea
    places.CursorArea=function(self,...)
        -- Spoken's mouse-up hook runs after the canvas has consumed the click.
        -- Skip the outdoor area lookup until that entrance activation is handled.
        if pendingEntrance and pendingEntrance.mapID==WorldMapFrame:GetMapID() then return end
        return cursorArea(self,...)
    end
end

-- Hover belongs to the pin; clicks belong to the map scroll controller. Its
-- canvas handler runs only for a completed click, after rejecting map drags.
function ns.ConfigurePinInput(pin)
    pin:SetMouseClickEnabled(false)
    pin:SetMouseMotionEnabled(true)
end

function ns.HandleCanvasClick(map,button)
    ns.lastMapInput=button
    -- The dungeon art uses Orgrimmar as its base map.
    if ns.IsDungeonMapShown() then return button=='LeftButton' end
    if button~='LeftButton' or (IsModifierKeyDown and IsModifierKeyDown()) then return false end
    local cursorX,cursorY=GetCursorPosition()
    local selected,best
    for _,template in ipairs({ns.PinTemplate,ns.EntrancePinTemplate}) do
        for pin in map:EnumeratePinsByTemplate(template) do
            if pin:IsShown() then
                local x,y=pin:GetCenter()
                if x and y then
                    local scale=pin:GetEffectiveScale()
                    local dx,dy=cursorX/scale-x,cursorY/scale-y
                    if math.abs(dx)<=pin:GetWidth()/2 and math.abs(dy)<=pin:GetHeight()/2 then
                        local distance=(dx*scale)^2+(dy*scale)^2
                        if not best or distance<best then selected,best=pin,distance end
                    end
                end
            end
        end
    end
    if not selected then return false end
    ns.lastMapInput=selected.dungeonID and 'dungeon entrance' or 'quest pickup'
    local mapID=map:GetMapID()
    -- Snapshot data before any other provider can recycle the frame.
    local dungeonID,cluster=selected.dungeonID,selected.cluster
    local dungeonIDs=selected.dungeonIDs or (dungeonID and {dungeonID})
    local entrance
    if dungeonID then
        entrance={mapID=mapID}
        pendingEntrance=entrance
        ns.entranceClickCount=(ns.entranceClickCount or 0)+1
    end
    C_Timer.After(0,function()
        if entrance and pendingEntrance==entrance then pendingEntrance=nil end
        if not map:IsShown() or map:GetMapID()~=mapID or ns.IsDungeonMapShown() then return end
        if dungeonID then ns.OpenEntranceDungeons(dungeonIDs)
        elseif cluster then
            QuestsStartsPickupPinMixin.OnMouseUpAction({cluster=cluster,mapID=mapID},'LeftButton',selected)
        end
    end)
    return true
end

function ns.InstallMapInput()
    WorldMapFrame:AddCanvasClickHandler(ns.HandleCanvasClick,100)
end
