# Claude Code Instructions

This file provides guidance for Claude Code when working on this repository.

## Quick Reference

- **[AGENTS.md](./AGENTS.md)** - Technical guidelines for LLMs working on this codebase
- **[CONTRIBUTING.md](./CONTRIBUTING.md)** - Contribution workflow and standards
- **[TESTING.md](./TESTING.md)** - How to validate and test plugins

## Before Making Changes

1. Read [AGENTS.md](./AGENTS.md) for structural constraints
2. Run `./scripts/validate.sh` after changes
3. Follow patterns in existing plugins

## Key Commands

```bash
# Validate everything
./scripts/validate.sh

# Test plugin install
/plugin marketplace add jontsai/claude-plugins
/plugin install researcher@jontsai
```
