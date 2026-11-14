# Dungeon source coverage

Generated from QuestieDB `aa1d7e7294596cf50a6fd0946dfae0d969cb9623` with reviewed local corrections. Counts include faction/class variants and repeatable steps before character filtering; they do not establish complete live Forever coverage.

| Dungeon | Area ID | Source quest records |
| --- | ---: | ---: |
| Blackfathom Deeps | 719 | 12 |
| Blackrock Depths | 1584 | 41 |
| Blackrock Spire | 1583 | 37 |
| City of Dalaran | 16544 | 10 |
| Dire Maul | 2557 | 37 |
| Excavation Site: Wetlands | 16732 | 14 |
| Gnomeregan | 721 | 27 |
| Maraudon | 2100 | 11 |
| Ragefire Chasm | 2437 | 6 |
| Razorfen Downs | 722 | 7 |
| Razorfen Kraul | 491 | 6 |
| Ruins of Lordaeron | 16611 | 13 |
| Scarlet Monastery | 796 | 8 |
| Scholomance | 2057 | 12 |
| Shadowfang Keep | 209 | 3 |
| Stratholme | 2017 | 16 |
| The Hall of Thanes | 16919 | 4 |
| The Temple of Atal'Hakkar | 1477 | 9 |
| Uldaman | 1337 | 29 |
| Wailing Caverns | 718 | 9 |
| Zul'Farrak | 1176 | 10 |

21 dungeon groups, 321 membership records. Blackrock Spire and Dire Maul combine their wings.

## Pickup gaps and qualifications

This pickup audit covers Horde-compatible records and their dependencies; Alliance-only rows intentionally have no pickups in this Horde export.

- 2955: quest record missing; no supported pickup source.

The missing 2955 record is referenced by the upstream prerequisite alternatives for Gnomeregan quest 4604. It remains an unknown step; no replacement quest or position is inferred.

Rexxie Copperclutch (96987) has an Alterac Mountains sewer-entrance description, without exact coordinates or navigation. Legacy Dire Maul variant 1318 has a historically reported inside giver but remains explicitly unverified for Forever. Item steps and inside pickups are labeled by their actual source rather than assigned entrance waypoints. See [reviewed corrections](data-corrections.md).

Riverglades, Mount Hyjal, and Deadwind Pass still lack reliable world-map pickup coordinates; see [the source audit](coverage-gaps.md). This build uses source-only data and adds no passive location capture. Other new Forever dungeons without sufficient source metadata remain unsupported.
