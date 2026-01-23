#!/bin/bash
# Validate plugin structure locally
# Run this before pushing to catch errors early

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$ROOT_DIR"

echo ""
echo "Validating Claude Code plugin structure..."
echo ""

echo "1. Checking JSON syntax..."
python3 scripts/validate_json.py

echo "2. Checking marketplace and plugin structure..."
python3 scripts/validate_marketplace.py

echo "3. Checking SKILL.md frontmatter..."
python3 scripts/validate_skills.py

echo "4. Checking hooks.json format..."
python3 scripts/validate_hooks.py

echo ""
echo "========================================"
echo "  All validations passed!"
echo "========================================"
echo ""
