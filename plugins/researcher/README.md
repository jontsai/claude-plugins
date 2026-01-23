# Researcher

A Claude Code plugin for creating distinctive, memorable research documents in HTML or Markdown.

**Say goodbye to generic AI design.** This skill provides curated aesthetic presets that produce professional, visually striking documents.

![Terminal Aesthetic Example](https://via.placeholder.com/800x400/0d1117/00ff88?text=Terminal+Aesthetic)

## Features

- **Dual Output Modes** - HTML (styled) or Markdown (plaintext)
- **5 Curated Aesthetics** - Terminal, Editorial, Corporate, Industrial, Fresh
- **Anti-AI-Slop Design** - Intentional typography, textures, micro-interactions
- **Cross-Platform** - Works on macOS, Linux, and Windows (WSL)
- **Print-Ready** - Optimized for Letter-size PDF output
- **Zero Dependencies** - Just needs a Chromium-based browser (for HTML/PDF)

## Installation

```bash
/plugin marketplace add jontsai/claude-plugins
/plugin install researcher@jontsai
```

### Setup

After installation, run the setup:

```bash
cd ~/.claude/plugins/cache/jontsai/claude-plugins/plugins/researcher
make install
make install-alias  # Optional: adds 'rpdf' command
```

### Browser Requirement

You need one of these browsers installed:
- [Brave Browser](https://brave.com/) (recommended)
- [Google Chrome](https://www.google.com/chrome/)
- Chromium

### 4. Use the Skill

Just ask Claude Code to create a research document:

```
Create a cheatsheet for kubectl commands
```

```
Research the best sushi restaurants in San Francisco and create a PDF
```

```
Make a one-pager comparing React vs Vue vs Svelte
```

## Aesthetic Presets

| Preset | Best For | Key Elements |
|--------|----------|--------------|
| **TERMINAL** | Dev tools, CLI, cheatsheets | Dark theme, JetBrains Mono, green accents, scanlines |
| **EDITORIAL** | Restaurant guides, reviews | Playfair Display, warm paper texture, carmine red |
| **CORPORATE** | Business docs, analysis | Fraunces serif, navy/gold, subtle gradients |
| **INDUSTRIAL** | Automotive, hardware, specs | Oswald bold, uppercase, grid pattern, red/yellow |
| **FRESH** | Health, eco, nature | DM Serif, soft greens, organic rounded shapes |

## Directory Structure

```
$RESEARCHER_DIR/
├── html/                    # HTML source files (styled)
│   ├── k9s-cheatsheet-20251209.html
│   └── sushi-guide-20251210.html
├── md/                      # Markdown source files (plaintext)
│   └── quick-notes-20251211.md
├── pdf/                     # Generated PDFs
│   ├── k9s-cheatsheet-20251209.pdf
│   └── sushi-guide-20251210.pdf
└── generate-pdfs.sh         # HTML → PDF conversion script
```

## PDF Generation

Generate PDFs from all HTML files:

```bash
# Generate new PDFs only
$RESEARCHER_DIR/generate-pdfs.sh

# Force regenerate all PDFs
$RESEARCHER_DIR/generate-pdfs.sh --force

# Show help
$RESEARCHER_DIR/generate-pdfs.sh --help
```

## Design Philosophy

This plugin deliberately avoids "AI slop" - the generic, forgettable design patterns that plague AI-generated content:

### What We Avoid
- System font stacks (`-apple-system, Inter, Roboto`)
- Flat white backgrounds with no texture
- Purple gradients on white (the AI default)
- Cookie-cutter layouts

### What We Embrace
- **Intentional typography** - Fonts chosen for personality
- **Texture & atmosphere** - Paper grain, subtle patterns
- **Micro-interactions** - Hover states, transitions
- **Layout surprise** - Grid-breaking elements for emphasis
- **Cohesive theming** - CSS variables throughout

## Configuration

### Makefile Targets

| Target | Description |
|--------|-------------|
| `make install` | Create directories and install generation script |
| `make install-alias` | Add `RESEARCHER_DIR` and `rpdf` alias to shell profile |
| `make uninstall` | Remove installed script (preserves your HTML/PDF files) |
| `make check-browser` | Verify a compatible browser is installed |
| `make help` | Show all available targets |

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `RESEARCHER_DIR` | `~/research` | Base directory for HTML and PDF files |

### Shell Alias

After running `make install-alias`, you can generate PDFs with:

```bash
rpdf              # Generate new PDFs
rpdf --force      # Regenerate all PDFs
```

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| macOS | ✅ Full | Brave, Chrome, Chromium |
| Linux | ✅ Full | Brave, Chrome, Chromium |
| Windows (WSL) | ✅ Full | Uses Windows Chrome/Brave |
| Windows (Native) | ⚠️ Partial | Use WSL for best results |

## Examples

### Terminal Aesthetic (Dev Cheatsheet)

```html
<link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600;700&display=swap" rel="stylesheet">
<style>
:root {
  --font-display: 'JetBrains Mono', monospace;
  --color-ink: #e6edf3;
  --color-ink-bright: #00ff88;
  --color-paper: #0d1117;
}
</style>
```

### Editorial Aesthetic (Restaurant Guide)

```html
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Source+Sans+3&display=swap" rel="stylesheet">
<style>
:root {
  --font-display: 'Playfair Display', serif;
  --color-ink: #1a1a1a;
  --color-paper: #fefcf9;
  --color-accent: #c41e3a;
}
</style>
```

## Contributing

Contributions welcome! Please feel free to submit issues and pull requests.

### Ideas for Contribution
- New aesthetic presets
- Additional platform support
- Template HTML files
- Improved PDF generation options

## License

MIT License - see [LICENSE](LICENSE) for details.

## Credits

Created by [Jonathan Tsai](https://github.com/jontsai) with Claude Code.

Design philosophy inspired by the [frontend-design plugin](https://github.com/anthropics/claude-code-plugins).
