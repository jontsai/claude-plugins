# research-pdf-plugin Makefile
#
# Usage:
#   make install          - Set up directories and install script
#   make install-alias    - Add shell alias to profile
#   make uninstall        - Remove installed files
#   make help             - Show this help
#

SHELL := /bin/bash

# Configuration
RESEARCH_PDF_DIR ?= $(HOME)/research-pdfs
SCRIPT_NAME := generate-pdfs.sh
SHELL_PROFILE := $(shell if [ -f "$(HOME)/.zshrc" ]; then echo "$(HOME)/.zshrc"; else echo "$(HOME)/.bashrc"; fi)

# Colors
GREEN := \033[0;32m
YELLOW := \033[0;33m
CYAN := \033[0;36m
NC := \033[0m # No Color

.PHONY: help install install-alias uninstall check-browser

help:
	@echo ""
	@echo "$(CYAN)research-pdf-plugin$(NC) - Installation targets"
	@echo ""
	@echo "$(GREEN)make install$(NC)          Set up directories and install generation script"
	@echo "$(GREEN)make install-alias$(NC)    Add 'rpdf' alias to your shell profile"
	@echo "$(GREEN)make uninstall$(NC)        Remove installed files and directories"
	@echo "$(GREEN)make check-browser$(NC)    Verify a compatible browser is installed"
	@echo ""
	@echo "$(YELLOW)Configuration:$(NC)"
	@echo "  RESEARCH_PDF_DIR    Target directory (default: ~/research-pdfs)"
	@echo ""
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make install"
	@echo "  make install RESEARCH_PDF_DIR=~/Documents/research"
	@echo "  make install-alias"
	@echo ""

install: check-browser
	@echo ""
	@echo "$(CYAN)Installing research-pdf...$(NC)"
	@echo ""
	@echo "  Target directory: $(RESEARCH_PDF_DIR)"
	@echo ""
	@mkdir -p "$(RESEARCH_PDF_DIR)/html"
	@mkdir -p "$(RESEARCH_PDF_DIR)/pdf"
	@echo "  $(GREEN)✓$(NC) Created $(RESEARCH_PDF_DIR)/html/"
	@echo "  $(GREEN)✓$(NC) Created $(RESEARCH_PDF_DIR)/pdf/"
	@cp scripts/$(SCRIPT_NAME) "$(RESEARCH_PDF_DIR)/$(SCRIPT_NAME)"
	@chmod +x "$(RESEARCH_PDF_DIR)/$(SCRIPT_NAME)"
	@echo "  $(GREEN)✓$(NC) Installed $(SCRIPT_NAME)"
	@echo ""
	@echo "$(CYAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "$(GREEN)Installation complete!$(NC)"
	@echo ""
	@echo "$(YELLOW)Next steps:$(NC)"
	@echo ""
	@echo "  1. Add this to your shell profile ($(SHELL_PROFILE)):"
	@echo ""
	@echo "     export RESEARCH_PDF_DIR=\"$(RESEARCH_PDF_DIR)\""
	@echo ""
	@echo "  2. Or run: $(CYAN)make install-alias$(NC) to set this up automatically"
	@echo ""
	@echo "  3. Generate PDFs with:"
	@echo ""
	@echo "     $(RESEARCH_PDF_DIR)/$(SCRIPT_NAME)"
	@echo ""
	@echo "$(CYAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""

install-alias:
	@echo ""
	@echo "$(CYAN)Adding environment variable and alias to $(SHELL_PROFILE)...$(NC)"
	@echo ""
	@if grep -q "RESEARCH_PDF_DIR" "$(SHELL_PROFILE)" 2>/dev/null; then \
		echo "  $(YELLOW)⚠$(NC)  RESEARCH_PDF_DIR already exists in $(SHELL_PROFILE)"; \
	else \
		echo "" >> "$(SHELL_PROFILE)"; \
		echo "# research-pdf-plugin" >> "$(SHELL_PROFILE)"; \
		echo "export RESEARCH_PDF_DIR=\"$(RESEARCH_PDF_DIR)\"" >> "$(SHELL_PROFILE)"; \
		echo "alias rpdf=\"\$$RESEARCH_PDF_DIR/generate-pdfs.sh\"" >> "$(SHELL_PROFILE)"; \
		echo "  $(GREEN)✓$(NC) Added RESEARCH_PDF_DIR to $(SHELL_PROFILE)"; \
		echo "  $(GREEN)✓$(NC) Added 'rpdf' alias"; \
	fi
	@echo ""
	@echo "$(GREEN)Done!$(NC) Restart your shell or run:"
	@echo ""
	@echo "  source $(SHELL_PROFILE)"
	@echo ""
	@echo "Then generate PDFs with: $(CYAN)rpdf$(NC)"
	@echo ""

uninstall:
	@echo ""
	@echo "$(CYAN)Uninstalling research-pdf...$(NC)"
	@echo ""
	@if [ -f "$(RESEARCH_PDF_DIR)/$(SCRIPT_NAME)" ]; then \
		rm "$(RESEARCH_PDF_DIR)/$(SCRIPT_NAME)"; \
		echo "  $(GREEN)✓$(NC) Removed $(SCRIPT_NAME)"; \
	fi
	@echo ""
	@echo "$(YELLOW)Note:$(NC) HTML and PDF directories preserved at:"
	@echo "  $(RESEARCH_PDF_DIR)/html/"
	@echo "  $(RESEARCH_PDF_DIR)/pdf/"
	@echo ""
	@echo "To fully remove, run:"
	@echo "  rm -rf \"$(RESEARCH_PDF_DIR)\""
	@echo ""
	@echo "To remove from shell profile, edit $(SHELL_PROFILE) and remove:"
	@echo "  - export RESEARCH_PDF_DIR=..."
	@echo "  - alias rpdf=..."
	@echo ""

check-browser:
	@echo ""
	@echo "$(CYAN)Checking for compatible browser...$(NC)"
	@FOUND=""; \
	if [ "$$(uname)" = "Darwin" ]; then \
		if [ -x "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" ]; then \
			FOUND="Brave Browser"; \
		elif [ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then \
			FOUND="Google Chrome"; \
		fi; \
	else \
		if command -v brave-browser >/dev/null 2>&1; then \
			FOUND="Brave Browser"; \
		elif command -v google-chrome >/dev/null 2>&1; then \
			FOUND="Google Chrome"; \
		elif command -v chromium-browser >/dev/null 2>&1; then \
			FOUND="Chromium"; \
		elif command -v chromium >/dev/null 2>&1; then \
			FOUND="Chromium"; \
		fi; \
	fi; \
	if [ -n "$$FOUND" ]; then \
		echo "  $(GREEN)✓$(NC) Found: $$FOUND"; \
	else \
		echo "  $(YELLOW)⚠$(NC)  No compatible browser found!"; \
		echo ""; \
		echo "  Please install one of:"; \
		echo "    - Brave Browser: https://brave.com/"; \
		echo "    - Google Chrome: https://www.google.com/chrome/"; \
		echo ""; \
		exit 1; \
	fi
