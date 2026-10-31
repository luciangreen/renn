"""Parse pl2ann_io_pairs.md into pairs.json: program, domain, options, queries and outputs."""
import json, re, sys

src = sys.argv[1] if len(sys.argv) > 1 else "pl2ann_io_pairs.md"
text = open(src).read()
blocks = re.split(r"\n## (\d+)\. ", text)[1:]
pairs = []
for i in range(0, len(blocks), 2):
    n = int(blocks[i]); body = blocks[i + 1]
    title = body.split("\n", 1)[0].strip()
    cat = re.search(r"\*Category:\* `([^`]+)`", body).group(1)
    codes = re.findall(r"```(\w+)\n(.*?)```", body, re.S)
    prolog = [c for lang, c in codes if lang == "prolog"]
    program = prolog[0]
    domain = prolog[1] if "Domain file" in body and len(prolog) > 1 else None
    opts = re.search(r"Convert options: `([^`]*)`", body).group(1)
    opts = "" if opts.startswith("(defaults") else opts
    out = [c for lang, c in codes if lang == "text"][0]
    queries = []
    for m in re.finditer(r"\?- (.*?)  =>  (.*)", out):
        queries.append({"query": m.group(1).strip(), "answer": m.group(2).strip()})
    net = re.search(r"network: (\d+) atoms, (\d+) hidden.*?, (\d+) weighted edges, (\d+) strata; run: (\d+) active atoms after (\d+) rounds, fixpoint reached = (\w+)", out)
    err = re.search(r"^error: (.*)$", out, re.M)
    pairs.append({"id": n, "title": title, "category": cat, "program": program, "domain": domain,
                  "options": opts, "queries": queries,
                  "network": None if not net else dict(zip(
                      ["atoms", "hidden", "edges", "strata", "active", "rounds", "fixpoint"], net.groups())),
                  "error": err.group(1) if err else None})
json.dump(pairs, open("/home/claude/exp/pairs.json", "w"), indent=1)
print(len(pairs), "pairs;", sum(p["error"] is None for p in pairs), "with networks")
