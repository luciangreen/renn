"""Stage 1 over the dataset (regime Q: the dataset's own query answers; regime F: the full output layer)
plus hand-built trivial, edge and interesting cases. Writes results/stage1.json."""
import json, os, time
from netlib import Net, pred
from renn_invert import report

os.makedirs("/home/claude/exp/results", exist_ok=True)
pairs = json.load(open("/home/claude/exp/pairs.json"))
rows = []
for p in pairs:
    if p["error"] or p["network"]["fixpoint"] != "true": continue
    net = Net(f"/home/claude/exp/nets/{p['id']}/net.json")
    if not net.edb_atoms:
        rows.append({"id": p["id"], "category": p["category"], "closed": True}); continue
    full_model, _ = net.forward(net.true_input)
    idb = [a for a in net.atoms if pred(a) not in net.edb_preds]
    for regime, obs in (("Q", net.observation_from_queries(p["queries"])),
                        ("F", {a: (a in full_model) for a in idb})):
        t = time.time()
        r = report(net, obs, net.true_input, cap=500)
        r.update({"id": p["id"], "category": p["category"], "regime": regime, "n_obs": len(obs),
                  "n_edb_atoms": len(net.edb_atoms), "seconds": round(time.time() - t, 3)})
        rows.append(r)
    print(p["id"], p["category"], [ (x["regime"], x["status"], x["min_size"], x["orig_size"], x["n_explanations"], x["orig_is_minimal_explanation"]) for x in rows[-2:]], flush=True)
json.dump(rows, open("/home/claude/exp/results/stage1.json", "w"), indent=1)
