# Pilote RBP : Revit 2025.5 / 2026.5 / 2027

Ce pilote utilise .NET 10 et IronPython 3.4.2 pour les tâches Revit 2025–2027.
Revit 2025 avant 2025.5 et Revit 2026 avant 2026.5 sont refusés. Le superviseur,
la GUI et le pré/post-traitement restent .NET Framework 4.8 et Python 2.
Les lots traversant les familles 2015–2024 et 2025–2027 sont refusés avant
prétraitement. La liste initiale doit donc être disponible avant le prétraitement ;
elle est contrôlée de nouveau après celui-ci.

## Construction et validation sans installation

Prérequis : Windows, PowerShell 5.1 ou 7, SDK .NET 10, Visual Studio MSBuild, accès NuGet.
Depuis la racine :

```powershell
./scripts/BuildNet10Pilot.ps1 -ControlEngineFolder './artifacts/britton-build-20260930/BatchRvtAddin2025/bin/x64/Release'
```

Le contrôle doit contenir IronPython 2.7.12 ; son processus séparé doit échouer
dans `ImplementCTDOverride`. Ce paramètre est obligatoire avant packaging.
Chaque lancement crée un nouveau dossier `artifacts/net10-pilot-<date>` avec
sources (y compris changements locaux), packages, logs et ZIP. Les versions
modernes sont restaurées en mode verrouillé. Chaque projet garde ses propres
intermédiaires. Les empreintes des installations sont comparées avant/après.
La sortie GUI conserve son moteur historique ; chaque sortie moderne doit avoir
IronPython 3.4.2.0 et DLR 1.3.5.0. Les hôtes/utilitaires proviennent du même build.

Le témoin négatif est lancé via `scripts/InvokeEngineControl.ps1`, qui capture
stdout/stderr en UTF-8 et retourne explicitement le code de sortie. Son erreur
attendue ne doit pas interrompre PowerShell 5.1 avant la vérification. Le build
exécute aussi les tests de ce contrôle sous les shells 5.1 et 7 disponibles.
Pour les autres commandes natives, stderr est conservé dans les logs et le code
de sortie détermine l’échec ; la préférence d’erreur du shell est restaurée.
Les listes issues d’un fichier sont relues avec toutes leurs colonnes après
prétraitement ; une liste explicitement fournie en mémoire reste prioritaire.

`DeployAddinOnBuild` vaut `false` par défaut pour 2025–2027. Les builds historiques
du script utilisent `/p:PostBuildEvent=`. Aucune commande de déploiement ni
installation n’est exécutée. Le workflow MSI historique vérifie désormais 2027,
mais l’installateur BVN ne constitue pas le déploiement de ce pilote.

Le ZIP contient `GUI`, `2025`, `2026`, `2027`, les manifests, les verrous NuGet,
les logs, le commit de base, le patch local et `SHA256.json`. Les archives
« Britton modified » sont exclues. Il n’installe aucun addin 2015–2024.

## Qualification Revit restant obligatoire

Les probes testent le moteur, les classes, une interface .NET, TypeDescriptor,
les imports StdLib, les assemblies RBP historiques, la syntaxe de tous les scripts
actifs, le routage pur, les flux, les accents et les exceptions d’une tâche.
La suite inclut aussi les régressions de listes CSV/texte, le lecteur Excel simulé,
la priorité de l’entrée en mémoire et le refus d’un lot devenu mixte après prétraitement.
Ils ne testent pas l’orchestration complète, les pipes, les dialogues ni les API Revit.
Une compilation ne qualifie aucune version de Revit.

Après approbation explicite du déploiement pilote :

1. Fermer Revit, sauvegarder les installations RBP, manifests, scripts et configs.
2. Vérifier les installations concurrentes utilisateur/machine. Installer uniquement
   l’année à qualifier dans `%APPDATA%/Autodesk/Revit/Addins/<année>/BatchRvt` et
   son manifest ; placer les fichiers GUI/scripts ensemble dans la distribution RBP.
   Préserver les dossiers et manifests 2015–2024.
3. Commencer par 2025.5 build 25.5.0.57 : tâche sans document, puis tâche en lecture
   seule sur modèle local jetable. Vérifier `%TEMP%/BatchRvt/Diagnostics/runtime-<pid>.txt`
   (build, runtime, DLL réellement chargées, scripts et StdLib).
4. Tester progression, erreur utilisateur, plusieurs fichiers, nouvelles sessions,
   fermeture et coexistence des addins habituels, notamment pyRevit.
5. Qualifier séparément 2026.5 et 2027. Consigner build exact et résultats ; une
   version absente ou uniquement compilée reste non qualifiée.

Aucun modèle de production, central, cloud ou synchronisation. Le chemin Britton
`TMP` écrase sa copie : utiliser uniquement une copie dédiée et ne pas exécuter
les branches dont la fermeture n’est pas sûre avant correction distincte.
Dynamo reste inchangé et non qualifié par ces essais Python.

Les tâches utilisateur gardent leurs chemins explicites. Aucun original n’est
converti automatiquement. Inventorier les configurations métier et leurs imports,
créer des copies Python 3, tester l’interop et les dépendances, puis modifier
uniquement les configurations modernes. Aucun script/configuration métier n’a été
fourni pour cette migration. IronPython 3.4.2 implémente Python 3.4 et ne garantit
pas les paquets d’un CPython récent. Le pré/post-traitement reste Python 2.

Retour arrière : fermer Revit, restaurer ensemble addins, hôte/utilitaires, scripts,
manifests et configurations, redémarrer. L’ancien moteur 2.7.12 reste incompatible
avec .NET 10 ; suspendre les traitements modernes en cas d’échec. Ne pas changer
le runtime Autodesk.

## État initial de la qualification hors Revit

Le contrôle 2.7.12 reproduit l’erreur sous .NET 10.0.12. Les sorties candidates
2025, 2026 et 2027 réussissent les probes sous ce runtime avec le véritable hôte
et les utilitaires .NET Framework 4.8. La GUI construite utilise l’assembly Python
2.7.0.40 issue des références historiques ; elle est testée sous .NET Framework.
Les warnings historiques de références/ruleset et les dépendances de tests restent
visibles dans les logs. Ces résultats permettent de poursuivre l’approche
progressive ; ils ne prouvent pas le chargement dans une session Revit.

Les adaptations Britton sont préservées ; deux clauses `except` ont seulement été
rendues compatibles avec Python 3. Un test de flux a révélé et corrigé l’inversion
stdout/stderr dans `RestoreScriptOutput`. Aucun essai Revit ni déploiement effectué.
