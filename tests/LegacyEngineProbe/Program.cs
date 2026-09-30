// Revit Batch Processor — GPL-3.0-or-later; see LICENSE.
using System;
using System.IO;
using System.Reflection;
using System.Linq;

class Program
{
    static int Main(string[] args)
    {
        if (args.Length != 3) throw new ArgumentException("Usage: LegacyEngineProbe <host-folder> <scripts-folder> <tests-folder>");
        var folder = Path.GetFullPath(args[0]);
        AppDomain.CurrentDomain.AssemblyResolve += (sender, ev) => {
            var path = Path.Combine(folder, new AssemblyName(ev.Name).Name + ".dll");
            return File.Exists(path) ? Assembly.LoadFrom(path) : null;
        };
        try {
            Console.WriteLine("Framework runtime: " + Environment.Version);
            var host = Assembly.LoadFrom(Path.Combine(folder, "BatchRvtScriptHost.dll"));
            var util = host.GetType("BatchRvt.ScriptHost.ScriptUtil", true);
            dynamic engine = util.GetMethod("CreatePythonEngine").Invoke(null, null);
            dynamic scope = util.GetMethod("CreateMainModule").Invoke(null, new object[] { engine });
            util.GetMethods().Single(m => m.Name == "AddPythonStandardLibrary" && m.GetParameters().Length == 1)
                .Invoke(null, new object[] { scope });
            Console.WriteLine("Language: " + engine.LanguageVersion);
            engine.Execute("class Empty(object):\n    pass\nEmpty()\nimport encodings, codecs, json, platform, collections, logging, traceback\n", scope);
            util.GetMethod("AddSearchPaths").Invoke(null, new object[] { engine, new[] { Path.GetFullPath(args[1]), Path.GetFullPath(args[2]), folder } });
            Assembly.LoadFrom(Path.Combine(folder, "BatchRvtUtil.dll"));
            engine.Execute("import batch_rvt_util, script_util, json_util, script_environment\nimport unittest, runtime_preflight_tests, script_compatibility_tests\nsuite = unittest.TestSuite([unittest.defaultTestLoader.loadTestsFromModule(m) for m in [runtime_preflight_tests, script_compatibility_tests]])\nresult = unittest.TextTestRunner().run(suite)\nassert result.wasSuccessful()\n", scope);
            dynamic kind = Enum.Parse(Assembly.Load("Microsoft.Scripting").GetType("Microsoft.Scripting.SourceCodeKind", true), "File");
            foreach (var path in Directory.GetFiles(args[1], "*.py"))
                engine.CreateScriptSourceFromString(File.ReadAllText(path), path, kind).Compile();
            Console.WriteLine("PASS: Python 2 host, ZIP stdlib, util imports, routing and distributed scripts");
            return 0;
        } catch (Exception e) { Console.Error.WriteLine(e); return 1; }
        finally {
            foreach (var a in AppDomain.CurrentDomain.GetAssemblies().Where(a => !a.IsDynamic && (a.GetName().Name.StartsWith("IronPython") || a.GetName().Name.StartsWith("Microsoft.Scripting") || a.GetName().Name == "Microsoft.Dynamic")))
                Console.WriteLine(a.FullName + " | " + a.Location);
        }
    }
}
