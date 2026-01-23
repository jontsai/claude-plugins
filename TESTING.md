# Testing

## Local Validation

Run all validation checks:

```bash
./scripts/validate.sh
```

Individual validators:

```bash
# JSON syntax
python3 scripts/validate_json.py

# Marketplace structure
python3 scripts/validate_marketplace.py

# SKILL.md frontmatter
python3 scripts/validate_skills.py

# hooks.json format
python3 scripts/validate_hooks.py
```

## Testing Plugin Installation

### From Local Marketplace

```bash
# Add local marketplace (use absolute path)
/plugin marketplace add /path/to/claude-plugins

# Install plugin
/plugin install researcher@jontsai
```

### From GitHub

```bash
# Add marketplace
/plugin marketplace add jontsai/claude-plugins

# Install plugin
/plugin install researcher@jontsai

# Verify
/plugin list
```

## Testing Individual Components

### Skills

Test that a skill loads correctly:

```bash
# After installing plugin
/researcher
```

### Hooks

SessionStart hooks run automatically when Claude Code starts a session. Check output for any hook messages.

### Install Scripts

Test the Makefile install:

```bash
cd plugins/researcher
make install

# Check output directory was created
ls -la ~/research
```

## CI

The GitHub Actions workflow runs on:
- Push to `main`
- Pull requests to `main`

It runs all four validation scripts and reports any errors.

## Debugging

### Common Issues

1. **"expected record, received array"**: hooks.json format wrong
2. **"skills path not found"**: Don't use explicit skills array
3. **"duplicate hooks"**: Remove hooks field from plugin.json
4. **Colors not showing**: Use `printf` not `echo` in Makefile
