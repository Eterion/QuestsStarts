# In-game check: Horde zones and capitals

## Blocked interface actions

After `/reload`, confirm the installed build with `/qs`. Open and close the map,
maximize and minimize it, and switch between Dungeon Quests, Zone Quests, and
Place Story. Repeat with other Blizzard windows open and during/after combat.
Run `/qs blocked`: the expected count is zero. If it is nonzero, run `/reload`
to persist the bounded trace for inspection. Check that the map, tabs, and story
still lay out correctly. The dock no longer moves or hides other native windows,
so also inspect windowed-panel overlap. See [the investigation](blocked-actions.md).

The offline checks validate rules and runtime calls against client doubles, not the live client. Record the actual build, character race/class/level, any Lua error, and a screenshot when evaluating this prototype.

For dungeon-list controls, open a map without a dungeon and click **Browse all
dungeons**. It should uncheck **Current map** and show the world list. Both controls
use the same action. Also check **Clear search** after an unmatched search.

An unchanged empty state must remain visible through refreshes, including while
the search box loses focus. Hiding its parent between mouse-down and mouse-up
can cancel the click. The regression now checks that the parent stays visible
and the click handler stays installed; earlier callback-only checks missed this.
Both side panels use darker plain parchment for populated lists and restore the
native spiderweb artwork for empty states. Verify readability and native mouse
delivery in game.

Switch between windowed and maximized maps with each of Dungeon Quests, Zone
Quests, and Place Story selected. Windowed panels must retain their native frame,
title and close button beside icon tabs. Maximized panels use content-sized text
tabs and Blizzard's quest-list border with its top filigree on all three side
panels, with no extra title bar. The map viewport retains its plain inset border.
Check at 1920x1080 and 2560x1440 with the native quest log open
and closed: the map artwork should fill the viewport proportionally. Repeat the
mode switch to check that titles, page insets and borders restore correctly.

On 19 November 2026, the owner confirmed in build `0.16.0-dev.6` that **Browse all
dungeons** now unchecks **Current map** and displays the world list. The plain
parchment's final appearance has not yet received an in-game review.

1. After deployment completes, run `/reload`. If QuestsStarts is absent from the AddOns list, restart the client once and enable it. Run `/qs` to confirm version 0.9.1.
2. Open the Tirisfal Glades zone map. Inspect the yellow quest-start markers. Hover a known quest giver: the tooltip should show the starter name and eligible quest titles, with no duplicate title at that pickup.
3. In the native map filter menu, toggle **Quest Starts** off and on. Only the addon markers should disappear and return. Zoom, pan, resize, and close/reopen the map; markers should stay attached to their locations and match native icon scale.
4. Left-click a pickup. A native user waypoint should appear if supported. Right-click should retain normal map navigation. The addon must not accept or modify a quest.
5. During normal play, accept a quest you intended to take. Its pickup entry should disappear; other available quests from that giver should remain. Finish a normal prerequisite chain and check the next pickup when it becomes available. Do not abandon or complete quests solely for testing.
6. Unverified requirements are hidden by default. Enable **Include Unverified Pickups** to inspect them: uncertain entries must carry `(?)`; a pin containing only uncertain entries is dimmed.
7. Run `/reload` again and later check a normal client restart. Verify filter persistence separately; a rendering check does not prove saved settings persist.
8. Hover a shared pin near tightly packed givers in Brill. The tooltip should use uniformly sized green giver names, a shallow two-space quest indent, and half-height spacer lines above each giver name (including the first). No overall Quest Starts heading or availability labels should appear. Levels and difficulty colors should follow native filters. Click it: the Quest Starts menu should list those same givers in the same order, each opening a submenu of the same quest titles, levels, and difficulty colors. Select a quest to set that giver's waypoint. A single-giver pin should still set its waypoint directly. Zoom in/out: nearby locations should split/merge as their displayed separation changes.
9. Toggle Blizzard's existing **Show quest levels**, **Quest difficulty color**, and **Low level quests** controls. Tooltip levels/colors and low-level pickups should update without `/reload`. The accepted-quest objective setting (`questPOI`) must not override the independent **Quest Starts** setting.
10. With uncertain pickups both on and off, confirm inactive Winter Veil, Lunar Festival, and other seasonal pickups stay hidden. Server-calendar loading may briefly leave active holiday pickups hidden; an event-list update or reopening the map refreshes them. Holiday matching is currently English-only, and unknown seasonal associations stay hidden.
11. Open the Durotar zone map without travelling there. If above starting-zone level, enable **Low level quests** first. Run `/qs`: it should report the selected map, player level, pickup candidate counts, and hidden reasons. An empty map must distinguish completed/filtered quests, unsupported coverage, and a refresh error.

Start with known nearby quest givers in Deathknell or Brill. The data treats **Rude Awakening** (363) as an optional breadcrumb into **The Mindless Ones** (364); **Rattling the Rattlecages** (3901) depends on 364. These relationships are source evidence until checked in the live game.

## Known gaps

The prototype does not provide other dungeon checklists, minimap markers, general map-pin coverage outside its mapped world-zone/city export, item/drop pickup pins, complete eligibility gates, or translated fallback strings. Three configured maps have no source coordinates; see coverage.md and coverage-gaps.md. Inherited spawn locations are not proof of a current Forever NPC placement. A quest passing the supported checks can still have a server-side condition missing from upstream.

If the UI errors, `/qs off` hides pickup pins when the addon loaded successfully; disabling QuestsStarts from the AddOns list and reloading removes it completely. Report the first Lua error rather than subsequent cascades.

## Dungeon preparation (0.3.0)

1. Click the dungeon side tab below Spoken's story tab. The browser should offer RFC, WC, SFK, BFD, RFK, Gnomeregan, Scarlet Monastery, RFD, Ruins of Lordaeron, Hall of Thanes, Excavation Site: Wetlands, and City of Dalaran with level ranges. Select RFC: navigation should show **World → Ragefire Chasm**; click World to return, or use the dungeon arrow to switch instances. Check the flat frame has no portrait, matches story dimensions, and retains wrapped titles and no footer hints.
2. Check the six known quest records and accepted/completed counts against the character's actual log. Quests above your minimum level should state that requirement; completed/logged quests stay in the checklist even when low-level map pickups are hidden.
3. Check distinct sections for quests in your log, outdoor pickups, inside pickups, prerequisite chains, unavailable quests, and completed quests. Only chains should have plus/minus controls. **Hidden Enemies** (5728) should expose earlier steps 5726 and 5727 if needed. A logged 5727 must be labelled **In Your Quest Log**, not offered again.
4. Click the available first step or another available pickup. Verify the correct city map and native waypoint, including Orgrimmar, Thunder Bluff, and Undercity where relevant. This is navigation only; no quest should be accepted automatically.
5. **Returning the Lost Satchel** should identify Maur Grimtotem inside Ragefire Chasm. It must not place a pickup at a fabricated outdoor coordinate. Locations with no known coordinates should remain explicit.
6. During normal play, accept/complete an intended quest and check the panel updates without reloading. Expand/collapse several rows, scroll to the bottom, and verify there are no stale rows or overlapping labels.
7. Open the Orgrimmar map and click the RFC entrance marker. It should open RFC directly. Check Wailing Caverns in the Barrens and Shadowfang Keep in Silverpine; parent-map markers should only appear where a native map rectangle supports projection. Toggle **Dungeon Entrances** independently of **Quest Starts**.
8. With Spoken enabled, both side tabs should be visible beyond the currently open panel. Dungeons replaces the story in the same slot; clicking the story tab replaces dungeons with the story. Check repeated switching, map close/reopen, width/UI-scale changes, and quest-log toggling. With Spoken disabled or absent, only the dungeon tab occupies the first slot and it hides while preparation is open. No addon files/settings other than Spoken's normal collapsed preference should be changed.
9. Select Wailing Caverns and find **The Glowing Shard** in the inside-pickup section, with Glowing Shard/Mutanus the Devourer in its tooltip. It must not invent an outdoor waypoint for that item drop.
10. With the map and dungeon panel open, start walking. Both the dungeon panel and its side tab should fade with the map, then return to full opacity when the map does. Repeat with the dungeon panel closed and with Spoken disabled. Opening the dungeon panel while the map is already faded should immediately use the same opacity.

Pickup font regression (0.4.8): alternate hovering single-giver and grouped pins with different quest counts, then hover native quest/item tooltips. All pickup giver names and quest titles should retain the same normal font size; only the half-row spacers should be smaller. Pickup tooltips now use a dedicated GameTooltipTemplate frame and reset every visible row's font on every hover, with no font overrides or hooks on the shared GameTooltip.

## Expanded coverage (0.5.0)

Open each map without travelling there: the Barrens (1413), Silverpine Forest (1421), Orgrimmar (1454), Undercity (1458), and Thunder Bluff (1456). Check available pickups against the character's level and quest state; enable Low Level Quests if needed. `/qs` should report filtering counts for each supported map rather than a coverage warning. Known source pickups include Avenge My Village in the Barrens, A Recipe For Death in Silverpine, Hidden Enemies in Orgrimmar, The Power to Destroy... in Undercity, and Searching for the Lost Satchel in Thunder Bluff. Their actual availability depends on the character. Check nearby givers cluster correctly, markers remain aligned while zooming, and city dungeon entrances still open their preparation panel. Source coordinates and server eligibility require live verification.

The build now validates all nine class exports, retains only changed quest rows as class deltas, and checks exact reconstruction before shipping. Runtime regression checks cover the distinct Warrior/Priest Challenge follow-ups. Rebuilding from the pinned upstream revision does not require Questie to be installed in the game.

## More dungeon preparation (0.6.0)

Browse the five new instances through both World navigation and the dungeon arrow menu. The list should scroll through all eight supported dungeons, with higher-level instances still available to inspect. Scarlet Monastery is one combined checklist for its four wings. On a low-level Horde character, Alliance-only and other-class quests should remain absent rather than appearing as level-blocked entries.

Check RFK's A Vengeful Fate and Going, Going, Guano!, Gnomeregan's Rig Wars and the Scooty travel chain, BFD's Blackfathom Villainy, Scarlet Monastery's Into The Scarlet Monastery and Vorrel's Revenge, and RFD's Bring the End and An Unholy Alliance. Outdoor locations should navigate to their actual giver. Willix and Vorrel should be labeled inside their respective dungeons. The Small Scroll pickup for RFD's An Unholy Alliance must name Razorfen Kraul as its actual source. Item/drop or unknown locations must not become guessed outdoor waypoints.

On the Barrens map, check the WC, RFK, and RFD entrances independently. Check BFD in Ashenvale, Gnomeregan in Dun Morogh, and Scarlet Monastery in Tirisfal. Each should open the matching checklist. Dungeon pickup navigation works independently of general quest-start map coverage. Recommendations for the five additions use Classic Era bands, unconfirmed for Forever; see the linked reference in README. Source quest membership, coordinates, and server eligibility still require live verification.


## New Forever dungeons (0.7.0)

The browser and dungeon arrow menu should now offer twelve instances, including Ruins of Lordaeron, The Hall of Thanes, Excavation Site: Wetlands, and City of Dalaran. Check their entrance markers in Undercity, Ironforge, Wetlands, and Alterac Mountains respectively. Each should open its own checklist, independently of general quest-start map coverage.

For a Horde character, Hall should retain the two reported neutral quests: An Ancient Grudge, picked up from Ghostly Attendant inside, and Important Heirlooms, picked up from Thom Filch in Ironforge. Their local faction/starter corrections are documented in data-corrections.md and need confirmation during normal play. Ghostly Attendant must not generate an outdoor waypoint. Alliance-only Hall quests should stay excluded.

In Lordaeron, check the prerequisite chain for The Wrath of Rath'mael and the Abominable Head source for Unending Torment. In Dalaran, Shrewd Negotiations should be listed with its outdoor Magus Wordeen Voidglare pickup despite having an inside objective. Missing pickups, including source gaps for Crest of Lordaeron and Opportunistic Education, should show the existing unknown-location explanation in their tooltip. No missing location should turn into an entrance waypoint. Complete live quest coverage is not established by these source records.

The recommendation bands use Blizzard's published announcement: Hall 13–18, Lordaeron 15–20, Excavation 24–29, Dalaran 28–33. These remain separate from quest minimum levels. The README records the primary reference and the discrepancy with the current community Excavation recommendation.

## More quest-start maps (0.8.0)

Open Mulgore (1412), Stonetalon Mountains (1442), Ashenvale (1440), Thousand Needles (1441), and Hillsbrad Foothills (1424) without travelling there. `/qs` should report candidates and filtering reasons rather than an unsupported-map warning. Source location counts are 44, 19, 30, 29, and 37 respectively; available pins depend on character state and can be fewer or empty. At higher levels, enable Low Level Quests to inspect Mulgore.

Known source pickups include Defending the Dead in Mulgore, Report to Kadrak in Stonetalon, The Ashenvale Hunt in Ashenvale, Message to Freewind Post in Thousand Needles, and Elixir of Suffering in Hillsbrad. Inspect coordinates and availability against normal play. Verify grouped hover/menu behavior and native level/difficulty filters. Accepting an intended quest should remove its available entry. Inactive holiday and incompatible race/class pickups should remain hidden. This expands regular quest-start maps; it does not add dungeon-list entrance buttons.

## Remaining world maps (0.9.0)

The current generated coverage.md report lists all 50 configured maps, of which 47 have candidate pickup locations. Darkspear Islands was removed from the overworld list after the 0.9.1 audit identified it as a battleground. Open later-level maps such as Stranglethorn, Desolace, Dustwallow, Tanaris, Feralas, the Hinterlands, both Plaguelands, Un'Goro, Winterspring, and Silithus. Source map coverage should no longer be the reason for missing markers there. A lower-level character may still have no eligible quests: use `/qs` to inspect filtering reasons, not a promise of visible pins on every map at every level.

Check Zephras Isle and Shen'dralas separately; the pinned data has recorded coordinates there, but live placement and availability still require confirmation. Riverglades, Mount Hyjal, and Deadwind Pass have no coordinates in this Horde export. On those maps, `/qs` must report the source-data absence rather than suggesting all quests were completed or level-filtered. This does not establish whether those areas have active quests in the current game. Darkspear Islands is outside general overworld coverage.

Check Ironforge's neutral Thom Filch pickup for Important Heirlooms on an eligible Horde character. The documented NPC-faction exception must work for both the map pin and dungeon pickup. Alliance-only quests in Alliance cities and zones should stay filtered. Native difficulty/level/low-level filters, clustered selection, map zooming, completion refreshes, and the existing twelve dungeon checklists should retain their behavior. The reverted dungeon-list entrance buttons must remain absent.

## Source corrections (0.9.1)

During normal Silverpine play, check Return to Quinn → Wild Eyes → Return to Quinn (Again) → Ivar the Foul, and the Arugal's Folly/Stop the Spread prerequisites. The Tortured Soul must wait for The Offering Stone; The Offering of Blood must wait for The Tortured Soul. The Dormant Shade and Candles of Beckoning still require their active parent quest even after the incorrect Prodigal Lich exclusion is removed. A non-rogue should not receive Horn of Xelthos pickup pins. These source-rule changes have offline regression coverage; live quest acceptance remains the server's authority. The reviewed update does not add new pickup coordinates.

The offline suites cover nested/alternative/grouped prerequisites, accepted/completed states, cycle/missing-data safety, actual RFC pickup data, and UI callbacks against doubles. They do not validate live templates, screenshot appearance, or server-side quest availability.

## Remaining Classic dungeons and pickup gaps (0.10.0)

After `/reload`, check that the browser offers 21 dungeon groups. Open Uldaman, Zul'Farrak, Maraudon, Sunken Temple, Blackrock Depths, Blackrock Spire, Dire Maul, Scholomance, and Stratholme. Level ranges should appear in the browser and headings. Spire and Dire Maul combine wings. Long chains such as BRD's royal chain should start collapsed and expand on click. Existing RFC behavior should remain unchanged.

On Searing Gorge's map, the shared Blackrock entrance should offer Depths and Spire, each opening its own preparation panel. No entrance interaction should set a waypoint. Uldaman's distinct entrances should remain separate. Test plain clicks, drags, native marker overlap, map fade while walking, and switching between Spoken and preparation. Dungeon-list entrance buttons remain absent.

Inspect Crest of Lordaeron as an inside container pickup, Titan Relic as an inside Relic Guardian drop, and Open the Maw as an outdoor Deathstalker Agent pickup in Wetlands (51.4, 59.2) following Dragonmaw Rumors. That giver should also have an eligible regular map pin. Rexxie should say Alterac Mountains, near the sewer entrance, coordinates unknown, without a navigation action. The Forging of Quel'Serrar should identify the blade from its preceding compendium step. Legacy Gordok variant 1318 should remain unverified; absent Gnomeregan prerequisite 2955 must not acquire a fabricated giver.

Riverglades, Hyjal, and Deadwind should retain the source-gap diagnostic. No passive location capture is present. Current source additions, new dungeon templates, and corrected availability still require live gameplay verification; offline checks validate data construction and callback behavior only.

For the persistent click issue, version 0.4.2 routes both custom marker types through `WorldMapFrame:AddCanvasClickHandler`. Pins retain mouse-motion input for tooltips but leave mouse clicks to Blizzard's scroll controller, which rejects drags before invoking the handler. Hit testing uses the actual pin rectangles and effective scale. The action runs after scroll-container hooks so Spoken's place-story hook runs before dungeon selection. Tests exercise the registered canvas callback for both marker types, scaling, clustered pickup choices, modifier/right/empty clicks, and frame recycling without any global mouse events. Live input delivery still requires an in-game check.

Hover the portal to confirm its tooltip includes **Click to view dungeon quests**, click it, then test a yellow pickup marker. If either fails, run `/qs`: **Map click handler** always prints, distinguishing no canvas clicks, clicks on empty map, and a matched entrance/pickup. Check a short drag starting on each marker pans the map without activating it, and native Blizzard quest markers still select their quests normally.

Version 0.4.1 also accepts a plain click on the native dungeon entrance/area-POI marker when its exact name matches a supported dungeon. Verify RFC on the Orgrimmar map, then check that panning, modified clicks, unrelated map POIs, and other windows covering the map retain their normal behavior. A direct working click must not open the panel twice. `/qs` reports the last entrance input focus when available. The dungeon navigation item should be absent from the map filter, and addon-owned summary/location strings should have no dot or en/em-dash separators.

## Entrance appearance and refresh stability (0.10.1)

On a zone map, leave slightly overlapping entrance icons visible while standing and moving. Their stacking must remain stable across quest and canvas refreshes. Zoom out to continent and world maps: addon entrance markers must disappear. Zoom back into the zone: they must return. Hovering an entrance should add its glow; moving away, changing maps, or hiding the map must clear it. Toggling Dungeon Entrances off and on must remove and restore all markers. Entrance tooltips and clicks, including the shared Blackrock choice menu, must retain their behavior.

The dungeon browser should show larger 24-pixel portal icons without glow and keep both title and summary text clear of the icon. Open a dungeon after viewing the browser to check that recycled quest rows retain their smaller quest icons and original text gutter. Offline regression checks cover same-map frame retention, filter invalidation, hover/release cleanup, and the list gutter. Live world-map stacking and appearance still need in-game confirmation.

The normal artwork is the client's Interface/Minimap/Dungeon texture. In 0.10.2 the hover overlay uses that same portal at the same size with additive blending; the oversized Dungeon_Icon texture was removed after the user reported its visible ring. Verify that hover brightens the portal itself without adding an outer ring. The files were visually checked against the [Blizzard texture mirror](https://github.com/Gethe/wow-ui-textures/tree/live/MINIMAP); no external art is bundled.

## Item-started world quests (0.11.0)

The generated map report now distinguishes NPC/object givers from item sources. Counts are candidates before filtering, including Alliance-only variants that remain hidden for Horde. Item sources use one recorded point per creature/object per map. A point marks a recorded source and does not promise that every kill or container awards the item. Vendor purchases and reward-only items are not mapped.

After `/reload`, inspect an eligible item quest such as A Letter Undelivered in Tirisfal (item A Letter to Yvette), Ukor's Lost Pack in Durotar, or The Runed Scroll in the Barrens. Quest-level, difficulty-color, low-level, holiday, race/class, prerequisite, and completion rules should behave as for other pickups. Pins can be absent if your character is ineligible or has already completed the quest.

The tooltip and clustered menu should use the same item/source heading. A waypoint should lead to the selected recorded creature/object point. Existing giver waypoints must still work. Collecting a starter item should remove its source markers on the bag refresh; moving it out of your bags should restore eligible markers. Accepting or completing its quest must hide them. No item is used automatically. The lookup checks carried bags, not bank contents.

The offline suite verifies source deduplication, recorded-point selection, invalid/phased exclusion, NPC versus object identity, nested container cycles, inside-source exclusion from outdoor pins, exported item/quest references, item ownership, quest states, native-pin suppression, and matching menu/tooltip headings. Live drop conditions, current spawn positions, and rendering require gameplay confirmation.

## Item-source icons (0.11.1)

Item-only map clusters use the native VignetteLoot treasure chest. Giver-only pins retain QuestNormal. A mixed cluster keeps the exclamation mark and shows a small chest at the lower left; the source count remains at the lower right. Hover and click behavior is unchanged. If VignetteLoot is unavailable in the client, the native minimap Banker chest texture is used. Verify the artwork in game and zoom between mixed and separated clusters; recycled giver pins must clear the chest badge.

## Independent pickup filters (0.11.2)

The native map filter has Quest Starts for NPC/object givers and Item Quest Starts for item/drop sources. Test all four combinations: both enabled, only exclamation marks, only chests, and neither. Filtering happens before clustering, so a hidden type must not leave its badge or entries in tooltips/menus. Entrance markers and dungeon preparation remain independent. Both settings persist across reloads. On upgrade, the item setting initially inherits the previous pickup setting; subsequent toggles are independent. The Include Unverified Pickups option must not reveal a disabled source type. `/qs on` and `/qs off` now affect the giver toggle only; `/qs` reports both settings.

## Profession and reputation eligibility (0.12.0)

The existing source fields now use live character state. The export contains 195 profession-gated quests and 270 quests with reputation bounds; these counts include dependencies and faction/class variants, not newly available quests for every player. No source data or coordinates changed in this release.

Check a profession quest below its required base rank, at the exact threshold, and after unlearning the profession. Temporary skill bonuses should not satisfy the base-rank requirement. Existing SKILL_LINES_CHANGED events refresh the map and dungeon panel. Profession IDs are read through C_SkillInfo when available; legacy clients match supported professions through localized client spell names. The legacy Herb Gathering name is not assumed to match Herbalism, so that fallback remains unverified. No skill headers are expanded or collapsed by this addon. Hidden lines or incomplete API data cannot establish an absent profession.

For reputation quests, test one point below and exactly at a minimum. At a maximum, the quest must disappear at the exact threshold. Negative standings use their actual value, not the reaction bar's relative progress. UPDATE_FACTION refreshes the snapshot. Modern C_Reputation.GetFactionDataByID and legacy GetFactionInfoByID are supported. Missing/undiscovered factions remain unknown; the addon does not assume Neutral standing. Known profession/reputation failures cannot be revealed by Include Unverified Pickups; unknown values can still be inspected using that option. Dungeon rows should explain profession, skill, and reputation failures.

Offline tests cover threshold boundaries, negative standings, combined known/unknown requirements, unavailable APIs, modern IDs, localized legacy skill names, collapsed headers, base ranks, per-snapshot caching, and map-filter behavior. Live client values and server eligibility still need in-game confirmation. Compatibility was checked against [Questie's client adapters](https://github.com/Questie/Questie/blob/master/Modules/QuestieCompat.lua), [its reputation boundary rules](https://github.com/Questie/Questie/blob/master/Modules/QuestieReputation.lua), and [Blizzard's reputation API documentation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ReputationInfoDocumentation.lua). No Questie runtime is required.
