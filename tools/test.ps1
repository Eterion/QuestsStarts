$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$lua = Join-Path $projectRoot 'work/QuestieDB/tools/lua-binary/lua.exe'
& $lua (Join-Path $projectRoot 'tests/run.lua') $projectRoot
if ($LASTEXITCODE -ne 0) { throw 'Runtime tests failed.' }
# Parse every shipped Lua chunk, including classes not selected by the smoke test.
Get-ChildItem -LiteralPath (Join-Path $projectRoot 'addon/QuestsStarts') -Filter '*.lua' -Recurse | ForEach-Object {
    $env:QUESTSSTARTS_PARSE_FILE = $_.FullName
    & $lua -e 'assert(loadfile(os.getenv("QUESTSSTARTS_PARSE_FILE")))'
    if ($LASTEXITCODE -ne 0) { throw "Lua parse failed: $($_.FullName)" }
}
Remove-Item Env:QUESTSSTARTS_PARSE_FILE
[xml]$pins = Get-Content -LiteralPath (Join-Path $projectRoot 'addon/QuestsStarts/Pins.xml') -Raw
$addonRoot = Join-Path $projectRoot 'addon/QuestsStarts'
Get-Content -LiteralPath (Join-Path $addonRoot 'QuestsStarts.toc') | Where-Object { $_.Trim() -and -not $_.StartsWith('#') } | ForEach-Object {
    if (-not (Test-Path -LiteralPath (Join-Path $addonRoot $_))) { throw "Missing TOC file: $_" }
}
Write-Output 'Lua syntax, XML parsing, and TOC file checks passed.'
$mapsRoot = Join-Path $addonRoot 'Maps'
$mapSources = Get-Content -LiteralPath (Join-Path $mapsRoot 'ClassicBlizzardSources.json') -Raw | ConvertFrom-Json
foreach ($asset in $mapSources.files) {
    if ($asset.file -notmatch '^(WailingCaverns|BlackrockSpire)/[A-Za-z0-9_]+\.blp$') { throw 'Unexpected archived map path.' }
    $path = Join-Path $mapsRoot $asset.file
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ine $asset.sha256) {
        throw "Archived Blizzard map differs from its pinned source: $($asset.file)"
    }
    $header = [System.IO.File]::ReadAllBytes($path)
    if ([System.Text.Encoding]::ASCII.GetString($header, 0, 4) -ne 'BLP2' -or
        [BitConverter]::ToUInt32($header, 12) -ne 256 -or [BitConverter]::ToUInt32($header, 16) -ne 256) {
        throw "Expected a 256x256 Blizzard BLP2 map tile: $($asset.file)"
    }
}
Write-Output "Verified $($mapSources.files.Count) archived Blizzard map tiles against pinned hashes and dimensions."
