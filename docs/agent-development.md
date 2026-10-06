# Développement avec des agents

Ce guide constitue la source commune pour Codex, Claude Code et GitHub Copilot.
La configuration est documentaire : elle n'installe aucun outil, n'accorde aucune
permission et ne lance aucun script. Les consignes d'une tâche précisent son périmètre.

## Démarrer une tâche

1. Lire ce guide et les éventuelles instructions propres au dossier concerné.
2. Examiner `git status --short`, puis le diff des fichiers à modifier. Conserver les changements préexistants.
3. Lire les points d'entrée et les projets concernés avant de proposer une modification.
4. Identifier les versions Revit et moteurs Python touchés, puis choisir une validation adaptée.
5. Effectuer des changements ciblés et rendre compte des résultats observés.

Répondre dans la langue de l'utilisateur. Conserver les conventions et la langue
du code environnant ; ne pas traduire les identifiants ou messages sans nécessité.
Ne pas ajouter des chemins personnels, secrets, modèles métier ou réglages globaux
d'agent dans le dépôt. Un lien vers le guide n'implique pas que tous les clients
le chargent automatiquement : l'agent doit le lire explicitement.

## Carte du dépôt

| Emplacement | Rôle et points d'attention |
| --- | --- |
| `RevitBatchProcessor.sln` | Solution principale, configurations Debug/Release et mappings de plateformes. |
| `BatchRvtGUI/` | Interface Windows Forms ; formulaires, ressources, paramètres. |
| `BatchRvt/BatchRvtMain.cs` | Entrée console ; lance le script de supervision via `BatchRvtUtil`. |
| `BatchRvtUtil/` | Paramètres, arguments, versions Revit, recherche de fichiers et utilitaires partagés. |
| `BatchRvtUtil/Scripts/` | Orchestration Python, processus Revit, sessions, fichiers, dialogues, journaux et scripts modèles. |
| `BatchRvtScriptHost/` | Création du moteur IronPython et exécution de `revit_script_host.py` dans Revit. |
| `BatchRvtAddin2015/` à `BatchRvtAddin2027/` | Addin et manifeste propres à chaque version de Revit. |
| `BatchRevitDynamo/` | Intégration Dynamo. |
| `References/` | Bibliothèques embarquées, API Revit historiques et bibliothèque standard IronPython. |
| `AddinDeployment/` | Installation et suppression des addins dans le profil Windows. |
| `scripts/` | Anciens lanceurs de build et d'exécution utilisant IronPython. |
| `Setup/` | Packaging Inno Setup et outils associés. |
| `.github/workflows/build_msi.yml` | Workflow de release : build du tag, packaging, publication, puis PR de version vers `master`. |
| `.github/workflows/ci.yml` | CI des PR et de `master` : vérifications du dépôt, build de la solution comme en release, addins 2025–2027 en restauration verrouillée. |
| `.github/scripts/` | Scripts partagés par les workflows (`check_repo.py`, version, sources de l'installateur, manifeste winget). |
| `.github/workflows/` (autres) | CodeQL, labels des PR, veille upstream (issue `upstream-sync`, sans fusion automatique). |

Le flux passe par la GUI ou la console, les utilitaires/scripts de supervision,
puis l'addin et l'hôte de scripts dans Revit. Examiner les deux côtés d'un échange
avant de changer les paramètres, variables d'environnement, formats JSON ou messages.

## Compatibilité observée dans les projets

| Projets | Cible déclarée | Python déclaré / référencé |
| --- | --- | --- |
| GUI, console, utilitaires, ScriptHost, Dynamo | .NET Framework 4.8 | Références historiques IronPython 2.7.3. |
| Addins 2015–2024 | .NET Framework 4.8 | Chemin historique via ScriptHost ; vérifier les références de chaque projet. |
| Addins 2025–2027 | `net10.0-windows` | Packages IronPython et StdLib 3.4.2. |

Ces déclarations ne prouvent pas la compatibilité à l'exécution : les addins modernes
référencent également des projets historiques. Vérifier la résolution des assemblies
et le chargement dans la version Revit visée pour toute modification de cette frontière.

- Ne pas introduire de syntaxe Python 3 dans un chemin exécuté sous IronPython 2.7. Pour les scripts partagés, examiner les deux moteurs réellement consommateurs.
- CPython ne remplace pas IronPython pour valider les imports `clr`, `System` et les API Revit.
- Respecter le framework et les options de langage du projet ; ne pas migrer les frameworks ou dépendances pour accompagner une simple correction.
- Les projets historiques listent explicitement les fichiers `Compile` et `Content`. Inclure les nouveaux fichiers nécessaires et vérifier la copie des scripts dans la sortie.
- `BatchRvtUtil/Scripts/Britton modified/` contient uniquement des archives, non utilisées par l'application. Modifier les sources actives dans `BatchRvtUtil/Scripts/` et consulter le [registre des adaptations Britton](britton-customizations.md) avant une fusion ou une modification de ces comportements.
- Préserver les fichiers WinForms `.Designer.cs`, `.resx`, paramètres et ressources générés ; maintenir leur cohérence lors d'une modification d'interface.
- Respecter les en-têtes et la licence GPL-3.0-or-later ; traiter `References/` comme des dépendances, sans reformater ni remplacer ses fichiers incidentalement.

## Compilation et commandes

Exécuter les commandes depuis la racine dans un terminal Windows disposant des outils
Visual Studio/MSBuild et NuGet. Vérifier `msbuild -version`, `nuget help` et
`dotnet --list-sdks` selon le projet. Les cibles modernes requièrent un outillage
compatible avec .NET 10 ; la mention « Visual Studio 2017 ou ultérieur »
du README ne suffit pas pour toute la solution actuelle.

Le dépôt combine `packages.config`, `PackageReference` et références à des DLL locales.
`Directory.Build.props` ajoute `Microsoft.NETFramework.ReferenceAssemblies` 1.0.3.
Les commandes ci-dessous documentent le dépôt ; elles ne constituent pas un build
réussi et vérifié sur chaque poste.

Restauration utilisée par le workflow de release :

```powershell
nuget restore "RevitBatchProcessor.sln"
```

Pour les projets à `PackageReference`, si nécessaire, utiliser une restauration
MSBuild distincte et examiner ses erreurs avant la compilation :

```powershell
msbuild "RevitBatchProcessor.sln" /t:Restore /p:Configuration=Release /p:Platform=x64
```

Pour une modification limitée à la GUI/console/utilitaires, une compilation ciblée
évite d'inclure automatiquement tous les addins. Vérifier les références et cibles
du projet avant exécution :

```powershell
msbuild "BatchRvtGUI/BatchRvtGUI.csproj" /t:Build /p:Configuration=Release /p:Platform=x64 /m
```

Compilation complète utilisée par le workflow de release, **avec effets de déploiement** :

```powershell
msbuild "RevitBatchProcessor.sln" /p:Configuration=Release /p:Platform=x64 /m
```

Les addins appellent `AddinDeployment/DeployAddin.bat`, qui supprime puis remplace
le dossier `BatchRvt` et son manifeste sous `%APPDATA%/Autodesk/Revit/Addins/<année>`.
Avant un build complet ou d'addin, vérifier que ce remplacement entre dans le périmètre
autorisé et fermer Revit. Une demande de documentation n'autorise pas ce déploiement.

`/p:PostBuildEvent=` et l'option `NOPOSTBUILD` de `scripts/msbuild.py` ne garantissent
pas l'absence de déploiement : les projets 2025–2027 définissent une cible `PostBuild`
avec un `Exec` explicite, désormais conditionné à `DeployAddinOnBuild=true`.
Conserver explicitement `DeployAddinOnBuild=false` pour une validation isolée.
Ne pas présenter `PostBuildEvent` seul comme une protection globale.
Ne pas lancer les scripts de suppression, l'installateur ou le workflow de publication
comme simple vérification du code.

Les lanceurs de `scripts/` dépendent de chemins d'outillage locaux ; les lire avant
usage. Privilégier les commandes directes documentées pour diagnostiquer les prérequis.

## Validation et état des tests

À l'analyse initiale du 30 septembre 2026, aucun projet de tests n'est suivi dans Git
ni inscrit à la solution principale. Le dossier local `BatchRvtUtil.Tests/` ne contient
que des artefacts `obj/`. Les références Moq/FluentAssertions et les scripts
`global_test_mode.py` / `test_mode_util.py` ne constituent pas une suite de tests exécutable.
Ne pas annoncer « tests réussis » sur la seule base d'un `dotnet test` sans tests découverts.

La CI (`.github/workflows/ci.yml`) exécute `git diff --check`,
`python .github/scripts/check_repo.py` (scripts inscrits dans `BatchRvtUtil.csproj`,
liens Markdown, structure de `README.fr.md` identique à `README.md`, en-têtes GPL des nouveaux fichiers), `tests/release_metadata_tests.ps1`
(versions tirées du tag, identité de l'installeur, manifeste winget), le build de la solution et
celui des addins 2025–2027. Le script de vérification peut être lancé localement.
Elle exécute ensuite `EngineProbe` sur chaque sortie 2025–2027 (IronPython 3.4.2 sous
.NET 10) et `LegacyEngineProbe` sur la sortie GUI (IronPython 2.7) : hôte de scripts
réel, tests de `tests/` et compilation de tous les scripts par les deux moteurs.
Le témoin négatif IronPython 2.7.12 de `BuildNet10Pilot.ps1` reste local
(`-ControlEngineFolder`). La CI ne qualifie aucune version de Revit : une CI verte
ne remplace pas la validation ci-dessous.

| Changement | Validation attendue |
| --- | --- |
| Documentation | Relire les consignes, vérifier les chemins/liens et `git diff --check`. Aucun build requis. |
| C# | Compiler les projets touchés et les consommateurs pertinents ; préciser configuration et versions. |
| Scripts Python | Vérifier syntaxe et comportement avec les moteurs concernés ; une analyse CPython seule ne suffit pas. |
| GUI | Build ciblé et vérification manuelle du parcours touché lorsque l'environnement le permet. |
| API Revit / addin / traitement de fichiers | Validation dans Revit sur une copie de test, avec version, scénario et résultat consignés. |

Pour un essai Revit, utiliser un modèle jetable ou une copie détachée du central.
Décrire les options d'ouverture, la tâche exécutée et les écritures attendues avant
l'essai. N'effectuer ni synchronisation vers un central, ni traitement de lots métier,
ni traitement cloud réel sans autorisation correspondante.

Si l'environnement manque, indiquer précisément ce qui a été vérifié et ce qui reste
à tester. Distinguer un défaut de code d'un prérequis manquant sans masquer les erreurs.

## Collaboration et livraison

- Garder chaque tâche ciblée. Si plusieurs agents travaillent en parallèle, attribuer des fichiers distincts et coordonner les changements partagés (`.sln`, `.csproj`, versions, guide commun).
- Préserver les modifications utilisateur ; ne pas nettoyer le dépôt ou les fichiers ignorés pour faciliter une tâche.
- Ne pas ajouter de dépendance à un plugin, un modèle d'IA ou un chemin de poste dans les instructions communes.
- Avant livraison, examiner le diff et vérifier que les modifications se limitent à la demande.
- Dans le compte rendu, indiquer les fichiers modifiés, la raison, les validations exécutées et les limitations restantes.
- Mettre à jour ce guide lorsque les commandes, projets, runtimes ou tests changent ; garder les trois points d'entrée courts et cohérents.

Règles du mainteneur, dont l'historique est dans le [journal des décisions](journal-decisions.md) :

- Analyser et planifier avant d'implanter ; ne poser que les questions qui changent la solution.
- Vérifier les choix techniques auprès des sources officielles (Autodesk, Microsoft Learn, projets en amont) avant d'agir ; distinguer faits vérifiés, hypothèses et validations restantes.
- Préférer la solution la plus simple, par exemple un installateur standard sans configuration spécifique.
- Garder les fichiers propres à un poste hors des PR, sauf exception consignée dans le journal (D-12).
- Les essais dans Revit et en production, la publication d'une release, le lancement manuel d'un workflow et les réglages du dépôt sont faits par le mainteneur lui-même.
- Faire une revue de code avant chaque fusion, puis un plan de correction des constats retenus.
- Git : travailler dans un worktree, ouvrir la PR en brouillon, fusionner par merge commit (avance rapide seulement pour mettre à jour la copie locale), puis supprimer la branche et le worktree.
- Consigner tout nouveau choix délibéré dans le journal des décisions (entrée `D-NN`).

## Langues de la documentation

Le fork limite ses écarts avec le dépôt officiel pour faciliter les fusions :

| Fichiers | Langue |
| --- | --- |
| Fichiers issus du dépôt officiel (`README.md`, `docs/SampleScripts.md`, `docs/ui.md`, code, commentaires, interface) | Anglais ; modifications Britton minimales et regroupées. |
| Documents créés par Britton (ce guide, `britton-customizations.md`, `journal-decisions.md`, `winget.md`, `net10-pilot.md`) | Français. |
| Traductions de fichiers officiels | Fichier voisin `*.fr.md`, par exemple `README.fr.md`. |

Toute modification de `README.md` doit être reportée dans `README.fr.md`.
`check_repo.py` vérifie que les deux fichiers ont la même structure de titres et
les mêmes liens de release ; `update_readme.py` met à jour les versions des deux.
Lors d'une fusion du dépôt officiel, intégrer d'abord les changements dans
`README.md`, puis les traduire dans `README.fr.md`. Ne pas traduire l'interface
WinForms : les `.Designer.cs` et `.resx` proviennent du dépôt officiel.

## Parcours .NET 10

Les addins 2025–2027 ciblent désormais `net10.0-windows`, x64, IronPython et
StdLib 3.4.2. Les anciennes mises à jour 2025/2026 sous .NET 8 sont exclues.
`DeployAddinOnBuild=false` protège leurs builds ; activer cette propriété exécute
le script de remplacement de l’installation et constitue un déploiement explicite.
GUI, console, pré/post-traitement et anciens addins gardent leurs moteurs historiques.
L’hôte partagé choisit la StdLib par `Engine.LanguageVersion.Major` : ZIP embarqué
pour Python 2, dossier `lib` obligatoire pour Python 3. Les projets partagés restent
.NET Framework 4.8 et sont validés hors Revit sous .NET 10 sans séparation nouvelle.
Le mainteneur a qualifié ce parcours dans Revit 2025.5, 2026.5 et 2027 le
2 octobre 2026 ; Dynamo et le cloud restent non qualifiés.

Utiliser [le runbook .NET 10](net10-pilot.md) et `scripts/BuildNet10Pilot.ps1` pour
une construction isolée sans déploiement, avec verrous, probes et empreintes.
Les tâches modernes exigent une qualification utilisateur Python 3 ; le pré/post
reste Python 2. Refus des lots mixtes avant prétraitement et contrôle du
`RevitNET.runtimeconfig.json` de chaque Revit moderne sélectionné.
Les tests hors Revit ne qualifient ni les API Revit ni les communications complètes.
Le contrôle négatif capture stderr via `InvokeEngineControl.ps1` pour fonctionner
sous PowerShell 5.1 et 7. Les tests de listes utilisent de vrais fichiers temporaires
CSV/texte et un lecteur Excel simulé, sans ouvrir de modèle ni lancer `Main()`.
`BatchRvtConfig.RevitFileList` désigne uniquement l’entrée explicitement fournie en
mémoire : ne pas y mettre en cache les chemins d’une liste fichier, car cela perd
les colonnes associées et empêche la relecture après prétraitement.

## Références internes

- [README et usage](../README.md) et sa [traduction française](../README.fr.md)
- [Scripts exemples](SampleScripts.md)
- [Documentation UI](ui.md)
- [Workflow de release](../.github/workflows/build_msi.yml)
- [Distribution Britton par winget](winget.md)
- [Journal des décisions du fork](journal-decisions.md) : y consigner tout nouveau choix délibéré
- [CI des PR](../.github/workflows/ci.yml)
- [Instructions Codex et agents compatibles](../AGENTS.md)
- [Instructions Claude Code](../CLAUDE.md)
- [Instructions GitHub Copilot](../.github/copilot-instructions.md)
