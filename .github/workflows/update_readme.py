import os
import re


def update_line(line, tag_without_v, version):
    """Replace version numbers in a single README line."""
    line = re.sub(r"\d+\.\d+\.\d+-beta", tag_without_v, line)
    return re.sub(r"\d+\.\d+\.\d+", version, line)


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
    version = os.getenv("VERSION_NUM")

    os.chdir(root_dir)

    # Read the README.md file
    with open("README.md", "r", encoding="utf-8", newline="") as file:
        lines = file.readlines()

    updated = 0
    for i, line in enumerate(lines):
        if "/releases" in line:
            new_line = update_line(line, tag_without_v, version)
            if new_line != line:
                lines[i] = new_line
                updated += 1

    # Write the updated README.md file
    with open("README.md", "w", encoding="utf-8", newline="") as file:
        file.writelines(lines)

    print(f"Updated {updated} README.md line(s) with version {version}")


if __name__ == "__main__":
    update_readme()
