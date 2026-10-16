# mem-rescue

Diagnose and fix memory pressure in one or two commands: a full swap, a compressor eating half
your RAM, browser tabs that fail to open. Built after a 32 GB Mac hit 27 GB of swap under one
browser session and two leaked Electron apps.

**Agent-agnostic.** The skill is a plain `SKILL.md` plus two shell scripts. It carries no
instructions specific to any one coding agent, so the same directory works in any tool that
reads the `skills/<name>/SKILL.md` convention.

## What it does

| Script | Purpose | Side effects |
|--------|---------|--------------|
| `scripts/memcheck.sh` | One-shot diagnosis: verdict, headline numbers, memory by app, Chromium/Electron process load, leak suspects, recent crashes, ranked actions. `--json` for machine-readable. | None (read-only) |
| `scripts/rescue.sh` | Graceful quit and relaunch of named apps (`brave`, `chrome`, `slack`, `notion`, `calendar`, `all`, or any app name). `--dry-run`, `--force`, `--no-relaunch`. Reports swap before/after. | Quits apps |

Example report:

```
=== MEMORY CHECK (Darwin): CRITICAL ===
RAM 32 GB | used 31.0 GB (wired 4.6, compressor 16.0) | swap 26.7/27.6 GB in 27 files | free 38% | demand 57.7 GB
uptime 7 days, 3:07 | 775 processes

APP                      TOTAL   CMPRS  PROCS   OLDEST
Brave                    42.8G   36.8G    149     1.9d
Slack                     2.5G    2.0G      6     6.6d
Notion Calendar           1.7G    1.6G      3     7.0d
...
Ranked actions (est. recoverable):
  1. restart Brave              ~ 36.4 GB   149 processes, 86% compressed out -> mostly idle tabs
  2. restart Slack              ~  2.1 GB   over 1 GB and running 6.6 days -> likely unbounded growth
```

## Platform support

| Platform | Status | Notes |
|----------|--------|-------|
| macOS | Tested | `top`, `sysctl`, `memory_pressure`, AppleScript quit |
| Linux | Best-effort | `/proc/meminfo`, `VmSwap` per process, SIGTERM quit. Parser tested against fixtures, not yet on real hosts. |

Requires bash and python3 (present by default on both).

## Install

From the repo root, link every skill in this repo into whichever agent skill directories exist
on this machine:

```bash
./install.sh            # symlinks into ~/.claude/skills, ~/.codex/skills, ~/.agents/skills (those that exist)
./install.sh --dry-run
./install.sh --allow    # also allowlist the scripts in Claude Code so they never prompt
```

Symlinks mean this checkout is the single source of truth: `git pull` updates every agent.
Or install into Claude Code only via the marketplace:

```
/plugin install mem-rescue@jontsai
```

### Why allowlisting matters

The scripts are designed to be invoked by their path with no surrounding pipeline so an agent
with a command allowlist can approve them once. In Claude Code, `./install.sh --allow` adds the
two `Bash(...)` rules to `~/.claude/settings.json`. For other agents, allow the two script
paths in that agent's equivalent.

## Usage

Ask your agent anything like "my mac is swapping like crazy", "new tabs keep crashing", or
"what's eating my RAM". It runs `memcheck.sh`, reports the verdict and ranked actions, and
asks before running `rescue.sh`. You can also run the scripts directly.
