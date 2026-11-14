local _, ns = ...
-- QuestSort categories from the pinned upstream schema. Generic Seasonal requires
-- an explicit quest association: it must never mean "any holiday is active".
local categories = {
    [-404]='winter', [-402]='harvest', [-378]='children', [-376]='love',
    [-375]='pilgrim', [-374]='noblegarden', [-370]='brewfest', [-369]='midsummer',
    [-366]='lunar', [-364]='darkmoon', [-41]='dead', [-21]='hallow',
}
local overrides = {
    [1657]={event='hallow'}, [8322]={event='hallow'},
    [8827]={event='winter',from=1225,untilDate=102},
    [8828]={event='winter',from=1225,untilDate=102},
    [8860]={event='winter',from=1231,untilDate=101},
    [8861]={event='winter',from=1231,untilDate=101},
    [8902]={event='love'},
}
local holidayNames = {
    ['Feast of Winter Veil']='winter', ['Winter Veil']='winter',
    ['Harvest Festival']='harvest', ["Children's Week"]='children',
    ['Love is in the Air']='love', ["Pilgrim's Bounty"]='pilgrim',
    ['Noblegarden']='noblegarden', ['Brewfest']='brewfest',
    ['Midsummer Fire Festival']='midsummer', ['Lunar Festival']='lunar',
    ['Darkmoon Faire']='darkmoon', ['Day of the Dead']='dead', ["Hallow's End"]='hallow',
}

function ns.GetQuestEvent(id, quest)
    if overrides[id] then return overrides[id] end
    if categories[quest.zoneOrSort] then return {event=categories[quest.zoneOrSort]} end
    if quest.zoneOrSort == -22 then return {event='unknown'} end
end

function ns.IsEventAvailable(info, state)
    if not state.holidays or not state.holidays[info.event] then return false end
    if info.from then
        local day = state.monthDay
        if not day then return false end
        if info.from <= info.untilDate then return day >= info.from and day <= info.untilDate end
        return day >= info.from or day <= info.untilDate
    end
    return true
end

local function dateKey(value)
    if not value then return end
    return (((value.year*12+value.month)*32+value.monthDay)*24+(value.hour or 0))*60+(value.minute or 0)
end

function ns.ReadHolidays()
    local active = {}
    local now = C_DateAndTime and C_DateAndTime.GetCurrentCalendarTime and C_DateAndTime.GetCurrentCalendarTime()
    if not now then return active end
    local monthDay = now.month*100+now.monthDay
    if not C_Calendar or not C_Calendar.GetMonthInfo or not C_Calendar.GetHolidayInfo then return active, monthDay end
    -- English names are the verified mapping for this prototype. Unrecognized/localized
    -- events stay hidden instead of guessing dates or changing the user's calendar filters.
    local base = C_Calendar.GetMonthInfo()
    if not base then return active, monthDay end
    local offset = (now.year-base.year)*12+now.month-base.month
    local current = dateKey(now)
    for index=1,C_Calendar.GetNumDayEvents(offset,now.monthDay) do
        local holiday = C_Calendar.GetHolidayInfo(offset,now.monthDay,index)
        local key = holiday and holidayNames[holiday.name]
        if key then
            local first,last = dateKey(holiday.startTime),dateKey(holiday.endTime)
            if first and last and current >= first and current < last then active[key]=true end
        end
    end
    return active, monthDay
end
