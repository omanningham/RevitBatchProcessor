*Français | [English](README.en.md)*

# Revit Batch Processor (RBP) — édition Britton

Traitement par lots entièrement automatisé de fichiers Revit à l'aide de vos propres scripts de tâche Python ou Dynamo!

> [!IMPORTANT]
> **Ce dépôt est le fork de La Cie Électrique Britton Ltée (« Britton »), et non le projet officiel.**
>
> - Il est maintenu par Britton pour ses propres besoins. Ni BVN ni l'auteur original (@DanRumery) ne le soutiennent; ce dernier ne maintient d'ailleurs plus le projet officiel.
> - Le projet officiel, en anglais, se trouve à <https://github.com/bvn-architecture/RevitBatchProcessor>. Les problèmes propres à cette édition doivent être signalés dans [ce dépôt](https://github.com/omanningham/RevitBatchProcessor/issues), pas dans le dépôt officiel.
> - Les adaptations Britton (libellés de boutons français, prétraitement des dossiers `TMP`, etc.) sont décrites dans le [registre des adaptations Britton](docs/britton-customizations.md).

## En quoi ce fork diffère de l'original

| Sujet | Édition Britton |
| --- | --- |
| Versions | Tags `vX.Y.Z-brt.N` : `X.Y.Z` est la version officielle fusionnée, `N` le numéro de release Britton sur cette base. Aucune release bêta. Voir la [numérotation des versions](docs/britton-customizations.md#numérotation-des-versions). |
| Installeur | Affiché sous le nom « Revit Batch Processor (Britton) », éditeur « Britton ». Il conserve l'identifiant d'application officiel : il **remplace** une installation BVN existante au lieu de coexister avec elle. |
| Distribution | Installeur publié dans les [releases du fork](https://github.com/omanningham/RevitBatchProcessor/releases) et manifeste pour une [source winget privée](docs/winget.md). |
| Revit 2025 à 2027 | Addins ciblant .NET 10 (`net10.0-windows`) avec IronPython 3.4.2, qualifiés par le mainteneur dans Revit 2025.5, 2026.5 et 2027 le 2 octobre 2026. Dynamo et l'infonuagique restent non qualifiés. Voir le [runbook .NET 10](docs/net10-pilot.md). |
| Dialogues Revit | Reconnaissance de certains boutons français (Fermer, Oui, Non) en plus des libellés anglais (BRT-01 et BRT-02). |
| Dossiers `TMP` | Un fichier dont le chemin contient un dossier `TMP` est réenregistré sur lui-même avant l'exécution de la tâche (BRT-03). |
| Mises à jour officielles | Intégrées manuellement; une veille signale les nouveautés du dépôt officiel sans fusion automatique. |

Ce README est la traduction en français canadien du README officiel, adaptée à l'édition Britton. Une [version anglaise](README.en.md) de ce README est maintenue en parallèle. Le [README original en anglais](https://github.com/bvn-architecture/RevitBatchProcessor/blob/master/README.md) reste disponible dans le dépôt officiel.

## Dernière version

La version 1.13.0-brt.1 est disponible et prend en charge Revit 2027. [Télécharger l'installeur](https://github.com/omanningham/RevitBatchProcessor/releases/download/v1.13.0-brt.1/RevitBatchProcessorSetup_v1.13.0-brt.1.exe)

Consultez la page des [releases](https://github.com/omanningham/RevitBatchProcessor/releases) pour les [notes de version 1.13.0-brt.1](https://github.com/omanningham/RevitBatchProcessor/releases/tag/v1.13.0-brt.1).

## Scripts exemples

Des exemples simples de tâche, de prétraitement et de post-traitement se trouvent dans [docs/SampleScripts.md](docs/SampleScripts.md). L'interface est décrite dans [docs/ui.md](docs/ui.md). Ces deux documents sont en anglais.

[Cliquez ici pour des exemples de scripts Python pour RBP maintenus par Jan Christel (@jchristel)](https://github.com/jchristel/SampleCodeRevitBatchProcessor/) (en anglais).

Un grand merci à Jan d'avoir écrit et rendu publics ces scripts exemples!

## FAQ

Voir la [FAQ de Revit Batch Processor](https://github.com/bvn-architecture/RevitBatchProcessor/wiki/Revit-Batch-Processor-FAQ) du projet officiel (en anglais). Elle ne couvre pas les adaptations Britton.

## Cas d'utilisation

Cet outil ne _fait_ aucune de ces choses par lui-même, mais il vous _permet_ de les faire :

- Ouvrir tous les fichiers Revit de vos projets et y exécuter un script de vérification de l'état des modèles. Surveiller l'état et la performance de nombreux fichiers Revit prend du temps. Vous pouvez vous en servir pour vérifier vos fichiers régulièrement et réagir aux problèmes avant qu'ils ne s'aggravent (RBP travaille normalement sur des copies détachées : les résultats décrivent donc un instantané du modèle central).
- Effectuer des audits de projets et de familles dans l'ensemble de vos projets Revit.
- Exécuter des requêtes à grande échelle sur de nombreux fichiers Revit.
- Extraire des données de vos projets Revit à des fins d'analyse.
- Automatiser des tâches d'entretien (p. ex. placer les éléments dans les bons sous-projets).
- Mettre à niveau des projets et des familles Revit par lots.
- Tester vos propres scripts et addins de l'API Revit sur divers modèles et familles, de façon automatisée.
- La plupart des actions possibles sur un fichier Revit avec l'API Revit ou un script Dynamo peuvent maintenant être faites sur plusieurs (lisez [Un grand pouvoir](#un-grand-pouvoir) avant de modifier des fichiers partagés).

![Capture d'écran de l'interface](BatchRvt_Screenshot.png)

## Fonctionnalités

- Traitement par lots de fichiers Revit (.rvt et .rfa) avec une version précise de Revit ou avec la version dans laquelle chaque fichier a été enregistré. Les versions de Revit 2015 à 2027 sont prises en charge (la version de Revit requise doit évidemment être installée).
- Scripts de tâche personnalisés en Python ou en Dynamo! Les scripts Python ont accès à toute l'API Revit. Les scripts Dynamo peuvent faire tout ce que Dynamo sait faire.
- Création, d'un simple clic, d'un nouveau script de tâche Python contenant le minimum de code requis pour agir sur un fichier Revit ouvert. Ce script peut ensuite être enrichi pour accomplir un travail utile. Il peut même charger et exécuter vos fonctions existantes dans une DLL C# (voir [Exécuter des fonctions dans une DLL C#](#exécuter-des-fonctions-dans-une-dll-c)).
- Scripts personnalisés de prétraitement et de post-traitement, utiles lorsque la tâche globale demande une préparation ou un nettoyage supplémentaire.
- Options de traitement des fichiers centraux : créer un nouveau fichier local (*Create New Local*) ou détacher du central (*Detach from Central*).
- Traitement des fichiers d'une même version de Revit dans une seule session Revit, ou de chaque fichier dans sa propre session. La seconde option est utile si Revit plante pendant le traitement, car le reste du lot n'est pas bloqué.
- Gestion automatique des dialogues et boîtes de message de Revit. Ceux-ci, de même que les messages d'erreur de Revit, sont traités et consignés dans la console de l'interface. Le traitement par lots a ainsi de très bonnes chances de se terminer sans intervention de l'utilisateur!
- Importation et exportation des paramètres. Combinée à l'[interface en ligne de commande](#interface-en-ligne-de-commande), cette fonction permet de planifier des traitements automatiques (avec le Planificateur de tâches de Windows) sans l'interface graphique.
- Génération d'une liste .txt de chemins de fichiers Revit compatible avec RBP. Le bouton *New List* de l'interface demande un dossier à analyser. Vous pouvez préciser le type de fichiers Revit recherchés et inclure ou non les sous-dossiers.

## Un grand pouvoir

> « With great power comes great responsibility » (« Un grand pouvoir implique de grandes responsabilités »)
>
> [— Spiderman](https://quoteinvestigator.com/2015/07/23/great-power/)

Cet outil permet d'agir sur des fichiers Revit à très grande échelle. C'est pourquoi les scripts Python ou Dynamo qui modifient des fichiers Revit (surtout des fichiers partagés) doivent être développés avec le plus grand soin! Vous devez être certain que vos scripts ne ruineront pas vos fichiers en masse. L'option *Detach from Central* de Revit Batch Processor devrait être utilisée pendant les essais et pour tout script qui ne dépend pas explicitement d'un fichier central partagé actif.

### Sécurité des données

- Faites vos essais sur des copies jetables de vos modèles, jamais sur des fichiers de production.
- *Detach from Central* ne s'applique qu'aux fichiers partagés. Les fichiers .rvt non partagés et les familles (.rfa) sont ouverts directement : un script de tâche qui enregistre le document modifie l'original. Un document détaché qui est enregistré devient un nouveau modèle central.
- *Create New Local* est le seul mode qui ne détache pas. Le fichier local est créé sous `C:\REVIT_LOCAL<année>` et tout fichier déjà présent à cet emplacement est d'abord supprimé.
- Dans cette édition, un chemin contenant un dossier `TMP` est réenregistré sur lui-même avant l'exécution de la tâche (BRT-03). Voir [docs/britton-customizations.md](docs/britton-customizations.md).

# Compilation et installation

## Développement avec des agents de programmation

Voir le [guide commun de développement avec des agents](docs/agent-development.md) pour l'architecture du dépôt, les contraintes de compilation et les consignes de validation. Les points d'entrée sont `AGENTS.md`, `CLAUDE.md` et `.github/copilot-instructions.md`.

## Installeur

[Installeur de Revit Batch Processor 1.13.0-brt.1](https://github.com/omanningham/RevitBatchProcessor/releases/download/v1.13.0-brt.1/RevitBatchProcessorSetup_v1.13.0-brt.1.exe)

L'application Revit Batch Processor (interface graphique) apparaît dans le menu Démarrer après l'installation. L'installation se fait dans le profil de l'utilisateur, sans droits d'administrateur. Pour une installation par winget, voir [docs/winget.md](docs/winget.md).

## Compiler à partir du code source

Ouvrez la solution RevitBatchProcessor.sln dans Visual Studio et lancez *Build Solution*. Les addins Revit 2025 à 2027 ciblent `net10.0-windows`, ce qui exige Visual Studio 18.0 (2026) ou ultérieur avec le SDK .NET 10; les autres projets ne demandent que Visual Studio 2017 ou ultérieur. La compilation remplace les fichiers d'addins déjà installés sous `%APPDATA%` : lisez d'abord la section sur la compilation de [docs/agent-development.md](docs/agent-development.md).

Les addins Revit sont déployés automatiquement dans le dossier Addins de chaque version de Revit disponible (2015 à 2027), p. ex. `%APPDATA%\Autodesk\Revit\Addins\2019`.

Le projet BatchRvtGUI est l'interface graphique qui pilote le moteur sous-jacent (le projet BatchRvt). Une fois la compilation terminée, lancez BatchRvtGUI.exe pour démarrer l'interface de Revit Batch Processor.

Avant de recompiler, assurez-vous que toutes les instances de Revit sont fermées.

# Prérequis

- Au moins une version de Revit installée. Les versions de Revit 2015 à 2027 sont prises en charge.
- Pour compiler toute la solution à partir du code source : Visual Studio 2026 (version 18.0 ou ultérieure, requise pour cibler `net10.0`) avec le SDK .NET 10. Visual Studio 2017 ou ultérieur suffit seulement pour les projets qui ne ciblent pas .NET 10. Voir [Microsoft Learn](https://learn.microsoft.com/dotnet/core/porting/versioning-sdk-msbuild-vs#targeting-and-support-rules).
- Pour exécuter des scripts Dynamo à partir du script de tâche : Dynamo 1.3 ou ultérieur (Revit 2016 à 2027). NOTE : RBP exécute une copie temporaire du script Dynamo en mode d'exécution « Automatic »; le dossier du script doit donc être accessible en écriture. La prise en charge de Dynamo pour Revit 2025 à 2027 n'a pas été qualifiée dans cette édition (voir [docs/net10-pilot.md](docs/net10-pilot.md)). Il doit y avoir **EXACTEMENT UNE VERSION DE DYNAMO INSTALLÉE** pour chaque version de Revit.
- Pour utiliser un fichier Excel comme liste de fichiers Revit : Microsoft Office / Excel installé.

# Licence

Ce projet est distribué selon les modalités de la [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl.html). L'avis de licence officiel, en anglais, est reproduit ci-dessous.

Copyright (c) 2021  Daniel Rumery, BVN

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Crédits

Daniel Rumery [@DanRumery](https://github.com/DanRumery) (auteur original et principal)

## Autres contributeurs (code)

- Vincent Cadoret [@vinnividivicci](https://github.com/vinnividivicci)
- Ryan Schwartz [@RyanSchw](https://github.com/RyanSchw)
- Dimitar Venkov [@dimven](https://github.com/dimven) (prise en charge de Revit 2025)
- Nicklas Ostergaard [@NicklasOestergaard](https://github.com/NicklasOestergaard) (prise en charge de Revit 2022)
- Peter Smith [@punderscoresmithuk](https://github.com/punderscoresmithuk) (prise en charge de Revit 2023)
- Maciej Wypych [@maciejwypych](https://github.com/maciejwypych) (prise en charge de Revit 2024 et plus)
- Rob Mintzes [@rgdt-bert](https://github.com/rgdt-bert) (prise en charge de Revit 2027)

Les adaptations de l'édition Britton sont maintenues par La Cie Électrique Britton Ltée.

# Utilisation

Les ***deux ingrédients*** nécessaires pour utiliser Revit Batch Processor (« RBP ») sont :

- Un **fichier Excel (.xlsx / .xls)**, un **fichier CSV (.csv)** ou un **fichier texte (.txt)** contenant une liste de chemins de fichiers Revit. Chaque chemin doit être complet (aucun chemin partiel).

  Pour un fichier Excel, la première colonne de chaque ligne contient un chemin de fichier.

  Pour un fichier texte, chaque ligne contient un chemin de fichier.

  Par exemple :
  ```
  P:\15\ProjectABC\MainModel.rvt
  P:\16\ProjectXYZ\ModelA.rvt
  P:\16\ProjectXYZ\ModelB.rvt
  P:\16\ProjectXYZ\ConsultantModel.rvt
  ```

  NOTE : vous pouvez générer cette liste au format .txt avec le bouton *New List* de l'interface. Il vous demandera un dossier à analyser. Vous pouvez préciser le type de fichiers Revit recherchés et inclure ou non les sous-dossiers.

  *Nouveau depuis la version 1.6*

  La prise en charge du traitement de fichiers hébergés dans BIM 360 est limitée. Pour ces fichiers, utilisez plutôt le format suivant :

  `<Version de Revit> <GUID du projet> <GUID du modèle>`

  *Note : ces trois éléments doivent être séparés par des espaces (pas des tabulations!).*

  Par exemple :
  ```
  2020 75b6464c-ba0f-4529-b049-0de9e473c2d6 0d54b8cc-3837-4df2-8c8e-0a94f4828868
  2020 c0dc2fda-fd34-42fe-8bb7-bd9f43841dbf d9f011d6-d52c-4c9f-9d7b-eb8388bd3ed0
  ```

  RBP ne peut pas détecter la version de Revit des modèles infonuagiques; c'est pourquoi elle est indiquée explicitement.

- Un script de tâche **Dynamo (.dyn)** ou **Python (.py)**. Ce script est exécuté une fois pour chaque fichier de la liste.

  Pour Dynamo, **tout fichier d'espace de travail (.dyn) devrait fonctionner** comme script de tâche sans modification. *(Si vous trouvez un script qui fonctionne dans Dynamo mais pas dans RBP, [signalez-le](https://github.com/omanningham/RevitBatchProcessor/issues/new/choose) dans ce dépôt!)*

  Un script Python (\*.py) doit contenir au minimum le code suivant :
  ```python
  '''Output "Hello Revit world!" to the console / log.'''

  # This section is common to all Python task scripts.
  import clr
  import System

  clr.AddReference("RevitAPI")
  clr.AddReference("RevitAPIUI")
  from Autodesk.Revit.DB import *

  import revit_script_util
  from revit_script_util import Output

  sessionId = revit_script_util.GetSessionId()
  uiapp = revit_script_util.GetUIApplication()

  doc = revit_script_util.GetScriptDocument()
  revitFilePath = revit_script_util.GetRevitFilePath()

  # The code above is boilerplate, everything below is all yours.
  # You can use almost any part of the Revit API here!

  Output()
  Output("Hello Revit world!")
  ```

# Exécuter des fonctions dans une DLL C#

Un script de tâche Python peut facilement charger et exécuter du code d'une DLL C#. Lorsque RBP exécute le script de tâche Python, il ajoute le dossier du script aux chemins de recherche. Si votre DLL se trouve dans le même dossier que le script, vous pouvez donc exécuter vos fonctions ainsi :

```python
# For example assume your DLL is called MyUtilities.dll and you have a static function called SomeClass.DoSomeWork() in namespace MyNameSpace:
# Assume this python script exists in the same folder as MyUtilities.dll.
clr.AddReference("MyUtilities")
from MyNameSpace import SomeClass

# Invoke your static function, passing in any parameters you need.
SomeClass.DoSomeWork(doc)
```

# Interface en ligne de commande

Revit Batch Processor peut être lancé en ligne de commande, sans l'interface graphique. Configurez et exportez d'abord les paramètres de traitement voulus à partir de l'interface. Lancez ensuite l'utilitaire en ligne de commande **BatchRvt.exe** en lui passant le chemin du fichier de paramètres exporté :

```
%LOCALAPPDATA%\RevitBatchProcessor\BatchRvt.exe --settings_file "BatchRvt.Settings.json"
```

Vous pouvez aussi préciser l'emplacement du fichier journal :

```
%LOCALAPPDATA%\RevitBatchProcessor\BatchRvt.exe --log_folder "C:\MyBatchTasks\Logs" --settings_file "C:\MyBatchTasks\BatchRvt.Settings.json"
```

RBP peut aussi être lancé en mode de traitement par lots sans fichier de paramètres, avec quelques arguments de base :

```
%LOCALAPPDATA%\RevitBatchProcessor\BatchRvt.exe --task_script MyDynamoWorkspace.dyn --file_list RevitFileList.xlsx --revit_version 2018
```

Deux options n'apparaissent pas dans l'aide ci-dessous : `--per_file_timeout` (voir `--help` de votre version) et `--worksets last_viewed`.

NOTE : ce mode traite les fichiers centraux en mode détaché. L'argument **--revit_version** est facultatif ici; s'il est omis, RBP utilise la version de Revit dans laquelle chaque fichier a été enregistré.

Pour afficher l'aide de toutes les options en ligne de commande, utilisez `--help` (l'aide est en anglais) :

```
%LOCALAPPDATA%\RevitBatchProcessor\BatchRvt.exe --help
```

```
Help:

	Usage (using a settings file):

		BatchRvt.exe --settings_file <SETTINGS FILE PATH> [--log_folder <LOG FOLDER PATH>]

	Example:

		BatchRvt.exe --settings_file BatchRvt.Settings.json --log_folder .


	Usage (without a settings file):

		BatchRvt.exe --file_list <REVIT FILE LIST PATH> --task_script <TASK SCRIPT FILE PATH>

	(NOTE: this mode operates in batch mode only; by default operates in detach mode for central files.)


	Additional command-line options:

		--revit_version <REVIT VERSION>

		--log_folder <LOG FOLDER PATH>

		--detach | --create_new_local

		--worksets <open_all | close_all>

		--audit

		--help


	Examples:

		BatchRvt.exe --task_script MyDynamoWorkspace.dyn --file_list RevitFileList.xlsx

		BatchRvt.exe --task_script MyDynamoWorkspace.dyn --file_list RevitFileList.xlsx --detach --audit

		BatchRvt.exe --task_script MyTask.py --file_list RevitFileList.txt --create_new_local --worksets open_all

		BatchRvt.exe --task_script MyTask.py --file_list RevitFileList.xlsx --revit_version 2019 --detach --worksets close_all

```

# Contribuer

Les commentaires et suggestions d'amélioration sont les bienvenus! Signalez les bogues de cette édition dans la page Issues de ce dépôt. Vous pouvez aussi proposer votre propre code par une pull request.

<https://github.com/omanningham/RevitBatchProcessor>

Ce dépôt est un fork du projet original, <https://github.com/bvn-architecture/RevitBatchProcessor>. Une correction qui ne concerne pas les adaptations Britton peut aussi intéresser le projet officiel.

# Limitations et problèmes connus

- Il doit y avoir **EXACTEMENT UNE VERSION DE DYNAMO INSTALLÉE** pour chaque version de Revit. Si plusieurs versions de Dynamo sont installées pour la même version de Revit, Revit Batch Processor ne parvient pas à exécuter le script de tâche Dynamo, car le module Dynamo Revit requis n'est pas chargé. Cela pourrait être corrigé dans une version future.
- Les scripts Dynamo sont toujours exécutés avec l'option *Use separate Revit session for each Revit File*. Cette restriction découle du contexte dans lequel Revit Batch Processor utilise l'API Revit, qui empêche de fermer ou de changer le document actif de l'interface pendant la session Revit. (NOTE : pour un script de tâche Dynamo, Revit Batch Processor ouvre le document dans l'interface et est donc soumis à cette limite de l'API Revit. Pour un script de tâche Python, le document est seulement ouvert en mémoire : les scripts Python ne subissent pas cette restriction!)
- Revit Batch Processor ne reconnaît et ne traite automatiquement que les dialogues Revit présentés en anglais (titre, texte et libellés des boutons). Avec une version non anglaise de Windows ou de Revit, il est très probable que RBP ne puisse pas traiter certains dialogues pendant le traitement. (Cette édition ajoute quelques libellés de boutons français — Fermer, Oui, Non — voir [docs/britton-customizations.md](docs/britton-customizations.md); la couverture reste partielle.)
- Revit Batch Processor doit avoir accès en écriture au dossier qui contient le script Dynamo, car il crée une copie temporaire du script dans le même dossier que l'original. Cette copie permet de régler temporairement le mode d'exécution du script à « Automatic » (s'il ne l'est pas déjà). Elle est créée dans le même dossier afin que les chemins relatifs du script restent valides.
