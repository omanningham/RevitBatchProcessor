# Revit Batch Processor -- GPL-3.0-or-later.
# Fails when a file or build output referenced by the installer script is missing.
# Run from the repository root after a Release|x64 build of the solution.
$ErrorActionPreference = 'Stop'
$missing = @()
function Test-DirWithFiles($path) {
  if (-not (Test-Path -Path $path -PathType Container)) { return "Missing directory: $path" }
  $fileCount = (Get-ChildItem -Path $path -File -ErrorAction SilentlyContinue | Measure-Object).Count
  if ($fileCount -eq 0) { return "Directory has no files (expected build output): $path" }
  return $null
}

# 1. Inno Setup script file
$issFile = "Setup/RevitBatchProcessor.iss"
if (-not (Test-Path -Path $issFile -PathType Leaf)) { $missing += "Missing file: $issFile" }

# 2. GUI output directory
$guiOut = "BatchRvtGUI/bin/x64/Release"
$res = Test-DirWithFiles $guiOut; if ($res) { $missing += $res }

# 3. Addin years 2015-2027 (directories + .addin files)
foreach ($year in 2015..2027) {
  $addinDir = "BatchRvtAddin$year/bin/x64/Release"
  $res = Test-DirWithFiles $addinDir; if ($res) { $missing += $res }
  $addinFile = "BatchRvtAddin$year/BatchRvtAddin$year.addin"
  if (-not (Test-Path -Path $addinFile -PathType Leaf)) { $missing += "Missing file: $addinFile" }
}

if ($missing.Count -eq 0) {
  Write-Host "Verification succeeded: all referenced installer sources exist."
} else {
  Write-Host "The following required sources were NOT found:"
  $missing | ForEach-Object { Write-Host "::error::$_" }
  exit 1
}
