"""Stage 2b: pool the recovered inputs and outputs of all networks that share a program shape, then learn once.

Each network's constants are renamed apart (g<id>_<const>) so graphs do not merge."""
import json, os, re, itertools
from netlib import Net, pred, parse, show
from renn_invert import invert
from datalog import parse_program, least_model, agreement
from stage2_popper import pairs, task_of, TASKS, run_popper

def rename(atom, pid):
    return re.sub(r"(?<=[(,])([a-z]\w*)", lambda m: f"g{pid}_{m.group(1)}", atom)

def pooled(task, regime, timeout=300):
    target, ar, body, extra = TASKS[task]
    ids = [i for i, p in pairs.items() if not p["error"] and task_of(p) == task]
    bk, exs = [], {}
    for pid in ids:
        net = Net(f"/home/claude/exp/nets/{pid}/net.json")
        full_model, _ = net.forward(net.true_input)
        idb = [a for a in net.atoms if pred(a) not in net.edb_preds]
        obs = {a: (a in full_model) for a in idb} if regime == "F" else net.observation_from_queries(pairs[pid]["queries"])
        inp = invert(net, obs, cap=1)["explanations"][0]
        model, _ = net.forward(inp)
        cs = sorted({show(x) for a in net.atoms if parse(a)[0] == "cmp" for x in parse(a)[2]})
        if regime == "F":
            e = {f"{target}({','.join(t)})": None for t in itertools.product(cs, repeat=ar)}
            e = {a: (a in model) for a in e}
        else:
            e = {a: v for a, v in obs.items() if pred(a) == (target, ar)}
        bk += [rename(a, pid) + "." for a in inp]
        if "neq/2" in body:
            bk += [f"neq(g{pid}_{x},g{pid}_{y})." for x in cs for y in cs if x != y]
        exs.update({rename(a, pid): v for a, v in e.items()})
    d = f"/home/claude/exp/popper/pool_{task.replace('/', '_').replace(':', '_')}_{regime}"
    os.makedirs(d, exist_ok=True)
    open(f"{d}/bk.pl", "w").write("\n".join(sorted(set(bk)) + [f":- dynamic {b}." for b in body]) + "\n")
    open(f"{d}/exs.pl", "w").write("\n".join(f"{'pos' if v else 'neg'}({a})." for a, v in sorted(exs.items())) + "\n")
    open(f"{d}/bias.pl", "w").write(f"head_pred({target},{ar}).\n" + "".join(f"body_pred({b.split('/')[0]},{b.split('/')[1]}).\n" for b in body) + extra)
    prog, stats, secs = run_popper(d, timeout)
    res = {"task": task, "regime": regime, "networks": len(ids), "n_pos": sum(exs.values()),
           "n_neg": len(exs) - sum(exs.values()), "popper": prog, "stats": stats, "seconds": secs}
    if prog:
        orig = [c for c in parse_program(pairs[ids[0]]["program"]) if c[1]]
        learned = parse_program(prog.replace("neq(", "neq_("))
        learned = [(h, [("neq", l[1][2][0], l[1][2][1]) if l[0] == "pos" and l[1][1] == "neq_" else l for l in b]) for h, b in learned]
        edb = [(b.split('/')[0], int(b.split('/')[1])) for b in body if b != "neq/2"]
        res["agreement_random_inputs"] = agreement(orig, learned, edb, ["a", "b", "c", "d", "e"], {(target, ar)}, trials=200)
    print(res["task"], regime, (prog or "NONE").replace("\n", " | "), res.get("agreement_random_inputs"), secs, flush=True)
    return res

if __name__ == "__main__":
    out = [pooled(t, r) for t in ["recursion/reachability", "relations/family:ancestor", "relations/family:sibling",
                                  "relations/family:grandparent", "negation/stratified"] for r in ("F", "Q")]
    json.dump(out, open("/home/claude/exp/results/stage2_pool.json", "w"), indent=1)
