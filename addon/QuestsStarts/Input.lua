local _,ns=...

-- Hover belongs to the pin; clicks belong to the map scroll controller. Its
-- canvas handler runs only for a completed click, after rejecting map drags.
function ns.ConfigurePinInput(pin)
    pin:SetMouseClickEnabled(false)
    pin:SetMouseMotionEnabled(true)
end

function ns.HandleCanvasClick(map,button)
    ns.lastMapInput=button
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
    -- Snapshot data before any other provider can recycle the frame. Run after
    -- ScrollContainer hooks, including Spoken's place-story selection.
    local dungeonID,cluster=selected.dungeonID,selected.cluster
    local dungeonIDs=selected.dungeonIDs or (dungeonID and {dungeonID})
    if dungeonID then ns.entranceClickCount=(ns.entranceClickCount or 0)+1 end
    C_Timer.After(0,function()
        if not map:IsShown() or map:GetMapID()~=mapID then return end
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
