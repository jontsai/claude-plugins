#!/usr/bin/env python3
"""Validate all JSON files in the repository."""

import json
import os
import sys


def main():
    files = []
    for root, dirs, filenames in os.walk("."):
        # Skip .git directory (but not .github)
        if ".git" in root.split(os.sep):
            continue
        for f in filenames:
            if f.endswith(".json"):
                files.append(os.path.join(root, f))

    errors = 0

    for f in files:
        try:
            with open(f, encoding="utf-8") as fp:
                json.load(fp)
        except (OSError, UnicodeDecodeError) as e:
            print(f"  ✗ Cannot read: {f} - {e}")
            errors += 1
        except json.JSONDecodeError as e:
            print(f"  ✗ Invalid JSON: {f} - {e}")
            errors += 1

    if errors:
        print(f"  ✗ {errors} JSON errors found")
        sys.exit(1)
    print("✓ All JSON files are valid")


if __name__ == "__main__":
    main()
