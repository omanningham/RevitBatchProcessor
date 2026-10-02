# Instructions Claude Code — Revit Batch Processor

Lire et appliquer [le guide commun](docs/agent-development.md) avant de modifier le dépôt.
Le lire explicitement si son contenu n'est pas déjà dans le contexte.

- Préserver les changements locaux existants ; commencer par `git status --short`.
- Vérifier le framework, le moteur Python et la version Revit des chemins concernés.
- Les builds des addins peuvent remplacer une installation sous `%APPDATA%` : lire la section compilation du guide avant de les lancer.
- Ne pas traiter de modèles Revit de production pour valider une modification.
- Rapporter les vérifications réellement effectuées et leurs limites.

Maintenir les règles détaillées dans le guide commun, sans les dupliquer ici.
