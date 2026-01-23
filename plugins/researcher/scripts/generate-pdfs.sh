#!/bin/bash
#
# generate-pdfs.sh
# Converts HTML files to PDF using Chrome/Brave headless mode
# Part of the researcher plugin for Claude Code
#
# Usage:
#   generate-pdfs.sh [options]
#
# Options:
#   -f, --force     Regenerate all PDFs (ignore existing)
#   -h, --help      Show this help message
#   --setup         Create directory structure and show setup instructions
#

set -e

# ============================================
# Configuration
# ============================================

# Use environment variable or default to ~/research
RESEARCHER_DIR="${RESEARCHER_DIR:-$HOME/research}"
HTML_DIR="$RESEARCHER_DIR/html"
PDF_DIR="$RESEARCHER_DIR/pdf"

# ============================================
# Browser Detection (Cross-platform)
# ============================================

find_browser() {
    local browser=""

    # macOS paths
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [[ -x "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" ]]; then
            browser="/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
            echo "🦁 Using Brave Browser (macOS)"
        elif [[ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]]; then
            browser="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
            echo "🌐 Using Google Chrome (macOS)"
        elif [[ -x "/Applications/Chromium.app/Contents/MacOS/Chromium" ]]; then
            browser="/Applications/Chromium.app/Contents/MacOS/Chromium"
            echo "🔵 Using Chromium (macOS)"
        fi
    # Linux paths
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v brave-browser &> /dev/null; then
            browser="brave-browser"
            echo "🦁 Using Brave Browser (Linux)"
        elif command -v google-chrome &> /dev/null; then
            browser="google-chrome"
            echo "🌐 Using Google Chrome (Linux)"
        elif command -v google-chrome-stable &> /dev/null; then
            browser="google-chrome-stable"
            echo "🌐 Using Google Chrome Stable (Linux)"
        elif command -v chromium-browser &> /dev/null; then
            browser="chromium-browser"
            echo "🔵 Using Chromium (Linux)"
        elif command -v chromium &> /dev/null; then
            browser="chromium"
            echo "🔵 Using Chromium (Linux)"
        fi
    # Windows (WSL)
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || grep -qi microsoft /proc/version 2>/dev/null; then
        # Try to find Chrome in Windows from WSL
        if [[ -x "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe" ]]; then
            browser="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"
            echo "🌐 Using Google Chrome (Windows/WSL)"
        elif [[ -x "/mnt/c/Program Files/BraveSoftware/Brave-Browser/Application/brave.exe" ]]; then
            browser="/mnt/c/Program Files/BraveSoftware/Brave-Browser/Application/brave.exe"
            echo "🦁 Using Brave Browser (Windows/WSL)"
        fi
    fi

    echo "$browser"
}

# ============================================
# Help & Setup Functions
# ============================================

show_help() {
    cat << 'EOF'
@jontsai/researcher: Generate PDFs from HTML files

USAGE:
    generate-pdfs.sh [OPTIONS]

OPTIONS:
    -f, --force     Regenerate all PDFs, even if they already exist
    -h, --help      Show this help message
    --setup         Create directory structure and show setup instructions

ENVIRONMENT:
    RESEARCHER_DIR    Base directory for HTML and PDF files
                        Default: ~/research

EXAMPLES:
    # Generate PDFs for new HTML files only
    generate-pdfs.sh

    # Force regenerate all PDFs
    generate-pdfs.sh --force

    # Use a custom directory
    RESEARCHER_DIR=/path/to/docs generate-pdfs.sh

DIRECTORY STRUCTURE:
    $RESEARCHER_DIR/
    ├── html/           # Place your HTML files here
    └── pdf/            # Generated PDFs appear here

Claude Code plugin by @jontsai
https://github.com/jontsai/claude-plugins

EOF
}

setup_directories() {
    echo "📁 Setting up research-pdf directories..."
    echo ""
    echo "   Base directory: $RESEARCHER_DIR"

    mkdir -p "$HTML_DIR" "$PDF_DIR"

    echo "   ✅ Created: $HTML_DIR"
    echo "   ✅ Created: $PDF_DIR"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 Next Steps:"
    echo ""
    echo "1. Add this to your shell profile (~/.zshrc or ~/.bashrc):"
    echo ""
    echo "   export RESEARCHER_DIR=\"$RESEARCHER_DIR\""
    echo ""
    echo "2. Optionally create an alias:"
    echo ""
    echo "   alias research-pdf-generate=\"\$RESEARCHER_DIR/generate-pdfs.sh\""
    echo ""
    echo "3. Copy this script to your research directory:"
    echo ""
    echo "   cp generate-pdfs.sh \"\$RESEARCHER_DIR/\""
    echo "   chmod +x \"\$RESEARCHER_DIR/generate-pdfs.sh\""
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ============================================
# Main Script
# ============================================

main() {
    local force=false

    # Parse arguments
    for arg in "$@"; do
        case $arg in
            -f|--force)
                force=true
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            --setup)
                setup_directories
                exit 0
                ;;
            *)
                echo "Unknown option: $arg"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    # Find browser
    browser=$(find_browser)

    if [[ -z "$browser" ]]; then
        echo ""
        echo "❌ No compatible browser found!"
        echo ""
        echo "Please install one of the following:"
        echo ""
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "  macOS:"
            echo "    • Brave Browser: https://brave.com/"
            echo "    • Google Chrome: https://www.google.com/chrome/"
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            echo "  Linux (Debian/Ubuntu):"
            echo "    • sudo apt install chromium-browser"
            echo "    • Or download Chrome: https://www.google.com/chrome/"
            echo ""
            echo "  Linux (Fedora):"
            echo "    • sudo dnf install chromium"
        else
            echo "  • Brave Browser: https://brave.com/"
            echo "  • Google Chrome: https://www.google.com/chrome/"
        fi
        echo ""
        exit 1
    fi

    # Ensure directories exist
    if [[ ! -d "$HTML_DIR" ]]; then
        echo ""
        echo "❌ HTML directory not found: $HTML_DIR"
        echo ""
        echo "Run with --setup to create the directory structure:"
        echo "  generate-pdfs.sh --setup"
        echo ""
        exit 1
    fi

    mkdir -p "$PDF_DIR"

    # Track counts
    local converted=0
    local skipped=0
    local failed=0

    echo ""
    if [[ "$force" == true ]]; then
        echo "🔄 Force mode: Regenerating ALL PDFs..."
    else
        echo "🔍 Scanning for HTML files missing PDFs..."
    fi
    echo "   HTML dir: $HTML_DIR"
    echo "   PDF dir:  $PDF_DIR"
    echo ""

    # Check if any HTML files exist
    shopt -s nullglob
    local html_files=("$HTML_DIR"/*.html)
    shopt -u nullglob

    if [[ ${#html_files[@]} -eq 0 ]]; then
        echo "📭 No HTML files found in $HTML_DIR"
        echo ""
        echo "Create an HTML file and run this script again."
        exit 0
    fi

    # Process each HTML file
    for html_file in "${html_files[@]}"; do
        local basename=$(basename "$html_file" .html)
        local pdf_file="$PDF_DIR/${basename}.pdf"

        if [[ -f "$pdf_file" ]] && [[ "$force" != true ]]; then
            echo "⏭️  Skipping: $basename (PDF exists)"
            ((skipped++))
        else
            echo "📄 Converting: $basename.html → $basename.pdf"

            # Use headless browser to generate PDF
            if "$browser" \
                --headless=new \
                --disable-gpu \
                --no-sandbox \
                --print-to-pdf="$pdf_file" \
                --no-pdf-header-footer \
                "file://$html_file" \
                2>/dev/null; then

                if [[ -f "$pdf_file" ]]; then
                    echo "   ✅ Success: $pdf_file"
                    ((converted++))
                else
                    echo "   ❌ Failed: PDF file not created"
                    ((failed++))
                fi
            else
                echo "   ❌ Failed: Browser error"
                ((failed++))
            fi
        fi
    done

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 Summary:"
    echo "   Converted: $converted"
    echo "   Skipped:   $skipped (already exist)"
    echo "   Failed:    $failed"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [[ $failed -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
