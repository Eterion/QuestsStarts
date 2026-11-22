# Class restriction audit — 20 November 2026

Scope: the entire bundled dataset, not a reported quest. All nine supported class
profiles reconstruct 4,441 quest rows. Comparing every row with the pinned
QuestieDB source (including local overrides) found no class masks lost during
export; each profile initially retained 690 quests with explicit class restrictions.

`tools/audit-classes.lua` performs that independent source comparison. Run it from
`work/QuestieDB`, passing the project root, class token and class ID, like the
exporter. Repeat for WARRIOR/1, PALADIN/2, HUNTER/3, ROGUE/4, PRIEST/5, SHAMAN/7,
MAGE/8, WARLOCK/9 and DRUID/11. The source revision remains pinned by
`tools/upstream-revision.txt`.

`tests/class-restrictions.lua` reloads the actual class-specific dataset for each
profile, checks all recorded class exclusions, and scans all 50 maps with
unverified pickups both enabled and disabled. NPC, object and item starts share
this path. Fixtures also cover class-only chains and collection items.

Two runtime bypasses were corrected:

- An unknown race previously returned an unknown result before checking a known
  class mismatch. Unverified pickups could therefore reveal the wrong-class quest.
  Unknown identity data now defers to definite exclusions.
- The carried-library-book shortcut could replace a known class/race exclusion
  with an eligible result. Carrying the item now preserves those exclusions.

## Source limitations

This verifies enforcement of recorded restrictions. It does not establish that
the source records every server restriction. In particular, six quests have a
class quest category but no class mask:

| Quest | Category | Review result |
| --- | --- | --- |
| 8249 Junkboxes Needed | Rogue | Deliberately cleared to all classes by `src/corrections/Forever/legacy/classicQuestFixes.lua`; retain this exception. |
| 93797 Boughs in the Wind | Mage | Missing class mask in source; server class eligibility unverified. |
| 98341 The Great Windborne Cat Spirit | Druid | Missing class mask in source; server class eligibility unverified. |
| 98404 The Great Windborne Cat Spirit | Druid | Missing class mask in source; server class eligibility unverified. |
| 98517 Call of Fire | Shaman | Missing class mask in source; objectives explicitly describe shaman training, but the server restriction is not recorded. |
| 98738 Blessings of the Great Windborne Cat Spirit | Druid | Missing class mask in source; server class eligibility unverified. |

The five unresolved records remain unchanged. A class category alone is not used
as an eligibility rule: doing so would incorrectly hide the documented all-class
Junkboxes quest. Restrictions missing from both a class mask and a class category
cannot be discovered by this consistency audit. Live server verification remains
necessary before claiming universal coverage or that the original report is fixed.

## Capture a remaining failure

The owner reported that the first fixes did not resolve the observed marker.
The original issue therefore remains unresolved; passing the audit is not proof
that the displayed quest is correct.

With the affected map open, `/qs diagnose` refreshes the actual markers and saves
one whole-map snapshot in `QuestsStartsDB.mapDiagnostic`. Run `/reload` afterward
to write it to the addon's SavedVariables file. The snapshot records the build,
map, raw class/race IDs and masks, filters, quest data, eligibility decisions,
and whether each quest is shown by QuestsStarts or Blizzard's native offer pins.
Hidden candidates and native offers missing from the bundled data are included.
It records no character/account names. Another successful capture replaces it;
an unsupported map does not overwrite the previous snapshot.

## Captured failure and expanded audit

The subsequent build `0.16.0-dev.20` capture identified map 1442 (Stonetalon),
level 26, Mage/class ID 8/mask 128. QuestsStarts rendered Goblin Lockpicks (78270)
as available. Its sparse Forever record had no class mask or category; the
detected player class was correct. This was not the unknown-race bypass.

The pinned `src/corrections/Sod/sodBaseQuests.lua` records a Rogue class mask.
`src/corrections/Sod/sodQuestFixes.lua` independently retains that class and records
`parentQuest=78261` (The Horn of Xelthos). The local override now restores mask 8,
the active parent requirement, and the Rogue quest category. The generated data
now contains 691 explicitly class-restricted quests. Regression checks exercise
the actual Stonetalon marker pipeline for all nine classes, both with and without
the parent active, including the captured level-26 Mage case.

The earlier audit compared the export to its immediate source and inspected
class categories; it could not detect this omission in both fields. The build
now also runs `tools/audit-inherited-classes.lua` against the independent Era/SoD
view of the pinned source. It compares 648 matching class-restricted records and
records all 49 remaining mask differences in `docs/inherited-class-audit.md`.
Some represent intentional Forever changes. They are review candidates, not
proof of 49 bugs, and are not automatically assigned another expansion's rules.
The captured failure is corrected in data and reproduced in offline map tests;
the deployed result still requires in-game confirmation. Universal source
completeness remains unproven.

## Disposition of all 49 inherited differences

The follow-up review is complete at the data-handling level; every one of the
49 entries now has an explicit, enforced decision in `tools/class-gate-reviews.lua`.
See [the evidence and confidence notes](class-gate-decisions.md) and the generated
[per-quest disposition table](inherited-class-audit.md).

- 42 library records and Anyone Can Cook remain deliberately shared across classes.
- All three Earthmother records retain no class gate but are corrected to Tauren
  using the subsequent upstream race fix.
- Three Dragonslayer records are quarantined behind Include Unverified Pickups.
  Their actual server eligibility is still unconfirmed; normal markers no longer
  claim that they are available.

The audit fails for new unreviewed inherited differences, changed source class
masks, or regressions in any reviewed field. Runtime checks cover every disposition
for all nine classes, Earthmother progression across races and the Dragonslayer
default/opt-in distinction. This does not resolve the separate five class-category
records listed earlier, nor establish unknown Dragonslayer server facts.
