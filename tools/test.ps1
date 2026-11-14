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
