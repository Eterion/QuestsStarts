local _, ns = ...
-- Connected components in displayed map coordinates. Rebuilt after zoom/resize;
-- a wider map can separate pickups that share a pin at the previous zoom level.
function ns.ClusterGroups(groups, width, height, radius)
    local parents,order = {},{}
    local minX,maxX,minY,maxY=math.huge,-math.huge,math.huge,-math.huge
    for i,group in ipairs(groups) do
        parents[i]=i order[i]=i
        local point=group.starter
        minX,maxX=math.min(minX,point.x),math.max(maxX,point.x)
        minY,maxY=math.min(minY,point.y),math.max(maxY,point.y)
    end
    local axis,axisScale='x',width
    if (maxY-minY)*math.abs(height)>(maxX-minX)*math.abs(width) then axis,axisScale='y',height end
    table.sort(order,function(a,b)
        local x,y=groups[a].starter[axis],groups[b].starter[axis]
        if x~=y then return x<y end
        return a<b
    end)
    local function find(i)
        while parents[i] ~= i do parents[i]=parents[parents[i]] i=parents[i] end
        return i
    end
    local radiusSquared=radius*radius
    for sortedIndex=1,#order do
        local i=order[sortedIndex]
        local first=groups[i].starter
        for nextIndex=sortedIndex+1,#order do
            local j=order[nextIndex]
            local second=groups[j].starter
            local gap=(first[axis]-second[axis])*axisScale
            if gap*gap>radiusSquared then break end
            local dx=(first.x-second.x)*width
            local dy=(first.y-second.y)*height
            if dx*dx+dy*dy <= radiusSquared then parents[find(j)]=find(i) end
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
