local _, ns = ...

function ns.IndexZoneQuests(data, mapID)
    local ids, dungeons, pickups = {}, {}, {}
    for id, quest in pairs(data.quests) do
        if quest.checklistMaps and quest.checklistMaps[mapID] then ids[id] = true end
    end
    for _, starter in ipairs(data.maps[mapID] or {}) do
        for _, id in ipairs(starter.quests) do
            if data.quests[id] then ids[id] = true end
        end
    end
    for _, dungeon in pairs(data.dungeons) do
        local localEntrance = false
        for _, entrance in ipairs(dungeon.entrances) do
            if entrance.mapID == mapID then localEntrance = true end
        end
        for _, id in ipairs(dungeon.quests) do
            if localEntrance then
                for _, pickup in ipairs(data.pickups[id] or {}) do
                    if data.quests[id] and pickup.insideDungeon and data.dungeons[pickup.insideDungeon] == dungeon then
                        ids[id] = true
                    end
                end
            end
            if ids[id] and (not dungeons[id] or dungeon.name < dungeons[id]) then dungeons[id] = dungeon.name end
        end
    end
    for id in pairs(ids) do
        if data.pickups[id] and #data.pickups[id] > 0 then pickups[id] = data.pickups[id] end
    end
    local mapIDs = {}
    for id in pairs(data.maps) do mapIDs[#mapIDs+1] = id end
    table.sort(mapIDs)
    for _, id in ipairs(mapIDs) do
        for _, starter in ipairs(data.maps[id]) do
            for _, questID in ipairs(starter.quests) do
                if ids[questID] and not (data.pickups[questID] and #data.pickups[questID] > 0) then
                    pickups[questID] = pickups[questID] or {}
                    pickups[questID][#pickups[questID]+1] = starter
                end
            end
        end
    end
    return ids, dungeons, pickups
end

function ns.BuildZoneChecklist(quests, ids, dungeons, player, showCompleted)
    local result = { chains = {}, quests = {}, completed = 0, accepted = 0, total = 0 }
    local rows, ordered = {}, {}
    for id in pairs(ids) do
        local quest = quests[id]
        local race, class = quest.requiredRaces, quest.requiredClasses
        if (not race or not player.raceMask or ns.HasBit(race, player.raceMask))
            and (not class or not player.classMask or ns.HasBit(class, player.classMask)) then
            local active, complete = player.active(id), player.completed(id)
            local row = { id = id, name = quest.name or '', level = quest.questLevel or 0,
                active = active, complete = complete and not active, dungeon = dungeons[id],
                previous = {}, next = {}, neighbors = {} }
            rows[id] = row
            ordered[#ordered+1] = row
            result.total = result.total+1
            if row.complete then result.completed = result.completed+1 end
            if row.active then result.accepted = result.accepted+1 end
        end
    end
    local function less(a, b)
        if a.level ~= b.level then return a.level < b.level end
        if a.name ~= b.name then return a.name < b.name end
        return a.id < b.id
    end
    local function connect(before, after)
        if before == after or not quests[before] or not quests[after] then return end
        local a, b = rows[before], rows[after]
        if (ids[before] and not a) or (ids[after] and not b) then return end
        if a then a.next[after] = true end
        if b then b.previous[before] = true end
        if a and b then
            a.neighbors[after] = true
            b.neighbors[before] = true
        end
    end
    -- Forward links may be the only evidence of a prerequisite outside the zone.
    for id, quest in pairs(quests) do
        local nextID = quest.nextQuestInChain
        if nextID and (rows[id] or rows[nextID]) then connect(id, nextID) end
    end
    for _, row in ipairs(ordered) do
        local quest = quests[row.id]
        local prerequisites = quest.preQuestSingle
        if not prerequisites or #prerequisites == 0 then prerequisites = quest.preQuestGroup end
        for _, id in ipairs(prerequisites or {}) do connect(math.abs(id), row.id) end
        if quest.parentQuest then connect(quest.parentQuest, row.id) end
        if quest.availableStartingWith then connect(quest.availableStartingWith, row.id) end
    end
    table.sort(ordered, less)
    local grouped = {}
    for _, first in ipairs(ordered) do
        if not grouped[first.id] then
            local component = { first }
            grouped[first.id] = true
            local index = 1
            while component[index] do
                for id in pairs(component[index].neighbors) do
                    if not grouped[id] then
                        grouped[id] = true
                        component[#component+1] = rows[id]
                    end
                end
                index = index+1
            end
            table.sort(component, less)
            local chain = { steps = {}, visible = {}, completed = 0 }
            local visited, visiting = {}, {}
            local function append(row)
                if visited[row.id] or visiting[row.id] then return end
                visiting[row.id] = true
                local previous = {}
                for id in pairs(row.previous) do
                    if rows[id] then previous[#previous+1] = rows[id] end
                end
                table.sort(previous, less)
                for _, earlier in ipairs(previous) do append(earlier) end
                visiting[row.id], visited[row.id] = nil, true
                chain.steps[#chain.steps+1] = row
                row.stepNumber = #chain.steps
                if row.complete then chain.completed = chain.completed+1 end
                if showCompleted or not row.complete then chain.visible[#chain.visible+1] = row end
            end
            for _, row in ipairs(component) do append(row) end
            if #chain.visible > 0 then
                local linked = #component > 1 or next(first.previous) or next(first.next)
                if linked then result.chains[#result.chains+1] = chain
                else result.quests[#result.quests+1] = first end
            end
        end
    end
    return result
end

function ns.ZoneChainTooltipSteps(chain, quests, player)
    local steps, localIDs, added = {}, {}, {}
    for _, row in ipairs(chain.steps) do localIDs[row.id] = true end
    local function addOutside(links)
        local ids = {}
        for id in pairs(links) do
            if quests[id] and not localIDs[id] and not added[id] then ids[#ids+1] = id end
        end
        table.sort(ids)
        for _, id in ipairs(ids) do
            local active = player.active(id)
            steps[#steps+1] = { id = id, active = active, complete = not active and player.completed(id) }
            added[id] = true
        end
    end
    for _, row in ipairs(chain.steps) do
        addOutside(row.previous)
        steps[#steps+1] = row
    end
    for _, row in ipairs(chain.steps) do addOutside(row.next) end
    return steps
end
