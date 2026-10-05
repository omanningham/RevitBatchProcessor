# Revit Batch Processor -- GPL-3.0-or-later.
# Applies a release tag to the installer script and GlobalAssemblyInfo.cs, and writes the
# numeric version and whether the tag is a Britton release to $GITHUB_OUTPUT. Used by
# build_msi.yml (build of the tag, and version PR against master). Tag rules and version
# forms are in release_metadata.ps1.
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Tag)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'release_metadata.ps1')

# A define or attribute lost in an upstream merge must stop the release here, not later
# in Inno Setup or at the upload step.
function Update-Required([string]$Content, [string]$Pattern, [string]$Replacement, [string]$What, [string]$Path) {
    if ($Content -notmatch $Pattern) { throw "$What not found in $Path; cannot apply the release version" }
    return $Content -replace $Pattern, $Replacement
}

$release = ConvertFrom-ReleaseTag -Tag $Tag
Write-Host "Tag $Tag -> version $($release.Version), display version $($release.DisplayVersion)"

$iss = 'Setup/RevitBatchProcessor.iss'
$issContent = Get-Content -Path $iss -Raw
# [^"\r\n]* rather than .* so the CRLF line ending is preserved.
$issContent = Update-Required $issContent '#define AppVersion "[^"\r\n]*"' "#define AppVersion `"$($release.Version)`"" 'AppVersion define' $iss
$issContent = Update-Required $issContent '#define AppDisplayVersion "[^"\r\n]*"' "#define AppDisplayVersion `"$($release.DisplayVersion)`"" 'AppDisplayVersion define' $iss
# The workflow uploads RevitBatchProcessorSetup_<tag>.exe: the file name follows the tag.
$issContent = Update-Required $issContent 'OutputBaseFilename=[^\r\n]*' 'OutputBaseFilename=RevitBatchProcessorSetup_v{#AppDisplayVersion}' 'OutputBaseFilename' $iss

$assemblyInfo = 'Common/GlobalAssemblyInfo.cs'
$csContent = Get-Content -Path $assemblyInfo -Raw
$csContent = Update-Required $csContent 'AssemblyVersion\("[^"]*"\)' "AssemblyVersion(`"$($release.AssemblyVersion)`")" 'AssemblyVersion attribute' $assemblyInfo
$csContent = Update-Required $csContent 'AssemblyFileVersion\("[^"]*"\)' "AssemblyFileVersion(`"$($release.Version)`")" 'AssemblyFileVersion attribute' $assemblyInfo
$csContent = Update-Required $csContent 'AssemblyInformationalVersion\("[^"]*"\)' "AssemblyInformationalVersion(`"$($release.DisplayVersion)`")" 'AssemblyInformationalVersion attribute' $assemblyInfo

Set-Content -Path $iss -Value $issContent -NoNewline
Set-Content -Path $assemblyInfo -Value $csContent -NoNewline

if ($env:GITHUB_OUTPUT) {
    "version=$($release.Version)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
    "is_britton=$($release.IsBritton.ToString().ToLowerInvariant())" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
}
