local addonName,ns=...
local maxRecords=8

function ns.StartBlockedActionLog(build)
    local old=ns.Settings.blockedActions
    local previous=type(old)=='table' and (old.total and old.total>0 and old or old.previous) or nil
    if previous then previous.previous=nil end
    ns.Settings.blockedActions={build=build,total=0,records={},order={},omitted=0,previous=previous}
end

function ns.RecordBlockedAction(event,addon,action)
    if addon~=addonName or not ns.Settings or not ns.Settings.blockedActions then return end
    local log=ns.Settings.blockedActions
    log.total=log.total+1
    action=tostring(action or '(unknown)'):sub(1,250)
    local key=event..':'..action
    local record=log.records[key]
    if record then record.count=record.count+1 return end
    if #log.order>=maxRecords then log.omitted=log.omitted+1 return end
    record={event=event,action=action,count=1,
        combat=InCombatLockdown and InCombatLockdown() or false,
        stack=debugstack and debugstack(2,16,0) or 'Stack unavailable'}
    log.records[key]=record
    log.order[#log.order+1]=key
end

function ns.ShowBlockedActionLog()
    local log=ns.Settings.blockedActions
    if not log then return end
    print('QuestsStarts '..tostring(log.build)..': '..log.total..' blocked actions captured this reload.')
    for _,key in ipairs(log.order) do
        local record=log.records[key]
        print(record.count..'x '..record.action..' ('..record.event..')')
    end
    if log.previous then print('Previous capture: '..tostring(log.previous.build)..', '..log.previous.total..' blocked actions.') end
    if log.total>0 then print('Run /reload to save the bounded trace for local inspection.') end
end
