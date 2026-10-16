#!/usr/bin/env bash
# install.sh - link every plugins/*/skills/<skill> in this repo into the skill directories of
# whichever coding agents are present on this machine. Symlinks keep this checkout as the
# single source of truth: `git pull` updates every agent at once.
#
# Usage: ./install.sh [--dry-run] [--force] [--uninstall] [--allow] [--into DIR]...
#   --into DIR    link into DIR instead of the auto-detected agent dirs (repeatable)
#   --only NAME   link only this skill (repeatable); default is every skill in the repo
#   --force       replace an existing real directory of the same name (default: skip it)
#   --uninstall   remove the symlinks this script would have created
#   --allow       Claude Code adapter: allowlist each skill's scripts/*.sh in ~/.claude/settings.json

set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY=0; FORCE=0; UNINSTALL=0; ALLOW=0; TARGETS=(); ONLY=()
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1;; --force) FORCE=1;; --uninstall) UNINSTALL=1;; --allow) ALLOW=1;;
    --into) TARGETS+=("$2"); shift;;
    --only) ONLY+=("$2"); shift;;
    -h|--help) sed -n '2,12p' "$0"; exit 0;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac; shift
done

# Agent skill directories, keyed by the parent dir that signals the agent is installed.
# Add a line here to support another agent; nothing else in the repo needs to know.
if [ ${#TARGETS[@]} -eq 0 ]; then
  for parent in "$HOME/.claude" "$HOME/.codex" "$HOME/.agents"; do
    [ -d "$parent" ] && TARGETS+=("$parent/skills")
  done
fi
[ ${#TARGETS[@]} -eq 0 ] && { echo "no agent skill directories found; use --into DIR"; exit 1; }

SKILLS=()
for d in "$REPO"/plugins/*/skills/*/; do
  [ -f "$d/SKILL.md" ] || continue
  if [ ${#ONLY[@]} -gt 0 ]; then
    keep=0; for o in "${ONLY[@]}"; do [ "$o" = "$(basename "${d%/}")" ] && keep=1; done
    [ $keep -eq 1 ] || continue
  fi
  SKILLS+=("${d%/}")
done
[ ${#SKILLS[@]} -eq 0 ] && { echo "no matching skills"; exit 1; }

run() { if [ $DRY -eq 1 ]; then echo "  [dry-run] $*"; else "$@"; fi; }

for target in "${TARGETS[@]}"; do
  echo "$target"
  run mkdir -p "$target"
  for src in "${SKILLS[@]}"; do
    name="$(basename "$src")"; dst="$target/$name"
    if [ $UNINSTALL -eq 1 ]; then
      if [ -L "$dst" ]; then run rm "$dst"; echo "  - removed $name"; fi
      continue
    fi
    if [ -L "$dst" ]; then
      [ "$(readlink "$dst")" = "$src" ] && { echo "  = $name (already linked)"; continue; }
      run ln -sfn "$src" "$dst"; echo "  ~ $name (relinked)"
    elif [ -e "$dst" ]; then
      if [ $FORCE -eq 1 ]; then run rm -rf "$dst"; run ln -s "$src" "$dst"; echo "  ! $name (replaced real directory)"
      else echo "  x $name exists as a real directory; use --force to replace"; fi
    else
      run ln -s "$src" "$dst"; echo "  + $name"
    fi
  done
done

# --- Claude Code adapter: permission allowlist so bundled scripts never prompt -------------
if [ $ALLOW -eq 1 ] && [ $UNINSTALL -eq 0 ]; then
  SETTINGS="$HOME/.claude/settings.json"
  echo "allowlisting scripts in $SETTINGS"
  rules=()
  for src in "${SKILLS[@]}"; do
    name="$(basename "$src")"
    for s in "$src"/scripts/*.sh; do
      [ -f "$s" ] || continue
      base="$(basename "$s")"
      rules+=("Bash(~/.claude/skills/$name/scripts/$base)" "Bash(~/.claude/skills/$name/scripts/$base *)")
      rules+=("Bash($HOME/.claude/skills/$name/scripts/$base)" "Bash($HOME/.claude/skills/$name/scripts/$base *)")
    done
  done
  if [ $DRY -eq 1 ]; then printf '  [dry-run] %s\n' "${rules[@]}"
  else
    python3 - "$SETTINGS" "${rules[@]}" <<'PY'
import json, os, sys
path, rules = sys.argv[1], sys.argv[2:]
d = json.load(open(path)) if os.path.exists(path) else {}
allow = d.setdefault("permissions", {}).setdefault("allow", [])
added = [r for r in rules if r not in allow]
allow.extend(added)
json.dump(d, open(path, "w"), indent=2); open(path, "a").write("\n")
print(f"  added {len(added)} rules ({len(rules)-len(added)} already present)")
PY
  fi
fi
