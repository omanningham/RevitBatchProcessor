#
# Revit Batch Processor
#
# Copyright (c) 2020  Dan Rumery, BVN
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#

import clr
import System
clr.AddReference("System.Core")
clr.ImportExtensions(System.Linq)
from System import AppDomain
from System.IO import IOException, Path
import os

BATCH_RVT_UTIL_ASSEMBLY_NAME = "BatchRvtUtil"
BATCH_RVT_SCRIPT_HOST_ASSEMBLY_NAME = "BatchRvtScriptHost"

def GetExistingLoadedAssembly(assemblyName):
    return (
            AppDomain.CurrentDomain.GetAssemblies()
            .FirstOrDefault(lambda assembly: assembly.GetName().Name == assemblyName)
        )

def AddBatchRvtUtilAssemblyReference():
    try:
        clr.AddReference(BATCH_RVT_UTIL_ASSEMBLY_NAME)
    except IOException as e: # Can occur if PyRevit is installed. Need to use AddReferenceToFileAndPath() in this case.
        scriptsFolder = os.environ.get("BATCHRVT__SCRIPTS_FOLDER_PATH")
        if not scriptsFolder:
            raise
        assemblyPath = Path.Combine(Path.GetDirectoryName(scriptsFolder.rstrip("\\/")), BATCH_RVT_UTIL_ASSEMBLY_NAME + ".dll")
        clr.AddReferenceToFileAndPath(assemblyPath)
    loaded = list(assembly for assembly in AppDomain.CurrentDomain.GetAssemblies()
                  if assembly.GetName().Name == BATCH_RVT_UTIL_ASSEMBLY_NAME)
    if len(loaded) != 1:
        raise RuntimeError("Ambiguous BatchRvtUtil assemblies: " + str([assembly.Location for assembly in loaded]))
    scriptsFolder = os.environ.get("BATCHRVT__SCRIPTS_FOLDER_PATH")
    if scriptsFolder:
        host = GetExistingLoadedAssembly(BATCH_RVT_SCRIPT_HOST_ASSEMBLY_NAME)
        expectedFolders = [Path.GetDirectoryName(scriptsFolder.rstrip("\\/"))]
        if host is not None:
            expectedFolders.append(Path.GetDirectoryName(host.Location))
        actual = Path.GetFullPath(loaded[0].Location).lower()
        expected = [Path.GetFullPath(Path.Combine(folder, BATCH_RVT_UTIL_ASSEMBLY_NAME + ".dll")).lower() for folder in expectedFolders]
        if actual not in expected:
            raise RuntimeError("Unexpected BatchRvtUtil assembly: " + loaded[0].Location)
    return

AddBatchRvtUtilAssemblyReference()

import BatchRvtUtil
from BatchRvtUtil import *

