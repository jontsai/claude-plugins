#!/usr/bin/env python3
"""Validate hooks.json format."""

import json
import os
import sys

VALID_EVENTS = [
    "PreToolUse",
    "PostToolUse",
    "SessionStart",
    "Stop",
    "SubagentStop",
    "SessionEnd",
    "UserPromptSubmit",
    "PermissionRequest",
    "PreCompact",
    "Notification",
]


def main():
    errors = []

    for root, dirs, files in os.walk("."):
        # Skip .git directory (but not .github)
        if ".git" in root.split(os.sep):
            continue
        for f in files:
            if f == "hooks.json":
                path = os.path.join(root, f)
                try:
                    with open(path, encoding="utf-8") as fp:
                        data = json.load(fp)
                except (OSError, UnicodeDecodeError, json.JSONDecodeError) as e:
                    errors.append(f"{path}: Failed to load JSON: {e}")
                    continue

                hooks = data.get("hooks", {})
                if isinstance(hooks, list):
                    errors.append(f"{path}: 'hooks' must be an object, not array")
                    continue

                for event in hooks.keys():
                    if event not in VALID_EVENTS:
                        errors.append(f"{path}: Unknown event '{event}'")

    if errors:
        print("Errors found:")
        for e in errors:
            print(f"  ✗ {e}")
        sys.exit(1)
    print("✓ All hooks.json files are valid")


if __name__ == "__main__":
    main()
