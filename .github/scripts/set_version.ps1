# Revit Batch Processor -- GPL-3.0-or-later.
# Applies a release tag to the installer script and GlobalAssemblyInfo.cs, and writes
# the versions to $GITHUB_OUTPUT. Used by build_msi.yml (build of the tag, and version
# PR against master).
#
# Britton releases are tagged vX.Y.Z-brt.N: X.Y.Z is the upstream base and N the Britton
# release number (restarts at 1 for each new upstream base). The numeric version
# X.Y.Z.N is what Windows and winget compare, so N > 0 always sorts above the upstream
# X.Y.Z. Upstream tags (vX.Y.Z, vX.Y.Z-beta) are still accepted and map to X.Y.Z.0.
#   version         numeric X.Y.Z.N (AppVersion / DisplayVersion, file version, winget)
#   display_version tag without the "v" (installer file name, GUI, informational version)
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Tag)
$ErrorActionPreference = 'Stop'

# The leading "v" is required: the uploaded installer name is built from the raw tag.
if ($Tag -cnotmatch '^v(\d+\.\d+\.\d+)(?:-beta|-brt\.([1-9]\d{0,4}))?$') {
    throw "Unexpected release tag format (expected vX.Y.Z-brt.N, vX.Y.Z or vX.Y.Z-beta): $Tag"
}
$baseVersion = $Matches[1]
$revision = if ($Matches[2]) { [int]$Matches[2] } else { 0 }
# Each part of a Windows file version is limited to 65535.
if ($revision -gt 65535) { throw "Britton release number too large (max 65535): $Tag" }
$version = "$baseVersion.$revision"
$displayVersion = $Tag.Substring(1)
Write-Host "Tag $Tag -> version $version, display version $displayVersion"

$iss = 'Setup/RevitBatchProcessor.iss'
$content = Get-Content -Path $iss -Raw
# [^"\r\n]* rather than .* so the CRLF line ending is preserved.
$content = $content -replace '#define AppVersion "[^"\r\n]*"', "#define AppVersion `"$version`""
$content = $content -replace '#define AppDisplayVersion "[^"\r\n]*"', "#define AppDisplayVersion `"$displayVersion`""
Set-Content -Path $iss -Value $content -NoNewline

# AssemblyVersion keeps the upstream base: it is the binding identity and need not change
# for a Britton-only release.
$assemblyInfo = 'Common/GlobalAssemblyInfo.cs'
$content = Get-Content -Path $assemblyInfo -Raw
$content = $content -replace 'AssemblyVersion\("[^"]*"\)', "AssemblyVersion(`"$baseVersion.0`")"
$content = $content -replace 'AssemblyFileVersion\("[^"]*"\)', "AssemblyFileVersion(`"$version`")"
$content = $content -replace 'AssemblyInformationalVersion\("[^"]*"\)', "AssemblyInformationalVersion(`"$displayVersion`")"
Set-Content -Path $assemblyInfo -Value $content -NoNewline

if ($env:GITHUB_OUTPUT) {
    "version=$version" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
    "display_version=$displayVersion" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
}
