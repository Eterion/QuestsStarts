$ErrorActionPreference = 'Stop'

$root = Split-Path $PSScriptRoot -Parent
$addon = Join-Path $root 'addon/QuestsStarts'
$toc = Get-Content -LiteralPath (Join-Path $addon 'QuestsStarts.toc') -Raw
$version = [regex]::Match($toc, '(?m)^## Version:[ \t]*(\d+\.\d+\.\d+)[ \t]*\r?$').Groups[1].Value
$interface = [regex]::Match($toc, '(?m)^## Interface:[ \t]*(\d+)[ \t]*\r?$').Groups[1].Value
if (-not $version -or -not $interface) { throw 'Expected a stable Version and one Interface in QuestsStarts.toc.' }

& (Join-Path $PSScriptRoot 'test.ps1')

$out = Join-Path $root "dist/v$version"
New-Item -ItemType Directory -Path $out -Force | Out-Null
$filename = "QuestsStarts-$version.zip"
$zip = Join-Path $out $filename
$manifest = Join-Path $out 'release.json'

# Compress the directory itself so the archive installs directly into Interface/AddOns.
Compress-Archive -LiteralPath $addon -DestinationPath $zip -Force
$index = @{
    releases = @(@{
        filename = $filename
        version = $version
        nolib = $false
        metadata = @(@{ flavor = 'camelot'; interface = [int]$interface })
    })
}
$index | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifest -Encoding utf8NoBOM
Get-Item -LiteralPath $zip, $manifest
