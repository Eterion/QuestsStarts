# Blocked interface actions

The AddOns menu's reported 1792 is a count of blocked interface actions, not a Lua error code. Blizzard's [AddOnList implementation](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_AddOnList/AddonList.lua) increments that count for each attributed action. The existing local logs did not identify the blocked function, so the historical count cannot establish a single cause.

The dock called `UpdateUIPanelPositions` while arranging its companions. On this client's [panel manager](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIParentPanelManager/Shared/UIParentPanelManager.lua), that function writes attributes on a frame marked forbidden. The dock also changed native panel attributes and moved or hid other Blizzard windows. These calls have been removed. The passive secure hook that observes native panel layout updates remains.

Fullscreen Place Story previously replaced `WorldMapFrame.IsMaximized` temporarily to bypass Spoken's windowed-panel check. It now renders through Spoken's page and data APIs without replacing native map methods. Dock layout changes wait until combat ends.

The windowed dock no longer moves or hides other Blizzard panels to make space. Other open windows can therefore overlap its companion panels; verify the layout during normal play.

## Capturing remaining failures

After loading the new build with `/reload`, reproduce the problem, then run `/qs blocked`. The report lists attributed action names and counts for this reload. Run `/reload` again to persist the trace in `QuestsStartsDB.blockedActions` for local inspection.

The capture retains at most eight distinct actions, one stack per action, repeat counts, and one previous nonempty capture. It records only actions attributed to QuestsStarts and does not change Blizzard's counter or enable global taint logging. A zero count after a short check does not prove that every gameplay path is safe.

Offline coverage checks that dock layout never calls the removed native dispatchers, combat defers layout, fullscreen story rendering does not write native map state, and repeated diagnostics remain bounded. In-game confirmation is still required.
