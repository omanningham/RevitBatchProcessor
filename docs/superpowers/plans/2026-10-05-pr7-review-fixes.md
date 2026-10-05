# Corrections de la revue de la PR #7 — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Corriger les constats confirmés de la revue de la PR #7 (numérotation Britton `vX.Y.Z-brt.N` et manifeste winget) : une seule source de vérité pour les versions et l'identité de l'installeur, un générateur de manifeste compatible avec la source REST et économe en mode manuel, et le nettoyage du code et de la documentation.

**Architecture:** Un nouveau script `.github/scripts/release_metadata.ps1`, chargé par dot-sourcing, regroupe :
- la conversion d'un tag en formes de version ;
- la lecture de l'identité de l'installeur (`AppId`, noms, éditeur) dans le script Inno ;
- la lecture de l'empreinte SHA256 publiée par GitHub.

`set_version.ps1` et `new_winget_manifest.ps1` s'appuient dessus au lieu de recopier les règles. Un script de test PowerShell autonome, sans Pester, couvre le tout, et la CI l'exécute.

**Tech Stack:** Windows PowerShell 5.1 et PowerShell 7, Inno Setup 6, manifestes winget au schéma 1.10.0, GitHub Actions, WinForms .NET Framework 4.8 (C#), Python 3 (`update_readme.py`), documentation Markdown en français.

**Spec:** pas de document de spécification séparé. Le plan applique le plan de correction validé dans la conversation du 5 octobre 2026, dont les éléments sont reproduits ici :
- Constats confirmés : (1) le dépôt est écrit en dur dans le générateur ; (2) la règle tag → version est dupliquée ; (3) la sortie `display_version` n'est pas utilisée ; (4) l'identité de l'installeur est recopiée du `.iss` ; (5) le schéma 1.12.0 n'est pas accepté par la source REST ; (6) l'installeur est téléchargé entièrement pour son empreinte ; (7) le helper du titre GUI est redondant ; (8) les commentaires et la documentation sont à corriger.
- Sources vérifiées :
  - Inno Setup, pages *AppId* (clé `<AppId>_is1`), *UninstallDisplayName* (valeur par défaut : `AppVerName`) et *Constants* (`{{` produit `{`).
  - GitHub Docs : `digest` est de type « string ou null » ; `GITHUB_REPOSITORY` et `github.repository` valent « owner/name ».
  - `winget-cli-restsource` 1.10.1 : versions serveur acceptées jusqu'à `1.10.0`.
  - Microsoft Learn : `$ProgressPreference` ; `-ProgressAction` n'existe qu'à partir de PowerShell 7.4.
  - Test réel sous .NET Framework 4.8 : `Control.ProductVersion` renvoie `AssemblyInformationalVersion`.

**Point de départ :** la branche `worktree-britton-versioning` (PR #7), commits `a76d859` et `425c4e8`. Le worktree se trouve dans `.claude/worktrees/britton-versioning`. Toutes les commandes s'exécutent depuis sa racine.

## Global Constraints

- Lire `docs/agent-development.md` avant toute modification ; commencer par `git status --short` et conserver les changements existants.
- Tous les scripts PowerShell doivent fonctionner sous Windows PowerShell 5.1 **et** PowerShell 7 ; les tests et la CI s'exécutent aussi sous PowerShell 7 Linux (`ubuntu-latest`).
- Un script `.ps1` contenant des caractères non ASCII (accents) doit être enregistré en UTF-8 **avec BOM** (sinon Windows PowerShell 5.1 le lit mal). `release_metadata.ps1` et les tests restent en ASCII.
- Nouveau fichier `.ps1`/`.py`/`.cs` : première ligne `# Revit Batch Processor -- GPL-3.0-or-later.` (vérifié par `check_repo.py`).
- Commentaires du code en anglais, documentation en français canadien avec accents.
- Ne pas modifier : le format des tags (`vX.Y.Z-brt.N`, et `vX.Y.Z` / `vX.Y.Z-beta` acceptés par `set_version.ps1`), l'`AppId` `{B5CA57EA-7BB2-4620-916C-AE98376C1EF1}`, le nom `RevitBatchProcessorSetup_<tag>.exe`, l'identifiant `Britton.RevitBatchProcessor`.
- Schéma des manifestes winget : `1.10.0`.
- Interdits : build de la solution ou des addins, compilation Inno Setup (`iscc`), installation, déploiement d'addins, `winget install`/`settings`/`source add`, `gh release`/`gh workflow run`.
- Hook du dépôt `.claude/hooks/block_addin_deploy.py` : toute commande Bash/PowerShell dont le **texte** contient `Setup/` suivi de `.iss` ou `.exe`, ou le mot `iscc`, est refusée. Lire le `.iss` avec l'outil Read ; indexer avec `git add -u` plutôt qu'en nommant le `.iss`. Ne jamais contourner le hook (chemins découpés, variables) : le classificateur le refuse.
- Fin de chaque message de commit : `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **Exécution manuelle depuis un autre dossier que la racine du dépôt** : le générateur doit quand même trouver le `.iss` (chemin relatif au script, pas au dossier courant). Test : tâche 4, exécution depuis un dossier temporaire.
2. **Fichier de release sans `digest` (valeur nulle)** : le générateur doit revenir au téléchargement, sans laisser de fichier temporaire. Tests : `ConvertFrom-AssetDigest $null` (tâche 1) et la vérification manuelle de la tâche 4.
3. **`.iss` retouché à la main** (espaces autour de `=`, `UninstallDisplayName` défini, define inconnu) : l'identité suit Inno ou échoue clairement. Test : jeux d'essai de la tâche 2.
4. **Poste sans PowerShell 7** : tout doit passer sous Windows PowerShell 5.1. Test : la tâche 7 exécute la suite sous les deux.
5. **`GITHUB_REPOSITORY` défini (CI) ou absent (poste)** : l'URL de l'installeur suit le dépôt réel. Test : tâche 4, les deux cas.

---

## Structure des fichiers

| Fichier | Action | Responsabilité |
| --- | --- | --- |
| `.github/scripts/release_metadata.ps1` | Créer | Fonctions partagées : `ConvertFrom-ReleaseTag`, `ConvertFrom-AssetDigest`, `Get-InstallerIdentity`. |
| `tests/release_metadata_tests.ps1` | Créer | Suite de tests autonome (fonctions, `set_version.ps1`, `new_winget_manifest.ps1`). |
| `.github/workflows/ci.yml` | Modifier | Exécuter la suite dans le job `checks`. |
| `.github/scripts/set_version.ps1` | Réécrire | Utiliser `ConvertFrom-ReleaseTag` ; retirer la sortie `display_version`. |
| `.github/scripts/new_winget_manifest.ps1` | Réécrire | Utiliser les fonctions partagées, schéma 1.10.0, dépôt depuis `GITHUB_REPOSITORY`, empreinte via l'API. |
| `BatchRvtGUI/BatchRvtGuiForm.cs` | Modifier | Titre via `ProductVersion` ; supprimer le helper. |
| `.github/workflows/build_msi.yml` | Modifier | Commentaires à leur juste place. |
| `.github/workflows/update_readme.py` | Modifier | Commentaire du motif. |
| `docs/winget.md`, `docs/britton-customizations.md`, `docs/agent-development.md` | Modifier | Documentation. |

---

### Task 1: Fonctions de version partagées et suite de tests

**Files:**
- Create: `.github/scripts/release_metadata.ps1`
- Create: `tests/release_metadata_tests.ps1`
- Modify: `.github/workflows/ci.yml` (job `checks`, après l'étape « Scripts listed in csproj, Markdown links, GPL headers »)

**Interfaces:**
- Consumes: rien.
- Produces:
  - `ConvertFrom-ReleaseTag -Tag <string> [-BrittonOnly]` → `[pscustomobject]` avec `Tag` (string), `IsBritton` (bool), `Version` (`X.Y.Z.N`), `DisplayVersion` (tag sans `v`), `AssemblyVersion` (`X.Y.Z.0`). Lève une exception si le format est invalide, si `N` > 65535, ou si le tag n'est pas Britton avec `-BrittonOnly`.
  - `ConvertFrom-AssetDigest [string]$Digest` → empreinte SHA256 hexadécimale en majuscules, ou `$null`.
  - Dans `tests/release_metadata_tests.ps1` : les helpers `Assert-Equal($Expected, $Actual, [string]$What)` et `Assert-Throws([scriptblock]$Code, [string]$Pattern, [string]$What)`, la variable `$temp` (dossier temporaire supprimé en fin d'exécution) et `$scripts` (chemin de `.github/scripts`). Les tâches suivantes ajoutent leurs sections **juste avant la ligne `} finally {`**.

- [ ] **Step 1: Écrire la suite de tests (échoue : le script partagé n'existe pas)**

Créer `tests/release_metadata_tests.ps1` :

```powershell
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
```

- [ ] **Step 2: Vérifier que la suite échoue**

Run: `pwsh -NoProfile -File tests/release_metadata_tests.ps1`
Expected: FAIL. Le message indique que `release_metadata.ps1` est introuvable (« is not recognized » ou « Cannot find path »).

- [ ] **Step 3: Écrire le script partagé**

Créer `.github/scripts/release_metadata.ps1` (ASCII uniquement) :

```powershell
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
```

- [ ] **Step 4: Vérifier que la suite passe**

Run: `pwsh -NoProfile -File tests/release_metadata_tests.ps1`
Expected: `PASS: release metadata tests under PowerShell 7.x`

Run: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/release_metadata_tests.ps1`
Expected: `PASS: release metadata tests under PowerShell 5.1.x`

- [ ] **Step 5: Brancher la suite dans la CI**

Dans `.github/workflows/ci.yml`, job `checks`, ajouter juste après l'étape `Scripts listed in csproj, Markdown links, GPL headers` (même indentation) :

```yaml
      - name: Release version and winget manifest scripts
        shell: pwsh
        run: ./tests/release_metadata_tests.ps1
```

- [ ] **Step 6: Contrôles du dépôt**

Run: `python .github/scripts/check_repo.py --base master`
Expected: `scripts: OK`, `links: OK`, `headers: OK`

Run: `git diff --check`
Expected: aucune sortie (les avertissements LF/CRLF sont acceptables).

- [ ] **Step 7: Commit**

```bash
git add .github/scripts/release_metadata.ps1 tests/release_metadata_tests.ps1 .github/workflows/ci.yml
git commit -m "Share release tag parsing in release_metadata.ps1, with tests in CI" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Identité de l'installeur lue dans le script Inno

**Files:**
- Modify: `.github/scripts/release_metadata.ps1` (ajouter `Get-InstallerIdentity` à la fin)
- Modify: `tests/release_metadata_tests.ps1` (nouvelle section avant `} finally {`)

**Interfaces:**
- Consumes: l'objet renvoyé par `ConvertFrom-ReleaseTag` (Task 1), propriétés `Version` et `DisplayVersion`.
- Produces: `Get-InstallerIdentity -IssPath <string> -Release <object>` → `[pscustomobject]` avec :
  - `ProductCode` (`<AppId>_is1`, accolade d'échappement réduite) ;
  - `PackageName` (`AppName` développé) ;
  - `DisplayName` (`UninstallDisplayName` s'il est défini, sinon `AppVerName`, développé) ;
  - `Publisher` (`AppPublisher`).

  Lève une exception si `AppId`, `AppName`, `AppVerName` ou `AppPublisher` manque, ou si un `{#Define}` est inconnu.

- [ ] **Step 1: Ajouter les tests (échouent : fonction absente)**

Insérer dans `tests/release_metadata_tests.ps1`, juste avant la ligne `} finally {` :

```powershell
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
```

- [ ] **Step 2: Vérifier l'échec**

Run: `pwsh -NoProfile -File tests/release_metadata_tests.ps1`
Expected: FAIL avec « The term 'Get-InstallerIdentity' is not recognized ».

- [ ] **Step 3: Implémenter**

Ajouter à la fin de `.github/scripts/release_metadata.ps1` :

```powershell

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
```

- [ ] **Step 4: Vérifier le succès sous les deux moteurs**

Run: `pwsh -NoProfile -File tests/release_metadata_tests.ps1`
Expected: `PASS: ... 7.x`

Run: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/release_metadata_tests.ps1`
Expected: `PASS: ... 5.1.x`

- [ ] **Step 5: Commit**

```bash
git add .github/scripts/release_metadata.ps1 tests/release_metadata_tests.ps1
git commit -m "Read the installer identity from the Inno script" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: `set_version.ps1` sur les fonctions partagées

**Files:**
- Modify (réécriture complète) : `.github/scripts/set_version.ps1`
- Modify: `tests/release_metadata_tests.ps1` (nouvelle section avant `} finally {`)

**Interfaces:**
- Consumes: `ConvertFrom-ReleaseTag` (Task 1).
- Produces: comportement inchangé pour le workflow. Seule différence : `GITHUB_OUTPUT` reçoit uniquement `version=X.Y.Z.N`, puisque la sortie `display_version` est supprimée. `build_msi.yml` lit toujours `steps.version_num_set.outputs.version`.

- [ ] **Step 1: Ajouter le test de bout en bout (échoue : `display_version` est encore écrit)**

Insérer avant `} finally {` :

```powershell
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
```

- [ ] **Step 2: Vérifier l'échec**

Run: `pwsh -NoProfile -File tests/release_metadata_tests.ps1`
Expected: FAIL avec `v1.14.0-brt.3 GITHUB_OUTPUT has only version : expected 'version=1.14.0.3', got 'version=1.14.0.3|display_version=1.14.0-brt.3'`

- [ ] **Step 3: Réécrire `set_version.ps1`**

Remplacer tout le contenu de `.github/scripts/set_version.ps1` par :

```powershell
# Revit Batch Processor -- GPL-3.0-or-later.
# Applies a release tag to the installer script and GlobalAssemblyInfo.cs, and writes the
# numeric version to $GITHUB_OUTPUT. Used by build_msi.yml (build of the tag, and version
# PR against master). Tag rules and version forms are in release_metadata.ps1.
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Tag)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'release_metadata.ps1')

$release = ConvertFrom-ReleaseTag -Tag $Tag
Write-Host "Tag $Tag -> version $($release.Version), display version $($release.DisplayVersion)"

$iss = 'Setup/RevitBatchProcessor.iss'
$content = Get-Content -Path $iss -Raw
# [^"\r\n]* rather than .* so the CRLF line ending is preserved.
$content = $content -replace '#define AppVersion "[^"\r\n]*"', "#define AppVersion `"$($release.Version)`""
$content = $content -replace '#define AppDisplayVersion "[^"\r\n]*"', "#define AppDisplayVersion `"$($release.DisplayVersion)`""
Set-Content -Path $iss -Value $content -NoNewline

$assemblyInfo = 'Common/GlobalAssemblyInfo.cs'
$content = Get-Content -Path $assemblyInfo -Raw
$content = $content -replace 'AssemblyVersion\("[^"]*"\)', "AssemblyVersion(`"$($release.AssemblyVersion)`")"
$content = $content -replace 'AssemblyFileVersion\("[^"]*"\)', "AssemblyFileVersion(`"$($release.Version)`")"
$content = $content -replace 'AssemblyInformationalVersion\("[^"]*"\)', "AssemblyInformationalVersion(`"$($release.DisplayVersion)`")"
Set-Content -Path $assemblyInfo -Value $content -NoNewline

if ($env:GITHUB_OUTPUT) { "version=$($release.Version)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8 }
```

- [ ] **Step 4: Vérifier le succès sous les deux moteurs**

Run: `pwsh -NoProfile -File tests/release_metadata_tests.ps1`, puis `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/release_metadata_tests.ps1`
Expected: `PASS` deux fois.

Run: `git diff -- Common/GlobalAssemblyInfo.cs`
Expected: aucune sortie. Le test a travaillé sur des copies, les fichiers du dépôt sont inchangés.

- [ ] **Step 5: Commit**

```bash
git add .github/scripts/set_version.ps1 tests/release_metadata_tests.ps1
git commit -m "set_version.ps1: use the shared tag parsing, drop the unused display_version output" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Générateur de manifeste winget sur les fonctions partagées

**Files:**
- Modify (réécriture complète) : `.github/scripts/new_winget_manifest.ps1` (UTF-8 **avec BOM**)
- Modify: `tests/release_metadata_tests.ps1` (nouvelle section avant `} finally {`)

**Interfaces:**
- Consumes: `ConvertFrom-ReleaseTag -BrittonOnly`, `Get-InstallerIdentity`, `ConvertFrom-AssetDigest` (Tasks 1-2).
- Produces: script `new_winget_manifest.ps1 -Tag <vX.Y.Z-brt.N> [-InstallerPath <file>] [-OutputDir <dir>] [-Repository <owner/name>] [-IssPath <file>]`.
  - Écrit `<OutputDir>/Britton.RevitBatchProcessor/<X.Y.Z.N>/` avec trois fichiers : `Britton.RevitBatchProcessor.yaml`, `Britton.RevitBatchProcessor.locale.fr-CA.yaml` et `Britton.RevitBatchProcessor.installer.yaml`.
  - Ajoute `manifest_dir=<chemin avec />` à `GITHUB_OUTPUT`.
  - `-Repository` vaut par défaut `$env:GITHUB_REPOSITORY`, sinon `omanningham/RevitBatchProcessor`.
  - `-IssPath` vaut par défaut `<racine du dépôt>/Setup/RevitBatchProcessor.iss`, résolu depuis l'emplacement du script.
  - Le workflow (`build_msi.yml`) n'a pas besoin de changer d'appel.

- [ ] **Step 1: Ajouter les tests (échouent : schéma 1.12.0, dépôt en dur)**

Insérer avant `} finally {` :

```powershell
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
```

Le fichier de test contient maintenant « à » : l'enregistrer en UTF-8 **avec BOM** (sinon Windows PowerShell 5.1 lit mal le motif et le test échoue) :

```powershell
$p = (Resolve-Path 'tests/release_metadata_tests.ps1').Path
[IO.File]::WriteAllText($p, [IO.File]::ReadAllText($p, [Text.Encoding]::UTF8), (New-Object Text.UTF8Encoding $true))
```

- [ ] **Step 2: Vérifier l'échec**

Run: `pwsh -NoProfile -File tests/release_metadata_tests.ps1`
Expected: FAIL avec `installer.yaml (example/fork) contains '  InstallerUrl: https://github.com/example/fork/...' : expected 'True', got 'False'`, puisque le dépôt est encore écrit en dur.

- [ ] **Step 3: Réécrire le générateur**

Remplacer tout le contenu de `.github/scripts/new_winget_manifest.ps1` par :

```powershell
# Revit Batch Processor -- GPL-3.0-or-later.
# Writes the winget manifest (version, defaultLocale and installer files) of a Britton
# release, for a private winget source. See docs/winget.md. Schema 1.10.0: the latest
# version accepted by the Microsoft.WinGet.RestSource server.
#
# Versions come from the tag and the installer identity (ProductCode, names, publisher)
# from the Inno script, through release_metadata.ps1, so the manifest matches what the
# installer registers. The installer hash comes from -InstallerPath (release workflow)
# or, for a manual run, from the digest GitHub publishes for the release asset, with a
# download of the installer as fallback.
# Output: <OutputDir>/Britton.RevitBatchProcessor/<X.Y.Z.N>/*.yaml, the folder layout
# expected by `winget validate --manifest` and Add-WinGetManifest.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Tag,
    [string]$InstallerPath,
    [string]$OutputDir = 'winget-manifests',
    [string]$Repository,
    [string]$IssPath
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'release_metadata.ps1')

# GITHUB_REPOSITORY is set in workflows; the fork is the default for a manual run.
if (-not $Repository) { $Repository = if ($env:GITHUB_REPOSITORY) { $env:GITHUB_REPOSITORY } else { 'omanningham/RevitBatchProcessor' } }
if (-not $IssPath) { $IssPath = Join-Path (Split-Path (Split-Path $PSScriptRoot)) 'Setup/RevitBatchProcessor.iss' }

$release = ConvertFrom-ReleaseTag -Tag $Tag -BrittonOnly
$installer = Get-InstallerIdentity -IssPath $IssPath -Release $release
$version = $release.Version

$packageId = 'Britton.RevitBatchProcessor'
$repoUrl = "https://github.com/$Repository"
$installerName = "RevitBatchProcessorSetup_$Tag.exe"
$installerUrl = "$repoUrl/releases/download/$Tag/$installerName"
$manifestVersion = '1.10.0'
$schemaBase = 'https://aka.ms/winget-manifest'

if ($InstallerPath) {
    $sha256 = (Get-FileHash -Path $InstallerPath -Algorithm SHA256).Hash
} else {
    $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repository/releases/tags/$Tag" -Headers @{ 'User-Agent' = 'new_winget_manifest.ps1' }
    $asset = @($releaseInfo.assets | Where-Object { $_.name -eq $installerName })
    if ($asset.Count -ne 1) { throw "Installer $installerName not found in release $Tag of $Repository" }
    $sha256 = ConvertFrom-AssetDigest $asset[0].digest
    if (-not $sha256) {
        # No digest for this asset: hash a downloaded copy, then delete it.
        $download = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
        try {
            # The progress bar slows large downloads under Windows PowerShell 5.1.
            $ProgressPreference = 'SilentlyContinue'
            Write-Host "Downloading $installerUrl"
            Invoke-WebRequest -Uri $installerUrl -OutFile $download -UseBasicParsing
            $sha256 = (Get-FileHash -Path $download -Algorithm SHA256).Hash
        } finally {
            Remove-Item -LiteralPath $download -ErrorAction SilentlyContinue
        }
    }
}

$header = "# Generated by .github/scripts/new_winget_manifest.ps1 from tag $Tag."
$files = @{
    "$packageId.yaml" = @"
$header
# yaml-language-server: `$schema=$schemaBase.version.$manifestVersion.schema.json

PackageIdentifier: $packageId
PackageVersion: $version
DefaultLocale: fr-CA
ManifestType: version
ManifestVersion: $manifestVersion
"@
    "$packageId.locale.fr-CA.yaml" = @"
$header
# yaml-language-server: `$schema=$schemaBase.defaultLocale.$manifestVersion.schema.json

PackageIdentifier: $packageId
PackageVersion: $version
PackageLocale: fr-CA
Publisher: $($installer.Publisher)
PackageName: $($installer.PackageName)
PackageUrl: $repoUrl
License: GPL-3.0-or-later
LicenseUrl: $repoUrl/blob/master/LICENSE.txt
ShortDescription: Traitement par lots de fichiers Revit avec des scripts Python ou Dynamo (version Britton $($release.DisplayVersion)).
Description: |-
  Version Britton de Revit Batch Processor : addins Revit 2015 à 2027 et interface BatchRvtGUI.
  Fermer Revit avant l'installation ou la mise à jour : les addins sont remplacés dans le profil Windows.
Moniker: revit-batch-processor
Tags:
- revit
- autodesk
- batch
- python
- dynamo
ReleaseNotesUrl: $repoUrl/releases/tag/$Tag
ManifestType: defaultLocale
ManifestVersion: $manifestVersion
"@
    "$packageId.installer.yaml" = @"
$header
# yaml-language-server: `$schema=$schemaBase.installer.$manifestVersion.schema.json

PackageIdentifier: $packageId
PackageVersion: $version
Platform:
- Windows.Desktop
MinimumOSVersion: 10.0.0.0
InstallerType: inno
Scope: user
InstallModes:
- interactive
- silent
- silentWithProgress
UpgradeBehavior: install
ProductCode: '$($installer.ProductCode)'
AppsAndFeaturesEntries:
- DisplayName: $($installer.DisplayName)
  Publisher: $($installer.Publisher)
  DisplayVersion: $version
  ProductCode: '$($installer.ProductCode)'
Installers:
- Architecture: x64
  InstallerUrl: $installerUrl
  InstallerSha256: $sha256
ManifestType: installer
ManifestVersion: $manifestVersion
"@
}

$dir = Join-Path $OutputDir (Join-Path $packageId $version)
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
foreach ($name in $files.Keys) {
    [IO.File]::WriteAllText((Join-Path $dir $name), $files[$name].Replace("`r`n", "`n") + "`n", $utf8NoBom)
}
Write-Host "Manifest $packageId $version written to $dir (SHA256 $sha256)"
# Forward slashes: the release upload step uses the folder in a glob, where "\" escapes.
if ($env:GITHUB_OUTPUT) { "manifest_dir=$($dir -replace '\\', '/')" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8 }
```

Puis réenregistrer le fichier en UTF-8 avec BOM, car il contient des accents :

```powershell
$p = (Resolve-Path '.github/scripts/new_winget_manifest.ps1').Path
[IO.File]::WriteAllText($p, [IO.File]::ReadAllText($p, [Text.Encoding]::UTF8), (New-Object Text.UTF8Encoding $true))
[IO.File]::ReadAllBytes($p)[0..2] -join ','
```
Expected: `239,187,191`

- [ ] **Step 4: Vérifier le succès sous les deux moteurs**

Run: `pwsh -NoProfile -File tests/release_metadata_tests.ps1`, puis `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/release_metadata_tests.ps1`
Expected: `PASS` deux fois.

- [ ] **Step 5: Valider le manifeste avec winget (Windows uniquement)**

```powershell
$out = Join-Path ([IO.Path]::GetTempPath()) 'rbp-winget-validate'
if (Test-Path $out) { Remove-Item $out -Recurse -Force }
$dummy = Join-Path ([IO.Path]::GetTempPath()) 'rbp-dummy.exe'; [IO.File]::WriteAllText($dummy, 'x')
.\.github\scripts\new_winget_manifest.ps1 -Tag v1.13.0-brt.1 -InstallerPath $dummy -OutputDir $out
winget validate --manifest "$out\Britton.RevitBatchProcessor\1.13.0.1"
Remove-Item $out -Recurse -Force; Remove-Item $dummy
```
Expected: `La validation du manifeste a réussi.` (ou « Manifest validation succeeded »)

- [ ] **Step 6: Vérifier la lecture de l'empreinte par l'API (réseau, sans téléchargement)**

Le fork n'a pas encore de release `-brt.N`. On vérifie donc, sur la release officielle `v1.13.0-beta`, la forme réelle de la réponse de l'API et la conversion :

```powershell
. .\.github\scripts\release_metadata.ps1
$r = Invoke-RestMethod -Uri 'https://api.github.com/repos/bvn-architecture/RevitBatchProcessor/releases/tags/v1.13.0-beta' -Headers @{ 'User-Agent' = 'check' }
ConvertFrom-AssetDigest ($r.assets | Where-Object name -eq 'RevitBatchProcessorSetup_v1.13.0-beta.exe').digest
```
Expected: `F8E7F6D17ED0FF34978B5D205B1999CF0E66DC042FE995D88281806AF5A6A88D`

- [ ] **Step 7: Commit**

```bash
git add .github/scripts/new_winget_manifest.ps1 tests/release_metadata_tests.ps1
git commit -m "winget manifest: shared metadata, schema 1.10.0, repository from GITHUB_REPOSITORY, hash from the release digest" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Titre de BatchRvtGUI via `ProductVersion`

**Files:**
- Modify: `BatchRvtGUI/BatchRvtGuiForm.cs`. Trois zones : la directive `using System.Reflection;` vers la ligne 27, `Text = GetWindowTitleWithVersion();` dans `BatchRvtGuiForm_Load` vers la ligne 376, et la méthode `GetWindowTitleWithVersion` avec son commentaire, vers les lignes 495-503.

**Interfaces:**
- Consumes: `AssemblyInformationalVersion` de `Common/GlobalAssemblyInfo.cs` (actuellement `1.13.0-brt.1`).
- Produces: un titre de fenêtre inchangé, `Revit Batch Processor v1.13.0-brt.1`.

Il s'agit d'une refonte sans changement de comportement : le même contrôle s'exécute avant et après la modification.

- [ ] **Step 1: Compiler la GUI et relever le titre actuel (référence)**

Build ciblé, sans addin ni déploiement. La GUI ne référence que `BatchRvtUtil`, `BatchRvt` et `BatchRevitDynamo`.

```powershell
& 'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\amd64\MSBuild.exe' 'BatchRvtGUI/BatchRvtGUI.csproj' -restore -p:RestorePackagesConfig=true /t:Build /p:Configuration=Release /p:Platform=x64 /p:DeployAddinOnBuild=false /p:PostBuildEvent= /m /v:minimal /nologo
```
Expected: `BatchRvtGUI -> ...\BatchRvtGUI\bin\x64\Release\BatchRvtGUI.exe`. Les avertissements MSB3243, MSB3277, MSB3884, CS0168 et CS0169 existaient déjà.

Lire le titre de la fenêtre. La GUI s'ouvre puis est fermée ; elle ne lance pas Revit.

```powershell
$p = Start-Process -FilePath (Resolve-Path 'BatchRvtGUI\bin\x64\Release\BatchRvtGUI.exe') -PassThru
$title = ''
for ($i = 0; $i -lt 40 -and -not $title; $i++) { Start-Sleep -Milliseconds 500; $p.Refresh(); $title = $p.MainWindowTitle }
Stop-Process -Id $p.Id
$title
```
Expected: `Revit Batch Processor v1.13.0-brt.1`. Si une boîte de dialogue de démarrage s'affiche à la place, la noter et refaire la même observation à l'étape 3.

- [ ] **Step 2: Simplifier le code**

Dans `BatchRvtGUI/BatchRvtGuiForm.cs` :

1. Remplacer :

```csharp
        Text = GetWindowTitleWithVersion();
```

par :

```csharp
        // ProductVersion is the informational version (Common/GlobalAssemblyInfo.cs), e.g. "1.13.0-brt.1".
        Text = $"{WINDOW_TITLE} v{ProductVersion}";
```

2. Supprimer entièrement le bloc suivant :

```csharp
    // Informational version from Common/GlobalAssemblyInfo.cs, e.g. "1.13.0-brt.1".
    private static string GetWindowTitleWithVersion()
    {
        var version = typeof(BatchRvtGuiForm).Assembly
            .GetCustomAttribute<AssemblyInformationalVersionAttribute>()?.InformationalVersion;

        return string.IsNullOrWhiteSpace(version) ? WINDOW_TITLE : $"{WINDOW_TITLE} v{version}";
    }

```

3. Vérifier qu'aucun autre code du fichier n'utilise `System.Reflection` :

Run: `git grep -n "Assembly\|GetCustomAttribute\|BindingFlags\|MethodInfo" -- BatchRvtGUI/BatchRvtGuiForm.cs`
Expected: aucune ligne. Supprimer alors la ligne `using System.Reflection;`. Si une ligne apparaît, conserver le `using`.

- [ ] **Step 3: Recompiler et relever le titre**

Relancer les deux commandes de l'étape 1.
Expected: le build réussit, sans nouvel avertissement venant de `BatchRvtGuiForm.cs`, et le titre est identique : `Revit Batch Processor v1.13.0-brt.1`.

- [ ] **Step 4: Commit**

```bash
git add BatchRvtGUI/BatchRvtGuiForm.cs
git commit -m "GUI title: use Control.ProductVersion instead of a reflection helper" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Commentaires et documentation

**Files:**
- Modify: `.github/workflows/build_msi.yml` (commentaires, lignes 53-79)
- Modify: `.github/workflows/update_readme.py` (commentaire de `VERSION_PATTERN`)
- Modify: `docs/winget.md`, `docs/britton-customizations.md`, `docs/agent-development.md`

**Interfaces:**
- Consumes: le comportement des tâches 1 à 4 (schéma 1.10.0, `GITHUB_REPOSITORY`, empreinte via l'API, identité lue dans le `.iss`, suite de tests en CI).
- Produces: aucune interface de code.

- [ ] **Step 1: `build_msi.yml`, mettre les commentaires à leur juste place**

Avant l'étape `- name: Upload Release Asset`, ajouter (6 espaces d'indentation) :

```yaml
      # The installer name is OutputBaseFilename, RevitBatchProcessorSetup_v{#AppDisplayVersion},
      # i.e. the raw tag: set_version.ps1 writes AppDisplayVersion from it.
```

Remplacer :

```yaml
      # winget manifest for the private source (docs/winget.md), hashed from the
      # installer built above. Britton tags only.
```

par :

```yaml
      # winget manifest for the private source (docs/winget.md), hashed from the
      # installer built above; URLs use GITHUB_REPOSITORY. Britton tags only.
```

Remplacer :

```yaml
  # Version bump PR against master: README, installer script and assembly version.
  # Britton tags are vX.Y.Z-brt.N (see docs/britton-customizations.md); the uploaded
  # installer name matches OutputBaseFilename only because both use the raw tag.
  # Requires "Allow GitHub Actions to create and approve pull requests" in the
```

par :

```yaml
  # Version bump PR against master: README, installer script and assembly version.
  # Britton tags are vX.Y.Z-brt.N (see docs/britton-customizations.md).
  # Requires "Allow GitHub Actions to create and approve pull requests" in the
```

- [ ] **Step 2: `update_readme.py`, préciser le commentaire du motif**

Remplacer :

```python
# A trailing " beta" label is dropped too: Britton releases are not beta.
```

par :

```python
# Matches X.Y.Z, X.Y.Z.N, X.Y.Z-beta and X.Y.Z-brt.N, plus a trailing " beta" label,
# dropped because Britton releases are not beta.
```

- [ ] **Step 3: `docs/winget.md`**

a) Supprimer le paragraphe (et la ligne vide qui le suit) :

```markdown
État constaté le 5 octobre 2026 : winget 1.29, sources par défaut seulement
(`msstore`, `winget`, `winget-font`), installation de manifestes locaux désactivée.
Aucune source Britton n'existe encore.
```

b) Dans le tableau « Ce que le dépôt fournit », remplacer la ligne du script par :

```markdown
| [new_winget_manifest.ps1](../.github/scripts/new_winget_manifest.ps1) | Écrit le manifeste winget (trois fichiers YAML, schéma 1.10.0, le plus récent accepté par la source REST officielle) d'un tag `vX.Y.Z-brt.N`. Les versions viennent du tag ; le code produit, le nom et l'éditeur sont lus dans le script Inno. |
```

c) Remplacer le paragraphe qui commence par « Le `ProductCode` est la clé de désinstallation » et tout ce qui le suit jusqu'à la ligne « Le dossier `winget-manifests/` est ignoré par Git. » incluse, par :

````markdown
Le `ProductCode` est la clé de désinstallation `<AppId>_is1` créée par Inno Setup ;
le choix de l'`AppId` est expliqué dans la
[numérotation des versions](britton-customizations.md#numérotation-des-versions).
Winget reconnaît ainsi une installation BVN ou Britton existante par ce code, pas par
le nom affiché, et propose la mise à jour vers la version Britton.

## Obtenir le manifeste

- Release `vX.Y.Z-brt.N` : télécharger ses trois fichiers `.yaml` dans un même dossier.
  Le workflow de release les y a ajoutés, avec l'empreinte de l'installeur compilé.
- Sinon (release sans manifeste joint), le générer depuis la racine du dépôt. Le script
  lit l'empreinte SHA256 publiée par GitHub pour l'installeur de la release et ne le
  télécharge que si GitHub n'en fournit pas :

```powershell
.\.github\scripts\new_winget_manifest.ps1 -Tag v1.13.0-brt.1
winget validate --manifest .\winget-manifests\Britton.RevitBatchProcessor\1.13.0.1
```

Le dossier `winget-manifests/` est ignoré par Git.
````

d) Dans « Étape 1 », remplacer l'item 2 par :

```markdown
2. Dans un terminal normal, placer les trois fichiers `.yaml` (voir « Obtenir le manifeste ») dans un même dossier.
```

e) Dans « Étape 2 », supprimer le paragraphe suivant le tableau :

```markdown
Une source REST est le choix le plus simple à maintenir pour quelques paquets internes.
La création des ressources Azure engage des coûts et relève de l'administration Azure
de Britton.
```

f) Dans « Étape 3 », remplacer « À faire une fois, par une personne disposant des droits sur l'abonnement Azure : » par :

```markdown
À faire une fois, par une personne disposant des droits sur l'abonnement Azure. La
création des ressources engage des coûts et relève de l'administration Azure de Britton.
```

g) Dans « Étape 5 », remplacer l'item 2 « Télécharger les trois fichiers `.yaml` dans un dossier, puis : » par :

```markdown
2. Placer les trois fichiers `.yaml` de la release dans un dossier (voir « Obtenir le manifeste »), puis :
```

h) Dans « Limites connues », ajouter en dernier item :

```markdown
- État au 5 octobre 2026 : aucune source Britton n'est encore créée ; les étapes 3 à 5 n'ont pas été exécutées.
```

- [ ] **Step 4: `docs/britton-customizations.md`, section « Numérotation des versions »**

Remplacer :

```markdown
car les deux installent les mêmes addins. Seuls le nom affiché
(« Revit Batch Processor (Britton) ») et l'éditeur changent.
```

par :

```markdown
car les deux installent les mêmes addins. Seuls le nom affiché
(« Revit Batch Processor (Britton) X.Y.Z-brt.N ») et l'éditeur (« Britton ») changent :
un inventaire ou une détection (Intune, script) fondé sur l'ancien nom doit passer à
la clé `{B5CA57EA-7BB2-4620-916C-AE98376C1EF1}_is1`.
```

Remplacer :

```markdown
[set_version.ps1](../.github/scripts/set_version.ps1) dérive toutes ces valeurs du tag,
dans le workflow de release et dans la PR de version vers `master`. La distribution
```

par :

```markdown
[release_metadata.ps1](../.github/scripts/release_metadata.ps1) définit ces règles ;
[set_version.ps1](../.github/scripts/set_version.ps1) les applique au tag dans le
workflow de release et dans la PR de version vers `master`. Il accepte aussi les tags
officiels `vX.Y.Z` et `vX.Y.Z-beta` (révision 0) ; seuls les tags `-brt.N` produisent
un manifeste winget. La distribution
```

- [ ] **Step 5: `docs/agent-development.md`, mentionner la suite de tests**

Remplacer :

```markdown
liens Markdown, en-têtes GPL des nouveaux fichiers), le build de la solution et
```

par :

```markdown
liens Markdown, en-têtes GPL des nouveaux fichiers), `tests/release_metadata_tests.ps1`
(versions tirées du tag, identité de l'installeur, manifeste winget), le build de la solution et
```

- [ ] **Step 6: Contrôles**

Run: `python .github/scripts/check_repo.py --base master`
Expected: `scripts: OK`, `links: OK`, `headers: OK`. Les ancres `#numérotation-des-versions` sont donc valides.

Run: `git diff --check`
Expected: aucune sortie.

Run: `pwsh -NoProfile -File tests/release_metadata_tests.ps1`
Expected: `PASS`. Aucun comportement n'a changé.

- [ ] **Step 7: Commit**

```bash
git add .github/workflows/build_msi.yml .github/workflows/update_readme.py docs/winget.md docs/britton-customizations.md docs/agent-development.md
git commit -m "Docs and comments after the PR #7 review" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Vérification finale, poussée et description de la PR

**Files:**
- Aucun fichier du dépôt. Un fichier temporaire sert pour la description de la PR.

**Interfaces:**
- Consumes: tous les commits des tâches 1 à 6.
- Produces: la branche `worktree-britton-versioning` poussée et la PR #7 mise à jour.

- [ ] **Step 1: Suite complète sous les deux moteurs**

Run: `pwsh -NoProfile -File tests/release_metadata_tests.ps1`
Expected: `PASS: release metadata tests under PowerShell 7.x`

Run: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/release_metadata_tests.ps1`
Expected: `PASS: release metadata tests under PowerShell 5.1.x`

- [ ] **Step 2: Contrôles du dépôt et état propre**

Run: `python .github/scripts/check_repo.py --base master` → `scripts: OK`, `links: OK`, `headers: OK`
Run: `git diff --check master...HEAD` → aucune sortie
Run: `git status --short` → aucune sortie (en dehors des sorties de build ignorées)

- [ ] **Step 3: Relire le diff complet**

Run: `git diff master...HEAD --stat` et `git log --oneline master..HEAD`
Expected : les deux commits d'origine plus les commits des tâches 1 à 6, sans aucun fichier hors de la liste « Structure des fichiers » de ce plan ni des commits d'origine.

- [ ] **Step 4: Pousser**

Run: `git push`
Expected : la branche `worktree-britton-versioning` est mise à jour sur `origin`. Ne jamais pousser sur `master`, ni forcer.

- [ ] **Step 5: Mettre à jour la description de la PR #7**

Écrire dans un fichier temporaire, hors du dépôt (par exemple `$env:TEMP\pr7_body_fixes.md`), la section suivante. Le texte ne doit pas contenir le mot réservé au compilateur Inno, sinon le hook refuse la commande `gh` qui l'utilise.

```markdown
## Corrections après revue (3e lot)

- `release_metadata.ps1` : règles du tag, identité de l'installeur lue dans le script Inno (`AppId` → `ProductCode`, nom affiché, éditeur), empreinte publiée par GitHub ; utilisées par `set_version.ps1` et `new_winget_manifest.ps1`.
- Manifeste au schéma 1.10.0 (dernier accepté par Microsoft.WinGet.RestSource), URLs depuis `GITHUB_REPOSITORY`, empreinte lue via l'API GitHub en usage manuel (téléchargement en repli, sans fichier résiduel).
- Sortie `display_version` retirée ; titre GUI via `ProductVersion`.
- `tests/release_metadata_tests.ps1` exécuté en CI (job `checks`) ; vérifié localement sous PowerShell 7 et 5.1, plus `winget validate` et build ciblé de la GUI.
```

Puis récupérer la description actuelle, y ajouter cette section juste avant la ligne `🤖 Generated with [Claude Code](https://claude.com/claude-code)` et republier :

```powershell
gh pr view 7 --repo omanningham/RevitBatchProcessor --json body --jq .body | Out-File "$env:TEMP\pr7_body.md" -Encoding utf8
```

Insérer la section dans `$env:TEMP\pr7_body.md` (avec l'outil Edit), puis :

```powershell
gh pr edit 7 --repo omanningham/RevitBatchProcessor --body-file "$env:TEMP\pr7_body.md"
```
Expected : la commande affiche l'URL de la PR #7.

- [ ] **Step 6: Compte rendu**

Rendre compte des fichiers modifiés, des commandes exécutées avec leur résultat, et des limites qui restent :
- pas de compilation Inno ;
- pas d'installation réelle par winget ;
- étapes du workflow de release non exécutées avant la première release `-brt.1` ;
- lecture de l'empreinte du fork par l'API non testée, faute de release `-brt.N`.

---

## Hors périmètre (décidé, ne pas implémenter)

- Fusionner les deux étapes d'upload de la release : un échec du manifeste bloquerait l'upload de l'installeur.
- Factoriser le nom de l'installeur, répété dans le workflow : un écart échoue de façon visible (`fail_on_unmatched_files`, fichier manquant).
- Faire lire la version par Inno dans l'exe, au lieu de garder le second `#define` : c'est une refonte, et la faisabilité n'est pas vérifiée avec l'action Inno du workflow.
- Le suffixe « (current user) » ajouté par Inno lors d'une installation pour tous les utilisateurs par une autre voie : la correspondance winget passe par le code produit.
- Les cas cosmétiques : `1.14.0.0` pour un tag officiel, le texte des liens du README pour un tag `-beta`, la différence entre le titre de la fenêtre et celui des boîtes de message.
