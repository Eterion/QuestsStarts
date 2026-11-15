# QuestsStarts

A lightweight quest-discovery addon for World of Warcraft: Forever.

Keep Blizzard's quest tracking and add the missing discovery tools: where to pick up quests and how to prepare dungeon quest chains.

## UI principles

- Feel like a native part of Forever's UI.
- Use Blizzard's world map, quest icons, fonts, tooltips, controls, and waypoint behavior.
- Respect UI scale and localization.
- Group quests offered by the same starter where appropriate.
- Avoid a replacement quest tracker, objective tracking, permanent floating widgets, and a branded minimap button.
- Inspect Forever's existing layouts before choosing where dungeon preparation belongs.

## Planned features

- World-map pins for quest starts, filtered by known character eligibility and completion.
- Pickup tooltips with quest titles, levels, and starter information.
- Click-to-waypoint navigation where the client supports it.
- A native map filter for pickup markers.
- Dungeon quest preparation showing accepted, completed, available, and prerequisite-blocked quests.
- For blocked dungeon quests, show the prerequisite pickup that starts the chain.
- Treat unknown requirements and missing locations explicitly rather than inventing availability or coordinates.

## Data approach

Use [QuestieDB's Forever dataset](https://github.com/Questie/QuestieDB) as the proposed upstream source. Generate a compact dataset offline containing the fields needed for discovery; do not require Questie's UI or runtime.

The prototype bundles generated pickup candidates on 47 world-zone/city maps, with 50 maps configured, and preparation data for 21 dungeon groups. Source data is pinned to the revision in `tools/upstream-revision.txt`; see the generated [map coverage report](docs/coverage.md) for counts and empty source maps. Reviewed local corrections are separate from the pinned source; see [data corrections](docs/data-corrections.md). Upstream licensing and provenance notices ship with the addon; see `addon/QuestsStarts/THIRD_PARTY_NOTICES.md`. The upstream statement describes historical licensing uncertainty and is preserved verbatim.

Forever-specific quest coverage, locations, restrictions, and dungeon associations require verification. Keep verified corrections separate from generated output, with provenance. Quest-line order alone is not proof of a prerequisite.

Native APIs can supply player quest state and may provide some quest offers. An initial user probe returned no available quest lines for the tested zone; this does not establish global coverage or API failure.

Zone Quests provides Horde checklists for the 50 configured world zones and
cities. It uses quests categorized to each zone, quests with a known local
pickup, and known pickups inside dungeons entered from the zone. Quests can
appear in multiple zones when the source associates them with each. Quest chains
group local steps and show known outside steps in tooltips. Zoom out on the map
to see continent or zone cards in the panel. Dungeon Quests follows the map and
lists instances with entrances in the current zone or continent. The world map
shows all tracked dungeons. The zone panel shows a source-data message
when it has no quests for the selected map or character.
The pinned source has checklist records on 48 maps before character filtering.
Riverglades has one categorized quest, while Deadwind Pass and Mount Hyjal have
no checklist records in this source.

Zone headers prefer the client's level range. Fallback ranges use the
[Kalimdor](https://www.60.tools/map/kalimdor) and
[Eastern Kingdoms](https://www.60.tools/map/eastern-kingdoms) client-data
summaries, with introductory zones starting at level 1. Headers use Blizzard
zone artwork where available and the continent loading screen elsewhere.

## First milestone

Build and validate quest-start pins in one zone before expanding coverage or adding dungeon preparation. Validate icon placement, native appearance, completion filtering, grouped tooltips, and waypoint behavior in game.

## Development workflow

- Keep editable source in this repository and deploy complete builds to the game's AddOns directory.
- The player can continue playing during development; running Lua does not automatically update when source files change.
- Announce when a complete build is ready, then use `/reload` to test ordinary file changes. Initial addon discovery may require a client restart.
- Keep account files, credentials, caches, and SavedVariables out of version control.
- Offline checks do not establish in-game rendering or gameplay correctness.

## Status

Version 0.14.0 adds Zone Quests checklists and searchable world, zone, and dungeon lists. It also includes Horde pickup markers across the world zones and cities represented in the source and preparation for 21 dungeon groups:

- 2,225 candidate pickup locations (1,464 NPC/object givers and 761 item sources) on 47 populated maps, including later leveling zones such as Desolace, Dustwallow, Stranglethorn, Tanaris, Feralas, the Hinterlands, Plaguelands, Winterspring, and Silithus. The dataset contains 3,682 quest records including transitive dependencies and dungeon preparation. Counts precede eligibility filtering; [coverage by map](docs/coverage.md) is generated during the build.
- The 50 configured maps comprise the 46 Classic world-zone/city maps and four mapped Forever areas. Zephras Isle and Shen'dralas have recorded pickup locations. Riverglades, Mount Hyjal, and Deadwind Pass currently have no pickup coordinates in the Horde export; `/qs` identifies this separately from unsupported maps and quests hidden by filters. The export configuration does not prove complete live quest or area availability. [The gap audit](docs/coverage-gaps.md) records the evidence. Darkspear Islands is a battleground and is excluded from overworld coverage.
- Source update `aa1d7e7` corrects the Return to Quinn and Arugal's Folly prerequisite chains and rogue-only Horn of Xelthos access. The Dormant Shade and Candles of Beckoning retain their active-parent requirement without the erroneous Prodigal Lich exclusion. Regression checks exercise these exported rules; actual pickup coordinates are unchanged by this source update.
- Item-source pins use Blizzard's native treasure-chest icon. Quest givers retain the yellow exclamation mark; mixed clusters add a small chest badge beside it. Tooltips and pickup menus share headings such as **A Letter to Yvette (drops from Rattlecage Soldier)** or **Item (found in Container)**. Existing character, quest-state, holiday, and native map filters apply. Carrying the starter item hides its acquisition markers until it leaves your bags; BAG_UPDATE_DELAYED refreshes that state. The export adds 761 source records for 97 starter items/quests before faction and eligibility filtering.
- Native `QuestNormal` icons, map scaling, difficulty-colored grouped tooltips, and waypoint clicks. Entrance portals use the native minimap artwork without a halo; an additive highlight brightens the portal only while hovering a map entrance, without an outer ring. Dungeon-list portals are 24 pixels with a wider text gutter. Entrance frames remain alive during same-map quest refreshes so overlapping icons keep their stacking order.
- Independent checkboxes in Blizzard's existing world-map filter menu: **Quest Starts** for NPC/object givers, **Item Quest Starts** for chests and library books, and **Include Unverified Pickups** for uncertain requirements. Uncertain pickups are opt-in, with dimmed pins and `(?)` labels.
- Completion, active-log, level, race/class, prerequisite, exclusive, breadcrumb, and supported quest-state gates. Profession requirements now use the trained skill and base rank; reputation gates use absolute standing, including negative values. Minimum reputation is inclusive and maximum reputation is exclusive. Known failures stay hidden even with Include Unverified Pickups enabled. Missing faction data and incomplete/collapsed skill lists remain unverified rather than being guessed.
- Quest data refreshes on map/quest changes. Suppresses quest offers already drawn by Blizzard. While the map is visible, the dungeon panel and tab follow its movement-fade opacity.
- Nearby pickup locations share one pin at the current zoom. Its tooltip lists all givers; clicking opens a native quest selection menu and sets the chosen giver's exact waypoint. Zooming can separate the pins.
- Honors Blizzard's **Show quest levels**, **Quest difficulty color**, and **Low level quests** controls; refreshes when those settings change. The independent **Quest Starts** and **Item Quest Starts** toggles control their pickup types; `questPOI` controls accepted-quest objectives and does not suppress pickups.
- Ordinary quest recommendations above player level + 5 are hidden even if their minimum level is low. Existing minimum-level and class/race restrictions still apply.
- Holiday categories and the prototype's generic-seasonal pickup associations require an active server-calendar holiday. Winter present/New Year sub-windows are also checked. Inactive holidays cannot be revealed by the uncertain-pickups toggle.
- A native right-side dungeon tab sits below Spoken Places' story tab. With either panel open, both tabs sit beyond the open panel. Without Spoken, the dungeon tab occupies the first slot and hides while its own panel is open. Entrance markers remain an alternate entry point. A **Dungeon Entrances** filter toggles those markers independently of ordinary quest starts.
- The browser orders the 21 supported dungeon groups for your character's quest levels. Native navigation breadcrumbs show **World → dungeon**, with World returning to the browser and the dungeon arrow offering other instances. The previous back button is removed.
- Dungeon preparation uses the same `DefaultPanelFlatTemplate` shell as Spoken, without a portrait. It matches Spoken's dimensions and location. Selecting dungeons collapses the story through `SpokenPlaces:SetMapPanelCollapsed(true)`; selecting the story closes preparation and reopens the story. No Spoken files are edited. The existing collapsed preference reflects that selection. Closing the map collapses both companion panels. Reopen either panel from its tab.
- Recommended dungeon ranges appear in the browser and selected dungeon title. A matching native LFG recommendation takes precedence for RFC, WC, and SFK. Fallback bands are RFC 13–18, WC 17–24, SFK 22–30, BFD 24–32, RFK/Gnomeregan 29–38, Scarlet Monastery 30–46, and RFD 37–46. Scarlet Monastery is one checklist covering all four wings. These Classic Era bands are not confirmed for Forever and are separate from quest minimum levels and entrance restrictions. Reference: [ForeverChanges dungeon guide](https://foreverchanges.pro/dungeons).
- New Forever coverage: Ruins of Lordaeron (15–20), The Hall of Thanes (13–18), Excavation Site: Wetlands (24–29), and City of Dalaran (28–33). These recommendations use [Blizzard's published ranges](https://us.forums.blizzard.com/en/wow/t/krol%E2%80%99dok-stronghold/2349672), separately from quest eligibility. The linked community guide currently gives a different Excavation range; this addon uses the primary Blizzard announcement.
- Custom pickup and entrance markers keep hover input and route clicks through Blizzard's map canvas click handler. The map handles click-versus-drag detection; deferred actions run after Spoken's story click hook. Controller activation uses the entrance pin's click method. `/qs` reports map-click input and entrance activation counts. Long row titles wrap, header/list gutters align, and there are no footer hints. The user confirmed working map clicks and the latest tooltip appearance before this data expansion.
- Plain left clicks over an entrance also have a deferred input fallback for a covering map layer. Native dungeon/area-POI markers resolve by exact supported dungeon identity, including when their client coordinates differ from the exported marker. The fallback requires map focus, excludes drags/modifiers/other windows, and suppresses duplicate activation after a working Button click. This response to the reported zero-activation result needs live verification.
- The map filter contains toggles only; dungeon navigation uses the side tab. Addon-owned UI strings use colons, commas, parentheses, and simple hyphens rather than dot or en/em-dash separators.
- Instance quests are organized into **In Your Quest Log**, **Pick Up Before Entering**, **Pick Up Inside the Instance**, **Prerequisite Chains**, **Not Yet Available**, and **Completed**. Dungeon cards show loading-screen artwork with level ranges and completed/total progress overlaid. Chains show their ordered steps and completed history in single-line rows. Hover a step for its pickup and detailed status. Available pickups navigate directly and accepted quests open native quest details.
- Added Uldaman (41–51), Zul'Farrak (44–54), Maraudon (46–55), Sunken Temple (50–60), Blackrock Depths (52–60), Blackrock Spire (55–60), Dire Maul (54–60), Scholomance (58–60), and Stratholme (58–60). These are Classic Era fallback recommendations, unconfirmed for Forever. Spire and Dire Maul combine their wings. Shared Blackrock entrance markers open a dungeon choice menu without setting a waypoint. See the generated [dungeon coverage and gaps](docs/dungeon-coverage.md).
- Source-backed pickup additions identify Crest of Lordaeron's container, Titan Relic's boss, Open the Maw's outdoor giver and prerequisite, and the carried blade for The Forging of Quel'Serrar. Rexxie Copperclutch has an area description but no exact coordinates. Legacy Gordok variant 1318 remains explicitly unverified. The source's missing Gnomeregan dependency 2955 remains unknown. No passive location capture is included.
- Known source quest records: RFC 6, Wailing Caverns 9, Shadowfang Keep 3, Blackfathom Deeps 12, Razorfen Kraul 6, Gnomeregan 27, Scarlet Monastery 8, and Razorfen Downs 7. Race/class filters remove incompatible quests, including those above the player's level. Source counts include faction variants, prerequisite steps, and repeatable variants, and do not establish complete live Forever coverage. Membership resolves alternate area IDs, including RFK's 1717 and Gnomeregan's 133.
- Inside pickups include Maur Grimtotem in RFC, Willix in RFK, Vorrel in Scarlet Monastery, and item/object starters in other supported instances. Cross-instance pickups retain their actual location: **An Unholy Alliance** in RFD preparation identifies its Small Scroll source inside RFK.
- The four Forever additions retain 13 Lordaeron, 4 Hall, 14 Excavation, and 10 Dalaran records before faction filtering. Hall's **An Ancient Grudge** and **Important Heirlooms** receive documented both-faction corrections supported by player reports; Ghostly Attendant is inside Hall, while Thom Filch retains the source Ironforge coordinates. Dalaran includes its outdoor-sorted quests with inside objectives. Missing pickup locations remain explicit rather than being guessed.
- Preparation includes pickups independently of general map-pin coverage. An inside-dungeon pickup is labelled with its dungeon and never assigned invented coordinates. Class/race restrictions and missing data remain explicit. AND/OR prerequisite semantics remain distinct.

The data build applies upstream Forever corrections for Horde and checks all nine class profiles. Shared map/location data must match; differing quest rows are stored as compact class deltas and applied for the current class. The build verifies that every delta reconstructs its complete source export byte for byte. No upstream runtime or binary is included in the addon.

Offline behavioral, Lua syntax, XML parsing, and TOC checks pass. The user confirmed pickup rendering, overlap handling, and native filters working in game on 0.1.2. The new dungeon panel's layout, pickup navigation, expansion, and live quest-state updates are **pending in-game validation**. Holiday boundary behavior and settings persistence have not been independently established in game. See [the gameplay checklist](docs/testing.md).

### Build and test (PowerShell 7)

```powershell
git clone https://github.com/Questie/QuestieDB.git work/QuestieDB
git -C work/QuestieDB checkout aa1d7e7294596cf50a6fd0946dfae0d969cb9623
./tools/build.ps1
./tools/test.ps1
./tools/deploy.ps1 -WhatIf
./tools/deploy.ps1
```

The build uses the upstream checkout's checksum-pinned Lua 5.1 interpreter offline. The generated data and required notices are already included, so installing the addon does not require upstream tooling.

The deploy script writes only `QuestsStarts` beneath the specified AddOns directory, verifies copied hashes, and refuses an existing folder without its ownership marker. It does not remove other addons or edit SavedVariables. Change its destination with `-AddOnsPath` for an isolated test installation.

### GitHub releases

Publish only when the repository owner explicitly requests a release. Commits and pushes are independent of this process.

For a release, select **Actions → Release QuestsStarts → Run workflow** on `master` and enter the manifest version and user-visible release notes. The workflow checks the version, rebuilds the pinned quest data, checks the packaged files against the selected commit, and runs the offline tests. It publishes the ZIP and `release.json` on a stable release tagged `v<version>`. For updates, use a version higher than the previous release.

To verify the package locally, run `./tools/package.ps1` with PowerShell 7. It writes both files to `dist/v<version>/`. The addon's `X-GitHub` metadata gives AddonUpdater the repository URL, and `release.json` tells it which ZIP matches WoW Forever.

In game, use the dungeon side tab or a dungeon entrance marker. `/qs dungeon` remains an alternate entry point; the native map filter menu controls marker visibility. `/qs` reports pickup diagnostics, entrance counts, and entrance activations; `/qs off` and `/qs on` toggle quest-giver markers; use the map filter to toggle item-source markers independently. No quest is accepted, abandoned, or completed by the addon.

### Current limitations

- Dedicated raid entrances and raid preparation checklists are not included. Ordinary eligible quest-start pins can include raid-related quests, and dungeon prerequisite chains can refer to raid steps.

- Horde characters only; continent overview maps, instance interiors, battlegrounds, and world areas absent from the mapped export do not receive general pickup pins. Three configured maps have no source locations, as listed above. At higher player levels, enable native **Low level quests** to inspect an unvisited starting zone. Missing source coordinates and eligibility requirements remain gaps even on populated maps.
- Dungeon preparation/entrance markers cover the twelve documented instances. Membership comes from source dungeon categories, aliases, and the reviewed local corrections, so unclassified or missing quests may be absent. Entrances are projected onto parent maps only when the client supplies a valid rectangle.
- Item-started quest markers cover recorded NPC drops and object/container sources, including nested containers, on supported world maps. Each source has one recorded spawn per map; this is a source location, not a guaranteed drop or an inferred area center. Vendor purchases, reward-only items, unrecorded sources, phased points, and invalid coordinates are omitted. Inside-instance sources remain in preparation lists.
- Specialization, spell, unclassified event requirements, and unavailable profession/reputation state remain unverified and hidden by default. Opt-in uncertain markers do not establish eligibility. Identified seasonal pickups remain hidden until their holiday is confirmed active.
- Completed repeatable quests are conservatively hidden; daily/reset availability is not implemented.
- English fallback UI/data only for now; cached native quest titles use the client's locale. Holiday names are matched to the English server calendar; unrecognized/localized or unavailable holiday data stays hidden. Other translations and localization QA remain open.
- Source data may omit new Forever quests or retain inaccurate locations/requirements. No claim of complete coverage.
- SavedVariables persistence and initial addon discovery need verification on the installed client.

Source references for native integration: Blizzard's Forever [map pin lifecycle](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_MapCanvas/Blizzard_MapCanvas.lua), [quest-offer pins](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedMapDataProviders/QuestOfferDataProvider.lua), and [map filter menu](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_WorldMap/Blizzard_WorldMapTemplates.lua).
