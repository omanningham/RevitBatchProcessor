import unittest
from runtime_preflight import ValidateRevitVersions


def net10(year):
    return {"runtimeOptions": {"tfm": "net10.0", "frameworks": [
        {"name": "Microsoft.NETCore.App", "version": "10.0.0"},
        {"name": "Microsoft.WindowsDesktop.App", "version": "10.0.0"}]}}


class PreflightTests(unittest.TestCase):
    def test_legacy_does_not_read_config(self):
        ValidateRevitVersions([2015, 2024], lambda year: self.fail("Legacy config read"))

    def test_modern_family(self):
        ValidateRevitVersions([2025, 2026, 2027], net10)

    def test_mixed_rejected_before_config_read(self):
        with self.assertRaises(ValueError):
            ValidateRevitVersions([2024, 2025], lambda year: self.fail("Config read before mixed check"))

    def test_net8_rejected(self):
        with self.assertRaises(ValueError):
            ValidateRevitVersions([2025], lambda year: {"runtimeOptions": {"tfm": "net8.0"}})

    def test_unknown_runtime_rejected(self):
        for config in [{}, None, {"runtimeOptions": {"tfm": "net10.0", "frameworks": []}}]:
            with self.assertRaises(ValueError):
                ValidateRevitVersions([2026], lambda year: config)

    def test_unreadable_runtime_rejected(self):
        def read(year):
            raise IOError("missing")
        with self.assertRaises(ValueError):
            ValidateRevitVersions([2027], read)

    def test_each_runtime_checked_once(self):
        seen = []
        def read(year):
            seen.append(year)
            return net10(year)
        ValidateRevitVersions([2025, 2025, 2026], read)
        self.assertEqual([2025, 2026], seen)


if __name__ == "__main__":
    unittest.main()
