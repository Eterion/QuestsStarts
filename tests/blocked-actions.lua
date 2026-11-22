return function(ns,check)
    local savedSettings,savedStack,savedCombat=ns.Settings,debugstack,InCombatLockdown
    ns.Settings={}
    local stacks=0
    debugstack=function()stacks=stacks+1 return 'test call site'end
    InCombatLockdown=function()return true end
    ns.StartBlockedActionLog('test-1')
    ns.RecordBlockedAction('ADDON_ACTION_BLOCKED','AnotherAddon','Frame:SetAttribute()')
    check(ns.Settings.blockedActions.total==0,'blocked-action diagnostics do not attribute another addon failures to QuestsStarts')
    for _=1,1000 do ns.RecordBlockedAction('ADDON_ACTION_BLOCKED','QuestsStarts','Frame:SetAttribute()')end
    local log=ns.Settings.blockedActions
    local record=log.records[log.order[1]]
    check(log.total==1000 and #log.order==1 and record.count==1000 and stacks==1 and record.combat,
        'repeated blocked actions aggregate without repeatedly allocating stacks')
    for i=1,12 do ns.RecordBlockedAction('ADDON_ACTION_FORBIDDEN','QuestsStarts','Action '..i)end
    check(#log.order==8 and log.omitted==5 and log.total==1012,'blocked-action capture has bounded distinct stacks but preserves total counts')
    ns.StartBlockedActionLog('test-2')
    check(ns.Settings.blockedActions.total==0 and ns.Settings.blockedActions.previous==log,
        'a reload starts a new counter while preserving the last nonempty trace')
    ns.RecordBlockedAction('ADDON_ACTION_FORBIDDEN','QuestsStarts','New action')
    ns.StartBlockedActionLog('test-3')
    check(ns.Settings.blockedActions.previous.build=='test-2' and not ns.Settings.blockedActions.previous.previous,
        'blocked-action history retains at most one prior nonempty capture')
    ns.Settings,debugstack,InCombatLockdown=savedSettings,savedStack,savedCombat
end
