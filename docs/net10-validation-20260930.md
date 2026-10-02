# Rapport du pilote .NET 10 — 30 septembre 2026

Base Git : `2a47aa6f493704ccac9da76c6eced5e5692dc020`, avec changements locaux
préservés et nouvelles sources du pilote. Aucun commit ni déploiement réalisé.

| Sortie construite | Runtime du probe | Moteur / DLR | Résultat hors Revit |
| --- | --- | --- | --- |
| Addin 2025 | .NET 10.0.12 | 3.4.2.0 / 1.3.5.0 | Classes, interfaces, TypeDescriptor, imports, hôte/utilitaires, 60 scripts compilés, 10 tests réussis |
| Addin 2026 | .NET 10.0.12 | 3.4.2.0 / 1.3.5.0 | Mêmes contrôles réussis |
| Addin 2027 | .NET 10.0.12 | 3.4.2.0 / 1.3.5.0 | Mêmes contrôles réussis |
| GUI / console / hôte historiques | .NET Framework, CLR 4.0.30319.42000 | Assembly Python 2.7.0.40 / DLR 1.1.0.20 | ZIP StdLib, imports, compilation des scripts, 10 tests réussis |
| Témoin 2.7.12 du build précédent | .NET 10.0.12 | 2.7.12.0 / 1.3.1.0 | Échec attendu `ArgumentException` dans `ImplementCTDOverride` |

Outillage : SDK .NET 10.0.401 et Visual Studio MSBuild 17.14.60. Les sorties sont
issues d’une copie fraîche des sources locales ; aucune ancienne DLL candidate
n’est utilisée comme preuve. Les chemins des DLL et de chacun des sept modules
StdLib sont inscrits dans les logs. La StdLib candidate vient bien du dossier `lib`
de chaque addin. Les packages modernes sont verrouillés dans `packages.lock.json`.
La paire hôte/utilitaires compilée par dotnet est distribuée à tous les consommateurs
avant leurs tests ; les empreintes de ces deux DLL sont identiques dans GUI/2025/2026/2027.

Les dix tests couvrent sept décisions de routage (familles, .NET 8, runtime inconnu,
lecture impossible, doublons) et trois comportements de scripts (flux, Unicode et
interop .NET, tâche sous chemin accentué et remontée d’exception).
Le point d’entrée réel de l’hôte est aussi exercé avec un script minimal et
`__revit__` simulé ; cela ne constitue pas un essai des API Revit.

Les builds 2025/2026/2027 ont respectivement 41/28/27 warnings, sans erreur :
références historiques absentes/conflits, ruleset absent et packages auxiliaires.
Le GUI signale également des conflits historiques. Ils restent visibles dans les
logs et ne sont pas masqués. Les DLL moteur/DLR candidates restent cohérentes.

561 fichiers d’installation RBP inventoriés avant/après : aucune différence
d’empreinte ou de chemin. Aucun appel à `DeployAddin.bat`, installateur ou Revit.
Les changements préexistants README/lanceurs et les documents locaux sont préservés.

## Éléments non qualifiés au 30 septembre 2026

Les sessions Revit et l’orchestration réelle ont depuis été qualifiées : voir
[Qualification Revit du 2 octobre 2026](#qualification-revit-du-2-octobre-2026).

- Sessions Revit 2025.5 build 25.5.0.57, 2026.5 et 2027 : aucun essai dans Revit.
- Orchestration réelle du monitor, pipes, progression, dialogues, fermeture et
  coexistence pyRevit : nécessitent le pilote jetable prévu au runbook.
- Scénarios Britton FR/EN et `TMP`/`tmp`/`TMP2` : comportements préservés, essais
  Revit restants ; branches à fermeture dangereuse non exécutées.
- Revit historiques : régression du moteur/hôte hors Revit réussie, sessions non testées.
- Scripts métier et configurations externes : aucun inventaire exhaustif possible
  sans leurs chemins ; le dépôt ne contient pas de configuration métier identifiée.
  Le template distribué fait partie des 60 scripts compilés. Aucune migration ou
  modification automatique d’un original/configuration utilisateur.
- Dynamo et cloud : inchangés, non qualifiés.

À cette date, le package était un candidat pilote. Consulter
[le runbook](net10-pilot.md) pour déploiement explicite et retour arrière.

## Qualification Revit du 2 octobre 2026

Le mainteneur a testé les addins .NET 10 dans Revit 2025.5, 2026.5 et 2027 :
fonctionnement conforme dans les trois versions. La validation .NET 10 de ces
versions est considérée comme terminée ; le package n’est plus un candidat pilote.
Les builds Revit exacts et le détail des scénarios ne sont pas consignés ici.
Dynamo et le cloud restent non qualifiés.

## Corrections après revue du commit 91935f7

La première qualification ci-dessus précédait la revue Codex/Astra. Celle-ci a
reproduit la perte des données associées et l’ignorance d’une liste réécrite : la
lecture fichier mettait les chemins seuls dans `RevitFileList`, réservé désormais
à l’entrée en mémoire. Le fichier est relu avec tous ses enregistrements.

Cinq tests supplémentaires vérifient les colonnes CSV/texte, les réécritures, la
priorité d’une liste en mémoire, le lecteur Excel simulé et le refus d’un lot devenu
mixte avant lancement. La suite comporte désormais quinze tests par moteur.
Les tests de monitor chargent ses fonctions sans exécuter son `Main()` automatique ;
inspection de modèles et lancement restent remplacés par des fonctions de test.

Le contrôle 2.7.12 écrit son exception sur stderr. Sous PowerShell 5.1, la
redirection native avec `ErrorActionPreference=Stop` interrompait le build avant
son contrôle de sortie. Un processus distinct capture maintenant les deux flux
en UTF-8, sans modifier la préférence du shell. Les tests vérifient l’erreur attendue,
la conservation des chemins accentués et le rejet d’un candidat qui réussit.
La fonction de lancement des autres commandes accepte également stderr avec un
code zéro (progression `unittest`), tout en rejetant un code non nul. Ces deux cas
sont testés sous PowerShell 5.1 et 7 sans changer la préférence du shell appelant.
Les logs du nouveau pilote constituent les résultats de cette nouvelle exécution ;
les archives de qualification antérieures restent conservées.
