# Revit Batch Processor -- GPL-3.0-or-later.
import unittest
import sys
import tempfile
import os
import System
import std_io_util
import script_util
from BatchRvtUtil import JsonUtil


class Capture(object):
    def __init__(self):
        self.text = u''
    def write(self, text):
        self.text += text
    def flush(self):
        pass
    def close(self):
        pass


class CompatibilityTests(unittest.TestCase):
    def test_redirect_and_restore_both_streams(self):
        stdout, stderr = sys.stdout, sys.stderr
        capture = Capture()
        try:
            std_io_util.RedirectScriptOutput(capture)
            sys.stdout.write(u'\u00e9 stdout\n')
            sys.stderr.write(u'\u00e0 stderr\n')
            std_io_util.RestoreScriptOutput()
            self.assertIs(stdout, sys.stdout)
            self.assertIs(stderr, sys.stderr)
            self.assertEqual(u'\u00e9 stdout\n\u00e0 stderr\n', capture.text)
        finally:
            sys.stdout, sys.stderr = stdout, stderr

    def test_unicode_json_and_dotnet_values(self):
        value = JsonUtil.DeserializeFromJson(u'{"accent":"\u00e9"}')
        self.assertEqual(u'\u00e9', value['accent'].ToString())
        self.assertEqual(42, int(System.Int32(42)))
        self.assertEqual('None', str(getattr(System.IO.FileShare, 'None')))

    def test_task_execution_accented_path_and_exception(self):
        folder = tempfile.mkdtemp(prefix=u'RBP_\u00e9_')
        path = os.path.join(folder, u't\u00e2che.py')
        try:
            System.IO.File.WriteAllText(path, "raise ValueError('RBP task exception')", System.Text.Encoding.UTF8)
            with self.assertRaises(ValueError) as context:
                script_util.ExecuteScript(path)
            self.assertIn('RBP task exception', str(context.exception))
        finally:
            os.remove(path)
            os.rmdir(folder)
