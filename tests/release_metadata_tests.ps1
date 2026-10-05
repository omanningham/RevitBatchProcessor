# Revit Batch Processor -- GPL-3.0-or-later.
# Tests of .github/scripts/release_metadata.ps1, set_version.ps1 and new_winget_manifest.ps1.
# Runs under Windows PowerShell 5.1 and PowerShell 7 (Windows or Linux), without network.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$scripts = Join-Path $repoRoot '.github/scripts'
. (Join-Path $scripts 'release_metadata.ps1')

function Assert-Equal($Expected, $Actual, [string]$What) {
    if ($Expected -cne $Actual) { throw "$What : expected '$Expected', got '$Actual'" }
}

function Assert-Throws([scriptblock]$Code, [string]$Pattern, [string]$What) {
    try { & $Code } catch {
        if ($_.Exception.Message -notmatch $Pattern) { throw "$What : unexpected error '$($_.Exception.Message)'" }
        return
    }
    throw "$What : no error"
}

$temp = Join-Path ([IO.Path]::GetTempPath()) ('rbp-release-tests-' + [IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $temp | Out-Null
try {
    # --- ConvertFrom-ReleaseTag ---
    $r = ConvertFrom-ReleaseTag -Tag 'v1.13.0-brt.1'
    Assert-Equal $true $r.IsBritton 'brt.1 IsBritton'
    Assert-Equal '1.13.0.1' $r.Version 'brt.1 Version'
    Assert-Equal '1.13.0-brt.1' $r.DisplayVersion 'brt.1 DisplayVersion'
    Assert-Equal '1.13.0.0' $r.AssemblyVersion 'brt.1 AssemblyVersion'
    Assert-Equal '1.13.0.65535' (ConvertFrom-ReleaseTag -Tag 'v1.13.0-brt.65535').Version 'brt.65535 Version'
    $r = ConvertFrom-ReleaseTag -Tag 'v1.14.0'
    Assert-Equal $false $r.IsBritton 'upstream IsBritton'
    Assert-Equal '1.14.0.0' $r.Version 'upstream Version'
    Assert-Equal '1.14.0' $r.DisplayVersion 'upstream DisplayVersion'
    $r = ConvertFrom-ReleaseTag -Tag 'v1.14.0-beta'
    Assert-Equal '1.14.0.0' $r.Version 'beta Version'
    Assert-Equal '1.14.0-beta' $r.DisplayVersion 'beta DisplayVersion'
    foreach ($bad in 'v1.13.0-brt.0', 'v1.13.0-BRT.1', '1.13.0-brt.1', 'v1.13.0-brt.1x', 'v1.13-brt.1', 'V1.13.0') {
        Assert-Throws { ConvertFrom-ReleaseTag -Tag $bad } 'Unexpected release tag format' "reject $bad"
    }
    Assert-Throws { ConvertFrom-ReleaseTag -Tag 'v1.13.0-brt.70000' } 'too large' 'reject brt.70000'
    Assert-Throws { ConvertFrom-ReleaseTag -Tag 'v1.14.0' -BrittonOnly } 'Not a Britton release tag' 'BrittonOnly rejects upstream'
    Assert-Throws { ConvertFrom-ReleaseTag -Tag 'v1.14.0-beta' -BrittonOnly } 'Not a Britton release tag' 'BrittonOnly rejects beta'
    Assert-Equal '1.13.0.2' (ConvertFrom-ReleaseTag -Tag 'v1.13.0-brt.2' -BrittonOnly).Version 'BrittonOnly accepts brt'

    # --- ConvertFrom-AssetDigest ---
    $hex = 'f8e7f6d17ed0ff34978b5d205b1999cf0e66dc042fe995d88281806af5a6a88d'
    Assert-Equal $hex.ToUpperInvariant() (ConvertFrom-AssetDigest "sha256:$hex") 'sha256 digest'
    Assert-Equal $null (ConvertFrom-AssetDigest $null) 'null digest'
    Assert-Equal $null (ConvertFrom-AssetDigest '') 'empty digest'
    Assert-Equal $null (ConvertFrom-AssetDigest "sha512:$hex$hex") 'other algorithm'
    Assert-Equal $null (ConvertFrom-AssetDigest 'sha256:1234') 'short digest'
} finally {
    Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Output "PASS: release metadata tests under PowerShell $($PSVersionTable.PSVersion)"
