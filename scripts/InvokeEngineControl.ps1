# Revit Batch Processor -- GPL-3.0-or-later.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$ProbePath,
    [Parameter(Mandatory=$true)][string]$EngineFolder,
    [Parameter(Mandatory=$true)][string]$LogPath
)
# Capture stderr directly: Windows PowerShell 5.1 otherwise promotes the
# expected Python 2 exception to NativeCommandError with ErrorAction=Stop.
$start = New-Object System.Diagnostics.ProcessStartInfo
$start.FileName = [IO.Path]::GetFullPath($ProbePath)
# A final '.' avoids the Windows quoted-argument trailing-backslash case.
$start.Arguments = '"' + [IO.Path]::Combine([IO.Path]::GetFullPath($EngineFolder), '.') + '"'
$start.UseShellExecute = $false
$start.CreateNoWindow = $true
$start.RedirectStandardOutput = $true
$start.RedirectStandardError = $true
$start.StandardOutputEncoding = New-Object System.Text.UTF8Encoding($false)
$start.StandardErrorEncoding = New-Object System.Text.UTF8Encoding($false)
$process = New-Object System.Diagnostics.Process
$process.StartInfo = $start
try {
    [void]$process.Start()
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
    $process.WaitForExit()
    $text = $stdout.GetAwaiter().GetResult() + [Environment]::NewLine + $stderr.GetAwaiter().GetResult()
    [IO.File]::WriteAllText([IO.Path]::GetFullPath($LogPath), $text, (New-Object System.Text.UTF8Encoding($false)))
    return $process.ExitCode
} finally { $process.Dispose() }
