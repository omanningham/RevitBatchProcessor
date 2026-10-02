# Revit Batch Processor -- GPL-3.0-or-later.
"""Repository consistency checks run by CI (CPython 3, no third-party packages).

Checks:
  scripts  every active BatchRvtUtil/Scripts/*.py is listed in BatchRvtUtil.csproj,
           and every listed Scripts\\*.py exists.
  links    relative Markdown links (and their #anchors) resolve.
  headers  .cs/.py files added since --base carry a GPL license header.

Usage: python .github/scripts/check_repo.py [--base <git-ref>]
"""
import argparse
import os
import re
import subprocess
import sys
from urllib.parse import unquote

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ARCHIVE_DIR = "BatchRvtUtil/Scripts/Britton modified/"
CSPROJ = "BatchRvtUtil/BatchRvtUtil.csproj"


def git(*args):
    out = subprocess.run(["git", *args], cwd=ROOT, check=True,
                         capture_output=True, text=True, encoding="utf-8")
    return [line for line in out.stdout.splitlines() if line]


def read(path):
    with open(os.path.join(ROOT, path), encoding="utf-8-sig") as f:
        return f.read()


def check_scripts():
    errors = []
    tracked = [p for p in git("ls-files", "--", "BatchRvtUtil/Scripts/*.py")
               if not p.startswith(ARCHIVE_DIR) and p.count("/") == 2]
    listed = set(re.findall(r'Include="(Scripts\\[^"\\]+\.py)"', read(CSPROJ)))
    for path in tracked:
        entry = "Scripts\\" + path.rsplit("/", 1)[1]
        if entry not in listed:
            errors.append("%s: not listed in %s (Content/Compile entry %s)" % (path, CSPROJ, entry))
    for entry in sorted(listed):
        if not os.path.isfile(os.path.join(ROOT, "BatchRvtUtil", entry.replace("\\", "/"))):
            errors.append("%s lists %s, which does not exist" % (CSPROJ, entry))
    return errors


LINK = re.compile(r"(?<!!)\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
HEADING = re.compile(r"^#{1,6}\s+(.*?)\s*#*\s*$")
FENCE = re.compile(r"^\s*(```|~~~)")


def slug(text):
    # GitHub heading anchors: link text only, lowercase, drop punctuation,
    # spaces to hyphens.
    text = re.sub(r"!?\[([^\]]*)\]\([^)]*\)", r"\1", text)
    text = re.sub(r"`|\*\*|__", "", text).strip().lower()
    text = re.sub(r"[^\w\- ]", "", text)
    return text.replace(" ", "-")


def anchors(path, cache={}):
    if path not in cache:
        seen, result, in_fence = {}, set(), False
        for line in read(path).splitlines():
            if FENCE.match(line):
                in_fence = not in_fence
                continue
            m = None if in_fence else HEADING.match(line)
            if m:
                base = slug(m.group(1))
                n = seen.get(base, 0)
                seen[base] = n + 1
                result.add(base if n == 0 else "%s-%d" % (base, n))
        cache[path] = result
    return cache[path]


def check_links():
    errors = []
    for md in git("ls-files", "--", "*.md"):
        in_fence = False
        for lineno, line in enumerate(read(md).splitlines(), 1):
            if FENCE.match(line):
                in_fence = not in_fence
            if in_fence:
                continue
            for target in LINK.findall(line):
                if re.match(r"^[a-z][a-z0-9+.-]*:", target, re.I):
                    continue  # http:, https:, mailto:, ...
                file_part, _, anchor = target.partition("#")
                file_part, anchor = unquote(file_part), unquote(anchor)
                resolved = md if not file_part else os.path.normpath(
                    os.path.join(os.path.dirname(md), file_part)).replace("\\", "/")
                if not os.path.exists(os.path.join(ROOT, resolved)):
                    errors.append("%s:%d: broken link %s" % (md, lineno, target))
                elif anchor and resolved.endswith(".md") and anchor.lower() not in anchors(resolved):
                    errors.append("%s:%d: missing anchor #%s in %s" % (md, lineno, anchor, resolved))
    return errors


def check_headers(base):
    if not base:
        return []
    errors = []
    added = git("diff", "--name-only", "--diff-filter=A", base + "...HEAD", "--", "*.cs", "*.py")
    for path in added:
        if path.startswith(("References/", ARCHIVE_DIR)) or path.endswith((".Designer.cs", "AssemblyInfo.cs")):
            continue
        head = "\n".join(read(path).splitlines()[:30])
        if "GPL" not in head and "GNU General Public License" not in head:
            errors.append("%s: new file without GPL license header" % path)
    return errors


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", help="git ref the branch is compared to for new-file checks")
    args = parser.parse_args()
    failed = False
    for name, errors in (("scripts", check_scripts()), ("links", check_links()),
                         ("headers", check_headers(args.base))):
        for error in errors:
            print("::error::[%s] %s" % (name, error))
        print("%s: %s" % (name, "FAIL (%d)" % len(errors) if errors else "OK"))
        failed = failed or bool(errors)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
