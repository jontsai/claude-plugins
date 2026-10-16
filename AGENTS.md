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

### Portability

Skills in this repo are used from several coding agents and many machines, so the portable
unit is `plugins/<name>/skills/<skill>/` and it must stay agent-agnostic:

1. `SKILL.md` and bundled scripts must not name or assume a specific agent (no "Claude",
   "Codex", `~/.claude/...` paths, or agent-only features). Refer to bundled files relative to
   the skill directory, e.g. `scripts/foo.sh`.
2. Anything agent-specific (permission allowlists, hooks, marketplace metadata) lives outside
   the skill directory: in `.claude-plugin/`, `hooks/`, or as an adapter in `install.sh`.
3. `install.sh` symlinks skills into each agent's skill directory. To support a new agent, add
   its parent directory to the detection list there; nothing inside a skill should change.
4. Scripts should need only bash and python3. If a script is OS-specific, say so in the
   plugin README and fail clearly on other platforms.

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
