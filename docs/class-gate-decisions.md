# Dispositions for the 49 inherited class differences

Reviewed 20 November 2026. The complete ID lists and applied fields live in
`tools/class-gate-reviews.lua`. This review concerns the 49 Era/SoD-versus-Forever
differences, not a claim that all server restrictions are known.

## Library: 42 intentional shared quests

Keep class mask zero for the book donations and library reward quests. Forever
expanded this system to every class; restoring the old Mage mask would break
legitimate collection and turn-ins. The [Forever library quest's first-person
Druid completion report](https://www.wowhead.com/forever/quest=78150/friend-of-the-library)
documents non-Mage collection and turn-in. The [Forever library system guide](https://www.wowhead.com/forever/guide/library-book-locations-and-rewards)
explicitly describes all-class access and distinguishes the Mage-only Study
ability from the shared collection rewards. The pinned Forever source replaces
the old class category and uses the faction librarians for these records.

The review preserves quest prerequisites, completion, item ownership and other
filters. Shared access does not mean every book or reward is immediately available.

## Earthmother: three race corrections

For 76156, 76160 and 76240, preserve class mask zero and set the race mask to
Tauren (32). Do not restore the old Shaman mask. The upstream fix in
[QuestieDB commit 26050f4cc1153961646ac00995362991826a91f2](https://github.com/Questie/QuestieDB/commit/26050f4cc1153961646ac00995362991826a91f2)
changes all three steps to Tauren-only. It closes the
[actual wrong-character marker report](https://github.com/Questie/Questie/issues/8356).
The [quest page's Tauren Druid acceptance report](https://www.wowhead.com/forever/quest=76156/stalk-with-the-earthmother)
also disproves Shaman-only access. Existing prerequisite links remain intact.

This applies the specific reviewed fix locally; the pinned QuestieDB revision
and unrelated upstream data remain unchanged.

## Anyone Can Cook: one intentional shared quest

Preserve class mask zero for 79624. The [Forever quest page](https://www.wowhead.com/forever/quest=79624/anyone-can-cook)
has a first-person report of all-class drops and describes the changed cooking
chain and cosmetic weapon reward. Its Forever entry has no Warrior restriction;
the old SoD mask belongs to a different reward context. Minimum level and other
eligibility checks remain in force.

## Dragonslayer: three quarantined records

For 78132, 78133 and 78134, set `sourceUnverified=true`. These are **not confirmed
all-class or Warrior-only**. The [upstream report](https://github.com/Questie/Questie/issues/8264)
describes three misleading Hunter markers and an absent Alonso; it has no
maintainer resolution or acceptance evidence. The [Helm](https://www.wowhead.com/forever/quest=78132/dragonslayers-helm),
[Shield](https://www.wowhead.com/forever/quest=78133/dragonslayers-shield) and
[Lance](https://www.wowhead.com/forever/quest=78134/dragonslayers-lance) pages
establish records, not proof that the giver currently offers them. Their absence
of a class field is insufficient to resolve that uncertainty.

Consequently these entries no longer produce normal/default available markers.
They appear only with Include Unverified Pickups enabled, using the existing
uncertain marker treatment. A live acceptance report or authoritative eligibility
fix is still needed to replace quarantine with a definite rule. Quarantine is an
explicit operational disposition, not a claim that their server restrictions
have been discovered.

## Enforcement

The exporter applies all reviewed fields to every class dataset. The inherited
audit checks each ID, original class evidence and exported review fields. A new
unreviewed difference or a changed reviewed field fails the build. Runtime tests
cover all 49 dispositions across all nine classes, Earthmother's race/chain
gates, and both default and opt-in Dragonslayer markers.
