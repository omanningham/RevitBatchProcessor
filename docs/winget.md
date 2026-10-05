# Distribution Britton par winget

Ce document explique comment distribuer les releases Britton de Revit Batch Processor
par une source winget privée, en partant d'un poste Windows sans configuration winget.
La numérotation utilisée est décrite dans les
[adaptations Britton](britton-customizations.md#numérotation-des-versions).

État constaté le 5 octobre 2026 : winget 1.29, sources par défaut seulement
(`msstore`, `winget`, `winget-font`), installation de manifestes locaux désactivée.
Aucune source Britton n'existe encore.

## Ce que le dépôt fournit

| Élément | Rôle |
| --- | --- |
| [new_winget_manifest.ps1](../.github/scripts/new_winget_manifest.ps1) | Écrit le manifeste winget (schéma 1.12.0, trois fichiers YAML) d'un tag `vX.Y.Z-brt.N`. |
| [Workflow de release](../.github/workflows/build_msi.yml) | Pour chaque release `-brt.N`, génère le manifeste à partir de l'installeur compilé et l'ajoute aux fichiers de la release GitHub. |

Contenu du paquet :

| Champ | Valeur |
| --- | --- |
| `PackageIdentifier` | `Britton.RevitBatchProcessor` |
| `PackageVersion` | `X.Y.Z.N`, par exemple `1.13.0.1` |
| `InstallerType` / `Scope` | `inno` / `user` (installation dans le profil, sans droits administrateur) |
| `InstallerUrl` | Installeur de la release GitHub publique du fork |
| `ProductCode` | `{B5CA57EA-7BB2-4620-916C-AE98376C1EF1}_is1` |

Le `ProductCode` est la clé de désinstallation créée par Inno Setup à partir de
l'`AppId`, commun avec la version officielle. Winget reconnaît donc aussi une
installation BVN ou Britton existante, et propose de la mettre à jour vers la
version Britton. La correspondance se fait par ce code, pas par le nom affiché.

Pour générer un manifeste à la main, depuis la racine du dépôt (le script télécharge
l'installeur de la release pour en calculer l'empreinte SHA256) :

```powershell
.\.github\scripts\new_winget_manifest.ps1 -Tag v1.13.0-brt.1
winget validate --manifest .\winget-manifests\Britton.RevitBatchProcessor\1.13.0.1
```

Le dossier `winget-manifests/` est ignoré par Git.

## Étape 1 — Essai sur un poste, sans source

Cette étape vérifie l'installation silencieuse et la mise à jour avant de créer une source.

1. Dans un terminal **administrateur**, autoriser les manifestes locaux (réglage du poste) :
   `winget settings --enable LocalManifestFiles`
2. Dans un terminal normal, télécharger les trois fichiers `.yaml` de la release dans un même dossier.
3. Fermer Revit, puis installer ou mettre à jour :
   `winget install --manifest <dossier>`
4. Vérifier l'entrée : `winget list --id Britton.RevitBatchProcessor` et le titre de BatchRvtGUI.
5. Après l'essai, si les manifestes locaux ne doivent pas rester permis :
   `winget settings --disable LocalManifestFiles` (administrateur).

## Étape 2 — Choisir la source privée

| Option | Mise en place | Pour | Contre |
| --- | --- | --- | --- |
| **Source REST sur Azure** (recommandée) | Module PowerShell officiel `Microsoft.WinGet.RestSource` | Officielle, `winget upgrade` normal, ajout d'un manifeste par une commande, authentification Microsoft Entra ID possible | Abonnement Azure requis : Functions, Cosmos DB et stockage facturés selon le niveau choisi |
| Source pré-indexée (`source.msix`) | Index à construire et signer, puis à héberger sur un site web ou un partage | Pas de service à exploiter | Outillage de création peu documenté, certificat de signature reconnu par les postes, index à reconstruire à chaque release |
| Pas de source | `winget install --manifest` depuis un partage réseau | Aucun service | Manifestes locaux à permettre sur chaque poste, pas de détection automatique des mises à jour |

Une source REST est le choix le plus simple à maintenir pour quelques paquets internes.
La création des ressources Azure engage des coûts et relève de l'administration Azure
de Britton.

## Étape 3 — Créer la source REST

À faire une fois, par une personne disposant des droits sur l'abonnement Azure :

```powershell
Install-Module -Name Microsoft.WinGet.RestSource
Connect-AzAccount
New-WinGetSource -Name "brittonwinget" -ResourceGroup "WinGet" -Region "canadacentral" `
    -ImplementationPerformance "Basic" -ShowConnectionInstructions -InformationAction Continue
```

`-ImplementationPerformance` accepte `Developer`, `Basic` ou `Enhanced`. Les noms ci-dessus
sont des exemples. La source créée ainsi est lisible publiquement et modifiable avec une clé ;
l'option `-RestSourceAuthentication "MicrosoftEntraId"` restreint la lecture aux comptes de
l'organisation. Noter l'URL affichée par `-ShowConnectionInstructions`.

## Étape 4 — Ajouter la source sur les postes

Sur chaque poste, dans un terminal **administrateur** :

```powershell
winget source add --name Britton --arg <URL de la source> --type "Microsoft.Rest"
```

Pour un parc, préférer la stratégie de groupe ou Intune (paramètres App Installer,
« sources supplémentaires ») ; `winget source export --name Britton` fournit le JSON
attendu par la stratégie.

## Étape 5 — Publier chaque release

1. Publier la release GitHub `vX.Y.Z-brt.N` (non marquée « pre-release ») ; le workflow
   y ajoute l'installeur et les trois fichiers `.yaml`.
2. Télécharger les trois fichiers `.yaml` dans un dossier, puis :

```powershell
winget validate --manifest <dossier>
Add-WinGetManifest -FunctionName "brittonwinget" -Path <dossier>
```

Sur les postes : `winget upgrade --id Britton.RevitBatchProcessor --source Britton`,
ou `winget upgrade --all`. Fermer Revit avant la mise à jour : l'installeur remplace
les addins dans `%APPDATA%\Autodesk\Revit\Addins`.

## Limites connues

- L'installation est par utilisateur : chaque compte Windows qui utilise Revit Batch Processor l'installe ou la met à jour pour lui-même.
- Le manifeste a été validé avec `winget validate` sur une empreinte fictive ; l'installation et la mise à jour réelles par winget restent à essayer avec la première release `-brt.1`.
- Seuls les tags `vX.Y.Z-brt.N` produisent un manifeste ; un tag officiel n'en génère pas.
