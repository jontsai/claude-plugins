# Contributing to @jontsai Claude Code Plugins

Thank you for your interest in contributing!

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Create a feature branch: `git checkout -b my-feature`

## Development Workflow

### Before Committing

Run the validation script to catch errors early:

```bash
./scripts/validate.sh
```

This checks:
- JSON syntax in all `.json` files
- Marketplace and plugin structure
- SKILL.md frontmatter format
- hooks.json event names

### Plugin Structure

Each plugin must have:

```
plugins/<plugin-name>/
├── .claude-plugin/
│   └── plugin.json          # Required: name, description, version, author
├── hooks/
│   └── hooks.json           # Optional: lifecycle hooks
├── skills/
│   └── <skill-name>/
│       └── SKILL.md         # Required: frontmatter with name, description
├── scripts/                 # Optional: helper scripts
├── LICENSE
├── Makefile                 # Optional: install/uninstall targets
└── README.md
```

### SKILL.md Frontmatter

Every SKILL.md must have YAML frontmatter:

```yaml
---
name: skill-name
description: What the skill does
---
```

### hooks.json Format

Hooks must be an object keyed by event name:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/my-hook.sh",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
```

Valid events: `PreToolUse`, `PostToolUse`, `SessionStart`, `Stop`, `SubagentStop`, `SessionEnd`, `UserPromptSubmit`, `PermissionRequest`, `PreCompact`, `Notification`

## Submitting Changes

1. Ensure `./scripts/validate.sh` passes
2. Commit with clear, descriptive messages
3. Push to your fork
4. Open a pull request against `main`

## Code Style

- Keep scripts POSIX-compatible where possible
- Use `printf` instead of `echo` for colored output
- Prefer readability over cleverness

## Questions?

Open an issue on [GitHub](https://github.com/jontsai/claude-plugins/issues).
