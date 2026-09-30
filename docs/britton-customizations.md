# Adaptations Britton

Ce document décrit les adaptations Britton intégrées aux sources de Revit Batch
Processor et les contrôles à effectuer après une mise à jour du dépôt officiel.
Il s'adresse aux mainteneurs et aux agents de programmation.

État de référence : 30 septembre 2026, commit du fork `2a47aa6`.
L'analyse porte sur le code source ; elle ne certifie pas le comportement dans Revit
ni la version actuellement installée sur un poste.

## Sources actives et archives

Les quatre fichiers actifs sont directement dans `BatchRvtUtil/Scripts/`.
Ils sont déclarés comme `Content` avec `CopyToOutputDirectory=Always` dans
[BatchRvtUtil.csproj](../BatchRvtUtil/BatchRvtUtil.csproj).

Le dossier `BatchRvtUtil/Scripts/Britton modified/` est conservé uniquement pour
archivage. Ses fichiers ne sont pas utilisés par l'application. Ne pas les recopier
sur les originaux lors d'une mise à jour : ils ne contiennent pas les évolutions
récentes du dépôt officiel, notamment celles concernant le cloud et les dialogues.
Toute nouvelle adaptation doit être faite dans les sources actives.

## Historique et conservation

- `b392bc6` — 27 janvier 2025 : archivage des quatre copies modifiées.
- `14f6113` — 28 janvier 2025 : intégration des adaptations Britton dans les quatre sources actives.
- `fe3eade` — 11 septembre 2025 : fusion du dépôt officiel dans le fork.
- `2a47aa6` — 30 septembre 2026 : nouvelle fusion du dépôt officiel, au commit `000d4cb`.

La vérification du 30 septembre 2026 a confirmé, fichier par fichier, que le patch
entre `000d4cb` et `2a47aa6` possède la même empreinte `git patch-id --stable` que
le patch initial `14f6113`. Les adaptations décrites ci-dessous ont donc été
conservées dans les sources actives après ces mises à jour. Cette comparaison
de patches ne remplace pas un test d'exécution.

## BRT-01 — Libellés de boutons français

Source : [revit_dialog_detection.py](../BatchRvtUtil/Scripts/revit_dialog_detection.py).

Objectif : permettre à la détection de boutons de reconnaître plusieurs libellés,
dont certaines traductions françaises, tout en conservant les libellés anglais.
Les constantes ajoutées ou redéfinies par Britton sont :

| Constante | Valeurs |
| --- | --- |
| `CLOSE_BUTTON_TEXT` | `Close`, `Fermer` |
| `OK_BUTTON_TEXT` | `OK`, `Ok` |
| `NO_BUTTON_TEXT` | `No`, `Non` |
| `YES_BUTTON_TEXT` | `Yes`, `Oui` |
| `ALWAYS_LOAD_BUTTON_TEXT` | `Always Load` |
| `CANCEL_LINK_BUTTON_TEXT` | `Cancel Link` |

Ces listes s'appuient sur BRT-02. Leur présence n'implique pas une traduction complète
des titres de fenêtres, ni un traitement automatique de tous les boutons : chaque
appelant et chaque branche de détection doivent être vérifiés. Conserver également
les traitements supplémentaires du dépôt officiel, y compris les libellés espagnols.

## BRT-02 — Recherche avec plusieurs libellés

Source : [ui_automation_util.py](../BatchRvtUtil/Scripts/ui_automation_util.py),
fonction `FilterControlsByText`.

Britton a ajouté une boucle sur les libellés reçus dans `controlText`. La fonction
compare le texte de chaque contrôle à chacun des libellés, après suppression des
esperluettes du texte du contrôle, suppression des espaces en bordure et conversion
en minuscules. Cela permet notamment de rechercher `Close` et `Fermer` ensemble.

Deux limites actuelles sont visibles dans le code :

- Une chaîne seule est parcourue caractère par caractère. Certains appelants passent encore des chaînes ; leur reconnaissance de boutons peut échouer.
- Deux libellés équivalents après normalisation peuvent produire deux entrées pour le même contrôle. La liste `OK`, `Ok` peut ainsi faire échouer un appelant exigeant exactement un résultat.

Ces limites sont documentées, pas corrigées par ce document. Une évolution devra
prendre en charge les chaînes et les listes tout en évitant les résultats dupliqués.

## BRT-03 — Prétraitement des fichiers dans un dossier TMP

Source : [revit_script_util.py](../BatchRvtUtil/Scripts/revit_script_util.py),
fonction `WithOpenedDetachedDocument`.

Britton a ajouté `import os` et un prétraitement conditionné par la présence d'un
composant de chemin exactement égal à `TMP` après `os.path.normpath` et découpage
par `os.path.sep`. La comparaison est sensible à la casse : `tmp` ou `TMP2` ne
déclenchent pas cette branche. Il ne s'agit pas de la variable d'environnement TMP.

Pour un chemin correspondant, dans les deux modes `openInUI` :

1. Écrire `Fichier Temporaire` dans le journal.
2. Ouvrir une instance détachée en conservant les sous-projets avec `OpenDetachAndPreserveWorksets`.
3. Appeler `SaveAsNewCentral` au **même chemin**, avec `overwrite=True` et `clearTransmitted=True`.
4. En cas d'exception, réessayer avec `clearTransmitted=False` et toujours `overwrite=True`.
5. Appeler `SafeCloseWithoutSave` dans le bloc `finally`, puis poursuivre le parcours normal d'ouverture détachée et d'exécution de la tâche si aucune erreur ne remonte.

Le comportement d'enregistrement de `SaveAsNewCentral` est défini dans
[revit_file_util.py](../BatchRvtUtil/Scripts/revit_file_util.py). Cette fonction
préexistante n'a pas été ajoutée par le commit Britton ; ce sont ses appels dans
le prétraitement qui constituent l'adaptation.

Points à préserver ou à vérifier :

- Ce prétraitement peut écraser le fichier de test au chemin reçu, avant l'exécution de la tâche. Utiliser une copie jetable pour toute validation.
- Les deux clauses `except Exception, e` ajoutées ici utilisent la syntaxe Python 2, incompatible avec Python 3. L'addin 2027 déclare IronPython 3 : ce chemin nécessite une correction de compatibilité avant validation sur ce moteur.
- `SafeCloseWithoutSave` ne ferme effectivement le document que si `isOpenedInUI` est faux. Dans la branche `openInUI=True`, le document temporaire est pourtant ouvert par l'API sans activation UI : sa fermeture effective reste à vérifier.

## BRT-04 — Encodage et imports

Les quatre sources actives déclarent l'encodage UTF-8. Le commit Britton a également
ajouté `import script_util` et `from script_util import Output` à
[revit_file_util.py](../BatchRvtUtil/Scripts/revit_file_util.py).

Ces ajouts doivent être distingués des évolutions officielles de ce fichier, notamment
la gestion des régions cloud. Les traces `teste1`, le suffixe `_BRT` et les commentaires
de diagnostic présents dans certaines archives ne constituent pas des fonctionnalités
actives à réintroduire automatiquement.

## Procédure après une mise à jour officielle

La configuration constatée utilise `origin` pour le fork Britton et `upstream` pour
le dépôt `bvn-architecture/RevitBatchProcessor`. La branche active à la date de
référence est `master` ; aucune branche `britton` n'a été créée dans le cadre de cette
documentation.

1. Vérifier `git status --short --branch` et sauvegarder les changements locaux dans des commits ciblés avant la fusion. Ne pas écraser les changements non commités.
2. Récupérer les références officielles avec `git fetch upstream` et examiner les nouveautés.
3. Sur la branche qui contient les adaptations Britton, fusionner `upstream/master` avec `git merge upstream/master`. Adapter le nom si le dépôt officiel change de branche principale.
4. En cas de conflit, préserver l'intention BRT-01 à BRT-04 tout en intégrant les améliorations officielles. Ne pas choisir globalement une seule version des fichiers.
5. Examiner les quatre sources actives et effectuer les validations ci-dessous avant de pousser la branche vers `origin`.

Commandes d'inspection depuis la racine, après récupération des références :

```powershell
git show 14f6113 -- BatchRvtUtil/Scripts/revit_dialog_detection.py BatchRvtUtil/Scripts/revit_file_util.py BatchRvtUtil/Scripts/revit_script_util.py BatchRvtUtil/Scripts/ui_automation_util.py
git diff upstream/master HEAD -- BatchRvtUtil/Scripts/revit_dialog_detection.py BatchRvtUtil/Scripts/revit_file_util.py BatchRvtUtil/Scripts/revit_script_util.py BatchRvtUtil/Scripts/ui_automation_util.py
git diff HEAD -- BatchRvtUtil/Scripts/revit_dialog_detection.py BatchRvtUtil/Scripts/revit_file_util.py BatchRvtUtil/Scripts/revit_script_util.py BatchRvtUtil/Scripts/ui_automation_util.py
```

La deuxième commande montre les différences commitées avec le dépôt officiel ; la
troisième montre les changements locaux, indexés ou non, par rapport à `HEAD`.
Après une correction ou une refonte, l'empreinte du patch peut changer légitimement :
évaluer le comportement attendu plutôt que d'imposer la conservation exacte du patch.

## Scénarios de validation à réaliser

Ces scénarios ne constituent pas une suite automatisée existante. Consigner pour
chaque essai le commit, la version Revit, le moteur Python, les options et le résultat.

| Adaptation | Scénario et résultat à vérifier |
| --- | --- |
| BRT-01 | Dialogues ciblés en français et en anglais : reconnaissance du bouton voulu, sans perte des cas officiels. |
| BRT-02 | Un contrôle `OK` avec `['OK', 'Ok']` : un seul résultat attendu après correction ; tester aussi un libellé seul, une liste, aucun résultat et plusieurs contrôles distincts. |
| BRT-03 | Copie jetable sous un dossier `TMP` : vérifier le prétraitement, l'enregistrement au même chemin, la fermeture puis la poursuite de la tâche, avec et sans ouverture UI. |
| BRT-03 | Chemins sans `TMP`, avec `tmp` ou `TMP2` : absence de prétraitement selon la condition actuelle. |
| BRT-03 | Cas où le premier enregistrement échoue : vérifier la seconde tentative et la remontée d'erreur si elle échoue aussi. |
| BRT-04 | Chargement des scripts et affichage des caractères accentués sous les moteurs concernés. |
| Compatibilité | Vérifier les scripts partagés sous IronPython 2.7 et, pour le chemin 2027, sous IronPython 3 après correction de la syntaxe incompatible. |

Lire les contraintes de compilation et de déploiement du
[guide de développement](agent-development.md) avant tout build d'addin.
Une compilation réussie ne prouve ni la reconnaissance des dialogues, ni la sécurité
du traitement TMP, ni que le poste exécute les scripts nouvellement construits.

Pour toute nouvelle adaptation, ajouter ici son objectif, ses sources actives, ses
conditions de déclenchement, ses effets sur les fichiers et son scénario de validation.

## Extension progressive .NET 10

Les deux clauses Python 2 `except Exception, e` de la source active
`revit_script_util.py` deviennent `except Exception as e`. Aucun changement de
reconnaissance FR/EN, de traitement `TMP`, de repli d’enregistrement ou de fermeture.
Les archives « Britton modified » restent exclues des imports et du package pilote.
Les scripts actifs sont compilés par les deux moteurs dans les harnais hors Revit.
Le test des flux a aussi corrigé l’inversion stdout/stderr de leur restauration.

Les scénarios FR/EN, `TMP`, `tmp` et `TMP2` restent à qualifier dans Revit sur
copies jetables. Ne pas exécuter les branches dont la fermeture n’est pas sûre.
Le [runbook pilote](net10-pilot.md) précise les commandes, preuves et limites ;
Python 3.4.2 est utilisé pour les tâches Revit 2025–2027, Python 2 pour la supervision.
