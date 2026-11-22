# Third-party data

Generated pickup data is derived from Questie/QuestieDB, pinned at
`aa1d7e7294596cf50a6fd0946dfae0d969cb9623`:
https://github.com/Questie/QuestieDB/tree/aa1d7e7294596cf50a6fd0946dfae0d969cb9623

Credit: QuestieDB and the Questie contributors, including Muehe, TheCrux/BreakBB,
Drejjmit, Dyaxler, Cheeq, TechnoHunter, Yttrium, Logonz, and the other contributors
identified by the upstream project.

The upstream licensing statement permits copying under GPLv3 terms while expressly
describing unresolved historical contributor coverage. This project preserves that
statement rather than asserting all upstream data has an uncomplicated blanket license.
See `Licenses/QuestieDB-LICENSE.md`, `Licenses/QuestieDB-PROVENANCE.md`, and
`Licenses/GPL-3.0.md`. The Questie name and logo are not reused as this addon's branding.

Transformation: the upstream Source-mode reader applies Forever static corrections and
Horde/class-dependent dynamic corrections offline. The exporter retains NPC/object
pickup candidates from the configured Classic world-zone/city maps and four mapped
Forever areas, their coordinates, selected requirements, and the transitive
quest dependencies needed for filtering. Dungeon membership comes from `zoneOrSort`
and the provider's canonical/alternative dungeon area IDs. Supported dungeons are
Ragefire Chasm, Wailing Caverns, Shadowfang Keep, Blackfathom Deeps, Razorfen Kraul,
Gnomeregan, Scarlet Monastery, Razorfen Downs, Ruins of Lordaeron, The Hall of Thanes,
Excavation Site: Wetlands, City of Dalaran, Uldaman, Zul'Farrak, Maraudon, The Temple of Atal'Hakkar, Blackrock Depths, Blackrock Spire, Dire Maul, Scholomance, and Stratholme; dungeon/prerequisite starter locations are retained independently
of the general map-pin coverage. Unlocated in-dungeon starters retain their dungeon
association, without converting the entrance into an asserted pickup coordinate.
The build checks all nine class profiles and
requires identical shared map/location data, stores differing quest rows as small
class-specific deltas, and verifies that applying each delta reconstructs that class's
complete export byte for byte. Only the current class's delta is applied when the data loads. Class eligibility
is evaluated at runtime. No QuestieDB runtime ships.
Dungeon entrances and interior aliases come from the provider's dungeon support table.
Item-started quests with recorded NPC/object drops and nested containers retain that item,
NPC, and dungeon association. No drop probability or outdoor position is invented.
General map pins include item/drop starters with recorded outdoor NPC/object sources, including nested item containers. One recorded point per source/map bounds pin counts; no centroid, drop probability, vendor location, or missing source is inferred. Phased and invalid coordinates are omitted.
The original client-extracted and community-data limitations remain applicable.
The repository's generated docs/coverage.md lists map IDs, counts, and empty source
maps. These are candidates before race/class and other player-state filtering;
presence in the map configuration does not establish complete live availability.

Reviewed local corrections are applied separately from the pinned upstream source.
Hall quests 96395 and 96403 retain both-faction access based on firsthand reports:
https://www.wowhead.com/forever/quest=96395/an-ancient-grudge
https://www.wowhead.com/forever/quest=96403/important-heirlooms
The first uses Ghostly Attendant (NPC 265002) inside Hall without invented coordinates.
Dalaran quests 92459 and 97287 are associated by their upstream inside-objective text,
while retaining outdoor pickups and original faction restrictions. Full evidence and
the source limitations are recorded in the repository's docs/data-corrections.md;
the offline override table is tools/forever-overrides.lua. No upstream files are edited.

The seasonal categories use the pinned `src/corrections/enum/quests.lua` values.
The Tirisfal seasonal associations for quests 1657, 8322, 8827, 8828, 8860, 8861,
and 8902 and their Winter sub-windows were cross-checked against Questie's
`Database/Corrections/Holidays/quests/{HallowsEnd,WinterVeil,LoveIsInTheAir}.lua`.
Active holiday dates themselves come from the live server calendar, not copied annual dates.

Reproduction scripts and the source revision are included in the project repository.

## Classic dungeon maps

The illustrated Ruins of Lordaeron surface uses Blizzard map symbols isolated
from Stratholme's Crusader's Square and Blackrock Depths' Detention Block.
The parchment texture is based on a sample from the Detention Block map.

The unchanged Ragefire Chasm, Razorfen Kraul, and Scholomance map tiles are from
`Media/Dungeons/Ragefire_Old`, `RazorfenKraul_Old`, and `Scholomance_Old` in YanHuo's
[ClassicDungeonMaps Forever release 9567661](https://www.curseforge.com/wow/addons/classicdungeonmaps/files/9567661).
Native map tile paths and floor subzone associations were checked against the same release.
The bundled Wailing Caverns and Blackrock Spire BLP tiles are archived Blizzard
parchment artwork obtained from Trimitor's WDM-patch archive, commit
`5e7e9d1957211f40c9636a9f417901d153b40d4d`:
https://github.com/Trimitor/WDM-patch/tree/5e7e9d1957211f40c9636a9f417901d153b40d4d/Stable/enUS/Interface/WorldMap

Wailing Caverns is the pre-4.1 layout. Blackrock Spire is the original seven-sheet
set, before the later Upper/Lower Spire artwork split. All 96 BLP files are copied
unchanged from the archive. `Maps/ClassicBlizzardSources.json` records their
individual source URLs, upstream Git blob IDs and SHA-256 hashes. The archive is
maintained by Trimitor; the artwork belongs to Blizzard Entertainment. No WDM
runtime or client patch is included or installed. Its fan-created additional
Sunken Temple floors are not included.
The remaining artwork is referenced from the installed client.
World of Warcraft artwork belongs to Blizzard Entertainment.
ClassicDungeonMaps is distributed under the MIT License.

Copyright (c) YanHuo (ClassicDungeonMaps)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
