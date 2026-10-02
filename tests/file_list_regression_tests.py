# Revit Batch Processor -- GPL-3.0-or-later.
import unittest
import tempfile
import os
import types
import System
from System.IO import File
import batch_rvt_config
import runtime_preflight
import revit_file_list
from batch_rvt_util import BatchRvt

# Load the real routing function without Main() or Framework-only supervisor imports.
monitor_path = os.path.join(os.path.dirname(batch_rvt_config.__file__), 'batch_rvt_monitor.py')
monitor_source = File.ReadAllText(monitor_path).replace('\r\n', '\n')
monitor_start = monitor_source.index('def RunBatchRevitTasks(')
monitor_end = monitor_source.index('\ndef TryGetCommandSettingsData()', monitor_start)
batch_rvt_monitor = types.ModuleType('batch_rvt_monitor_under_test')
batch_rvt_monitor.batch_rvt_monitor_util = types.ModuleType('batch_rvt_monitor_util_under_test')
batch_rvt_monitor.batch_rvt_monitor_util.ShowSupportedRevitFileInfo = lambda info: ''
exec(compile(monitor_source[monitor_start:monitor_end], monitor_path, 'exec'), vars(batch_rvt_monitor))


class FileListTests(unittest.TestCase):
    def setUp(self):
        self.folder = tempfile.mkdtemp(prefix='RBP-list-tests-')
        self.config = batch_rvt_config.BatchRvtConfig()
        self.config.RevitProcessingOption = BatchRvt.RevitProcessingOption.BatchRevitFileProcessing
        self.config.RevitFileListFilePath = os.path.join(self.folder, 'list.csv')

    def tearDown(self):
        for name in os.listdir(self.folder):
            os.remove(os.path.join(self.folder, name))
        os.rmdir(self.folder)

    def write(self, text):
        File.WriteAllText(self.config.RevitFileListFilePath, text, System.Text.Encoding.UTF8)

    def read(self):
        return self.config.ReadRevitFileListData(lambda *args: None)

    def test_repeated_file_read_keeps_all_columns(self):
        for extension, separator in [('.csv', ','), ('.txt', '\t')]:
            self.config.RevitFileListFilePath = os.path.join(self.folder, 'list' + extension)
            self.write(separator.join(['first.rvt', 'metadata', 'second-column']))
            first, second = self.read(), self.read()
            self.assertEqual(['metadata', 'second-column'], list(first[0].AssociatedData))
            self.assertEqual(['metadata', 'second-column'], list(second[0].AssociatedData))

    def test_rewritten_file_is_read_again(self):
        self.write('first.rvt,old')
        self.read()
        self.write('second.rvt,new')
        second = self.read()
        self.assertEqual('second.rvt', second[0].RevitFilePath)
        self.assertEqual(['new'], list(second[0].AssociatedData))

    def test_explicit_memory_list_remains_authoritative(self):
        self.write('file.rvt,file-data')
        self.config.RevitFileList = ['memory.rvt\tmemory-data']
        first = self.read()
        self.write('other-file.rvt,changed')
        second = self.read()
        self.assertEqual('memory.rvt', first[0].RevitFilePath)
        self.assertEqual('memory.rvt', second[0].RevitFilePath)
        self.assertEqual(['memory-data'], list(second[0].AssociatedData))

    def test_excel_dispatch_rereads_rows_without_excel_installation(self):
        self.config.RevitFileListFilePath = os.path.join(self.folder, 'list.xlsx')
        self.write('reader fixture only')
        rows = [revit_file_list.RevitFilePathData('first.rvt', ['metadata'])]
        old_installed, old_reader = revit_file_list.IsExcelInstalled, revit_file_list.FromExcelFile
        revit_file_list.IsExcelInstalled = lambda: True
        revit_file_list.FromExcelFile = lambda path: list(rows)
        try:
            first = self.read()
            rows[:] = [revit_file_list.RevitFilePathData('second.rvt', ['changed'])]
            second = self.read()
            self.assertEqual(['metadata'], list(first[0].AssociatedData))
            self.assertEqual('second.rvt', second[0].RevitFilePath)
            self.assertEqual(['changed'], list(second[0].AssociatedData))
        finally:
            revit_file_list.IsExcelInstalled, revit_file_list.FromExcelFile = old_installed, old_reader

    def test_monitor_rejects_mixed_rewritten_list_before_launch(self):
        # Real monitor/config orchestration; replace model inspection and launch only.
        self.write('legacy.rvt,keep')
        self.config.ExecutePreProcessingScript = True
        saved = {}
        launched = []
        checked = []
        def replace(name, value):
            saved[name] = getattr(batch_rvt_monitor, name, None)
            setattr(batch_rvt_monitor, name, value)
        def read(config):
            return config.ReadRevitFileListData(lambda *args: None)
        def preprocess(config, output):
            self.write('legacy.rvt,keep\nmodern.rvt,new')
            return False
        def validate(years):
            checked.append(list(years))
            try:
                runtime_preflight.ValidateRevitVersions(years, lambda year: self.fail('Mixed batch read runtime'))
                return True
            except ValueError:
                return False
        replace('GetSupportedRevitFiles', read)
        replace('GetRevitVersionForRevitFileSession', lambda config, info: 2025 if info.RevitFilePath == 'modern.rvt' else 2024)
        replace('ExecutePreProcessingScript', preprocess)
        replace('ValidateSessionVersions', validate)
        replace('ProcessRevitFiles', lambda config, files: launched.append(files))
        replace('Output', lambda *args: None)
        old_show = batch_rvt_monitor.batch_rvt_monitor_util.ShowSupportedRevitFileInfo
        batch_rvt_monitor.batch_rvt_monitor_util.ShowSupportedRevitFileInfo = lambda info: ''
        try:
            self.assertTrue(batch_rvt_monitor.RunBatchRevitTasks(self.config))
            self.assertEqual([[2024], [2024, 2025]], checked)
            self.assertEqual([], launched)
        finally:
            for name, value in saved.items():
                if value is None:
                    delattr(batch_rvt_monitor, name)
                else:
                    setattr(batch_rvt_monitor, name, value)
            batch_rvt_monitor.batch_rvt_monitor_util.ShowSupportedRevitFileInfo = old_show
