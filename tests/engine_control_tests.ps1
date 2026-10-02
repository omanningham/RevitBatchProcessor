# Revit Batch Processor -- GPL-3.0-or-later.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$ProbePath,
    [Parameter(Mandatory=$true)][string]$ControlEngineFolder,
    [Parameter(Mandatory=$true)][string]$OutputFolder,
    [string]$CandidateEngineFolder
)
$ErrorActionPreference = 'Stop'
$scriptsFolder = Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts'
$output = [IO.Path]::GetFullPath($OutputFolder)
New-Item -ItemType Directory -Force -Path $output | Out-Null
$tokens = $null
$parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $scriptsFolder 'BuildNet10Pilot.ps1'), [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw 'Build script parse error.' }
$control = @($ast.FindAll({ param($node)
    $node -is [Management.Automation.Language.IfStatementAst] -and $node.Clauses[0].Item1.Extent.Text -eq '$ControlEngineFolder'
}, $true))
if ($control.Count -ne 1) { throw 'Cannot locate real negative-control block.' }
# Execute the actual build control, with only its artifact paths substituted.
$code = $control[0].Extent.Text.Replace('"$output/EngineProbe/EngineProbe.exe"', '$ProbePath').Replace('$PSScriptRoot', '$scriptsFolder')
& ([ScriptBlock]::Create($code))
if (!(Select-String -LiteralPath "$output/test-control.log" -Pattern 'ImplementCTDOverride' -Quiet)) { throw 'Missing expected control diagnostic.' }
if (!([IO.File]::ReadAllText("$output/test-control.log").Contains([IO.Path]::GetFullPath($ControlEngineFolder)))) { throw 'Engine path was lost in captured diagnostics.' }
if ($ErrorActionPreference -ne 'Stop') { throw 'Control changed caller error preference.' }
Write-Output "PASS: expected failing engine accepted under PowerShell $($PSVersionTable.PSVersion)"
if ($CandidateEngineFolder) {
    $output = Join-Path $output 'unexpected-success'
    New-Item -ItemType Directory -Force -Path $output | Out-Null
    $ControlEngineFolder = $CandidateEngineFolder
    $rejected = $false
    try { & ([ScriptBlock]::Create($code)) }
    catch {
        if ($_.Exception.Message -notmatch 'did not reproduce') { throw }
        $rejected = $true
    }
    if (!$rejected) { throw 'Successful candidate was accepted as a failing control.' }
    Write-Output 'PASS: successful candidate rejected as negative control'
}
# Exercise the real Run function with native stderr on a successful command.
$runNode = @($ast.FindAll({ param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Run'
}, $true))
if ($runNode.Count -ne 1) { throw 'Cannot locate real native runner.' }
. ([ScriptBlock]::Create($runNode[0].Extent.Text))
$processName = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh.exe' } else { 'powershell.exe' }
$nativeShell = Join-Path $PSHOME $processName
$emit = '[Console]::Error.WriteLine("diagnostic only"); exit 0'
$encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($emit))
Run $nativeShell @('-NoProfile', '-EncodedCommand', $encoded) 'native-stderr-success.log'
if (!(Select-String -LiteralPath "$output/native-stderr-success.log" -Pattern 'diagnostic only' -Quiet)) { throw 'Native stderr diagnostic was lost.' }
if ($ErrorActionPreference -ne 'Stop') { throw 'Runner changed caller error preference.' }
$emit = '[Console]::Error.WriteLine("expected failure"); exit 7'
$encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($emit))
$rejected = $false
try { Run $nativeShell @('-NoProfile', '-EncodedCommand', $encoded) 'native-failure.log' }
catch {
    if ($_.Exception.Message -notmatch 'failed; see native-failure.log') { throw }
    $rejected = $true
}
if (!$rejected) { throw 'Runner accepted nonzero native exit.' }
Write-Output 'PASS: native stderr accepted for exit 0, nonzero exit rejected'
