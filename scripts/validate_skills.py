#!/usr/bin/env python3
"""Validate SKILL.md frontmatter."""

import os
import re
import sys


def main():
    errors = []

    for root, dirs, files in os.walk("."):
        # Skip .git directory (but not .github)
        if ".git" in root.split(os.sep):
            continue
        for f in files:
            if f == "SKILL.md":
                path = os.path.join(root, f)
                try:
                    with open(path, encoding="utf-8") as fp:
                        content = fp.read()
                except (OSError, UnicodeDecodeError) as e:
                    errors.append(f"{path}: Unable to read file ({e})")
                    continue

                if not content.startswith("---"):
                    errors.append(f"{path}: Missing YAML frontmatter")
                    continue

                match = re.match(r"^---\s*\n(.*?)\n---\s*", content, re.DOTALL)
                if not match:
                    errors.append(f"{path}: Invalid frontmatter format")
                    continue

                frontmatter = match.group(1)
                if "name:" not in frontmatter:
                    errors.append(f"{path}: Missing 'name' in frontmatter")
                if "description:" not in frontmatter:
                    errors.append(f"{path}: Missing 'description' in frontmatter")

    if errors:
        print("Errors found:")
        for e in errors:
            print(f"  ✗ {e}")
        sys.exit(1)
    print("✓ All SKILL.md files have valid frontmatter")


if __name__ == "__main__":
    main()
