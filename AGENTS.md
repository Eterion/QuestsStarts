# QuestsStarts development and releases

## Local installs

- Keep the checked-in `## Version` in `addon/QuestsStarts/QuestsStarts.toc` at the latest public version during development.
- After each addon change, run the relevant checks and deploy it with `tools/deploy.ps1` to the WoW Forever AddOns folder. A local install is part of completing the change.
- Give each successful development deployment an incrementing local identifier based on the public version, such as `0.13.24-dev.1` and `0.13.24-dev.2`. Store the identifier only in the local installation and exclude it from release packages.
- Report the exact identifier printed by deployment. After `/reload`, `/qs` should show the build WoW loaded so the player can confirm it matches.
- If the build number support is still missing, report that plainly and use the existing verified deploy script. Do not report a build identifier that WoW cannot show.

## Custom maps for WoW Forever

- For each new map, trace the original client minimap tiles with north up and preserve the positions of routes and landmarks. Use Blizzard dungeon maps as style references for the parchment, labels, and ink. Keep open ground continuous and pale so walls, buildings, and water read as obstacles.
- Keep a layered OpenRaster master and a full-size flattened PNG under `art/`. Separate the parchment base, encounter washes, and marker stamps, and keep a hidden walkable-ground mask. Save a new artwork revision when iterating.
- Clip each encounter wash to the walkable-ground mask. Preserve the floor shading, feather the edges, and give each boss a distinct muted hue. Place client-art skull and entrance stamps at their mapped locations. Spread the skull glow around the ink with a softer center.
- Composite the visible layers at master size. Downsample with Lanczos to the in-game map dimensions, then pad to the tile grid with the map anchored at the top left. Export 256×256 uncompressed 24-bit TGA tiles in row-major order, numbered from 1. Store them under `addon/QuestsStarts/Maps/` and match the floor registration in `DungeonMapData.lua`.
- Inspect the native-size preview for color balance, readable markers, and alignment. Verify the decoded tiles pixel for pixel against the padded preview. Run `tools/test.ps1`, deploy changes to shipped tiles with `tools/deploy.ps1`, and check the new build in game after `/reload`.

Ruins of Lordaeron is the first reference implementation. Use `art/RuinsOfLordaeron-Surface-v9.ora` for the accepted 1536×1024, 17-layer master and `art/RuinsOfLordaeron-prompts.txt` for the illustration and paint passes. Its seven washes use 68% of the v8 opacity, with teal for Rath’mael. Its 1003×668 native render is padded to 1024×768 and exported as `Maps/RuinsOfLordaeron/Surface_1.tga` through `Surface_12.tga`.

## Public releases

- Publish through the manual GitHub Actions workflow only when the owner explicitly requests a release. Commits, pushes, and local installs do not trigger a release.
- Bump the public version once, based on the changes since the last public release. A fixes-only release after `v0.13.24` is `v0.13.25`. A release that includes one or more features is `v0.14.0`. Local deployments do not consume public version numbers.
