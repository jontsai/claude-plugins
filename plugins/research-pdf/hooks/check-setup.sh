#!/bin/bash
# Check if research-pdf plugin is properly set up

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISSUES=()

# Check if RESEARCH_PDF_DIR is set
if [ -z "$RESEARCH_PDF_DIR" ]; then
    ISSUES+=("RESEARCH_PDF_DIR environment variable is not set")
fi

# Check if directories exist (only if RESEARCH_PDF_DIR is set)
if [ -n "$RESEARCH_PDF_DIR" ]; then
    if [ ! -d "$RESEARCH_PDF_DIR/html" ]; then
        ISSUES+=("Directory $RESEARCH_PDF_DIR/html does not exist")
    fi
    if [ ! -d "$RESEARCH_PDF_DIR/pdf" ]; then
        ISSUES+=("Directory $RESEARCH_PDF_DIR/pdf does not exist")
    fi
    if [ ! -x "$RESEARCH_PDF_DIR/generate-pdfs.sh" ]; then
        ISSUES+=("generate-pdfs.sh is not installed")
    fi
fi

# If there are issues, output a message for Claude to see
if [ ${#ISSUES[@]} -gt 0 ]; then
    echo "[research-pdf] Setup required:"
    for issue in "${ISSUES[@]}"; do
        echo "  - $issue"
    done
    echo ""
    echo "To complete setup, run:"
    echo "  cd ~/.claude/plugins/cache/jontsai/claude-plugins/plugins/research-pdf"
    echo "  make install"
    echo "  make install-alias"
fi
