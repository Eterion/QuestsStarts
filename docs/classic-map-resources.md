# Existing Blizzard maps for Classic dungeons

These corrections reuse existing Blizzard parchment map sheets. No Atlas art,
newly drawn map, generated artwork or replacement renderer is used.

| Dungeon | Resource correction |
| --- | --- |
| Wailing Caverns | Bundle the pre-4.1 Blizzard twelve-tile sheet, including the Winding Chasm |
| Blackrock Spire | Bundle the original seven Blizzard sheets, preserving both wings and restoring the Stadium sheet |
| Shadowfang Keep | Keep the existing Blizzard sheets; name the last menu entry Arugal's Chamber |

The source archive is [Trimitor/WDM-patch commit 5e7e9d1](https://github.com/Trimitor/WDM-patch/tree/5e7e9d1957211f40c9636a9f417901d153b40d4d/Stable/enUS/Interface/WorldMap).
Its [published history](https://www.wowmodding.net/topic/1167-dungeon-maps-for-wrath-of-the-lich-king-patchauthor-trimitor/)
identifies its Wailing Caverns set as the older map from before 4.1 and its
Blackrock Spire set as the 4.3.4 version. Blizzard's own
[4.1 patch notes](https://worldofwarcraft.blizzard.com/en-gb/news/9984237)
confirm the subsequent Wailing Caverns maze removal.

`addon/QuestsStarts/Maps/ClassicBlizzardSources.json` pins all 96 source URLs,
upstream Git blob IDs and SHA-256 hashes. Imported files were checked against
the upstream blob IDs and copied without conversion or alteration. This verifies
identity with the archive, not an independently authenticated copy of each original
Blizzard release. The archive also includes community additions and corrections;
only the existing Wailing Caverns and Blackrock Spire sheets described here were
selected. No executable, WDM Lua code or MPQ client patch is installed.

## Blackrock Spire floors

The seven sheets predate the later separation of Upper Spire artwork. Some
elevations contain rooms in both wings. The addon's existing combined Spire
checklist therefore keeps one floor menu:

| Menu entry | Original sheet | Detected subzones |
| --- | --- | --- |
| Hall of Blackhand | 4 | Hall of Blackhand |
| Hordemar City | 3 | Hordemar City |
| Skitterweb Tunnels | 2 | Skitterweb Tunnels |
| Tazz'Alor | 1 | Tazz'Alor |
| Halycon's Lair / Dragonspire Hall | 5 | Halycon's Lair, The Storehouse, Dragonspire Hall |
| Chamber of Battle / Hall of Binding | 6 | Chamber of Battle, Hall of Binding, The Rookery |
| Blackrock Stadium | 7 | Blackrock Stadium, The Furnace, Spire Throne, The Molten Span |

Recognized subzones take precedence over a shared dungeon UiMapID. No UiMapID
was invented for the old Stadium sheet. The floor menu remains available when
the client cannot identify the player's floor. Manual browsing still lasts until
the detected floor changes. No player coordinates are inferred.

## What the recheck corrected

The earlier audit understated the retained original Spire art: sheet seven exists,
and older sheets five and six include Dragonspire Hall, Hall of Binding and the
Rookery. These are now restored together rather than adding modern WoD Upper Spire
maps. The earlier suggestion that Shadowfang's Godfrey name was baked into its
artwork was also incorrect: it was an addon floor-menu label. Its map artwork
does not need replacement to correct that name.

Ragefire Chasm, Razorfen Kraul and Scholomance retain their existing bundled old
art. Deadmines and Maraudon retain their existing Blizzard maps; no replacement
was justified by a newly verified layout difference in this pass. Encounter
washes in retained client maps can still reflect later game versions.

## Sunken Temple limitation

The existing Blizzard main sheet is retained. The archive's extra floors are
explicitly described by its author as a **fan implementation**, with recreated
Blizzard-style artwork by Yuritsuki, in the 20 May 2021 update linked above.
Those are excluded because this task calls for existing Blizzard maps. This pass
found no verified Blizzard-authored additional sheets for the original lower
statue/Atal'alarion level and upper troll-balcony level. This is a remaining
source gap, not a claim that all possible archived Blizzard assets were exhausted.

## Validation

- Decode the selected BLP tiles and inspect the assembled 1003 by 668 previews.
- `tools/test.ps1` checks all imported tile hashes, 256 by 256 BLP2 dimensions,
  floor registration and subzone selection, plus the existing regression suite.
- Deploy with `tools/deploy.ps1`, then `/reload` and check `/qs` in game.
- Live checks: preview WC and its Winding Chasm; browse all seven Spire floors;
  verify automatic selection in Dragonspire Hall, the Rookery, Stadium and a
  Lower Spire room. Zoom, drag, movement fade and right-click navigation should
  retain the existing native-map behavior. Offline tests do not establish live
  appearance or API floor reporting.
