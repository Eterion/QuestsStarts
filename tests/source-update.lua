return function(ns,check)
    local done,active={},{}
    local state={level=30,raceMask=16,classMask=16,showLowLevel=true,holidays={},
        completed=function(id)return done[id] or false end,active=function(id)return active[id] or false end}
    done[430]=true
    check(ns.IsAvailable(91920,ns.Data.quests,state)==true,'Return to Quinn unlocks Wild Eyes')
    check(ns.IsAvailable(425,ns.Data.quests,state)==false,'Ivar the Foul does not skip the new Quinn chain')
    done[91920]=true
    check(ns.IsAvailable(91921,ns.Data.quests,state)==true,'Wild Eyes unlocks Return to Quinn Again')
    check(ns.IsAvailable(425,ns.Data.quests,state)==false,'Ivar waits for Return to Quinn Again')
    done[91921]=true
    check(ns.IsAvailable(425,ns.Data.quests,state)==true,'completed Quinn chain unlocks Ivar the Foul')
    check(ns.IsAvailable(98298,ns.Data.quests,state)==false and ns.IsAvailable(98299,ns.Data.quests,state)==false,'Arugal follow-ups wait for their actual prerequisite')
    done[99]=true
    check(ns.IsAvailable(98298,ns.Data.quests,state)==true and ns.IsAvailable(98299,ns.Data.quests,state)==true,'Arugal prerequisite unlocks both corrected follow-ups')
    check(ns.IsAvailable(95883,ns.Data.quests,state)==false,'Tortured Soul does not skip the Offering Stone')
    done[95884]=true
    check(ns.IsAvailable(95883,ns.Data.quests,state)==true,'Offering Stone unlocks Tortured Soul')
    check(ns.IsAvailable(95885,ns.Data.quests,state)==false,'Offering of Blood waits for Tortured Soul')
    done[95883]=true
    check(ns.IsAvailable(95885,ns.Data.quests,state)==true,'Tortured Soul unlocks Offering of Blood')
    done[366]=true done[411]=true
    active[409]=true
    check(ns.IsAvailable(410,ns.Data.quests,state)==true and ns.IsAvailable(431,ns.Data.quests,state)==true,'The Prodigal Lich no longer incorrectly excludes Dormant Shade and Candles')
    local _,reason=ns.IsAvailable(78261,ns.Data.quests,state)
    check(reason=='class','Horn of Xelthos is hidden from a priest')
    state.classMask=8
    check(ns.IsAvailable(78261,ns.Data.quests,state)==true,'Horn of Xelthos is available to the eligible rogue')
    check(ns.IsAvailable(78307,ns.Data.quests,state)==false,'Horn of Xelthos follow-up waits for the first step')
    done[78261]=true
    check(ns.IsAvailable(78307,ns.Data.quests,state)==true,'Horn of Xelthos follow-up unlocks for the rogue after completing the first step')
end
