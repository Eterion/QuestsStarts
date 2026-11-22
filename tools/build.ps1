param([string]$Upstream = (Join-Path $PSScriptRoot '../work/QuestieDB'))
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$sourceRoot = (Resolve-Path -LiteralPath $Upstream).Path
$expectedRevision = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'upstream-revision.txt') -Raw).Trim()
$actualRevision = (git -C $sourceRoot rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $actualRevision -ne $expectedRevision) { throw "QuestieDB must be at $expectedRevision" }
if (git -C $sourceRoot status --porcelain --untracked-files=no) { throw 'QuestieDB tracked files must be clean.' }
$lua = Join-Path $sourceRoot 'tools/lua-binary/lua.exe'
$expectedHash = '1e2911d6e9e29c2a0bd14a7e5477c4c42e433a3d13a5d82ff7a414d9782a7f0e'
if ((Get-FileHash -LiteralPath $lua -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expectedHash) { throw 'Unexpected Lua interpreter checksum.' }
$classes = [ordered]@{WARRIOR=1; PALADIN=2; HUNTER=3; ROGUE=4; PRIEST=5; SHAMAN=7; MAGE=8; WARLOCK=9; DRUID=11}
$dataRoot = Join-Path $projectRoot 'addon/QuestsStarts/Data'
New-Item -ItemType Directory -Path $dataRoot -Force | Out-Null
$candidateRoot = Join-Path $projectRoot 'work/exports'
New-Item -ItemType Directory -Path $candidateRoot -Force | Out-Null
Push-Location $sourceRoot
try {
    & $lua (Join-Path $PSScriptRoot 'audit-inherited-classes.lua') $projectRoot source
    if ($LASTEXITCODE -ne 0) { throw 'Inherited class source capture failed.' }
    foreach ($entry in $classes.GetEnumerator()) {
        $candidate = Join-Path $candidateRoot ($entry.Key + '.lua')
        & $lua (Join-Path $PSScriptRoot 'export.lua') $candidate $actualRevision $entry.Key $entry.Value
        if ($LASTEXITCODE -ne 0) { throw "Data export failed for $($entry.Key)" }
    }
} finally { Pop-Location }
& $lua (Join-Path $PSScriptRoot 'merge-classes.lua') (Join-Path $dataRoot 'Tirisfal.lua') $actualRevision $candidateRoot
if ($LASTEXITCODE -ne 0) { throw 'Class data compilation or reconstruction verification failed.' }
Push-Location $sourceRoot
try {
    & $lua (Join-Path $PSScriptRoot 'audit-inherited-classes.lua') $projectRoot audit
    if ($LASTEXITCODE -ne 0) { throw 'Inherited class metadata audit failed.' }
} finally { Pop-Location }
& $lua (Join-Path $PSScriptRoot 'coverage-report.lua') (Join-Path $dataRoot 'Tirisfal.lua') (Join-Path $projectRoot 'docs/coverage.md')
if ($LASTEXITCODE -ne 0) { throw 'Coverage report generation failed.' }
& $lua (Join-Path $PSScriptRoot 'dungeon-report.lua') (Join-Path $dataRoot 'Tirisfal.lua') (Join-Path $projectRoot 'docs/dungeon-coverage.md')
if ($LASTEXITCODE -ne 0) { throw 'Dungeon report generation failed.' }
$noticeRoot = Join-Path $projectRoot 'addon/QuestsStarts/Licenses'
New-Item -ItemType Directory -Path $noticeRoot -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $sourceRoot 'LICENSE.md') -Destination (Join-Path $noticeRoot 'QuestieDB-LICENSE.md')
Copy-Item -LiteralPath (Join-Path $sourceRoot 'PROVENANCE.md') -Destination (Join-Path $noticeRoot 'QuestieDB-PROVENANCE.md')
Copy-Item -LiteralPath (Join-Path $sourceRoot 'gpl-3.0.md') -Destination (Join-Path $noticeRoot 'GPL-3.0.md')
