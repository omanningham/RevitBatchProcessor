# Revit Batch Processor -- GPL-3.0-or-later.
# Release metadata shared by set_version.ps1 and new_winget_manifest.ps1 (dot-sourced):
# version forms derived from a release tag, the installer identity read from the Inno
# Setup script, and the SHA256 digest GitHub publishes for a release asset. Keeping
# them here stops the installer, the assemblies and the winget manifest from drifting.

# Britton releases are tagged vX.Y.Z-brt.N: X.Y.Z is the upstream base and N the Britton
# release number (restarts at 1 for each new upstream base). Upstream tags vX.Y.Z and
# vX.Y.Z-beta are accepted for the version PR and map to revision 0.
#   Version         X.Y.Z.N: Inno AppVersion (Windows DisplayVersion compared by winget),
#                   AssemblyFileVersion, winget PackageVersion
#   DisplayVersion  tag without the "v": installer file name, informational version, GUI
#   AssemblyVersion X.Y.Z.0: binding identity, unchanged by a Britton-only release
function ConvertFrom-ReleaseTag {
    param(
        [Parameter(Mandatory=$true)][string]$Tag,
        [switch]$BrittonOnly
    )
    # The leading "v" is required: the uploaded installer name is built from the raw tag.
    if ($Tag -cnotmatch '^v(\d+\.\d+\.\d+)(?:-beta|-brt\.([1-9]\d{0,4}))?$') {
        throw "Unexpected release tag format (expected vX.Y.Z-brt.N, vX.Y.Z or vX.Y.Z-beta): $Tag"
    }
    $base = $Matches[1]
    $isBritton = [bool]$Matches[2]
    $revision = if ($isBritton) { [int]$Matches[2] } else { 0 }
    if ($BrittonOnly -and -not $isBritton) { throw "Not a Britton release tag (expected vX.Y.Z-brt.N): $Tag" }
    # Each part of a Windows file version is limited to 65535.
    if ($revision -gt 65535) { throw "Britton release number too large (max 65535): $Tag" }
    [pscustomobject]@{
        Tag             = $Tag
        IsBritton       = $isBritton
        Version         = "$base.$revision"
        DisplayVersion  = $Tag.Substring(1)
        AssemblyVersion = "$base.0"
    }
}

# GitHub exposes a release asset's checksum as "digest": "sha256:<hex>", or null for
# assets uploaded before digests existed. Returns the uppercase hex, or $null.
function ConvertFrom-AssetDigest([string]$Digest) {
    if ($Digest -match '^sha256:([0-9a-fA-F]{64})$') { return $Matches[1].ToUpperInvariant() }
    return $null
}

# Installer identity as Inno Setup registers it under HKCU\...\Uninstall\<AppId>_is1:
# ProductCode (key name), DisplayName (UninstallDisplayName, else AppVerName) and
# Publisher. {#Define} references are expanded; AppVersion and AppDisplayVersion come
# from $Release, the values set_version.ps1 writes for the same tag.
function Get-InstallerIdentity {
    param(
        [Parameter(Mandatory=$true)][string]$IssPath,
        [Parameter(Mandatory=$true)]$Release
    )
    $defines = @{ AppVersion = $Release.Version; AppDisplayVersion = $Release.DisplayVersion }
    $setup = @{}
    foreach ($line in [IO.File]::ReadAllLines($IssPath)) {
        if ($line -match '^\s*#define\s+(\w+)\s+"([^"]*)"') {
            if (-not $defines.ContainsKey($Matches[1])) { $defines[$Matches[1]] = $Matches[2] }
        } elseif ($line -match '^\s*(AppId|AppName|AppVerName|AppPublisher|UninstallDisplayName)\s*=\s*(.*?)\s*$') {
            $setup[$Matches[1]] = $Matches[2]
        }
    }
    foreach ($name in 'AppId', 'AppName', 'AppVerName', 'AppPublisher') {
        if (-not $setup[$name]) { throw "$name not found in $IssPath" }
    }
    $expanded = @{}
    foreach ($name in @($setup.Keys)) {
        $value = $setup[$name]
        foreach ($define in $defines.Keys) { $value = $value.Replace("{#$define}", $defines[$define]) }
        if ($value -match '\{#(\w+)\}') { throw "Undefined Inno define {#$($Matches[1])} in $name of $IssPath" }
        # "{{" is Inno's escape for a literal "{" (AppId={{GUID}).
        $expanded[$name] = $value.Replace('{{', '{')
    }
    $displayName = if ($expanded['UninstallDisplayName']) { $expanded['UninstallDisplayName'] } else { $expanded['AppVerName'] }
    [pscustomobject]@{
        ProductCode = "$($expanded['AppId'])_is1"
        PackageName = $expanded['AppName']
        DisplayName = $displayName
        Publisher   = $expanded['AppPublisher']
    }
}
