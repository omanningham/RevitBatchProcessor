# Sample Scripts

The RevitBatchProcessor takes three types of scripts: a task script and (optionally) a pre-processing and post-processing script. These scripts are written in Iron-Python (a .NET variant of Python). With a small amount of additional code the task script can also execute your Dynamo script!

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

## Dynamo Scripts

Task script to execute a Dynamo script:

A Dynamo (.dyn) file can also be given directly as the task script, without any Python. Use a Python task script like this one only when you need to run extra code around the Dynamo script.

```python
'''Run a Dynamo workspace script on each Revit file.'''

import clr
import System

clr.AddReference("RevitAPI")
clr.AddReference("RevitAPIUI")
from Autodesk.Revit.DB import *

import revit_script_util
from revit_script_util import Output

import revit_dynamo_util

# Change this variable to the path of your Dynamo workspace file.
# (Note that the Dynamo script must have been saved in 'Automatic' mode.)
DYNAMO_SCRIPT_FILE_PATH = r"C:\DynamoScripts\MyDynamoWorkspace.dyn"

sessionId = revit_script_util.GetSessionId()
uiapp = revit_script_util.GetUIApplication()

# NOTE: these only make sense for batch Revit file processing mode.
doc = revit_script_util.GetScriptDocument()
revitFilePath = revit_script_util.GetRevitFilePath()

# Dynamo requires an active UIDocument, not just a loaded Document!
# For a Python task script RBP only opens the document in memory, so we use
# UIApplication.OpenAndActivateDocument() here. (Not needed if the document is
# already the active one.)
Output()
Output("Activating the document for Dynamo script automation.")
uidoc = uiapp.OpenAndActivateDocument(doc.PathName)

Output()
Output("Executing Dynamo script.")
# One line to execute the Dynamo script! Pass showUI=True as a third
# argument to display the Dynamo UI (default is False).
revit_dynamo_util.ExecuteDynamoScript(uiapp, DYNAMO_SCRIPT_FILE_PATH)

Output()
Output("Finished Dynamo script.")
```

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

