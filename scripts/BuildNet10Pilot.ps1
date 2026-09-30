# Revit Batch Processor -- GPL-3.0-or-later.
# Creates a fresh source snapshot; never invokes DeployAddin.bat or an installer.
[CmdletBinding()]
param(
    [string]$MsBuild,
    [Parameter(Mandatory=$true)][string]$ControlEngineFolder,
    [string]$OutputFolder
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
if (!$OutputFolder) { $OutputFolder = Join-Path $repo ('artifacts/net10-pilot-' + (Get-Date -Format 'yyyyMMdd-HHmmss')) }
$output = [IO.Path]::GetFullPath($OutputFolder)
if (Test-Path -LiteralPath $output) { throw 'Use a new output directory; existing artifacts are preserved.' }
if (!$MsBuild) {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
    $MsBuild = & $vswhere -latest -products '*' -requires Microsoft.Component.MSBuild -find 'MSBuild/Current/Bin/MSBuild.exe' | Select-Object -First 1
}
if (!$MsBuild -or !(Test-Path -LiteralPath $MsBuild)) { throw 'Visual Studio MSBuild is required for the historical projects.' }
function Run([string]$exe, [string[]]$arguments, [string]$log) {
    & $exe @arguments *> (Join-Path $output $log)
    if ($LASTEXITCODE) { throw "$exe failed; see $log" }
}
function InstallationInventory {
    foreach ($root in @((Join-Path $env:APPDATA 'Autodesk/Revit/Addins'), (Join-Path $env:ProgramData 'Autodesk/Revit/Addins'), (Join-Path $env:LOCALAPPDATA 'RevitBatchProcessor'))) {
        if (Test-Path -LiteralPath $root) {
            Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object FullName -Match 'BatchRvt|RevitBatchProcessor' | ForEach-Object {
                [PSCustomObject]@{ Path = $_.FullName; Hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
            }
        }
    }
}
New-Item -ItemType Directory -Path $output | Out-Null
$before = @(InstallationInventory)
$before | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $output 'installation-before.json') -Encoding UTF8
$source = Join-Path $output 'source'
Push-Location $repo
try {
    git -c core.excludesFile= status --short | Set-Content (Join-Path $output 'initial-status.txt')
    git rev-parse HEAD | Set-Content (Join-Path $output 'commit.txt')
    git diff --binary | Set-Content (Join-Path $output 'local-changes.patch') -Encoding UTF8
    $files = git -c core.excludesFile= ls-files --cached --others --exclude-standard
    if ($LASTEXITCODE) { throw 'Cannot enumerate source files.' }
    foreach ($file in $files) {
        if ($file -like 'artifacts/*' -or $file -match '(^|/)__pycache__/') { continue }
        $target = Join-Path $source $file
        New-Item -ItemType Directory -Force -Path (Split-Path $target -Parent) | Out-Null
        Copy-Item -LiteralPath (Join-Path $repo $file) -Destination $target
    }
} finally { Pop-Location }
$nuget = Join-Path $output 'NuGet.Config'
'<configuration><packageSources><clear/><add key="nuget.org" value="https://api.nuget.org/v3/index.json" /></packageSources></configuration>' | Set-Content $nuget
$packages = Join-Path $output 'packages'
Run $MsBuild @("$source/BatchRvtGUI/BatchRvtGUI.csproj", '/t:Restore', '/p:RestorePackagesConfig=true', "/p:RestoreConfigFile=$nuget", "/p:RestorePackagesPath=$packages", "/p:RestoreRepositoryPath=$source/packages") 'restore-legacy.log'
Run $MsBuild @("$source/BatchRvtGUI/BatchRvtGUI.csproj", '/p:Configuration=Release', '/p:Platform=x64', '/p:PostBuildEvent=', '/v:minimal') 'build-gui.log'
foreach ($year in 2025..2027) {
    $project = "$source/BatchRvtAddin$year/BatchRvtAddin$year.csproj"
    Run 'dotnet' @('restore', $project, '--locked-mode', '--configfile', $nuget, '--packages', $packages, '-p:Platform=x64') "restore-$year.log"
    Run 'dotnet' @('build', $project, '--no-restore', '-c', 'Release', '-p:Platform=x64', '-p:DeployAddinOnBuild=false', '-p:PostBuildEvent=') "build-$year.log"
}
# Qualify one exact pair of shared binaries for both engine families.
$shared = "$source/BatchRvtAddin2027/bin/x64/Release"
foreach ($consumer in @("$source/BatchRvtGUI/bin/x64/Release", "$source/BatchRvtAddin2025/bin/x64/Release", "$source/BatchRvtAddin2026/bin/x64/Release")) {
    foreach ($name in @('BatchRvtScriptHost', 'BatchRvtUtil')) {
        foreach ($extension in @('.dll', '.pdb', '.dll.config')) {
            $file = Join-Path $shared ($name + $extension)
            if (Test-Path -LiteralPath $file) { Copy-Item -LiteralPath $file -Destination $consumer }
        }
    }
}
foreach ($probe in @('EngineProbe', 'LegacyEngineProbe')) {
    $project = "$source/tests/$probe/$probe.csproj"
    Run 'dotnet' @('restore', $project, '--configfile', $nuget, '--packages', $packages) "restore-$probe.log"
    Run 'dotnet' @('build', $project, '--no-restore', '-o', "$output/$probe") "build-$probe.log"
}
if ($ControlEngineFolder) {
    & "$output/EngineProbe/EngineProbe.exe" $ControlEngineFolder *> "$output/test-control.log"
    if (!$LASTEXITCODE -or !(Select-String -LiteralPath "$output/test-control.log" -Pattern 'ImplementCTDOverride' -Quiet)) { throw 'The Python 2 control did not reproduce the expected error.' }
}
foreach ($year in 2025..2027) {
    $addin = "$source/BatchRvtAddin$year/bin/x64/Release"
    Run "$output/EngineProbe/EngineProbe.exe" @($addin, "$source/BatchRvtUtil/Scripts", $addin) "test-$year.log"
}
Run "$output/LegacyEngineProbe/LegacyEngineProbe.exe" @("$source/BatchRvtGUI/bin/x64/Release", "$source/BatchRvtUtil/Scripts", "$source/tests") 'test-legacy.log'
$after = @(InstallationInventory)
$after | ConvertTo-Json -Depth 4 | Set-Content "$output/installation-after.json" -Encoding UTF8
if (Compare-Object $before $after -Property Path, Hash) { throw 'Installation inventory changed; no package will be prepared.' }
$stage = Join-Path $output 'pilot'
New-Item -ItemType Directory -Path "$stage/GUI" -Force | Out-Null
Copy-Item "$source/BatchRvtGUI/bin/x64/Release/*" "$stage/GUI" -Recurse
foreach ($year in 2025..2027) {
    New-Item -ItemType Directory -Path "$stage/$year" -Force | Out-Null
    Copy-Item "$source/BatchRvtAddin$year/bin/x64/Release/*" "$stage/$year" -Recurse
    Copy-Item "$source/BatchRvtAddin$year/BatchRvtAddin$year.addin" "$stage/$year"
    Copy-Item "$source/BatchRvtAddin$year/packages.lock.json" "$stage/$year"
}
if (Get-ChildItem $stage -Recurse -Directory | Where-Object Name -EQ 'Britton modified') { throw 'An archive entered the pilot.' }
foreach ($name in @('BatchRvtScriptHost.dll', 'BatchRvtUtil.dll')) {
    $hashes = @('GUI','2025','2026','2027') | ForEach-Object { (Get-FileHash -LiteralPath "$stage/$_/$name").Hash } | Select-Object -Unique
    if (@($hashes).Count -ne 1) { throw "Inconsistent shared assembly: $name" }
}
Copy-Item "$output/commit.txt", "$output/test-*.log", "$output/build-*.log", "$output/local-changes.patch" $stage
Copy-Item "$source/docs/net10-pilot.md" "$stage/README.md"
Copy-Item "$source/docs/net10-validation-20260930.md" "$stage/validation.md"
Get-ChildItem $stage -Recurse -File | ForEach-Object {
    [PSCustomObject]@{ Path = $_.FullName.Substring($stage.Length + 1); SHA256 = (Get-FileHash -LiteralPath $_.FullName).Hash }
} | ConvertTo-Json -Depth 4 | Set-Content "$stage/SHA256.json" -Encoding UTF8
Compress-Archive -Path "$stage/*" -DestinationPath "$output/RBP-net10-pilot.zip"
Write-Output "Pilot prepared, not installed: $output/RBP-net10-pilot.zip"
