# Performance review — 22 November 2026

Measured with the pinned Lua interpreter using `tools/benchmark.lua`. These are
offline CPU and Lua allocation measurements, not live WoW frame rates, addon
memory totals or GPU/rendering costs. The representative workload is an Undead
Mage at level 60 with low-level and unverified pickups enabled, no completed or
active quests, and no carried quest items. Feralas is the largest eligible map
under this configuration, with 99 pickup groups.

| Operation | Before, ms/call | After, ms/call | Before, KiB allocated/call | After, KiB allocated/call |
| --- | ---: | ---: | ---: | ---: |
| Build map pickup groups | 0.291 | 0.132 | 142.74 | 84.38 |
| Cluster the actual map | 0.343 | 0.136 | 12.12 | 14.31 |
| Combined grouping + clustering | 0.634 | 0.268 | 154.86 | 98.69 |
| Synthetic 1,000 sparse points | 29.833 | 1.800 | 267.02 | 283.22 |

Figures are representative single-run observations on this machine, rounded;
repeat runs vary. Combined pure-Lua work is approximately 58% faster and produces
36% less transient allocation in this workload. The coordinate sweep allocates
an extra sorted index array; that small allocation increase is explicit in the
clustering rows. It avoids the much larger CPU cost of all-pairs comparisons.

## Changes

- Base quest eligibility is evaluated once per unique quest during one map
  build (61 evaluations instead of 152 in the representative workload). The
  memo lasts only for that call; character changes, quest completion and filters
  cannot reuse a stale evaluation. Source-specific transformations still happen
  individually for item, object and NPC sources.
- Constant field lists and an immutable empty iterator table are reused, and
  dependency evaluation no longer creates a closure for every quest. Empty pin
  groups are allocated only if a source has a visible quest.
- Clustering sorts indices along the axis with the widest displayed span and
  stops comparing points once the axis distance exceeds the radius. The original
  distance formula, transitive components, first representative, group ordering
  and input order are preserved. Dense coincident points remain worst-case
  quadratic; this is not a universal asymptotic speed guarantee.
- Hidden maps schedule no quest refreshes, and pending work is discarded if the
  map closes before the timer fires. Reopening schedules a fresh update. Closing
  releases marker groups and player-snapshot closures from Core's diagnostic
  state; explicit `/qs` status/diagnostic requests still refresh when requested.
- The review also corrected the zone checklist's handling of zero class/race
  masks. Zero means unrestricted, consistent with map eligibility and the shared
  library quests, rather than a mask that excludes everyone.

## Verification and limits

The clustering implementation is compared with an independent all-pairs oracle
for every bundled map at two sizes, randomized point sets, exact boundaries,
duplicate points and degenerate dimensions. Eligibility tests cover repeated
sources, unknown results, changed player state and independent source filters.
Lifecycle regressions cover hidden events, discarded timers and fresh reopening.
The existing quest/class, dungeon, source-data and map-tile checks also pass.

No long-lived eligibility cache was introduced. The generated dataset already
shares most data between class profiles; it was not rewritten for speculative
memory savings. UI frame pools, texture residency and actual in-game CPU/retained
memory still require client profiling before making claims about those costs.
