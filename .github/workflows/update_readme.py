import os
import re


# A trailing " beta" label is dropped too: Britton releases are not beta.
VERSION_PATTERN = re.compile(r"\d+\.\d+\.\d+(?:\.\d+)?(?:-beta|-brt\.\d+)?(?: beta\b)?")


def update_line(line, tag_without_v):
    """Replace version numbers in a single README line with the tag form
    (e.g. 1.13.0-brt.1), used both by release links and labels."""
    return VERSION_PATTERN.sub(tag_without_v, line)


def update_readme():
    """
    Function to update the README.md file with the latest version number.

    Only lines that link to a release ("/releases") are updated, so other
    version numbers in the README (IronPython, .NET, ...) are preserved.
    """
    # Get the current version number
    root_dir = os.getenv("GITHUB_WORKSPACE")
    tag_val = os.getenv("TAG_VALUE")
    tag_without_v = tag_val[1:] if tag_val.lower().startswith("v") else tag_val

    os.chdir(root_dir)

    # Read the README.md file
    with open("README.md", "r", encoding="utf-8", newline="") as file:
        lines = file.readlines()

    updated = 0
    for i, line in enumerate(lines):
        if "/releases" in line:
            new_line = update_line(line, tag_without_v)
            if new_line != line:
                lines[i] = new_line
                updated += 1

    # Write the updated README.md file
    with open("README.md", "w", encoding="utf-8", newline="") as file:
        file.writelines(lines)

    print(f"Updated {updated} README.md line(s) with version {tag_without_v}")


if __name__ == "__main__":
    update_readme()
