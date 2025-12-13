# Plugins

This directory contains all available plugins in the @jontsai marketplace.

## Available Plugins

| Plugin | Description |
|--------|-------------|
| [research-pdf](./research-pdf/) | Create distinctive HTML one-pagers with curated aesthetics, convert to PDF |

## Plugin Structure

Each plugin follows this structure:

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json       # Plugin manifest
├── skills/               # Skill definitions (optional)
├── commands/             # Slash commands (optional)
├── agents/               # Agent definitions (optional)
├── hooks/                # Event hooks (optional)
├── scripts/              # Supporting scripts (optional)
├── Makefile              # Setup automation (optional)
└── README.md             # Plugin documentation
```

## Adding a New Plugin

1. Create a new directory under `plugins/`
2. Add a `.claude-plugin/plugin.json` manifest
3. Add the plugin to `../.claude-plugin/marketplace.json`
