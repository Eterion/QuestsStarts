-- Offline Lua CPU/allocation benchmark; excludes WoW rendering and frame pools.
local root=arg[1] or '.'
local ns={}
local function load(name)assert(loadfile(root..'/addon/QuestsStarts/'..name))('QuestsStarts',ns)end
UnitClass=function()return 'Mage','MAGE',8 end
load('Events.lua') load('Eligibility.lua') load('Clusters.lua') load('Data/Tirisfal.lua')
local state={level=60,classMask=128,raceMask=16,showLowLevel=true,holidays={},
    completed=function()return false end,active=function()return false end,hasItem=function()return false end}
local largestMap,largestGroups
for mapID in pairs(ns.Data.maps) do
    local groups=ns.BuildGroups(ns.Data,mapID,state,true)
    if not largestGroups or #groups>#largestGroups then largestMap,largestGroups=mapID,groups end
end
local function measure(name,iterations,operation)
    collectgarbage('collect')
    local start=os.clock()
    for _=1,iterations do operation()end
    local ms=(os.clock()-start)*1000/iterations
    collectgarbage('collect') collectgarbage('stop')
    local before=collectgarbage('count')
    for _=1,100 do operation()end
    local allocated=(collectgarbage('count')-before)/100
    collectgarbage('restart') collectgarbage('collect')
    print(string.format('%s: %.4f ms/op; %.2f KiB allocated/op',name,ms,allocated))
end
print(string.format('Largest eligible map: %d; %d pickup groups',largestMap,#largestGroups))
local evaluations=0
local original=ns.IsAvailable
ns.IsAvailable=function(...)evaluations=evaluations+1 return original(...)end
ns.BuildGroups(ns.Data,largestMap,state,true)
ns.IsAvailable=original
print('Eligibility evaluations per map build: '..evaluations)
measure('BuildGroups',1000,function()ns.BuildGroups(ns.Data,largestMap,state,true)end)
measure('Cluster actual map',1000,function()ns.ClusterGroups(largestGroups,1000,668,28)end)
local sparse={}
for index=1,1000 do
    sparse[index]={starter={x=(index%40)/40,y=math.floor(index/40)/25}}
end
measure('Cluster 1000 sparse points',30,function()ns.ClusterGroups(sparse,4000,2500,28)end)
