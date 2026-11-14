local _, ns = ...
-- Connected components in displayed map coordinates. Rebuilt after zoom/resize;
-- a wider map can separate pickups that share a pin at the previous zoom level.
function ns.ClusterGroups(groups, width, height, radius)
    local parents = {}
    for i=1,#groups do parents[i]=i end
    local function find(i)
        while parents[i] ~= i do parents[i]=parents[parents[i]] i=parents[i] end
        return i
    end
    for i=1,#groups do
        for j=i+1,#groups do
            local dx=(groups[i].starter.x-groups[j].starter.x)*width
            local dy=(groups[i].starter.y-groups[j].starter.y)*height
            if dx*dx+dy*dy <= radius*radius then parents[find(j)]=find(i) end
        end
    end
    local result, byRoot = {}, {}
    for i,group in ipairs(groups) do
        local key=find(i)
        local cluster=byRoot[key]
        if not cluster then
            cluster={starter=group.starter,groups={}}
            byRoot[key]=cluster result[#result+1]=cluster
        end
        cluster.groups[#cluster.groups+1]=group
    end
    return result
end
