# Revit Batch Processor -- GPL-3.0-or-later.
# Applies a release tag (vX.Y.Z or vX.Y.Z-beta) to the installer script and
# GlobalAssemblyInfo.cs, and writes the numeric version to $GITHUB_OUTPUT.
# Used by build_msi.yml (build of the tag, and version PR against master).
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Tag)
$ErrorActionPreference = 'Stop'

if ($Tag -notmatch '^v?\d+\.\d+\.\d+(-beta)?$') { throw "Unexpected release tag format: $Tag" }
$version = ($Tag -replace '-beta', '') -replace 'v', ''
Write-Host "Version number from tag $Tag is $version"

$iss = 'Setup/RevitBatchProcessor.iss'
$content = Get-Content -Path $iss -Raw
# [^\r\n]* rather than .* so the CRLF line ending is preserved.
if ($Tag -like '*-beta') {
    $content = $content -replace 'OutputBaseFilename=[^\r\n]*', 'OutputBaseFilename=RevitBatchProcessorSetup_v{#AppVersion}-beta'
} else {
    $content = $content -replace 'OutputBaseFilename=[^\r\n]*', 'OutputBaseFilename=RevitBatchProcessorSetup_v{#AppVersion}'
}
$content = $content -replace '#define AppVersion "[^"\r\n]*"', "#define AppVersion `"$version`""
Set-Content -Path $iss -Value $content -NoNewline

$assemblyInfo = 'Common/GlobalAssemblyInfo.cs'
$content = Get-Content -Path $assemblyInfo -Raw
$content = $content -replace '\("\d+\.\d+\.\d+"\)', "(`"$version`")"
Set-Content -Path $assemblyInfo -Value $content -NoNewline

if ($env:GITHUB_OUTPUT) { "version=$version" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8 }
