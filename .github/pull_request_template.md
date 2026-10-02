## Résumé

<!-- Quoi et pourquoi. Lier l'issue le cas échéant (Fixes #123). -->

## Périmètre

- Versions Revit touchées : <!-- 2015–2024 / 2025–2027 / aucune -->
- Moteur Python concerné : <!-- IronPython 2.7 / IronPython 3.4 / les deux / aucun -->
- Composants : <!-- GUI, console, BatchRvtUtil/Scripts, ScriptHost, addin, installateur, docs… -->

## Validation

Voir le tableau « Validation et état des tests » de [`docs/agent-development.md`](https://github.com/omanningham/RevitBatchProcessor/blob/master/docs/agent-development.md#validation-et-état-des-tests).

- [ ] CI verte (vérifications du dépôt, build de la solution, addins 2025–2027)
- [ ] Nouveaux fichiers ajoutés aux `Compile` / `Content` des `.csproj` historiques
- [ ] Scripts partagés vérifiés pour chaque moteur consommateur (pas de syntaxe Python 3 sous IronPython 2.7)
- [ ] Essai dans Revit sur une copie jetable : version et build Revit, scénario, résultat → <!-- ou « non requis » avec la raison -->
- [ ] Aucun modèle de production, central, synchronisation ou traitement cloud réel utilisé
- [ ] Aucun déploiement non voulu (`DeployAddinOnBuild=false`, pas d'installateur lancé)
- [ ] [`docs/britton-customizations.md`](https://github.com/omanningham/RevitBatchProcessor/blob/master/docs/britton-customizations.md) mis à jour si un comportement Britton change
- [ ] Guide commun mis à jour si les commandes, projets, runtimes ou tests changent

## Limites connues

<!-- Ce qui n'a pas été vérifié, et pourquoi. -->
