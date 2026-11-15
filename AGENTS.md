# QuestsStarts development and releases

## Local installs

- Keep the checked-in `## Version` in `addon/QuestsStarts/QuestsStarts.toc` at the latest public version during development.
- After each addon change, run the relevant checks and deploy it with `tools/deploy.ps1` to the WoW Forever AddOns folder. A local install is part of completing the change.
- Give each successful development deployment an incrementing local identifier based on the public version, such as `0.13.24-dev.1` and `0.13.24-dev.2`. Store the identifier only in the local installation and exclude it from release packages.
- Report the exact identifier printed by deployment. After `/reload`, `/qs` should show the build WoW loaded so the player can confirm it matches.
- If the build number support is still missing, report that plainly and use the existing verified deploy script. Do not report a build identifier that WoW cannot show.

## Public releases

- Publish through the manual GitHub Actions workflow only when the owner explicitly requests a release. Commits, pushes, and local installs do not trigger a release.
- Bump the public version once, based on the changes since the last public release. A fixes-only release after `v0.13.24` is `v0.13.25`. A release that includes one or more features is `v0.14.0`. Local deployments do not consume public version numbers.
