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
if ($PSCmdlet.ShouldProcess($target, 'Deploy QuestsStarts prototype')) {
    foreach ($file in $files) {
        $relative = [System.IO.Path]::GetRelativePath($source, $file.FullName)
        $destination = Join-Path $target $relative
        New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $destination -Force
        if ((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $destination).Hash) { throw "Deploy verification failed: $relative" }
    }
    $version = ((Get-Content -LiteralPath (Join-Path $source 'QuestsStarts.toc') | Where-Object { $_ -match '^## Version:' }) -replace '^## Version:\s*','').Trim()
    @{addon='QuestsStarts';version=$version;upstream=(Get-Content (Join-Path $PSScriptRoot 'upstream-revision.txt') -Raw).Trim();fileCount=$files.Count} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $target 'QuestsStarts.build.json') -Encoding utf8
    Write-Output "Deployed and hash-verified $($files.Count) files to $target. Ready for /reload."
}
