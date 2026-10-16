#!/usr/bin/env bash
# rescue.sh - gracefully quit and relaunch memory-hungry apps, then report swap before/after.
#
# A graceful quit preserves session state: Chromium browsers restore tabs lazily (unloaded
# until clicked), Slack/Notion reopen where they were. Nothing is force-killed unless --force.
# macOS: AppleScript quit + `open -a`.  Linux (best-effort): SIGTERM to the main process + relaunch.
#
# Usage: rescue.sh [--dry-run] [--force] [--no-relaunch] <app> [<app>...]
#   app: brave | chrome | slack | notion | calendar | all   (or any exact app name)
#   all = brave slack notion calendar

set -u
DRY=0; FORCE=0; RELAUNCH=1; APPS=()
OS="$(uname -s)"
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1;; --force) FORCE=1;; --no-relaunch) RELAUNCH=0;;
    brave)    APPS+=("Brave Browser");;
    chrome)   APPS+=("Google Chrome");;
    slack)    APPS+=("Slack");;
    notion)   APPS+=("Notion");;
    calendar) APPS+=("Notion Calendar");;
    all)      APPS+=("Brave Browser" "Slack" "Notion" "Notion Calendar");;
    *)        APPS+=("$a");;
  esac
done
[ ${#APPS[@]} -eq 0 ] && { sed -n '2,12p' "$0"; exit 2; }

# Linux process/launch names for the friendly app names above.
linux_bin() {
  case "$1" in
    "Brave Browser") echo "brave-browser brave";;
    "Google Chrome") echo "google-chrome chrome";;
    "Slack")         echo "slack";;
    "Notion")        echo "notion-app notion";;
    *)               echo "$(echo "$1" | tr 'A-Z ' 'a-z-')";;
  esac
}

swap() {
  if [ "$OS" = "Darwin" ]; then sysctl -n vm.swapusage | sed -E 's/.*used = ([0-9.]+)M.*/\1/' | awk '{printf "%.1f GB", $1/1024}'
  else awk '/^SwapTotal/{t=$2}/^SwapFree/{f=$2}END{printf "%.1f GB",(t-f)/1048576}' /proc/meminfo; fi
}
running() {
  if [ "$OS" = "Darwin" ]; then pgrep -q -f "^/Applications/$1\.app/Contents/MacOS/"
  else for b in $(linux_bin "$1"); do pgrep -x -q "$b" && return 0; done; return 1; fi
}
graceful_quit() {
  if [ "$OS" = "Darwin" ]; then osascript -e "tell application \"$1\" to quit" >/dev/null 2>&1
  else for b in $(linux_bin "$1"); do pkill -TERM -o -x "$b" 2>/dev/null; done; fi   # -o: oldest = main process
}
force_quit() {
  if [ "$OS" = "Darwin" ]; then pkill -f "^/Applications/$1\.app/Contents/MacOS/"
  else for b in $(linux_bin "$1"); do pkill -x "$b" 2>/dev/null; done; fi
}
relaunch() {
  if [ "$OS" = "Darwin" ]; then open -a "$1"
  else for b in $(linux_bin "$1"); do command -v "$b" >/dev/null && { nohup "$b" >/dev/null 2>&1 & return 0; }; done; return 1; fi
}

echo "swap before: $(swap)"
for app in "${APPS[@]}"; do
  if ! running "$app"; then echo "- $app: not running, skipping"; continue; fi
  if [ $DRY -eq 1 ]; then echo "- $app: would quit$( [ $RELAUNCH -eq 1 ] && echo ' and relaunch')"; continue; fi
  printf -- "- %s: quitting..." "$app"
  graceful_quit "$app"
  for _ in $(seq 1 45); do running "$app" || break; sleep 1; done
  if running "$app"; then
    if [ $FORCE -eq 1 ]; then force_quit "$app"; sleep 2; echo " force-killed"
    else echo " still running after 45s (unsaved-changes dialog?). Re-run with --force to kill."; continue; fi
  else echo " done"; fi
  if [ $RELAUNCH -eq 1 ]; then sleep 2; relaunch "$app" && echo "  relaunched $app" || echo "  could not relaunch $app (open it manually)"; fi
done
sleep 5
echo "swap after:  $(swap)"
