# @jontsai Claude Code Plugins

[![Validate](https://github.com/jontsai/claude-plugins/actions/workflows/validate.yml/badge.svg)](https://github.com/jontsai/claude-plugins/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Curated Claude Code plugins for research, productivity, and development workflows.

## Quick Start

```bash
# Add marketplace (one time)
/plugin marketplace add jontsai/claude-plugins

# Install a plugin
/plugin install researcher@jontsai
```

## Available Plugins

| Plugin | Category | Description |
|--------|----------|-------------|
| [researcher](./plugins/researcher/) | Productivity | Create distinctive HTML/Markdown one-pagers with curated aesthetics, convert to PDF |

### researcher

Create professional, visually striking research documents that avoid generic "AI slop" aesthetics.

- **5 aesthetic presets:** Terminal, Editorial, Corporate, Industrial, Fresh
- **Dual output:** HTML (styled) or Markdown (plaintext)
- **Cross-platform:** macOS, Linux, Windows (WSL)
- **PDF generation:** via headless Chromium

```bash
/plugin install researcher@jontsai
```

## Documentation

- [CONTRIBUTING.md](./CONTRIBUTING.md) - How to contribute
- [TESTING.md](./TESTING.md) - Validation and testing
- [AGENTS.md](./AGENTS.md) - Guidelines for LLMs

## Contributing

Contributions welcome! See [CONTRIBUTING.md](./CONTRIBUTING.md) for details.

## License

[MIT](LICENSE)

---

Created by [Jonathan Tsai](https://github.com/jontsai)
