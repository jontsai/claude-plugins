#!/usr/bin/env python3
"""Validate marketplace.json structure."""

import json
import os
import sys


def main():
    try:
        with open(".claude-plugin/marketplace.json", encoding="utf-8") as f:
            data = json.load(f)
    except FileNotFoundError:
        print("Error: .claude-plugin/marketplace.json not found.")
        sys.exit(1)
    except PermissionError:
        print("Error: Permission denied when reading .claude-plugin/marketplace.json.")
        sys.exit(1)
    except (OSError, UnicodeDecodeError) as e:
        print(f"Error: Failed to read .claude-plugin/marketplace.json: {e}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in .claude-plugin/marketplace.json: {e}")
        sys.exit(1)

    errors = []

    # Required top-level fields
    for field in ["name", "owner", "plugins"]:
        if field not in data:
            errors.append(f"Missing required field: {field}")

    # Validate plugins
    for plugin in data.get("plugins", []):
        name = plugin.get("name", "<unnamed>")
        if "name" not in plugin:
            errors.append("Plugin missing required field: name")
        if "source" not in plugin:
            errors.append(f"Plugin '{name}' missing required field: source")

        # Check plugin.json exists
        source = plugin.get("source", "")
        plugin_json = os.path.join(source, ".claude-plugin", "plugin.json")
        if not os.path.exists(plugin_json):
            errors.append(f"Plugin '{name}': missing {plugin_json}")

        # Check skills have SKILL.md
        skills_dir = os.path.join(source, "skills")
        if os.path.exists(skills_dir):
            try:
                skill_entries = os.listdir(skills_dir)
            except OSError as e:
                errors.append(f"Plugin '{name}': cannot list skills directory: {e}")
                continue

            for skill_name in skill_entries:
                skill_path = os.path.join(skills_dir, skill_name)
                if os.path.isdir(skill_path):
                    skill_md = os.path.join(skill_path, "SKILL.md")
                    if not os.path.exists(skill_md):
                        errors.append(
                            f"Plugin '{name}': skill '{skill_name}' missing SKILL.md"
                        )

    if errors:
        print("Errors found:")
        for e in errors:
            print(f"  ✗ {e}")
        sys.exit(1)
    print("✓ marketplace.json and plugin structure valid")


if __name__ == "__main__":
    main()
