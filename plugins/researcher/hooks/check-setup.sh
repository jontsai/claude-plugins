#!/bin/bash
# Check if researcher plugin is properly set up

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISSUES=()

# Check if RESEARCHER_DIR is set
if [ -z "$RESEARCHER_DIR" ]; then
    ISSUES+=("RESEARCHER_DIR environment variable is not set")
fi

# Check if directories exist (only if RESEARCHER_DIR is set)
if [ -n "$RESEARCHER_DIR" ]; then
    if [ ! -d "$RESEARCHER_DIR/html" ]; then
        ISSUES+=("Directory $RESEARCHER_DIR/html does not exist")
    fi
    if [ ! -d "$RESEARCHER_DIR/pdf" ]; then
        ISSUES+=("Directory $RESEARCHER_DIR/pdf does not exist")
    fi
    if [ ! -x "$RESEARCHER_DIR/generate-pdfs.sh" ]; then
        ISSUES+=("generate-pdfs.sh is not installed")
    fi
fi

# If there are issues, output a message for Claude to see
if [ ${#ISSUES[@]} -gt 0 ]; then
    echo "[@jontsai/researcher] Setup required:"
    for issue in "${ISSUES[@]}"; do
        echo "  - $issue"
    done
    echo ""
    echo "To complete setup, run:"
    echo "  cd ~/.claude/plugins/cache/jontsai/claude-plugins/plugins/researcher"
    echo "  make install"
    echo "  make install-alias"
fi
