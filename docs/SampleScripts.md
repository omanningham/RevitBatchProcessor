# Sample Scripts

The RevitBatchProcessor takes a task script (Python or Dynamo) and, optionally, a Python pre-processing script and a Python post-processing script. These scripts are written in IronPython (a .NET variant of Python). A Dynamo (.dyn) workspace can also be used directly as the task script.

## Task scripts

Some simple Task scripts to demonstrate how they work:

'Hello World' task script:

```python
'''Output "Hello Revit world!" to the log.'''

# This section is common to all of these scripts.
import clr
import System

clr.AddReference("RevitAPI")
clr.AddReference("RevitAPIUI")
from Autodesk.Revit.DB import *

import revit_script_util
from revit_script_util import Output

sessionId = revit_script_util.GetSessionId()
uiapp = revit_script_util.GetUIApplication()

# NOTE: these only make sense for batch Revit file processing mode.
doc = revit_script_util.GetScriptDocument()
revitFilePath = revit_script_util.GetRevitFilePath()

# The code above is boilerplate, everything below is yours!

Output()
Output("Hello Revit world!")
```

## Dynamo scripts

Select the Dynamo (.dyn) file directly as the task script in the UI (or with `--task_script` on the command line). No Python wrapper is needed: RBP opens each Revit file in the UI, runs the workspace and closes the file.

- Dynamo task scripts always run with the "Use separate Revit session for each Revit file" option.
- RBP works on a temporary copy of the .dyn (with the Run mode forced to 'Automatic'), so the folder containing the .dyn must be writable.
- Do not call `UIApplication.OpenAndActivateDocument(doc.PathName)` from a Python task script to drive Dynamo yourself: `PathName` is empty for a detached document, and the activated document can no longer be closed by RBP at the end of processing.

## Pre-processing scripts

A pre-processing script runs once, before the first Revit file is processed. It has no Revit document (use the `script_util` module, not `revit_script_util`). Minimal example (same as the template created by the UI):

```python
'''Output a message before the batch starts.'''

import clr
import System
clr.AddReference("System.Core")
clr.ImportExtensions(System.Linq)

import script_util
from script_util import Output

sessionId = script_util.GetSessionId()

# NOTE: this only makes sense for batch Revit file processing mode.
revitFileListFilePath = script_util.GetRevitFileListFilePath()

# NOTE: these only make sense for data export mode.
sessionDataFolderPath = script_util.GetSessionDataFolderPath()
dataExportFolderPath = script_util.GetExportFolderPath()

# The code above is boilerplate, everything below is yours!
Output()
Output("This pre-processing script is running!")
```

## Post-processing scripts

A post-processing script runs once, after the last Revit file has been processed. It is useful for tear-down work such as merging the data exported by the task script. Minimal example (same as the template created by the UI):

```python
'''Output a message after the batch has finished.'''

import clr
import System
clr.AddReference("System.Core")
clr.ImportExtensions(System.Linq)

import script_util
from script_util import Output

sessionId = script_util.GetSessionId()

# NOTE: this only makes sense for batch Revit file processing mode.
revitFileListFilePath = script_util.GetRevitFileListFilePath()

# NOTE: these only make sense for data export mode.
sessionDataFolderPath = script_util.GetSessionDataFolderPath()
dataExportFolderPath = script_util.GetExportFolderPath()

# The code above is boilerplate, everything below is yours!
Output()
Output("This post-processing script is running!")
```

