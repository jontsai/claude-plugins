#!/usr/bin/env bash
# rescue.sh - gracefully quit and relaunch memory-hungry apps, then report swap before/after.
#
# A graceful quit preserves session state. Chromium browsers are relaunched with
# --restore-last-session so every tab comes back (lazily, unloaded until clicked) whatever the
# browser's "On startup" setting says; Slack/Notion reopen where they were on their own.
# Nothing is force-killed unless --force, and --force (SIGKILL) skips the relaunch if the app
# survives it. macOS: AppleScript quit + `open -a`. Linux (best-effort): SIGTERM + relaunch.
#
# Usage: rescue.sh [--dry-run] [--force] [--no-relaunch] <app> [<app>...]
#   app: brave | chrome | slack | notion | calendar | all   (or any exact app name)
#   all = brave slack notion calendar
#   --force: if an app is still running 45s after the graceful quit, SIGKILL it (unsaved
#            browser form state is lost; tabs still restore from the last saved session)

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
[ ${#APPS[@]} -eq 0 ] && { sed -n '2,16p' "$0"; exit 2; }

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
force_quit() {   # SIGKILL: the graceful path already failed, SIGTERM again would just hang on the same dialog
  if [ "$OS" = "Darwin" ]; then pkill -KILL -f "^/Applications/$1\.app/Contents/MacOS/"
  else for b in $(linux_bin "$1"); do pkill -KILL -x "$b" 2>/dev/null; done; fi
}
# Chromium honours --restore-last-session regardless of the "On startup" preference; Electron
# apps (Slack, Notion) restore their own window state and take no flag.
chromium() { case "$1" in "Brave Browser"|"Google Chrome"|"Chromium"|"Microsoft Edge"|"Vivaldi") return 0;; *) return 1;; esac; }
relaunch() {
  local args=(); chromium "$1" && args=(--restore-last-session)
  if [ "$OS" = "Darwin" ]; then
    if [ ${#args[@]} -gt 0 ]; then open -a "$1" --args "${args[@]}"; else open -a "$1"; fi
  else for b in $(linux_bin "$1"); do command -v "$b" >/dev/null && { nohup "$b" "${args[@]}" >/dev/null 2>&1 & return 0; }; done; return 1; fi
}

echo "swap before: $(swap)"
for app in "${APPS[@]}"; do
  if ! running "$app"; then echo "- $app: not running, skipping"; continue; fi
  if [ $DRY -eq 1 ]; then echo "- $app: would quit$( [ $RELAUNCH -eq 1 ] && echo ' and relaunch')"; continue; fi
  printf -- "- %s: quitting..." "$app"
  graceful_quit "$app"
  for _ in $(seq 1 45); do running "$app" || break; sleep 1; done
  if running "$app"; then
    if [ $FORCE -eq 0 ]; then echo " still running after 45s (unsaved-changes dialog?). Re-run with --force to kill."; continue; fi
    force_quit "$app"
    for _ in $(seq 1 10); do running "$app" || break; sleep 1; done
    if running "$app"; then echo " STILL RUNNING after SIGKILL; not relaunching (check Activity Monitor / ps)"; continue; fi
    echo " force-killed"
  else echo " done"; fi
  if [ $RELAUNCH -eq 1 ]; then sleep 2; relaunch "$app" && echo "  relaunched $app" || echo "  could not relaunch $app (open it manually)"; fi
done
sleep 5
echo "swap after:  $(swap)"
