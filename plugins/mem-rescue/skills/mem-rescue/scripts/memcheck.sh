#!/usr/bin/env bash
# memcheck.sh - one-shot memory pressure diagnosis for macOS and Linux.
#
# Prints a compact report: headline numbers, a verdict, per-app footprint,
# Chromium/Electron process load, leak suspects, recent crashes, and ranked actions.
# Read-only. Safe to run any time. Needs only bash, ps, and python3.
#
# Usage: memcheck.sh [--json]

set -u
MODE="${1:-text}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
OS="$(uname -s)"
echo "$OS" > "$TMP/os"

# ---------- collection: one pass per source, normalized into $TMP ----------
# procs.tsv columns: pid <TAB> mem_bytes <TAB> swapped_or_compressed_bytes <TAB> etime <TAB> comm
if [ "$OS" = "Darwin" ]; then
  sysctl -n hw.memsize                                   > "$TMP/memsize"
  sysctl -n vm.swapusage                                 > "$TMP/swap"
  top -l 1 -n 0 2>/dev/null | grep -E '^(PhysMem|Processes)' > "$TMP/top_hdr"
  memory_pressure 2>/dev/null | tail -1                  > "$TMP/pressure"
  ls /System/Volumes/VM/ 2>/dev/null | grep -c swapfile  > "$TMP/swapfiles"
  uptime                                                 > "$TMP/uptime"
  top -l 1 -o mem -n 400 -stats pid,mem,cmprs 2>/dev/null | awk '/^PID/{f=1;next} f' > "$TMP/top_procs"
  ps -axo pid=,etime=,comm=                              > "$TMP/ps"
  # join top (mem, cmprs) with ps (etime, comm) on pid
  awk -F'\t' 'NR==FNR { if ($1 ~ /^[0-9]+$/) { m[$1]=$2; c[$1]=$3 }; next }
       { if ($1 in m) printf "%s\t%s\t%s\t%s\t%s\n", $1, m[$1], c[$1], $2, $3 }' \
      <(awk '{print $1"\t"$2"\t"$3}' "$TMP/top_procs") \
      <(awk '{pid=$1; et=$2; $1=""; $2=""; sub(/^  */,""); print pid"\t"et"\t"$0}' "$TMP/ps") > "$TMP/procs.tsv"
  find ~/Library/Logs/DiagnosticReports -maxdepth 1 \( -name '*.ips' -o -name '*.crash' \) -mtime -1 2>/dev/null \
    | sed 's|.*/||' | sort -r | head -10               > "$TMP/crashes"
else
  cat /proc/meminfo                                      > "$TMP/meminfo"
  (swapon --show=NAME --noheadings 2>/dev/null || grep -v '^Filename' /proc/swaps) | grep -c . > "$TMP/swapfiles" || echo 0 > "$TMP/swapfiles"
  uptime                                                 > "$TMP/uptime"
  # rss in KB; VmSwap from /proc/<pid>/status (KB) when readable
  ps -eo pid=,rss=,etime=,comm= | while read -r pid rss et comm; do
    sw=$(awk '/^VmSwap:/{print $2}' "/proc/$pid/status" 2>/dev/null); sw=${sw:-0}
    printf "%s\t%s\t%s\t%s\t%s\n" "$pid" $((rss*1024)) $((sw*1024)) "$et" "$comm"
  done                                                   > "$TMP/procs.tsv"
  { command -v coredumpctl >/dev/null && coredumpctl list --since=-1d --no-pager --no-legend 2>/dev/null | awk '{print $NF" ("$1" "$2")"}' | tail -10
    ls -t /var/crash 2>/dev/null | head -5; } 2>/dev/null > "$TMP/crashes"
fi
ps -eo pid=,args= 2>/dev/null | grep -E -- '--type=(renderer|gpu|utility|zygote)' | grep -v grep > "$TMP/chromium" || true

# ---------- rendering ----------
python3 - "$TMP" "$MODE" <<'PY'
import sys, os, re, json, collections
tmp, mode = sys.argv[1], sys.argv[2]
rd = lambda n: open(os.path.join(tmp, n)).read() if os.path.exists(os.path.join(tmp, n)) else ""
OS = rd("os").strip()
GB = 1024**3

def mac_size(s):
    """top(1) sizes: 123K / 456M / 7.8G / 0B, optionally suffixed with + or -."""
    s = s.rstrip("+-")
    if s.endswith("B"): s = s[:-1] or "0"
    if not s or s[-1].isdigit(): return float(s)
    return float(s[:-1]) * {"K": 1024, "M": 1024**2, "G": 1024**3}[s[-1]]

def etime_days(et):
    d = 0
    if "-" in et: d, et = et.split("-"); d = int(d)
    parts = [int(x) for x in et.split(":")]
    while len(parts) < 3: parts.insert(0, 0)
    return d + (parts[0]*3600 + parts[1]*60 + parts[2]) / 86400

compressor = 0.0
if OS == "Darwin":
    ram = int(rd("memsize").strip()) / GB
    m = re.search(r"total = ([\d.]+)M\s+used = ([\d.]+)M", rd("swap"))
    swap_total, swap_used = (float(m.group(1))/1024, float(m.group(2))/1024) if m else (0.0, 0.0)
    hdr = rd("top_hdr")
    pm = re.search(r"PhysMem: (\S+) used \((\S+) wired(?:, (\S+) compressor)?\)", hdr)
    phys_used = mac_size(pm.group(1))/GB if pm else 0.0
    wired = mac_size(pm.group(2))/GB if pm else 0.0
    compressor = mac_size(pm.group(3))/GB if pm and pm.group(3) else 0.0
    pmatch = re.search(r"Processes: (\d+) total", hdr)
    nproc = int(pmatch.group(1)) if pmatch else 0
    fp = re.search(r"(\d+)%", rd("pressure"))
    free_pct = int(fp.group(1)) if fp else -1
    cmprs_label = "CMPRS"
    def parse_sizes(mem_s, c_s): return mac_size(mem_s)/GB, mac_size(c_s)/GB
else:
    mi = {k: int(v.split()[0])*1024 for k, v in
          (l.split(":", 1) for l in rd("meminfo").splitlines() if ":" in l)}
    ram = mi.get("MemTotal", 0)/GB
    avail = mi.get("MemAvailable", mi.get("MemFree", 0))/GB
    phys_used = ram - avail
    wired = (mi.get("Unevictable", 0) + mi.get("KernelStack", 0) + mi.get("Slab", 0))/GB
    swap_total = mi.get("SwapTotal", 0)/GB
    swap_used = swap_total - mi.get("SwapFree", 0)/GB
    compressor = mi.get("Zswapped", 0)/GB   # zswap only; zram is invisible here and counts as swap
    free_pct = int(avail/ram*100) if ram else -1
    nproc = sum(1 for _ in rd("procs.tsv").splitlines())
    cmprs_label = "SWAP"
    def parse_sizes(mem_s, c_s): return int(mem_s)/GB, int(c_s)/GB

swapfiles = int((rd("swapfiles").strip() or "0").split()[0])
up = re.search(r"up\s+(.+?),\s+\d+ users?", rd("uptime"))
uptime = up.group(1).strip() if up else rd("uptime").strip()

procs = {}
for line in rd("procs.tsv").splitlines():
    p = line.split("\t")
    if len(p) < 5: continue
    mem, cm = parse_sizes(p[1], p[2])
    procs[int(p[0])] = {"pid": int(p[0]), "mem": mem, "cmprs": cm, "etime": p[3],
                        "name": os.path.basename(p[4].strip()) or p[4].strip()}

def family(name):
    """Collapse helper processes onto their app: 'Brave Browser Helper (Renderer)' -> 'Brave'."""
    n = re.sub(r"\s+(Browser\s+)?Helper.*$", "", name)
    n = re.sub(r"\s+Browser$", "", n)
    n = re.sub(r"-(browser|bin|stable|beta)$", "", n)    # brave-browser, chrome-stable, firefox-bin
    return n or name

fam = collections.defaultdict(lambda: {"mem": 0.0, "cmprs": 0.0, "n": 0, "oldest": 0.0})
for pr in procs.values():
    f = fam[family(pr["name"])]
    f["mem"] += pr["mem"]; f["cmprs"] += pr["cmprs"]; f["n"] += 1
    f["oldest"] = max(f["oldest"], etime_days(pr["etime"]))
top_fam = sorted(fam.items(), key=lambda kv: -kv[1]["mem"])[:12]

chrom = collections.Counter(); chrom_by_app = collections.defaultdict(collections.Counter)
for line in rd("chromium").splitlines():
    pid_s, args = line.split(None, 1)
    t = re.search(r"--type=(\w+)", args).group(1)
    app = family(procs.get(int(pid_s), {}).get("name", "?"))
    chrom[t] += 1; chrom_by_app[app][t] += 1

big_helpers = sorted([p for p in procs.values() if p["mem"] >= 1.0 and
                      (re.search(r"Helper|renderer", p["name"]) or family(p["name"]) != p["name"])],
                     key=lambda p: -p["mem"])[:6]
leaks = sorted([p for p in procs.values() if p["mem"] >= 1.0 and etime_days(p["etime"]) >= 2
                and p["name"] not in ("kernel_task", "WindowServer", "Xorg", "gnome-shell")],
               key=lambda p: -p["mem"])

demand = phys_used + swap_used
# macOS allocates swapfiles on demand, so swap_total tracks swap_used and used/total is always
# high there; judge swap against installed RAM instead. Linux swap is a fixed partition/file,
# so "mostly full" is meaningful on that side only.
swap_full = OS != "Darwin" and swap_total >= 8 and swap_used > 0.6 * swap_total
if swap_full or swap_used > 0.5 * ram or (0 <= free_pct < 20):
    verdict = "CRITICAL"
elif swap_used > 6 or compressor > 0.3 * ram or (0 <= free_pct < 45):
    verdict = "STRAINED"
else:
    verdict = "OK"

actions = []
for name, f in top_fam:
    if name in ("kernel_task", "WindowServer", "Xorg", "gnome-shell", "systemd"): continue
    reason = None
    if f["mem"] >= 8 and f["n"] >= 20:
        reason = f"{f['n']} processes, {f['cmprs']/f['mem']*100:.0f}% {cmprs_label.lower()}ped out -> mostly idle tabs"
    elif f["mem"] >= 1.0 and f["oldest"] >= 2:
        reason = f"over 1 GB and running {f['oldest']:.1f} days -> likely unbounded growth"
    if reason: actions.append({"app": name, "recover_gb": round(f["mem"]*0.85, 1), "why": reason})
actions.sort(key=lambda a: -a["recover_gb"])

report = {
    "os": OS, "verdict": verdict, "ram_gb": round(ram), "phys_used_gb": round(phys_used, 1),
    "wired_gb": round(wired, 1), "compressor_gb": round(compressor, 1),
    "swap_used_gb": round(swap_used, 1), "swap_total_gb": round(swap_total, 1),
    "swapfiles": swapfiles, "free_pct": free_pct, "demand_gb": round(demand, 1),
    "uptime": uptime, "processes": nproc,
    "apps": [{"app": n, "mem_gb": round(f["mem"], 1), "cmprs_gb": round(f["cmprs"], 1),
              "procs": f["n"], "oldest_days": round(f["oldest"], 1)} for n, f in top_fam],
    "chromium_procs": dict(chrom),
    "chromium_by_app": {a: dict(c) for a, c in chrom_by_app.items() if sum(c.values()) >= 5},
    "big_helpers": [{"pid": p["pid"], "name": p["name"], "mem_gb": round(p["mem"], 1),
                     "cmprs_gb": round(p["cmprs"], 1), "etime": p["etime"]} for p in big_helpers],
    "leak_suspects": [{"pid": p["pid"], "name": p["name"], "mem_gb": round(p["mem"], 1),
                       "days": round(etime_days(p["etime"]), 1)} for p in leaks],
    "recent_crashes": [c for c in rd("crashes").splitlines() if c.strip()],
    "actions": actions,
}
if mode == "--json":
    print(json.dumps(report, indent=1)); sys.exit()

print(f"=== MEMORY CHECK ({OS}): {verdict} ===")
print(f"RAM {ram:.0f} GB | used {phys_used:.1f} GB (wired {wired:.1f}, compressor {compressor:.1f}) | "
      f"swap {swap_used:.1f}/{swap_total:.1f} GB in {swapfiles} files | free {free_pct}% | demand {demand:.1f} GB")
print(f"uptime {uptime} | {nproc} processes")
print()
print(f"{'APP':<22}{'TOTAL':>8}{cmprs_label:>8}{'PROCS':>7}{'OLDEST':>9}")
for n, f in top_fam:
    print(f"{n[:21]:<22}{f['mem']:>7.1f}G{f['cmprs']:>7.1f}G{f['n']:>7}{f['oldest']:>7.1f}d")
if chrom:
    print(); print("Chromium/Electron process load:", ", ".join(f"{k}={v}" for k, v in chrom.most_common()))
    for a, c in report["chromium_by_app"].items():
        print(f"  {a}: " + ", ".join(f"{k}={v}" for k, v in sorted(c.items())))
if big_helpers:
    print(); print("Largest helper/renderer processes (>=1 GB):")
    for h in report["big_helpers"]:
        print(f"  pid {h['pid']:<7}{h['mem_gb']:>5.1f}G ({h['cmprs_gb']:.1f}G {cmprs_label.lower()}) {h['etime']:>12}  {h['name']}")
if leaks:
    print(); print("Leak suspects (>=1 GB and alive >=2 days):")
    for l in report["leak_suspects"]:
        print(f"  pid {l['pid']:<7}{l['mem_gb']:>5.1f}G  {l['days']:.1f}d  {l['name']}")
if report["recent_crashes"]:
    print(); print("Crash reports in last 24h:")
    for c in report["recent_crashes"]: print("  " + c)
print()
if actions:
    print("Ranked actions (est. recoverable):")
    for i, a in enumerate(actions, 1):
        print(f"  {i}. restart {a['app']:<18} ~{a['recover_gb']:>5.1f} GB   {a['why']}")
else:
    print("No single app stands out. If the verdict is not OK, a reboot is the remaining lever.")
if swapfiles >= 10 or swap_used > 10:
    print(f"  +  reboot when convenient: {swapfiles} swapfiles / {swap_used:.0f} GB swap after {uptime} uptime")
PY
