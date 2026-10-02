# Revit Batch Processor -- GPL-3.0-or-later.
# Fails when a file or build output referenced by the installer script is missing.
# Reads the Source: entries of the [Files] section, so the check follows the
# installer script (e.g. a new Revit year) without a second list to maintain.
# Run from the repository root after a Release|x64 build of the solution.
$ErrorActionPreference = 'Stop'
$issFile = 'Setup/RevitBatchProcessor.iss'
if (-not (Test-Path -Path $issFile -PathType Leaf)) { Write-Host "::error::Missing file: $issFile"; exit 1 }
$setupDir = Split-Path -Path (Resolve-Path $issFile) -Parent

$sources = @(Select-String -Path $issFile -Pattern '^\s*Source:\s*"([^"]+)"' | ForEach-Object { $_.Matches[0].Groups[1].Value })
if ($sources.Count -eq 0) { Write-Host "::error::No Source: entries found in $issFile"; exit 1 }

$missing = @()
foreach ($source in $sources) {
  $path = Join-Path $setupDir ($source -replace '\\', [IO.Path]::DirectorySeparatorChar)
  if ($source -match '[*?]') {
    # Wildcard source: its folder must exist and contain build output.
    $dir = Split-Path -Path $path -Parent
    if (-not (Test-Path -Path $dir -PathType Container)) { $missing += "Missing directory: $source" }
    elseif (-not (Get-ChildItem -Path $path -File -ErrorAction SilentlyContinue | Select-Object -First 1)) {
      $missing += "No files match (expected build output): $source"
    }
  } elseif (-not (Test-Path -Path $path -PathType Leaf)) {
    $missing += "Missing file: $source"
  }
}

if ($missing.Count -eq 0) {
  Write-Host "Verification succeeded: all $($sources.Count) installer sources exist."
} else {
  Write-Host "The following required sources were NOT found:"
  $missing | ForEach-Object { Write-Host "::error::$_" }
  exit 1
}
