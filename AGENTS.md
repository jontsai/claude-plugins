# Agent Guidelines

Guidelines for LLMs working on this codebase.

## Project Overview

This is a Claude Code plugins marketplace. It contains:

- **Marketplace definition**: `.claude-plugin/marketplace.json`
- **Plugins**: `plugins/<name>/` directories
- **Validation scripts**: `scripts/validate_*.py`
- **CI workflow**: `.github/workflows/validate.yml`

## Key Constraints

### Plugin Structure

1. Each plugin needs `.claude-plugin/plugin.json` with:
   - `name`, `description`, `version`, `author`

2. Skills are auto-discovered from `skills/*/SKILL.md`
   - Do NOT add explicit `skills` array to marketplace.json
   - Each SKILL.md needs frontmatter with `name` and `description`

3. hooks.json format is specific:
   - Must be object keyed by event name, NOT an array
   - Use `${CLAUDE_PLUGIN_ROOT}` for paths in commands

### Validation

Always run before committing:

```bash
./scripts/validate.sh
```

Or run individual validators:

```bash
python3 scripts/validate_json.py
python3 scripts/validate_marketplace.py
python3 scripts/validate_skills.py
python3 scripts/validate_hooks.py
```

### Common Mistakes to Avoid

1. **hooks.json as array**: Must be `{"hooks": {"EventName": [...]}}` not `{"hooks": [...]}`
2. **Explicit skills array**: Don't add - causes path doubling
3. **Missing plugin.json**: Each plugin needs `.claude-plugin/plugin.json`
4. **echo for colors**: Use `printf` with `\e[0;32m` escapes in Makefiles

## Testing Plugin Installation

```bash
# Add marketplace
/plugin marketplace add jontsai/claude-plugins

# Install plugin
/plugin install researcher@jontsai

# Check installation
/plugin list
```

## File Locations

| Purpose | Path |
|---------|------|
| Marketplace def | `.claude-plugin/marketplace.json` |
| Plugin metadata | `plugins/<name>/.claude-plugin/plugin.json` |
| Plugin hooks | `plugins/<name>/hooks/hooks.json` |
| Skills | `plugins/<name>/skills/<skill>/SKILL.md` |
| Validation | `scripts/validate_*.py` |
| CI | `.github/workflows/validate.yml` |

## Commit Guidelines

- Run validation before committing
- Use clear, descriptive commit messages
- Squash fixup commits before merging
