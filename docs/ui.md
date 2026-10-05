# The UI: What it all means

![Screenshot of the Revit Batch Processor UI](../BatchRvt_Screenshot.png)

The screenshot was taken with *Show Advanced Settings* unchecked. The groups marked **(advanced)** below only appear once that box is checked. Labels are quoted from the UI; CLI options are those listed in the [command-line help](../README.md#command-line-interface).

TODO: swap the screenshot for a labelled version, with the advanced settings shown.

## Top of the window

| Control | What it does |
| --- | --- |
| Revit File List + *Browse ...* | The Excel, CSV or text file listing the Revit files to process (`--file_list`). |
| *New List ...* | Scans a folder for Revit files and writes a .txt list, optionally filtered by file type and including subfolders. |
| *Import Settings ...* / *Export Settings ...* | Load or save every setting as a JSON file, for use with `--settings_file`. |
| *Show Advanced Settings* | Shows the groups marked (advanced). |
| *Always on top* | Keeps the window above other applications. |
| *Start Processing* / *Close* | Start the batch / close the window. A *Progress* console replaces the settings while a batch runs. |

## Task Script

| Control | What it does |
| --- | --- |
| Task Script (\*.py; \*.dyn) + *Browse ...* | The script run once for each file (`--task_script`). A `.dyn` is used directly, without a Python wrapper. |
| *New Script ...* | Creates a Python task script containing the minimal boilerplate. |
| Show Message Box on Task Script Error **(advanced)** | Displays a message box when the task script reports an error. |

## Batch Revit File Processing

| Control | What it does |
| --- | --- |
| Enable Batch Revit File Processing | Runs the task script once per file in the list. Uncheck it to use *Single Revit Task Processing* only. |
| Use file Revit Version (if available) / Use specific Revit Version | Processes each file with the Revit version it was saved in, or forces one version (`--revit_version`). |
| If not available, use minimum available Revit Version | Falls back to the oldest installed Revit version when the required one is missing. |
| Use same Revit session for Revit files of the same Revit Version / Use separate Revit session for each Revit File | One Revit session shared by files of the same version, or a new session per file. Dynamo task scripts always use a separate session. |
| Per-File processing Time-out (in minutes) | Maximum time allowed per file (`--per_file_timeout`). |
| Audit on Opening | Opens each file with the audit option (`--audit`). |

## Central File Processing

| Control | What it does |
| --- | --- |
| Detach from Central | Opens a detached copy of workshared files (`--detach`). Does not apply to non-workshared files or families; see *Data safety* in the [README](../README.md#data-safety). |
| Create New Local | Creates a local file from the central file (`--create_new_local`). Any existing file at the local path is deleted first. |
| Discard Worksets | With *Detach from Central*, detaches and discards the worksets instead of preserving them. |
| Delete Local After | With *Create New Local*, deletes the local file when processing is done. |
| Open All Worksets / Close All Worksets / Open Last Viewed | Workset state on open (`--worksets open_all` or `close_all`; `last_viewed` is accepted too). |

## Data Export (advanced)

| Control | What it does |
| --- | --- |
| Enable Data Export | Gives the scripts a per-session folder for exported data, available through `script_util.GetExportFolderPath()`. |
| Data Export Base Folder + *Browse ...* | The folder under which those export folders are created. |

## Single Revit Task Processing (advanced)

| Control | What it does |
| --- | --- |
| Enable Single Revit Task Processing (Python scripts only) | Runs the task script once in a Revit session, with no Revit file opened (`doc` is `None`). |
| Revit Version | The Revit version used for that session. |

## Pre/Post-Processing (advanced)

| Control | What it does |
| --- | --- |
| Execute Pre-Processing Script (\*.py) | A Python script run before the batch. |
| Execute Post-Processing Script (\*.py) | A Python script run after the batch. |
| *Browse ...* / *New Script ...* | Pick an existing script, or create one from the template. See [SampleScripts.md](SampleScripts.md). |

## Settings that have no control in the UI

Some values exist only in the exported settings JSON, for example `openInUI` and `showRevitProcessErrorMessages`. Edit the exported file to change them.
