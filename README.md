*English | [Français](README.fr.md)*

# Revit Batch Processor (RBP) — Britton edition

Fully automated batch processing of Revit files with your own Python or Dynamo task scripts!

> [!IMPORTANT]
> **This repository is the fork maintained by La Cie Électrique Britton Ltée ("Britton"), not the official project.**
>
> *Ce dépôt est le fork de La Cie Électrique Britton Ltée, et non le projet officiel. Documentation en français : [README.fr.md](README.fr.md).*
>
> - It is maintained by Britton for its own needs. It is not supported by BVN or by the original author (@DanRumery), who no longer maintains the official project either.
> - The official project is at <https://github.com/bvn-architecture/RevitBatchProcessor>. Issues specific to this edition should be reported in [this repository](https://github.com/omanningham/RevitBatchProcessor/issues), not in the official one.
> - The Britton changes (French button labels, `TMP` folder pre-processing, etc.) are described in the [Britton customizations register](docs/britton-customizations.md) (in French).

## How this fork differs from the original

| Topic | Britton edition |
| --- | --- |
| Versions | Tags `vX.Y.Z-brt.N`: `X.Y.Z` is the merged official version, `N` the Britton release number on that base. No beta releases. See [version numbering](docs/britton-customizations.md#numérotation-des-versions) (in French). |
| Installer | Displayed as "Revit Batch Processor (Britton)", publisher "Britton". It keeps the official application identifier, so it **replaces** an existing BVN installation instead of coexisting with it. |
| Distribution | Installer published in the [fork's releases](https://github.com/omanningham/RevitBatchProcessor/releases), with a manifest for a [private winget source](docs/winget.md) (in French). |
| Revit 2025 to 2027 | Addins targeting .NET 10 (`net10.0-windows`) with IronPython 3.4.2, qualified by the maintainer in Revit 2025.5, 2026.5 and 2027 on October 2, 2026. Dynamo and cloud processing remain unqualified. See the [.NET 10 runbook](docs/net10-pilot.md). |
| Revit dialogs | Recognition of some French buttons (Fermer, Oui, Non) in addition to the English labels (BRT-01 and BRT-02). |
| `TMP` folders | A file whose path contains a `TMP` folder is re-saved over itself before the task runs (BRT-03). |
| Official updates | Merged manually; a watch job reports official changes without merging them automatically. |

This README follows the official one, with the Britton changes above; a [French translation](README.fr.md) is maintained alongside it. The [original README](https://github.com/bvn-architecture/RevitBatchProcessor/blob/master/README.md) is still available in the official repository.

## Latest version

Version 1.13.0-brt.1 is available, which includes support for Revit 2027. [Installer is here](https://github.com/omanningham/RevitBatchProcessor/releases/download/v1.13.0-brt.1/RevitBatchProcessorSetup_v1.13.0-brt.1.exe)

See the [Releases](https://github.com/omanningham/RevitBatchProcessor/releases) page for [v1.13.0-brt.1 release notes](https://github.com/omanningham/RevitBatchProcessor/releases/tag/v1.13.0-brt.1).

## RBP Sample Scripts

Simple task, pre- and post-processing examples are in [docs/SampleScripts.md](docs/SampleScripts.md). The UI is described in [docs/ui.md](docs/ui.md).

[Click here for some sample RBP python scripts maintained by Jan Christel (@jchristel)](https://github.com/jchristel/SampleCodeRevitBatchProcessor/)

Many thanks to Jan for authoring and making these RBP sample scripts public!

## FAQ

See the official project's [Revit Batch Processor FAQ](https://github.com/bvn-architecture/RevitBatchProcessor/wiki/Revit-Batch-Processor-FAQ). It does not cover the Britton changes.

## Use cases

This tool doesn't _do_ any of these things, but it _allows_ you to do them:

- Open all the Revit files across your Revit projects and run a health-check script against them. Keeping an eye on the health and performance of many Revit files is time-consuming. You could use this to check in on your files regularly and react to problems before they get too gnarly (note that RBP normally works on detached copies, so the results describe a snapshot of the central model).
- Perform project and family audits across your Revit projects.
- Run large scale queries against many Revit files.
- Extract data from your Revit projects for analytics.
- Automated housekeeping tasks (e.g. place elements on appropriate worksets)
- Batch upgrading of Revit projects and family files.
- Testing your own Revit API scripts and Revit addins against a variety of Revit models and families in an automated manner.
- Most things you can do to one Revit file with the Revit API or a Dynamo script, you can now do to many (read [Unlimited Power](#unlimited-power) before modifying workshared files).

![Screenshot of the UI](BatchRvt_Screenshot.png)

## Features

- Batch processing of Revit files (.rvt and .rfa files) using either a specific version of Revit or a version that matches the version of Revit the file was saved in. Currently supports processing files in Revit versions 2015 through 2027. (Of course the required version of Revit must be installed!)
- Custom task scripts written in Python or Dynamo! Python scripts have full access to the Revit API. Dynamo scripts can of course do whatever Dynamo can do :)
- Option to create a new Python task script at the click of a button that contains the minimal amount of code required for the custom task script to operate on an opened Revit file. The new task script can then easily be extended to do some useful work. It can even load and execute your existing functions in a C# DLL (see [Executing functions in a C# DLL](#executing-functions-in-a-c-dll)).
- Option for custom pre- and post-processing task scripts. Useful if the overall batch processing task requires some additional setup / tear down work to be done.
- Central file processing options (Create a new local file, Detach from central).
- Option to process files (of the same Revit version) in the same Revit session, or to process each file in its own Revit session. The latter is useful if Revit happens to crash during processing, since this won't block further processing.
- Automatic Revit dialog / message box handling. These, in addition to Revit error messages are handled and logged to the GUI console. This makes the batch processor very likely to complete its tasks without any user intervention required!
- Ability to import and export settings. This feature combined with the simple [command-line interface](#command-line-interface) allows for batch processing tasks to be setup to run automatically on a schedule (using the Windows Task Scheduler) without the GUI.
- Generate a .txt-based list of Revit model file paths compatible with RBP. The *New List* button in the GUI will prompt for a folder path to scan for Revit files. Optionally you can specify the type of Revit files to scan for and also whether to include subfolders in the scan.

## Unlimited Power

> "With great power comes great responsibility"
>
> [-- Spiderman](https://quoteinvestigator.com/2015/07/23/great-power/)

This tool enables you to do things with Revit files on a very large scale. Because of this ability, Python or Dynamo scripts that make modifications to Revit files (esp. workshared files) should be developed with the utmost care! You will need to be confident in your ability to write Python or Dynamo scripts that won't ruin your files en-masse. The Revit Batch Processor's 'Detach from Central' option should be used both while testing and for scripts that do not explicitly depend on working with a live workshared Central file.

### Data safety

- Test on disposable copies of your models, never on production files.
- 'Detach from Central' only applies to workshared files. Non-workshared .rvt files and families (.rfa) are opened directly, so a task script that saves the document modifies the original. A detached document that is saved becomes a new central model.
- 'Create New Local' is the only mode that does not detach. The local file is created under `C:\REVIT_LOCAL<year>` and any file already present at that path is deleted first.
- In this edition, a path containing a `TMP` folder is re-saved over itself before the task runs (BRT-03). See [docs/britton-customizations.md](docs/britton-customizations.md).

# Build & Installation Instructions

## Development with coding agents

See the [shared agent development guide](docs/agent-development.md) (in French) for repository
architecture, build constraints and validation guidance. Entry points are provided
in `AGENTS.md`, `CLAUDE.md` and `.github/copilot-instructions.md`.

## Installer

[Installer for Revit Batch Processor v1.13.0-brt.1](https://github.com/omanningham/RevitBatchProcessor/releases/download/v1.13.0-brt.1/RevitBatchProcessorSetup_v1.13.0-brt.1.exe)

The Revit Batch Processor (GUI) application will appear in the Start menu after the installation. It installs in the user profile, without administrator rights. For a winget installation, see [docs/winget.md](docs/winget.md).

## Build from Source code

Open the solution file RevitBatchProcessor.sln in Visual Studio and run Build Solution. The Revit 2025-2027 addins target `net10.0-windows`, which requires Visual Studio 18.0 (2026) or later with the .NET 10 SDK; older versions only need Visual Studio 2017 or later. Building replaces the addin files already installed under `%APPDATA%`: read the build section of [docs/agent-development.md](docs/agent-development.md) first.

Revit addins will be automatically deployed to the Addins folder for each available Revit version [2015-2027]. e.g. %APPDATA%\Autodesk\Revit\Addins\2019

The BatchRvtGUI project is the GUI that drives the underlying engine (the BatchRvt project). Once built, run BatchRvtGUI.exe to start the Revit Batch Processor GUI.

When rebuilding, please make sure all Revit applications are closed before attempting the rebuild.

# Requirements

- At least one version of Revit installed. Currently supports Revit versions 2015 through 2027.
- To build the whole solution from source code, Visual Studio 2026 (version 18.0 or later, required to target `net10.0`) with the .NET 10 SDK. Visual Studio 2017 or later is enough only for the projects that do not target .NET 10. See [Microsoft Learn](https://learn.microsoft.com/dotnet/core/porting/versioning-sdk-msbuild-vs#targeting-and-support-rules).
- If executing Dynamo scripts from the task script, Dynamo 1.3+ installed (currently supports Revit versions 2016 through 2027). NOTE: RBP runs a temporary copy of the Dynamo script with the 'Automatic' Run mode, so the script's folder must be writable. Dynamo support for Revit 2025-2027 has not been qualified in this edition (see [docs/net10-pilot.md](docs/net10-pilot.md)). There **MUST BE EXACTLY ONE VERSION OF DYNAMO INSTALLED** for each version of Revit.
- If using an Excel file for the Revit File List, Microsoft Office / Excel installed.

# License

This project is licensed under the terms of [The GNU General Public License v3.0](https://www.gnu.org/licenses/gpl.html)

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

# Credits

Daniel Rumery [@DanRumery](https://github.com/DanRumery) (Original / Primary Author)

## Other Contributors (code)

- Vincent Cadoret [@vinnividivicci](https://github.com/vinnividivicci)
- Ryan Schwartz [@RyanSchw](https://github.com/RyanSchw)
- Dimitar Venkov [@dimven](https://github.com/dimven) (Upgraded support for Revit 2025)
- Nicklas Ostergaard [@NicklasOestergaard](https://github.com/NicklasOestergaard) (Upgraded support for Revit 2022)
- Peter Smith [@punderscoresmithuk](https://github.com/punderscoresmithuk) (Upgraded support for Revit 2023)
- Maciej Wypych [@maciejwypych](https://github.com/maciejwypych) (Upgraded support for Revit 2024 and more)
- Rob Mintzes [@rgdt-bert](https://github.com/rgdt-bert) (Upgraded support for Revit 2027)

The Britton edition changes are maintained by La Cie Électrique Britton Ltée.

# Usage

The ***two ingredients*** you will need in order to use the Revit Batch Processor ("RBP") are:
- An **Excel (.xlsx / .xls) file**, **CSV (.csv) file** or **Text (.txt) file** that contains a list of Revit file paths. Each file path must be fully qualified (no partial paths).

  For an Excel file this means the first column of each row contains a file path.

  For a Text file this means each line contains a file path.

  For example:
  ```
  P:\15\ProjectABC\MainModel.rvt
  P:\16\ProjectXYZ\ModelA.rvt
  P:\16\ProjectXYZ\ModelB.rvt
  P:\16\ProjectXYZ\ConsultantModel.rvt
  ```

  NOTE: you can generate this list in .txt format using the *New List* button in the GUI. It will prompt you for a folder to scan for Revit files. Optionally you can specify the type of Revit files to scan for and also whether to include subfolders in the scan.

  *New in version 1.6+*

  There is limited support for processing files in BIM360. For BIM360-hosted files, use the following format instead:

  `<Revit version> <Project Guid> <Model Guid>`

  *Note: these three components must be separated by space(s) (not tabs!).*

  For example:
  ```
  2020 75b6464c-ba0f-4529-b049-0de9e473c2d6 0d54b8cc-3837-4df2-8c8e-0a94f4828868
  2020 c0dc2fda-fd34-42fe-8bb7-bd9f43841dbf d9f011d6-d52c-4c9f-9d7b-eb8388bd3ed0
  ```

  RBP is not able to detect the Revit version of cloud models hence why the Revit version is specified explicitly.

- A **Dynamo (.dyn)** or **Python (.py)** task script. This script will be executed once for each file in the list.

  For Dynamo scripts, **any workspace (.dyn) file should work** as a task script without modification. *(Indeed, if you find a script that works in Dynamo but not in RBP, [submit an Issue](https://github.com/omanningham/RevitBatchProcessor/issues/new/choose) to this repository!)*

  For Python scripts (\*.py) they should contain at minimum the following code:
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

# Executing functions in a C# DLL

Using a python task script it's quite easy to load and execute code in a C# DLL. When RBP runs the python task script, it adds the task script's folder path to the search paths so that if your DLL is in the same folder as your python task script you should be able to execute your functions as follows:

```python
# For example assume your DLL is called MyUtilities.dll and you have a static function called SomeClass.DoSomeWork() in namespace MyNameSpace:
# Assume this python script exists in the same folder as MyUtilities.dll.
clr.AddReference("MyUtilities")
from MyNameSpace import SomeClass

# Invoke your static function, passing in any parameters you need.
SomeClass.DoSomeWork(doc)
```

# Command-line Interface

Revit Batch Processor can be run from the command-line (bypassing the GUI). First configure and export the required processing settings from the GUI application. Once this is done you can simply run the command line utility **BatchRvt.exe** passing the exported settings file path as an argument:

```
%LOCALAPPDATA%\RevitBatchProcessor\BatchRvt.exe --settings_file "BatchRvt.Settings.json"
```

Optionally you can also specify the location for the log file:

```
%LOCALAPPDATA%\RevitBatchProcessor\BatchRvt.exe --log_folder "C:\MyBatchTasks\Logs" --settings_file "C:\MyBatchTasks\BatchRvt.Settings.json"
```

Alternatively, RBP can be run in batch processing mode without a settings file, using some basic arguments:

```
%LOCALAPPDATA%\RevitBatchProcessor\BatchRvt.exe --task_script MyDynamoWorkspace.dyn --file_list RevitFileList.xlsx --revit_version 2018
```

Two options are not listed in the help text below: `--per_file_timeout` (see `--help` on your build) and `--worksets last_viewed`.

NOTE: this mode will operate in Detach mode when processing Central files. The **--revit_version** argument is optional here---if it is omitted then RBP will use the version of Revit that each Revit file was saved in.

To see help on all available command-line options use `--help`:

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

# Contribute

Feedback and suggestions for improvement are more than welcome! Please report bugs in this edition via this repository's Github Issues page. If you're feeling particularly adventurous you may even submit your own code via a Github pull request.

<https://github.com/omanningham/RevitBatchProcessor>

This repository is a fork of the original project, <https://github.com/bvn-architecture/RevitBatchProcessor>. A fix unrelated to the Britton changes may also be of interest to the official project.

# Known Limitations / Issues

- There **MUST BE EXACTLY ONE VERSION OF DYNAMO INSTALLED** for each version of Revit. If two or more versions of Dynamo are installed for the same Revit version then the Revit Batch Processor fails to run the Dynamo task script because the required Dynamo Revit module is not loaded. This may be fixed in a future version.
- Dynamo scripts will always be executed using the 'Use separate Revit session for each Revit file' option. This restriction is due to the context in which Revit Batch Processor operates with the Revit API, which prevents the active UI document from being closed or switched during the Revit session. (NOTE: When executing a Dynamo task script, the Revit Batch Processor opens the document in the UI and is therefore subject to this Revit API limitation. For Python task scripts, the Revit Batch Processor only opens the document in memory, so Python scripts do not suffer this restriction!)
- Revit Batch Processor currently only recognizes and automatically handles Revit dialog boxes presented in English (dialog title, text and button text). If you're using a non-English version of Windows or Revit then it's very likely RBP will fail to handle any dialog boxes that appear during processing. (This edition adds a few French button labels — Fermer / Oui / Non — see [docs/britton-customizations.md](docs/britton-customizations.md); coverage is partial.)
- Revit Batch Processor requires write access to the folder containing the Dynamo script. This because it makes a temporary copy of the Dynamo script in the same folder as the original. The temporary copy is made so that the script's Run mode can be temporarily set to 'Automatic' (if it isn't already). It is created in the same folder as the original so that any relative paths in the script will remain valid.
