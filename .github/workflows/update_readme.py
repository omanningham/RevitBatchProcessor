import os
import re


# Matches any previous version form without depending on the tag grammar (defined in
# .github/scripts/release_metadata.ps1): X.Y.Z or X.Y.Z.N, an optional "-label" or
# "-label.N" suffix (not ".exe"), and a trailing " beta" label, dropped because Britton
# releases are not beta.
VERSION_PATTERN = re.compile(r"\d+\.\d+\.\d+(?:\.\d+)?(?:-[0-9A-Za-z]+(?:\.\d+)?)?(?: beta\b)?")

README_FILES = ("README.md", "README.en.md")


def update_line(line, tag_without_v):
    """Replace version numbers in a single README line with the tag form
    (e.g. 1.13.0-brt.1), used both by release links and labels."""
    return VERSION_PATTERN.sub(tag_without_v, line)


def update_readme():
    """
    Function to update the README files with the latest version number.

    Only lines that link to a release ("/releases") are updated, so other
    version numbers in the README (IronPython, .NET, ...) are preserved.
    """
    # Get the current version number
    root_dir = os.getenv("GITHUB_WORKSPACE")
    tag_val = os.getenv("TAG_VALUE")
    tag_without_v = tag_val[1:] if tag_val.lower().startswith("v") else tag_val

    os.chdir(root_dir)

    # README.md (French) and README.en.md (English); a missing file is skipped.
    for readme in README_FILES:
        if not os.path.exists(readme):
            continue

        with open(readme, "r", encoding="utf-8", newline="") as file:
            lines = file.readlines()

        updated = 0
        for i, line in enumerate(lines):
            if "/releases" in line:
                new_line = update_line(line, tag_without_v)
                if new_line != line:
                    lines[i] = new_line
                    updated += 1

        with open(readme, "w", encoding="utf-8", newline="") as file:
            file.writelines(lines)

        print(f"Updated {updated} {readme} line(s) with version {tag_without_v}")


if __name__ == "__main__":
    update_readme()
