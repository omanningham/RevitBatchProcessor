# Revit Batch Processor -- GPL-3.0-or-later.
# Pure Python policy shared by the Python 2 supervisor and Python 3 probes.

def ValidateRevitVersions(revitYears, readRuntimeConfig):
    years = sorted(set(int(year) for year in revitYears))
    if any(year < 2015 or year > 2027 for year in years):
        raise ValueError("Unsupported Revit version in batch.")
    if any(year < 2025 for year in years) and any(year >= 2025 for year in years):
        raise ValueError("Revit 2015-2024 and 2025-2027 require two separate batches/configurations (Python 2 / Python 3).")
    for year in years:
        if year < 2025:
            continue
        try:
            config = readRuntimeConfig(year)
            options = config["runtimeOptions"]
            frameworks = options["frameworks"]
            versions = dict((item["name"], item["version"]) for item in frameworks)
            valid = (options.get("tfm") == "net10.0" and
                     versions.get("Microsoft.NETCore.App", "").startswith("10.") and
                     versions.get("Microsoft.WindowsDesktop.App", "").startswith("10."))
        except Exception as error:
            raise ValueError("Cannot determine Revit " + str(year) + " runtime: " + str(error))
        if not valid:
            raise ValueError("Revit " + str(year) + " requires the .NET 10 update (2025.5 / 2026.5 or Revit 2027).")
