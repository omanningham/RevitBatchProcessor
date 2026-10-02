using System.Reflection;
using System.Runtime.Loader;
using System.Runtime.InteropServices;
using System.ComponentModel;

Console.OutputEncoding = new System.Text.UTF8Encoding(false);

// No IronPython reference: the control and candidate run in separate processes
// against the exact DLL directories supplied by the caller.
if (args.Length < 1) throw new ArgumentException("Usage: EngineProbe <engine-folder> [scripts-folder] [host-folder]");
var engineFolder = Path.GetFullPath(args[0]);
AssemblyLoadContext.Default.Resolving += (_, name) => {
    var path = Path.Combine(engineFolder, name.Name + ".dll");
    return File.Exists(path) ? AssemblyLoadContext.Default.LoadFromAssemblyPath(path) : null;
};
Console.WriteLine("Runtime: " + RuntimeInformation.FrameworkDescription);
var ironPython = AssemblyLoadContext.Default.LoadFromAssemblyPath(Path.Combine(engineFolder, "IronPython.dll"));
foreach (var path in Directory.GetFiles(engineFolder, "*.dll").Where(p => Path.GetFileName(p).StartsWith("IronPython") || Path.GetFileName(p).StartsWith("Microsoft.Scripting") || Path.GetFileName(p) == "Microsoft.Dynamic.dll")) {
    var identity = AssemblyName.GetAssemblyName(path);
    Console.WriteLine("Engine file: " + identity.FullName + " | " + path);
    if (ironPython.GetName().Version!.Major == 3) {
        var expected = identity.Name!.StartsWith("IronPython") ? new Version(3, 4, 2, 0) : new Version(1, 3, 5, 0);
        if (identity.Version != expected) throw new InvalidOperationException("Unexpected engine/DLR file: " + identity);
    }
}
var python = ironPython.GetType("IronPython.Hosting.Python", true)!;
dynamic engine = python.GetMethod("CreateEngine", Type.EmptyTypes)!.Invoke(null, null)!;
dynamic scope = engine.CreateScope();
try {
    Console.WriteLine("Language: " + engine.LanguageVersion);
    engine.Execute("class Empty(object):\n    pass\nassert isinstance(Empty(), Empty)\n", scope);
    engine.Execute("import clr\nimport System\nfrom System import IDisposable\nclass Managed(System.Object):\n    pass\nclass Disposable(IDisposable):\n    def Dispose(self):\n        pass\nManaged()\nDisposable().Dispose()\n", scope);
    object instance = engine.Execute("Empty()", scope);
    Console.WriteLine("Descriptors: " + TypeDescriptor.GetProperties(instance).Count);
    var lib = Path.Combine(engineFolder, "lib");
    if (Directory.Exists(lib)) engine.SetSearchPaths(new[] { lib });
    engine.Execute("import encodings, codecs, json, platform, collections, logging, traceback\nassert json.loads(json.dumps({'accent': u'\u00e9'}))['accent'] == u'\u00e9'\n", scope);
    scope.SetVariable("expected_lib", lib);
    engine.Execute("import os\nfor module in [encodings, codecs, json, platform, collections, logging, traceback]:\n    location = getattr(module, '__file__', None)\n    print('StdLib: ' + module.__name__ + ' | ' + str(location))\n    if location is not None:\n        assert os.path.normcase(os.path.abspath(location)).startswith(os.path.normcase(os.path.abspath(expected_lib)) + os.sep), location\n", scope);
    if (args.Length > 2) {
        var hostFolder = Path.GetFullPath(args[2]);
        AssemblyLoadContext.Default.Resolving += (_, name) => {
            var path = Path.Combine(hostFolder, name.Name + ".dll");
            return File.Exists(path) ? AssemblyLoadContext.Default.LoadFromAssemblyPath(path) : null;
        };
        var host = AssemblyLoadContext.Default.LoadFromAssemblyPath(Path.Combine(hostFolder, "BatchRvtScriptHost.dll"));
        var util = host.GetType("BatchRvt.ScriptHost.ScriptUtil", true)!;
        util.GetMethod("ValidateModernRuntime")!.Invoke(null, null);
        object hostedEngine = util.GetMethod("CreatePythonEngine")!.Invoke(null, null)!;
        object hostedScope = util.GetMethod("CreateMainModule")!.Invoke(null, new[] { hostedEngine })!;
        var setup = util.GetMethods().Single(m => m.Name == "AddPythonStandardLibrary" && m.GetParameters().Length == 2);
        setup.Invoke(null, new[] { hostedScope, lib });
        dynamic hosted = hostedEngine;
        hosted.Execute("import encodings, json, platform\nclass Hosted(object):\n    pass\nHosted()\n", (dynamic)hostedScope);
        if (File.Exists(Path.Combine(hostFolder, "BatchRvtUtil.dll"))) {
            var rbpUtil = AssemblyLoadContext.Default.LoadFromAssemblyPath(Path.Combine(hostFolder, "BatchRvtUtil.dll"));
            util.GetMethod("AddSearchPaths")!.Invoke(null, new object[] { hostedEngine, new[] { Path.GetFullPath(args[1]), hostFolder } });
            hosted.Execute("import batch_rvt_util, script_util, json_util, script_environment\nfrom BatchRvtUtil import JsonUtil\nassert JsonUtil.DeserializeFromJson('{\"value\":1}') is not None\n", (dynamic)hostedScope);
            Console.WriteLine("PASS: actual shared util, script imports and JSON");
            var testsFolder = Path.GetFullPath(Path.Combine(args[1], "..", "..", "tests"));
            util.GetMethod("AddSearchPaths")!.Invoke(null, new object[] { hostedEngine, new[] { testsFolder } });
            hosted.Execute("import unittest, runtime_preflight_tests, script_compatibility_tests, file_list_regression_tests\nsuite = unittest.TestSuite([unittest.defaultTestLoader.loadTestsFromModule(m) for m in [runtime_preflight_tests, script_compatibility_tests, file_list_regression_tests]])\nresult = unittest.TextTestRunner().run(suite)\nassert result.wasSuccessful()\n", (dynamic)hostedScope);
        }
        try {
            setup.Invoke(null, new[] { hostedScope, Path.Combine(hostFolder, "missing-stdlib") });
            throw new Exception("Missing stdlib was accepted");
        } catch (TargetInvocationException e) when (e.InnerException is DirectoryNotFoundException) { }
        Console.WriteLine("PASS: actual shared host and missing-stdlib rejection");
        // Exercise the real host entry point with a minimal script, without Revit API.
        var fixtureFolder = Path.Combine(Path.GetTempPath(), "RBP-probe-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(fixtureFolder);
        var fixturePath = Path.Combine(fixtureFolder, "revit_script_host.py");
        File.WriteAllText(fixturePath, "import sys, json\nassert sys.version_info[0] == 3\nassert __revit__ == 42\nclass HostEntry(object):\n    pass\nHostEntry()\n");
        const string scriptsVariable = "BATCHRVT__SCRIPTS_FOLDER_PATH";
        var previousScripts = Environment.GetEnvironmentVariable(scriptsVariable);
        try {
            Environment.SetEnvironmentVariable(scriptsVariable, fixtureFolder);
            var entry = host.GetType("BatchRvt.ScriptHost.ScriptHostUtil", true)!;
            entry.GetMethods().Single(m => m.Name == "ExecuteBatchScriptHost" && m.GetParameters().Length == 3)
                .Invoke(null, new object[] { hostFolder, 42, "isolated fixture (no Revit)" });
            Console.WriteLine("PASS: ExecuteBatchScriptHost entry, __revit__, main module and script execution");
        } finally {
            Environment.SetEnvironmentVariable(scriptsVariable, previousScripts);
            File.Delete(fixturePath);
            Directory.Delete(fixtureFolder); // Nonrecursive, newly allocated fixture only.
        }
    }
    if (args.Length > 1) {
        dynamic kind = Enum.Parse(Assembly.Load("Microsoft.Scripting").GetType("Microsoft.Scripting.SourceCodeKind", true)!, "File");
        foreach (var script in Directory.GetFiles(Path.GetFullPath(args[1]), "*.py")) {
            engine.CreateScriptSourceFromString(File.ReadAllText(script), script, kind).Compile();
            Console.WriteLine("Compiled: " + Path.GetFileName(script));
        }
    }
    Console.WriteLine("PASS: engine, types, descriptors, stdlib and supplied script syntax");
} catch (Exception exception) {
    Console.Error.WriteLine(exception);
    Environment.ExitCode = 1;
} finally {
    foreach (var assembly in AppDomain.CurrentDomain.GetAssemblies().Where(a => a.GetName().Name!.StartsWith("IronPython") || a.GetName().Name!.StartsWith("Microsoft.Scripting") || a.GetName().Name == "Microsoft.Dynamic"))
        Console.WriteLine(assembly.FullName + " | " + assembly.Location);
}
