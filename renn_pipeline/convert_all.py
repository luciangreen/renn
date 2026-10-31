"""Stage 0: compile every pair's source program to a network with pl2ann (CLI), exporting weights as JSON."""
import json, os, subprocess, shlex

PL2ANN = "/home/claude/pl2ann"
OUT = "/home/claude/exp/nets"
os.makedirs(OUT, exist_ok=True)
pairs = json.load(open("/home/claude/exp/pairs.json"))
ok = bad = 0
for p in pairs:
    if p["error"]:
        continue
    d = f"{OUT}/{p['id']}"; os.makedirs(d, exist_ok=True)
    open(f"{d}/src.pl", "w").write(p["program"])
    cmd = ["swipl", "bin/prolog2ann.pl", "convert", f"{d}/src.pl"]
    if p["domain"]:
        open(f"{d}/domain.pl", "w").write(p["domain"]); cmd += ["--domain", f"{d}/domain.pl"]
    cmd += shlex.split(p["options"])
    cmd += ["--out", f"{d}/net.pl", "--module", f"net{p['id']}", "--json", f"{d}/net.json"]
    r = subprocess.run(cmd, cwd=PL2ANN, capture_output=True, text=True, timeout=600)
    if r.returncode == 0 and os.path.exists(f"{d}/net.json"):
        ok += 1
    else:
        bad += 1; print("FAIL", p["id"], r.stderr[-300:])
print("converted", ok, "failed", bad)
