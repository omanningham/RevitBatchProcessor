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

    # --- Get-InstallerIdentity ---
    $brt = ConvertFrom-ReleaseTag -Tag 'v1.14.0-brt.3'
    $id = Get-InstallerIdentity -IssPath (Join-Path $repoRoot 'Setup/RevitBatchProcessor.iss') -Release $brt
    Assert-Equal '{B5CA57EA-7BB2-4620-916C-AE98376C1EF1}_is1' $id.ProductCode 'real iss ProductCode'
    Assert-Equal 'Revit Batch Processor (Britton)' $id.PackageName 'real iss PackageName'
    Assert-Equal 'Revit Batch Processor (Britton) 1.14.0-brt.3' $id.DisplayName 'real iss DisplayName follows the tag'
    Assert-Equal 'Britton' $id.Publisher 'real iss Publisher'

    $fixture = Join-Path $temp 'fixture.iss'
    Set-Content -Path $fixture -Value @(
        '#define AppName "Test App"',
        '#define AppVersion "0.0.0.0"',
        '[Setup]',
        'AppId = {{11111111-2222-3333-4444-555555555555}',
        'AppName={#AppName}',
        'AppVerName={#AppName} {#AppDisplayVersion}',
        'AppPublisher = Test Publisher ',
        'UninstallDisplayName={#AppName} v{#AppVersion}'
    )
    $id = Get-InstallerIdentity -IssPath $fixture -Release $brt
    Assert-Equal '{11111111-2222-3333-4444-555555555555}_is1' $id.ProductCode 'fixture ProductCode with spaces and {{'
    Assert-Equal 'Test Publisher' $id.Publisher 'fixture Publisher trimmed'
    Assert-Equal 'Test App v1.14.0.3' $id.DisplayName 'UninstallDisplayName wins, tag AppVersion wins over the file'

    Set-Content -Path $fixture -Value @('[Setup]', 'AppId=X', 'AppName=A', 'AppVerName=A 1')
    Assert-Throws { Get-InstallerIdentity -IssPath $fixture -Release $brt } 'AppPublisher not found' 'missing AppPublisher'
    Set-Content -Path $fixture -Value @('[Setup]', 'AppId=X', 'AppName={#Nope}', 'AppVerName=A 1', 'AppPublisher=P')
    Assert-Throws { Get-InstallerIdentity -IssPath $fixture -Release $brt } 'Undefined Inno define \{#Nope\}' 'unknown define'

    # --- set_version.ps1 on copies of the installer script and GlobalAssemblyInfo.cs ---
    foreach ($case in @(
        @{ Tag = 'v1.14.0-brt.3'; Version = '1.14.0.3'; Display = '1.14.0-brt.3'; Assembly = '1.14.0.0' },
        @{ Tag = 'v1.14.0-beta';  Version = '1.14.0.0'; Display = '1.14.0-beta';  Assembly = '1.14.0.0' })) {
        $work = Join-Path $temp ('setver-' + [IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory -Path (Join-Path $work 'Setup'), (Join-Path $work 'Common') | Out-Null
        Copy-Item (Join-Path $repoRoot 'Setup/RevitBatchProcessor.iss') (Join-Path $work 'Setup')
        Copy-Item (Join-Path $repoRoot 'Common/GlobalAssemblyInfo.cs') (Join-Path $work 'Common')
        $crlfBefore = ([regex]::Matches([IO.File]::ReadAllText((Join-Path $work 'Setup/RevitBatchProcessor.iss')), "`r`n")).Count
        $outputFile = Join-Path $work 'github_output.txt'
        $savedOutput = $env:GITHUB_OUTPUT
        $env:GITHUB_OUTPUT = $outputFile
        Push-Location $work
        try { & (Join-Path $scripts 'set_version.ps1') -Tag $case.Tag 6>$null | Out-Null }
        finally { Pop-Location; $env:GITHUB_OUTPUT = $savedOutput }
        $iss = [IO.File]::ReadAllText((Join-Path $work 'Setup/RevitBatchProcessor.iss'))
        $cs = [IO.File]::ReadAllText((Join-Path $work 'Common/GlobalAssemblyInfo.cs'))
        Assert-Equal $true $iss.Contains("#define AppVersion `"$($case.Version)`"") "$($case.Tag) iss AppVersion"
        Assert-Equal $true $iss.Contains("#define AppDisplayVersion `"$($case.Display)`"") "$($case.Tag) iss AppDisplayVersion"
        Assert-Equal $crlfBefore ([regex]::Matches($iss, "`r`n")).Count "$($case.Tag) iss CRLF preserved"
        Assert-Equal $true $cs.Contains("AssemblyVersion(`"$($case.Assembly)`")") "$($case.Tag) AssemblyVersion"
        Assert-Equal $true $cs.Contains("AssemblyFileVersion(`"$($case.Version)`")") "$($case.Tag) AssemblyFileVersion"
        Assert-Equal $true $cs.Contains("AssemblyInformationalVersion(`"$($case.Display)`")") "$($case.Tag) InformationalVersion"
        $outputs = @(Get-Content -Path $outputFile)
        Assert-Equal "version=$($case.Version)" ($outputs -join '|') "$($case.Tag) GITHUB_OUTPUT has only version"
    }

    # --- new_winget_manifest.ps1 with a dummy installer, run from outside the repository ---
    $dummy = Join-Path $temp 'dummy-installer.exe'
    [IO.File]::WriteAllText($dummy, 'not a real installer')
    $dummyHash = (Get-FileHash -Path $dummy -Algorithm SHA256).Hash
    foreach ($case in @(
        @{ Env = 'example/fork'; Repo = 'example/fork' },
        @{ Env = $null;          Repo = 'omanningham/RevitBatchProcessor' })) {
        $out = Join-Path $temp ('manifest-' + [IO.Path]::GetRandomFileName())
        $outputFile = "$out.github_output"
        $savedRepo = $env:GITHUB_REPOSITORY
        $savedOutput = $env:GITHUB_OUTPUT
        $env:GITHUB_REPOSITORY = $case.Env
        $env:GITHUB_OUTPUT = $outputFile
        Push-Location $temp
        try { & (Join-Path $scripts 'new_winget_manifest.ps1') -Tag 'v1.14.0-brt.3' -InstallerPath $dummy -OutputDir $out 6>$null | Out-Null }
        finally { Pop-Location; $env:GITHUB_REPOSITORY = $savedRepo; $env:GITHUB_OUTPUT = $savedOutput }
        $dir = Join-Path $out 'Britton.RevitBatchProcessor/1.14.0.3'
        $installer = @(Get-Content -Path (Join-Path $dir 'Britton.RevitBatchProcessor.installer.yaml'))
        $locale = @(Get-Content -Path (Join-Path $dir 'Britton.RevitBatchProcessor.locale.fr-CA.yaml') -Encoding UTF8)
        $versionFile = @(Get-Content -Path (Join-Path $dir 'Britton.RevitBatchProcessor.yaml'))
        $url = "https://github.com/$($case.Repo)/releases/download/v1.14.0-brt.3/RevitBatchProcessorSetup_v1.14.0-brt.3.exe"
        foreach ($expected in @(
            'PackageVersion: 1.14.0.3',
            "ProductCode: '{B5CA57EA-7BB2-4620-916C-AE98376C1EF1}_is1'",
            '- DisplayName: Revit Batch Processor (Britton) 1.14.0-brt.3',
            '  Publisher: Britton',
            '  DisplayVersion: 1.14.0.3',
            "  InstallerUrl: $url",
            "  InstallerSha256: $dummyHash",
            'ManifestVersion: 1.10.0')) {
            Assert-Equal $true ($installer -contains $expected) "installer.yaml ($($case.Repo)) contains '$expected'"
        }
        foreach ($expected in @('PackageName: Revit Batch Processor (Britton)', 'Publisher: Britton', "PackageUrl: https://github.com/$($case.Repo)", 'ManifestVersion: 1.10.0')) {
            Assert-Equal $true ($locale -contains $expected) "locale.yaml ($($case.Repo)) contains '$expected'"
        }
        Assert-Equal $true ($versionFile -contains 'ManifestVersion: 1.10.0') 'version.yaml schema'
        $accentLines = @($locale | Where-Object { $_ -match 'Revit 2015 à 2027' })
        Assert-Equal 1 $accentLines.Count 'locale.yaml keeps accents'
        $manifestDir = @(Get-Content -Path $outputFile) -join '|'
        Assert-Equal $true ($manifestDir -like 'manifest_dir=*' -and $manifestDir -notlike '*\*') 'manifest_dir uses forward slashes'
    }
    Assert-Throws { & (Join-Path $scripts 'new_winget_manifest.ps1') -Tag 'v1.14.0' -InstallerPath $dummy -OutputDir (Join-Path $temp 'x') } 'Not a Britton release tag' 'manifest rejects upstream tag'
} finally {
    Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Output "PASS: release metadata tests under PowerShell $($PSVersionTable.PSVersion)"
