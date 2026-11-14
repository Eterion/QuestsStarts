# Empty-map audit

Reviewed 2026-11-08 against QuestieDB `aa1d7e7294596cf50a6fd0946dfae0d969cb9623`. The Source-mode reader applied Forever/Horde corrections. The audit examined all quest categories and every NPC/object quest-starter spawn using the same corrected area-to-map relationships as the exporter. These are source findings, not live-client availability claims.

| Map | Source quests filed under this map | Recorded quest-starter positions on this map | Finding |
| --- | ---: | ---: | --- |
| Mount Hyjal (2482) | 0 | 0 | No quest-start coordinates can be exported from this snapshot. |
| Deadwind Pass (1430) | 0 | 0 | No quest-start coordinates can be exported from this snapshot. |
| Riverglades (2548) | 1 | 0 | The single filed quest is Remember That I Love You (95161). Its recorded starter is Orphan Matron Nightingale in Stormwind, not Riverglades. A quest's category does not establish its pickup location. |

The absence of source records does not establish that an area has no active quests in the current game. No coordinates were inferred from zone centers, entrances, or quest objectives.

The broader [Riverglades](https://forever-tool.com/en/quests/zone/16591/) and [Hyjal](https://forever-tool.com/en/quests/zone/616/) public quest catalogs contain additional titles, but do not provide the quest-giver coordinates needed for pins. Their [quest-record explanation](https://forever-tool.com/en/quests/97006/) distinguishes catalog fields from unavailable location details. The configured maps remain source gaps. Per the user's preference, no passive in-game location capture is added.

## Darkspear Islands classification

Darkspear Islands (2524) was mistakenly included as an overworld empty map in 0.9.0. [Blizzard's own preview](https://news.blizzard.com/en-gb/article/24307308/battle-for-the-darkspear-islands-in-world-of-warcraft-forever) identifies it as a battleground and places its quest pickups at the faction bases in the Barrens. The source files 18 quest rows under this category, which does not mean those quests start on the battleground map. It is excluded from general overworld coverage in 0.9.1. This does not add battleground-specific pin support or claim the current export has coordinates for every faction-base giver.

## Reviewed upstream update

The five commits between the original pin and `aa1d7e7` change quest/NPC correction files, with no emulator or interpreter changes. [The upstream comparison](https://github.com/Questie/QuestieDB/compare/5fba5d86641d1a64a787884e28e15ee16b115060...aa1d7e7294596cf50a6fd0946dfae0d969cb9623) includes Silverpine prerequisites, class restrictions, and NPC positioning fixes. The exported addon data changes prerequisite/class fields and gains two dependency records; its 1,464 pickup positions remain unchanged. All nine class profiles are reconstructed and verified during the build. Local Hall of Thanes corrections remain separate and were retained after review.
