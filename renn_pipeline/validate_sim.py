"""Check the weights-only simulator against the dataset: rebuilt network sizes and every query answer."""
import json
from netlib import Net, parse, show, match, split_list

pairs = json.load(open("/home/claude/exp/pairs.json"))
size_ok = ans_ok = ans_n = 0; bad = []
for p in pairs:
    if p["error"]: continue
    net = Net(f"/home/claude/exp/nets/{p['id']}/net.json")
    nh = len(net.hidden); ne = sum(len(v) for v in net.inc.values())
    if str(len(net.atoms)) == p["network"]["atoms"] and str(nh) == p["network"]["hidden"] and str(ne) == p["network"]["edges"]:
        size_ok += 1
    else:
        bad.append((p["id"], "size", len(net.atoms), nh, ne, p["network"]))
    if p["network"]["fixpoint"] != "true": continue
    model, _ = net.forward(net.true_input)
    obs = net.observation_from_queries(p["queries"])
    for a, v in obs.items():
        ans_n += 1
        if (a in model) == v: ans_ok += 1
        else: bad.append((p["id"], a, v))
print(f"network sizes reproduced: {size_ok}/{sum(1 for p in pairs if not p['error'])}")
print(f"query literals reproduced by weights-only simulator: {ans_ok}/{ans_n}")
print(bad[:15])
