# Instructions pour les agents — Revit Batch Processor

Lire [le guide commun](docs/agent-development.md) avant de modifier le dépôt.
Il décrit l'architecture, les commandes, les contraintes de compatibilité et la validation.

- Préserver les changements locaux existants ; commencer par `git status --short`.
- Vérifier le framework, le moteur Python et la version Revit des chemins concernés.
- Les builds des addins peuvent remplacer une installation sous `%APPDATA%` : lire la section compilation du guide avant de les lancer.
- Ne pas traiter de modèles Revit de production pour valider une modification.
- Rapporter les vérifications réellement effectuées et leurs limites.

Les règles communes se maintiennent dans `docs/agent-development.md`. Les fichiers
`CLAUDE.md` et `.github/copilot-instructions.md` sont des points d'entrée vers ce même guide.
