# Local Forever data corrections

Originally reviewed 2026-11-07 against QuestieDB `5fba5d86641d1a64a787884e28e15ee16b115060`; rechecked and retained on 2026-11-08 against the updated pin `aa1d7e7294596cf50a6fd0946dfae0d969cb9623`. These factual corrections live in `tools/forever-overrides.lua` and are applied offline to every class export. Upstream tracked files are not locally edited. Generated data should not be edited manually. Player reports are evidence, not an independent live-client test by this project.

The class eligibility follow-up is recorded separately in
[class-gate-decisions.md](class-gate-decisions.md): the 49 inherited class-mask
differences have explicit handling, with three Earthmother race corrections,
shared library/cooking exceptions, and three quarantined Dragonslayer entries.
Their fields are applied by the same local override pipeline.

## Hall of Thanes

The pinned `foreverQuestFixes.lua` marks An Ancient Grudge (96395) Alliance-only with the comment “not sure if horde can get this quest”. It also has no dungeon sort or starter. Player reports on [An Ancient Grudge](https://www.wowhead.com/forever/quest=96395/an-ancient-grudge) and [Ghostly Attendant, NPC 265002](https://www.wowhead.com/forever/npc=265002/ghostly-attendant) describe both-faction access and a giver inside Hall of Thanes. [ForeverChanges' observed Hall quest list](https://foreverchanges.pro/dungeons/hall-of-thanes) also lists this quest for both factions, from level 10. The override sets all-race access, minimum level 10, dungeon membership, and that inside starter. It supplies no coordinates.

The pinned source marks Important Heirlooms (96403) and its neutral giver as Alliance-only. First-person comments on [Important Heirlooms](https://www.wowhead.com/forever/quest=96403/important-heirlooms) report Horde access; the observed Hall quest list independently places it under both factions. The override removes its race restriction and retains its known Thom Filch starter even though the NPC faction flag would otherwise exclude it. Name, level and Ironforge coordinates remain from QuestieDB. Other Alliance-only Hall quests retain their restrictions.

## City of Dalaran membership

Friend of the Kirin Tor (92459) and Shrewd Negotiations (97287) use the outdoor Alterac Mountains quest sort. Their pinned source objective text explicitly requires speaking with Archmage Celindra inside City of Dalaran. Both are therefore associated with that dungeon. Original faction restrictions, prerequisite fields, and outdoor pickup locations remain unchanged. This is quest association, not an assertion that the quest is picked up inside the instance.

## Interior sub-areas

The exporter resolves the source's `subZoneToParentZone` and override tables to recognize named interior sub-areas under a supported dungeon. Explicit alternate dungeon IDs take precedence over outdoor ancestry. This preserves inside labels without using an entrance as a quest pickup coordinate.

## Reviewed pickup additions (0.10.0)

- **Crest of Lordaeron (95204):** the pinned item links to object 614679 inside Ruins of Lordaeron. The exporter now follows object drops as well as NPC drops and nested item containers. This requires no local coordinate correction.
- **Elder Knowledge (95664):** the source links Titan Relic (270866) to Relic Guardian (260326), but the NPC has no spawn coordinates. The [NPC record](https://www.wowhead.com/forever/npc=260326/relic-guardian) places the boss in Excavation Site: Wetlands; [quest reports](https://www.wowhead.com/forever/quest=95664/elder-knowledge) describe the boss item starter. The correction supplies only an inside association.
- **Open the Maw (95682):** the [original dungeon guide](https://www.warcrafttavern.com/forever/guides/excavation-site-wetlands-quests/) records Deathstalker Agent in Wetlands at 51.4, 59.2 and Dragonmaw Rumors (95663) as prerequisite. [Quest reports](https://www.wowhead.com/forever/quest=95682/open-the-maw) corroborate the preceding Zaruk step. This source-backed correction also adds the outdoor giver to the regular map export.
- **Opportunistic Education (96987):** [quest text](https://www.wowhead.com/forever/quest=96987/opportunistic-education) identifies Rexxie Copperclutch near the sewer entrance. The pinned NPC identity is 268743. The [authored Dalaran guide](https://mobalytics.gg/wow-forever/profile/phaseshifter/dungeons/the-city-of-dalaran-bosses-loot-and-quests) places that entrance in Alterac Mountains. Only the area and description are stored; exact coordinates remain unknown and navigation is unavailable.
- **The Forging of Quel'Serrar (7508):** pinned quest metadata identifies A Dull and Flat Elven Blade (18513) as starter and Nostro's Compendium (7507) as prerequisite. The UI identifies the carried item from that step rather than inventing an outdoor giver.
- **Unfinished Gordok Business (1318):** this legacy alternate has no source starter or finisher. [Historical firsthand reports](https://www.wowhead.com/forever/quest=1318/unfinished-gordok-business) identify Captain Kromcrush inside Dire Maul. Its availability in Forever is unconfirmed, so the correction explicitly marks this variant unverified. The normal 7703 variant keeps its existing source metadata.

## Added dungeon aliases

Blackrock Depths and Spire include the source's Forever root areas 17803 and 17804. Dire Maul includes the source's wing areas 10022 through 10027. These extend the provider's canonical/alternative IDs and interior ancestry; they do not convert outdoor parents to inside pickups. Blackrock's shared entrance position opens a choice menu without creating a waypoint.

## Remaining gaps

The source references absent quest 2955 among the alternative prerequisites for Gnomeregan 4604. That step remains unknown, without a replacement ID or invented pickup. Rexxie's exact point and legacy variant 1318 remain qualified as above. Riverglades, Mount Hyjal, and Deadwind Pass still have no reliable pickup coordinates. The addon uses source-only data and does not collect locations during play. Recommendations use the published ranges linked from the README and do not set quest eligibility. The generated dungeon-coverage.md audit includes transitive dependencies.

## Apothecary Society Primer

QuestieDB lists (59.4, 52.3) and (59.5, 52.3) for the same book object in Brill. Both guides describe the same alchemy shop shelf. The export keeps (59.5, 52.3). [Method](https://www.method.gg/wow-forever/wow-forever-all-library-books-locations-and-rewards) · [Warcraft Tavern](https://www.warcrafttavern.com/forever/guides/library-books/)
