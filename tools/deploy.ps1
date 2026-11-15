[CmdletBinding(SupportsShouldProcess)]
param([string]$AddOnsPath = 'C:\Games\World of Warcraft\_forever_\Interface\AddOns')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$source = (Resolve-Path -LiteralPath (Join-Path $projectRoot 'addon/QuestsStarts')).Path
$parent = (Resolve-Path -LiteralPath $AddOnsPath).Path
$target = [System.IO.Path]::GetFullPath((Join-Path $parent 'QuestsStarts'))
if ([System.IO.Path]::GetDirectoryName($target) -ne $parent.TrimEnd('\')) { throw 'Deploy target must be directly inside the specified AddOns folder.' }
if (Test-Path -LiteralPath $target) {
    $targetItem = Get-Item -LiteralPath $target
    if ($targetItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) { throw 'Refusing to deploy into a linked directory.' }
    if (-not (Test-Path -LiteralPath (Join-Path $target 'QuestsStarts.build.json'))) { throw 'Existing addon folder is not owned by this deploy script.' }
}
$files = @(Get-ChildItem -LiteralPath $source -Recurse -File)
$sourceToc = Get-Content -LiteralPath (Join-Path $source 'QuestsStarts.toc') -Raw
$version = [regex]::Match($sourceToc, '(?m)^## Version:[ \t]*(\d+\.\d+\.\d+)[ \t]*\r?$').Groups[1].Value
if (-not $version) { throw 'Expected a stable Version in QuestsStarts.toc.' }
$coreName = 'Core.lua'
$installedCore = Join-Path $target $coreName
$sourceCore = Get-Content -LiteralPath (Join-Path $source $coreName) -Raw
$buildMarker = '(?m)^local developmentBuild = nil(?= --)'
if ($sourceCore -notmatch $buildMarker) { throw 'Expected a development build marker in Core.lua.' }
$buildNumber = 1
if (Test-Path -LiteralPath $installedCore -PathType Leaf) {
    $previousCore = Get-Content -LiteralPath $installedCore -Raw
    $pattern = '(?m)^local developmentBuild = "' + [regex]::Escape($version) + '-dev\.(\d+)"'
    $previousBuild = [regex]::Match($previousCore, $pattern)
    if ($previousBuild.Success) { $buildNumber += [int]$previousBuild.Groups[1].Value }
}
$build = "$version-dev.$buildNumber"
if ($PSCmdlet.ShouldProcess($target, "Deploy QuestsStarts $build")) {
    $upstream = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'upstream-revision.txt') -Raw).Trim()
    foreach ($file in $files | Where-Object FullName -ne (Join-Path $source $coreName)) {
        $relative = [System.IO.Path]::GetRelativePath($source, $file.FullName)
        $destination = Join-Path $target $relative
        New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $destination -Force
        if ((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $destination).Hash) { throw "Deploy verification failed: $relative" }
    }
    @{addon='QuestsStarts';version=$version;developmentBuild=$build;upstream=$upstream;fileCount=$files.Count} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $target 'QuestsStarts.build.json') -Encoding utf8
    $localCore = $sourceCore -replace $buildMarker, ('local developmentBuild = "' + $build + '"')
    Set-Content -LiteralPath $installedCore -Value $localCore -Encoding utf8NoBOM -NoNewline
    if ((Get-Content -LiteralPath $installedCore -Raw) -cne $localCore) { throw "Deploy verification failed: $coreName" }
    Write-Output "Deployed and verified QuestsStarts $build ($($files.Count) files) to $target. After /reload, check /qs."
}
