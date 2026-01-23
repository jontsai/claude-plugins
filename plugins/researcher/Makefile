# researcher plugin Makefile
#
# Usage:
#   make install          - Set up directories and install script
#   make install-alias    - Add shell alias to profile
#   make uninstall        - Remove installed files
#   make help             - Show this help
#

SHELL := /bin/bash

# Configuration
RESEARCHER_DIR ?= $(HOME)/research
SCRIPT_NAME := generate-pdfs.sh
SHELL_PROFILE := $(shell if [ -f "$(HOME)/.zshrc" ]; then echo "$(HOME)/.zshrc"; else echo "$(HOME)/.bashrc"; fi)

# Colors (using \e escape sequence for printf)
GREEN := \e[0;32m
YELLOW := \e[0;33m
CYAN := \e[0;36m
NC := \e[0m

# Branding
define BANNER
     $(CYAN)╭─────────────────────────────────────────────╮$(NC)
     $(CYAN)│$(NC)   $(GREEN)R E S E A R C H E R$(NC)                      $(CYAN)│$(NC)
     $(CYAN)│$(NC)   Claude Code plugin by $(YELLOW)@jontsai$(NC)           $(CYAN)│$(NC)
     $(CYAN)╰─────────────────────────────────────────────╯$(NC)
endef
export BANNER

define BANNER_FULL
     $(CYAN)╭─────────────────────────────────────────────╮$(NC)
     $(CYAN)│$(NC)   $(GREEN)R E S E A R C H E R$(NC)                      $(CYAN)│$(NC)
     $(CYAN)│$(NC)   Claude Code plugin by $(YELLOW)@jontsai$(NC)           $(CYAN)│$(NC)
     $(CYAN)│$(NC)   github.com/jontsai/claude-plugins        $(CYAN)│$(NC)
     $(CYAN)╰─────────────────────────────────────────────╯$(NC)
endef
export BANNER_FULL

.PHONY: help install install-alias uninstall check-browser

help:
	@printf "\n"
	@printf "$$BANNER\n"
	@printf "\n"
	@printf "$(GREEN)make install$(NC)          Set up directories and install generation script\n"
	@printf "$(GREEN)make install-alias$(NC)    Add 'rpdf' alias to your shell profile\n"
	@printf "$(GREEN)make uninstall$(NC)        Remove installed files and directories\n"
	@printf "$(GREEN)make check-browser$(NC)    Verify a compatible browser is installed\n"
	@printf "\n"
	@printf "$(YELLOW)Configuration:$(NC)\n"
	@printf "  RESEARCHER_DIR    Target directory (default: ~/research)\n"
	@printf "\n"
	@printf "$(YELLOW)Examples:$(NC)\n"
	@printf "  make install\n"
	@printf "  make install RESEARCHER_DIR=~/Documents/research\n"
	@printf "  make install-alias\n"
	@printf "\n"

install: check-browser
	@printf "\n"
	@printf "$(CYAN)Installing researcher...$(NC)\n"
	@printf "\n"
	@printf "  Target directory: $(RESEARCHER_DIR)\n"
	@printf "\n"
	@mkdir -p "$(RESEARCHER_DIR)/html"
	@mkdir -p "$(RESEARCHER_DIR)/md"
	@mkdir -p "$(RESEARCHER_DIR)/pdf"
	@printf "  $(GREEN)✓$(NC) Created $(RESEARCHER_DIR)/html/\n"
	@printf "  $(GREEN)✓$(NC) Created $(RESEARCHER_DIR)/md/\n"
	@printf "  $(GREEN)✓$(NC) Created $(RESEARCHER_DIR)/pdf/\n"
	@cp scripts/$(SCRIPT_NAME) "$(RESEARCHER_DIR)/$(SCRIPT_NAME)"
	@chmod +x "$(RESEARCHER_DIR)/$(SCRIPT_NAME)"
	@printf "  $(GREEN)✓$(NC) Installed $(SCRIPT_NAME)\n"
	@printf "\n"
	@printf "$$BANNER_FULL\n"
	@printf "\n"
	@printf "  $(GREEN)✓ Installation complete!$(NC)\n"
	@printf "\n"
	@printf "  $(YELLOW)Next steps:$(NC)\n"
	@printf "\n"
	@printf "  1. Add this to your shell profile ($(SHELL_PROFILE)):\n"
	@printf "\n"
	@printf "     export RESEARCHER_DIR=\"$(RESEARCHER_DIR)\"\n"
	@printf "\n"
	@printf "  2. Or run: $(CYAN)make install-alias$(NC) to set this up automatically\n"
	@printf "\n"
	@printf "  3. Generate PDFs with:\n"
	@printf "\n"
	@printf "     $(RESEARCHER_DIR)/$(SCRIPT_NAME)\n"
	@printf "\n"

install-alias:
	@printf "\n"
	@printf "$(CYAN)Adding environment variable and alias to $(SHELL_PROFILE)...$(NC)\n"
	@printf "\n"
	@if grep -q "RESEARCHER_DIR" "$(SHELL_PROFILE)" 2>/dev/null; then \
		printf "  $(YELLOW)⚠$(NC)  RESEARCHER_DIR already exists in $(SHELL_PROFILE)\n"; \
	else \
		echo "" >> "$(SHELL_PROFILE)"; \
		echo "# @jontsai/researcher - Claude Code plugin" >> "$(SHELL_PROFILE)"; \
		echo "# https://github.com/jontsai/claude-plugins" >> "$(SHELL_PROFILE)"; \
		echo "export RESEARCHER_DIR=\"$(RESEARCHER_DIR)\"" >> "$(SHELL_PROFILE)"; \
		echo "alias rpdf=\"\$$RESEARCHER_DIR/generate-pdfs.sh\"" >> "$(SHELL_PROFILE)"; \
		printf "  $(GREEN)✓$(NC) Added RESEARCHER_DIR to $(SHELL_PROFILE)\n"; \
		printf "  $(GREEN)✓$(NC) Added 'rpdf' alias\n"; \
	fi
	@printf "\n"
	@printf "  $(GREEN)Done!$(NC) Restart your shell or run:\n"
	@printf "\n"
	@printf "    source $(SHELL_PROFILE)\n"
	@printf "\n"
	@printf "  Then generate PDFs with: $(CYAN)rpdf$(NC)\n"
	@printf "\n"
	@printf "  $(YELLOW)@jontsai$(NC) | github.com/jontsai/claude-plugins\n"
	@printf "\n"

uninstall:
	@printf "\n"
	@printf "$(CYAN)Uninstalling researcher...$(NC)\n"
	@printf "\n"
	@if [ -f "$(RESEARCHER_DIR)/$(SCRIPT_NAME)" ]; then \
		rm "$(RESEARCHER_DIR)/$(SCRIPT_NAME)"; \
		printf "  $(GREEN)✓$(NC) Removed $(SCRIPT_NAME)\n"; \
	fi
	@printf "\n"
	@printf "$(YELLOW)Note:$(NC) HTML and PDF directories preserved at:\n"
	@printf "  $(RESEARCHER_DIR)/html/\n"
	@printf "  $(RESEARCHER_DIR)/pdf/\n"
	@printf "\n"
	@printf "To fully remove, run:\n"
	@printf "  rm -rf \"$(RESEARCHER_DIR)\"\n"
	@printf "\n"
	@printf "To remove from shell profile, edit $(SHELL_PROFILE) and remove:\n"
	@printf "  - export RESEARCHER_DIR=...\n"
	@printf "  - alias rpdf=...\n"
	@printf "\n"

check-browser:
	@printf "\n"
	@printf "$(CYAN)Checking for compatible browser...$(NC)\n"
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
		printf "  $(GREEN)✓$(NC) Found: $$FOUND\n"; \
	else \
		printf "  $(YELLOW)⚠$(NC)  No compatible browser found!\n"; \
		printf "\n"; \
		printf "  Please install one of:\n"; \
		printf "    - Brave Browser: https://brave.com/\n"; \
		printf "    - Google Chrome: https://www.google.com/chrome/\n"; \
		printf "\n"; \
		exit 1; \
	fi
