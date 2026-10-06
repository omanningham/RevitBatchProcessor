# Journal des décisions du fork Britton

Ce journal consigne les décisions prises par le mainteneur pour le fork Britton de
Revit Batch Processor : ce qui a été choisi, pourquoi, ce qui a été écarté, et où
en trouver la trace. Il complète le [registre des adaptations Britton](britton-customizations.md),
qui décrit l'état du code, et le [guide de développement](agent-development.md),
qui fixe les règles de travail.

État au 6 octobre 2026, `master` au commit `4b4baee`. Sources : historique Git,
pull requests du fork, documents du dépôt et comptes rendus des sessions de travail
menées avec des agents de programmation. Une justification absente des sources est
indiquée « non documentée » plutôt que reconstituée.

Chaque entrée porte un identifiant `D-NN` à citer dans les commits, PR ou documents
qui s'y rapportent. Une décision remplacée n'est pas effacée : la nouvelle entrée
indique celle qu'elle remplace.

## 2025 — Adaptations Britton initiales

### D-01 — Intégrer les adaptations dans les sources actives, archiver les copies

- **Date :** 27 et 28 janvier 2025.
- **Décision :** intégrer les adaptations Britton (libellés de boutons français BRT-01,
  recherche sur une liste de libellés BRT-02, prétraitement des fichiers sous `TMP`
  BRT-03, UTF-8 et imports BRT-04) dans les quatre scripts actifs de
  `BatchRvtUtil/Scripts/`. Les copies modifiées sont conservées dans
  `BatchRvtUtil/Scripts/Britton modified/` à titre d'archive seulement.
- **Raison :** non documentée à l'époque. Précisé le 30 septembre 2026 : seules les
  sources actives font foi ; les archives ne doivent jamais être recopiées, car elles
  ne contiennent pas les évolutions officielles récentes.
- **Traces :** `b392bc6`, `14f6113`, [britton-customizations.md](britton-customizations.md).

### D-02 — Suivre le dépôt officiel par fusion

- **Date :** 11 septembre 2025, confirmé le 30 septembre 2026.
- **Décision :** intégrer le dépôt officiel par `git merge` dans `master`, sans
  rebase et sans choisir globalement une version d'un fichier en conflit.
- **Raison :** conserver l'historique des adaptations ; la fusion du 30 septembre 2026
  a été contrôlée par `git patch-id`, sans perte.
- **Écarté :** branche Britton dédiée distincte de `master`, recommandée en session
  mais jamais approuvée.
- **Traces :** `fe3eade`, `2a47aa6`, procédure dans [britton-customizations.md](britton-customizations.md#procédure-après-une-mise-à-jour-officielle).

## 30 septembre 2026 — Revit 2025 à 2027 sous .NET 10

Point de départ : RBP échouait dans Revit 2025.5 avec l'erreur `ImplementCTDOverride`,
même après mise à jour. IronPython 2.7.12 est incompatible avec .NET 10.

### D-03 — Versions de Revit visées

- **Décision :** Revit 2025.5, 2026.5 et 2027 passent à .NET 10. Revit 2015 à 2024
  restent inchangés. Revit 2025 avant 2025.5 et 2026 avant 2026.5 (encore sous .NET 8)
  ne sont plus pris en charge et sont refusés.
- **Raison :** le mainteneur s'engage à tenir les postes à jour (« je vais m'assurer
  de faire les mise à jour de Autodesk Revit ») ; maintenir aussi .NET 8 doublerait
  les configurations.
- **Traces :** `91935f7`, [net10-pilot.md](net10-pilot.md).

### D-04 — Moteur Python séparé par famille de versions

- **Décision :** IronPython 3.4.2 et sa bibliothèque standard pour les tâches exécutées
  dans Revit 2025 à 2027. La GUI, la console, le pré et le post-traitement ainsi que
  les addins 2015 à 2024 restent en .NET Framework 4.8 avec IronPython 2.7.
- **Raison :** IronPython 2.7.12 échoue sous .NET 10. Seul le code exécuté dans les
  Revit modernes doit changer de moteur.
- **Écarté :** préserver Python 2 partout (premier choix, abandonné) ; un paquet
  IronPython 2.7.12 recompilé avec correctif ; tout passer en Python 3.
- **Traces :** `91935f7`, PR #1 et #4.

### D-05 — Refuser les lots mixtes

- **Décision :** un lot ne peut pas mêler des fichiers 2015–2024 et 2025–2027. Il est
  refusé avant le prétraitement, puis vérifié de nouveau après.
- **Raison :** les deux familles n'utilisent pas le même moteur Python.
- **Écarté :** un script de tâche unique compatible avec Python 2 et 3.
- **Traces :** `91935f7`, [net10-pilot.md](net10-pilot.md).

### D-06 — Étendre le mécanisme existant plutôt que créer un nouvel hôte

- **Décision :** généraliser à 2025 et 2026 la prise en charge déjà en place pour 2027.
  La bibliothèque standard est choisie selon `Engine.LanguageVersion.Major` : ZIP
  embarqué pour Python 2, dossier `lib` obligatoire pour Python 3.
- **Raison :** changement le plus petit possible. Une architecture séparée (nouvel hôte,
  contexte de chargement privé) n'est envisagée que si les assemblies historiques
  bloquent.
- **Traces :** `91935f7`, [guide de développement](agent-development.md#parcours-net-10).

### D-07 — Aucun déploiement implicite pendant un build

- **Décision :** `DeployAddinOnBuild=false` par défaut pour les addins 2025 à 2027.
- **Raison :** un build remplaçait l'installation sous `%APPDATA%`, et `PostBuildEvent=`
  ne suffisait pas à l'empêcher.
- **Traces :** `91935f7`, PR #1, [guide de développement](agent-development.md#compilation-et-commandes).

### D-08 — Ne pas convertir automatiquement les scripts métier

- **Décision :** les tâches métier destinées à Revit 2025 à 2027 sont copiées et
  converties en Python 3 à la main ; le pré et le post-traitement restent en Python 2.
- **Raison :** non documentée au-delà du runbook.
- **Traces :** [net10-pilot.md](net10-pilot.md).

### D-09 — Corriger les constats de la revue avant de proposer la PR

- **Décision :** appliquer les corrections issues de la revue de `91935f7` : relire
  la liste de fichiers après le prétraitement avec toutes ses colonnes, et rendre
  la validation compatible avec PowerShell 5.1.
- **Raison :** la revue a reproduit la perte des données associées aux fichiers.
- **Traces :** `38c289b`, [rapport du 30 septembre 2026](net10-validation-20260930.md).

### D-10 — Préparer un installateur standard, les essais Revit restent au mainteneur

- **Décision :** produire l'installateur complet avec le script Inno du dépôt, sans
  configuration spécifique ; le mainteneur fait lui-même les essais dans Revit. Les
  scripts et l'installateur du déploiement pilote limité à 2025.5 sont supprimés.
- **Raison :** « Ne créé pas de configuration spécifique, je veux simplement créé un
  fichier d'installation du plugin complet ».
- **Écarté :** déploiement pilote 2025.5 avec scripts de déploiement et de restauration.
- **Traces :** compte rendu de session du 30 septembre 2026.

## 30 septembre 2026 — Adaptations Britton corrigées

### D-11 — Corriger BRT-02 et BRT-03

- **Décision :** `FilterControlsByText` accepte un libellé seul ou une liste et ne
  renvoie chaque contrôle qu'une fois ; le document temporaire du prétraitement `TMP`
  est toujours fermé.
- **Raison :** un libellé seul était découpé caractère par caractère, ce qui cassait
  certaines correspondances, et `OK`/`Ok` renvoyaient deux fois le même contrôle ;
  la fermeture du document était sautée quand `openInUI` valait vrai.
- **Limite :** vérifié hors Revit seulement (IronPython 3.4.2 et 2.7.3).
- **Traces :** `7a8ad30`, `2f9280a`, [britton-customizations.md](britton-customizations.md).

### D-12 — Isoler les chemins d'outillage du poste

- **Décision :** les chemins locaux d'IronPython 2.7 et de Visual Studio 2022
  (`scripts/ipy64.bat`, `scripts/msbuild.py`) sont commités sur une branche séparée,
  `local-tooling-paths`, hors de la PR principale, puis conservés lors de la fusion
  dans `master`.
- **Réserve :** ce chemin Visual Studio 2022 ne permet pas de compiler les addins
  `net10.0` (voir D-15). Non tranché.
- **Traces :** `d019e20`, PR #3 et #4.

## 30 septembre et 1er octobre 2026 — Agents et documentation

### D-13 — Un guide commun pour tous les agents, documentaire seulement

- **Décision :** une configuration portable avec un seul guide,
  [agent-development.md](agent-development.md), et trois points d'entrée courts :
  `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`. Aucun script, hook ni
  CI à ce stade. Aucun chemin de poste, secret, plugin ni modèle d'IA dans les
  instructions partagées, et aucun modèle Revit de production pour valider.
- **Écarté :** configuration propre à un seul outil ; instructions dupliquées.
- **Traces :** `3aefba3`.

### D-14 — Documenter les adaptations dans un registre

- **Décision :** créer [britton-customizations.md](britton-customizations.md) avec les
  identifiants BRT-xx et la procédure à suivre après une mise à jour officielle.
- **Traces :** registre lui-même.

### D-15 — Corriger la documentation selon les sources officielles

- **Décision :** après deux revues de la documentation, corriger le README
  (sécurité des données, usage direct d'un `.dyn` pour Dynamo), compléter
  [ui.md](ui.md), et exiger Visual Studio 2026 (18.0) avec le SDK .NET 10, d'après
  Microsoft Learn.
- **Raison :** le mainteneur a rappelé que les addins 2025 et 2026 étaient déjà passés
  à .NET 10 ; l'enveloppe Python pour Dynamo échouait en mode Detach.
- **Écarté :** baser la PR sur un `master` en retard (PR #2 fermée, remplacée par
  la PR #3 vers `local-tooling-paths`).
- **Traces :** `89dbdb8`, `f052755`, `f1bb733`, `f4e5a74`, PR #2 et #3.

### D-16 — Toutes les PR visent le fork

- **Décision :** les PR et fusions sont faites dans `omanningham/RevitBatchProcessor`,
  jamais vers le dépôt officiel ; `gh` vise le fork par défaut.
- **Raison :** « je veux mergé les PR dans ma fork Britton ».
- **Traces :** PR #1 à #9.

## 2 octobre 2026 — Qualification et sécurité du dépôt

### D-17 — .NET 10 qualifié dans Revit

- **Décision :** le parcours .NET 10 n'est plus un pilote. Le mainteneur l'a essayé
  lui-même dans Revit 2025.5, 2026.5 et 2027 (« tout est OK »). Dynamo et
  l'infonuagique restent non qualifiés. Toute modification de l'hôte, du moteur ou
  des addins demande une nouvelle qualification.
- **Limite :** les builds exacts de Revit et les scénarios essayés ne sont pas consignés.
- **Traces :** `eb96f4a`, [net10-pilot.md](net10-pilot.md).

### D-18 — Fusionner par merge commit

- **Décision :** fusionner la PR #4 (regroupant les PR #1 et #3 et les chemins
  d'outillage) par merge commit, pas par squash. Même règle pour les PR suivantes.
- **Raison :** garder séparés les commits BRT et .NET 10.
- **Traces :** `2b00c1b`, `322fbb3`, `4b4baee`.

### D-19 — Sécuriser le dépôt GitHub

- **Décision :** activer l'analyse des secrets, la protection des push, les alertes
  Dependabot et l'approbation des PR externes ; désactiver le wiki ; restreindre les
  actions autorisées. Le mainteneur fait lui-même les réglages refusés aux agents.
- **Traces :** compte rendu de session du 2 octobre 2026.

## 2 au 5 octobre 2026 — Release et intégration continue

### D-20 — Workflow de release fiable

- **Décision :** construire le commit tagué (et non `master`), échouer si une source
  de l'installeur manque, épingler par SHA les actions tierces, jeton en lecture
  seule par défaut, PR de version ouverte par un job séparé, tag exigé en `v`
  minuscule.
- **Écarté :** groupe de concurrence sur la release, retiré parce que GitHub ne garde
  qu'une exécution en attente par groupe et pourrait laisser une release sans
  installeur.
- **Traces :** `2d1eb01`, `929c8a9`, PR #5.

### D-21 — CI sur chaque PR, rendue obligatoire

- **Décision :** CI sur chaque PR et sur `master`, sans filtre de chemins ; le ruleset
  de `master` exige « Repository checks » et « Solution build (as release) », et
  CodeQL bloque à partir de la sévérité élevée. Aucune approbation obligatoire tant
  qu'il n'y a qu'un mainteneur.
- **Écarté :** une matrice par addin, redondante (trois runners Windows économisés).
- **Traces :** `0b76584`, `929c8a9`, `1d2588f`, en-tête de `.github/workflows/ci.yml`.

### D-22 — Dependabot et CodeQL ciblés

- **Décision :** Dependabot pour les GitHub Actions seulement ; CodeQL sur le C# et
  les workflows.
- **Raison :** les dépendances NuGet de Revit et IronPython sont verrouillées
  volontairement ; le code IronPython (`clr`, `System`) ne s'analyse pas comme du
  Python standard.
- **Traces :** `2b7014b`.

### D-23 — Veille du dépôt officiel sans fusion automatique

- **Décision :** un workflow hebdomadaire ouvre ou met à jour une seule issue
  `upstream-sync` ; aucune fusion automatique.
- **Traces :** `2b7014b`, `6954d44`, `929c8a9`.

### D-24 — Tests du moteur Python en CI

- **Décision :** exécuter EngineProbe (IronPython 3.4.2 sous .NET 10) sur chaque
  sortie 2025 à 2027, et LegacyEngineProbe (IronPython 2.7) sur la sortie GUI. Chaque
  sortie est testée telle que l'installeur la livre.
- **Raison :** IronPython 3.4.2 ne vise officiellement pas .NET 10.
- **Écarté :** le témoin négatif IronPython 2.7.12 en CI, jugé peu utile ; il reste local.
- **Traces :** `1a13488`, `0a31a74`, PR #6.

### D-25 — Numérotation des versions Britton

- **Décision :** tags `vX.Y.Z-brt.N`, où `X.Y.Z` est la version officielle fusionnée
  et `N` le numéro Britton, remis à 1 à chaque nouvelle base. Pas de version bêta.
  Version Windows et winget `X.Y.Z.N`. Version affichée dans le titre de la GUI.
- **Raison :** des releases Britton sont prévues sans nouvelle base officielle ; Windows
  et winget comparent des versions numériques, et un suffixe texte peut être classé
  avant la version officielle.
- **Traces :** `a76d859`, `32b8e7d`, PR #7, [numérotation des versions](britton-customizations.md#numérotation-des-versions).

### D-26 — Remplacer l'installation BVN plutôt que coexister

- **Décision :** l'installeur garde l'`AppId` officiel, avec le nom « Revit Batch
  Processor (Britton) » et l'éditeur « Britton ».
- **Raison :** les deux installent les mêmes addins ; deux installations simultanées
  entreraient en conflit.
- **Conséquence :** les inventaires (Intune, scripts) doivent utiliser la clé
  `{B5CA57EA-7BB2-4620-916C-AE98376C1EF1}_is1` plutôt que le nom affiché.
- **Traces :** `a76d859`, PR #7.

### D-27 — Distribution par une source winget privée

- **Décision :** manifeste `Britton.RevitBatchProcessor` généré à chaque release,
  portée utilisateur, schéma 1.10.0, langue fr-CA. Sa génération est facultative et
  ne bloque pas la release. Le manifeste lit le script Inno tel qu'il était au tag.
  Source recommandée : source REST sur Azure.
- **Raison :** distribution aux utilisateurs Britton avec mise à jour automatique ;
  le schéma 1.10.0 est le plus récent accepté par la source REST officielle.
- **Écarté :** source pré-indexée `source.msix` ; manifestes locaux sans source.
- **Traces :** `425c4e8`, `a4a0fce`, `74df836`, `1ff52b7`, [winget.md](winget.md).

### D-28 — Échouer tôt si un motif de version disparaît

- **Décision :** `set_version.ps1` échoue sans rien écrire si un motif attendu manque,
  par exemple après une fusion officielle. Les règles sont centralisées dans
  `release_metadata.ps1` et testées en CI.
- **Traces :** `b19af72`, `74df836`.

### D-29 — Pas de plan d'agent dans le dépôt

- **Décision :** retirer le plan d'implantation de session commité pendant la PR #7.
- **Raison :** le guide interdit toute dépendance à un plugin ou à un modèle d'IA dans
  les documents partagés.
- **Traces :** `09895fd`, `1ff52b7`.

### D-30 — Première release Britton

- **Décision :** publier `v1.13.0-brt.1` comme release définitive, avec l'installeur
  et les trois fichiers du manifeste winget. Publiée par le mainteneur lui-même.
- **Traces :** release GitHub `v1.13.0-brt.1`, 5 octobre 2026.

## 5 octobre 2026 — Identité du fork et langues

### D-31 — Identifier clairement le fork

- **Décision :** les liens de release, d'issues et de contribution du README pointent
  vers le fork ; un avis en tête indique que le fork est maintenu par Britton, sans
  soutien de BVN ni de l'auteur original, avec un tableau des différences.
- **Traces :** `9bca6fa`, `ae5d2c7`, PR #9.

### D-32 — Langues de la documentation

- **Décision :** les fichiers issus du dépôt officiel restent en anglais avec des
  modifications Britton minimales ; les documents créés par Britton sont en français ;
  les traductions de fichiers officiels sont des fichiers voisins `*.fr.md`.
  L'interface WinForms n'est pas traduite.
- **Raison :** limiter les conflits lors des fusions officielles et garder un diff
  lisible avec le dépôt officiel.
- **Écarté, dans l'ordre :** README entièrement traduit (`ae5d2c7`) ; traduction dans
  `README.md` avec l'anglais dans `README.en.md` (`0546733`).
- **Garde-fous :** la vérification `readmes` de `check_repo.py` exige la même structure
  de titres et les mêmes liens de release dans `README.md` et `README.fr.md` ;
  `update_readme.py` met à jour les deux ; l'issue de veille rappelle de traduire
  les changements officiels.
- **Traces :** `55997ee`, PR #9, [guide de développement](agent-development.md#langues-de-la-documentation).

### D-33 — Fermer la PR de version automatique remplacée

- **Décision :** fermer sans fusion la PR #8 générée par la release, la PR #9 portant
  déjà les liens vers `v1.13.0-brt.1`.
- **Traces :** PR #8 et #9.

## 6 octobre 2026 — Emplacement du dépôt

### D-34 — Transférer le fork vers l'organisation Britton, en restant public

- **Date :** 6 octobre 2026. Décision prise, transfert pas encore effectué.
- **Décision :** transférer le dépôt du compte personnel du mainteneur vers
  l'organisation GitHub Britton, avec la fonction *Transfer ownership*. Le dépôt
  reste public et reste un fork de `bvn-architecture/RevitBatchProcessor`.
- **Raison :** le dépôt avait été créé par erreur dans un compte personnel ; il doit
  appartenir à l'entreprise. La visibilité publique n'était pas le motif principal.
- **Écarté :** rendre le dépôt privé. D'après la documentation GitHub, un fork ne
  peut pas changer seul de visibilité ; il faudrait d'abord le détacher du réseau
  de forks (*Leave fork network*, irréversible), ce qui perd PR, issues et releases.
  Un dépôt privé au plan gratuit perdrait aussi l'application des rulesets et de la
  protection de branche, et CodeQL ; les installateurs publiés en release ne
  seraient plus téléchargeables sans authentification. Écarté aussi : copie miroir
  dans un nouveau dépôt, mêmes pertes.
- **Effets attendus :** PR, issues, releases, tags, lien de fork, ruleset `master`
  et protection de branche suivent le dépôt ; les anciennes URL web et Git sont
  redirigées.
- **Après le transfert :**
  - mettre à jour `origin` dans chaque clone (`git remote set-url`) ;
  - remplacer l'ancien chemin `owner/repo` dans `.github/ISSUE_TEMPLATE/config.yml`,
    `.github/SECURITY.md`, `.github/pull_request_template.md`, `README.md`,
    `README.fr.md`, `.github/scripts/new_winget_manifest.ps1` et
    `tests/release_metadata_tests.ps1` ;
  - vérifier que les réglages Actions propres au dépôt sont conservés : actions
    autorisées limitées à une liste, `GITHUB_TOKEN` en lecture par défaut,
    approbation des workflows pour tous les contributeurs externes ;
  - vérifier que le workflow planifié `upstream-watch.yml` reste activé ;
  - recréer les nouvelles releases sous la nouvelle URL ; les manifestes winget
    existants restent valides grâce à la redirection.
- **Sources :** documentation GitHub *Transferring a repository*, *About permissions
  and visibility of forks*, *Detaching a fork*, *Setting repository visibility*.

## Règles de travail du mainteneur

Règles exprimées à plusieurs reprises, appliquées à toute modification du fork :

- Analyser et planifier avant d'implanter ; ne poser que les questions qui changent
  la solution.
- Vérifier les choix techniques auprès des sources officielles (Autodesk, Microsoft
  Learn, projets en amont) avant d'agir.
- Distinguer les faits vérifiés, les hypothèses et les validations qui restent à faire.
- Préserver les changements locaux ; garder les fichiers propres à un poste hors des PR.
- Aucun déploiement implicite, aucun modèle Revit de production, aucune synchronisation
  vers un central. Les essais dans Revit et en production sont faits par le mainteneur.
- Les actions sensibles (publication d'une release, lancement manuel d'un workflow,
  réglages du dépôt) sont faites par le mainteneur lui-même.
- Préférer la solution la plus simple : installateur standard, aucune configuration
  spécifique.
- Revue de code avant chaque fusion, puis plan de correction des constats retenus.
- Git : travail en worktree, PR en brouillon d'abord, merge commit, avance rapide
  seulement pour la mise à jour locale, nettoyage des branches et worktrees après fusion.

## Questions ouvertes

1. **Essais Revit des adaptations Britton :** dialogues français (BRT-01, BRT-02) et
   fermeture du document temporaire `TMP` (BRT-03) restent vérifiés hors Revit seulement.
2. **Couverture de la qualification .NET 10 :** Dynamo, infonuagique et coexistence
   avec pyRevit non qualifiés ; builds Revit exacts du 2 octobre 2026 non consignés.
3. **Migration des tâches métier en Python 3** pour Revit 2025 à 2027 : non faite.
4. **winget :** source REST Azure non créée, budget et mode d'authentification
   (clé ou Entra ID) à décider ; installation réelle par winget non essayée.
5. **Inventaires et détection** (Intune, scripts) à migrer vers la clé `{AppId}_is1`
   (voir D-26) : aucune trace que ce soit fait.
6. **Chemin Visual Studio 2022** de `scripts/msbuild.py` (D-12), incompatible avec
   les addins `net10.0` (D-15) : à trancher.
7. **Épinglage des actions `actions/*`** : laissées en version majeure, contrairement
   aux actions tierces ; choix non documenté.
8. **Témoin négatif IronPython 2.7.12** et contrôle syntaxique IronPython 2.7 en CI :
   non retenus pour l'instant.
9. **Branches distantes anciennes** (`net10-ironpython3-agent-docs`, `v1.9.1-beta`) :
   à supprimer ou non.
10. **Registre des adaptations :** son « état de référence » date du commit `2a47aa6`,
    antérieur aux corrections de BRT-02 et BRT-03, et il mentionne encore un « package
    pilote ».
11. **Capture d'écran annotée** pour [ui.md](ui.md) : à produire.

## Tenir ce journal à jour

Ajouter une entrée `D-NN` pour chaque nouveau choix délibéré (architecture, versions,
release, CI, langues, processus), pas pour un simple correctif. Indiquer la date, la
décision, la raison, les options écartées et les traces (commit, PR, document). Quand
une question ouverte est tranchée, la retirer de la liste et créer l'entrée
correspondante.
