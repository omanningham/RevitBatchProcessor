# Revit Batch Processor -- GPL-3.0-or-later.
# Applies a release tag to the installer script and GlobalAssemblyInfo.cs, and writes the
# numeric version to $GITHUB_OUTPUT. Used by build_msi.yml (build of the tag, and version
# PR against master). Tag rules and version forms are in release_metadata.ps1.
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Tag)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'release_metadata.ps1')

$release = ConvertFrom-ReleaseTag -Tag $Tag
Write-Host "Tag $Tag -> version $($release.Version), display version $($release.DisplayVersion)"

$iss = 'Setup/RevitBatchProcessor.iss'
$content = Get-Content -Path $iss -Raw
# [^"\r\n]* rather than .* so the CRLF line ending is preserved.
$content = $content -replace '#define AppVersion "[^"\r\n]*"', "#define AppVersion `"$($release.Version)`""
$content = $content -replace '#define AppDisplayVersion "[^"\r\n]*"', "#define AppDisplayVersion `"$($release.DisplayVersion)`""
Set-Content -Path $iss -Value $content -NoNewline

$assemblyInfo = 'Common/GlobalAssemblyInfo.cs'
$content = Get-Content -Path $assemblyInfo -Raw
$content = $content -replace 'AssemblyVersion\("[^"]*"\)', "AssemblyVersion(`"$($release.AssemblyVersion)`")"
$content = $content -replace 'AssemblyFileVersion\("[^"]*"\)', "AssemblyFileVersion(`"$($release.Version)`")"
$content = $content -replace 'AssemblyInformationalVersion\("[^"]*"\)', "AssemblyInformationalVersion(`"$($release.DisplayVersion)`")"
Set-Content -Path $assemblyInfo -Value $content -NoNewline

if ($env:GITHUB_OUTPUT) { "version=$($release.Version)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8 }
