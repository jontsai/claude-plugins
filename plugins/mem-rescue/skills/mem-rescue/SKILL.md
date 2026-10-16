---
name: mem-rescue
description: Diagnose and fix memory pressure on a Mac (Linux best-effort) in one or two commands. Use whenever the user says their machine is slow, laggy, beachballing, out of memory, swapping, "swap is full", has low free memory, or that apps or browser tabs are crashing, failing to open, or being killed, even if they never say "memory". Also use for "what's eating my RAM", "why is my computer so slow", "is it safe to reboot", or any request to restart Brave, Chrome, Slack, or Notion to free memory. One read-only script gives the whole diagnosis; one script does the graceful restarts.
---

# mem-rescue

Two bundled scripts replace the dozen ad-hoc `top`, `ps`, and `vm_stat` calls a memory
diagnosis normally takes. Both live in this skill's `scripts/` directory; run them from the
directory this skill was loaded from (the loader tells you where that is). Running them by
path, with no shell pipeline around them, also lets the user allowlist them once in their
agent so they never prompt.

## 1. Diagnose (read-only, always safe)

```bash
scripts/memcheck.sh          # human report
scripts/memcheck.sh --json   # same data, machine-readable
```

Output: a verdict (OK / STRAINED / CRITICAL), the headline numbers, memory by app family,
Chromium/Electron process counts, the largest renderer processes, leak suspects, crash reports
from the last 24h, and ranked restart actions with estimated recoverable memory.

Run it once, read it, and go straight to the answer. Don't re-derive the numbers with your own
`top` or `ps` calls unless the report is missing something specific.

## 2. Rescue (quits and relaunches apps; confirm first)

```bash
scripts/rescue.sh --dry-run brave slack   # shows what would happen
scripts/rescue.sh brave slack             # does it
scripts/rescue.sh all                     # brave slack notion calendar
```

Quits are graceful, so Chromium browsers restore their tabs lazily and Slack/Notion reopen
where they were. The script never force-kills unless given `--force`, and it reports swap
before and after.

Quitting the user's browser or chat client interrupts their work. Unless the user already
told you to restart things ("restart brave", "go ahead and rescue it"), show the ranked
actions from the report and ask which ones to run. When they say yes, run rescue once, then
run memcheck again and show the before/after.

## Reading the report

- **Verdict CRITICAL** means swap is mostly full or free memory is under 20%. New processes
  (browser tabs, renderers) fail to launch because the compressor and swap have nowhere to put
  pages. The fix is "shed the biggest app family", not "close a few things".
- **Demand** is physical used plus swap used. When demand is far above installed RAM, the
  workload simply doesn't fit, and restarting the top app is the only quick lever.
- **High CMPRS (or SWAP) relative to TOTAL** on a browser means most tabs are idle background
  tabs that have been compressed or swapped out. A restart recovers nearly all of it because
  tabs come back as unloaded placeholders. Suggest enabling the browser's Memory Saver
  (`brave://settings/system`, `chrome://settings/performance`) so it discards idle tabs itself.
- **Leak suspects** are single processes over 1 GB that have run for 2+ days. Electron
  renderers (Slack, Notion, Discord) grow unbounded; a relaunch resets them to a few hundred MB.
- **Many swapfiles after days of uptime** means the compressor is fragmented. macOS does shrink
  swap once memory is freed, so a reboot is a "when convenient" item, not an emergency.
- **Crash reports** for the browser at the time the user reported tab failures confirm memory
  starvation rather than a browser bug. On macOS the `.ips` file's `parentProc` field shows
  who launched the crashed process; if it was an automation agent, say so.

## Answer format

Lead with the verdict and the one or two numbers that matter (swap used, free %, biggest
app). Then the ranked actions as a short list. Keep the full table out of the message unless
the user asks; they can run memcheck themselves. After a rescue, show a before/after table
with swap, compressor, free %, and the restarted app's footprint.
