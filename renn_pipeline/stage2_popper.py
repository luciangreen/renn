"""Stage 2: Popper learns code from (recovered input, network output).

Background knowledge = the minimal input recovered from the weights in Stage 1 (first explanation).
Examples = the network's output on that input: regime F uses every output atom of the target
predicate (true -> pos, false -> neg); regime Q uses only the dataset's own query answers."""
import json, os, subprocess, sys, re, time
from concurrent.futures import ThreadPoolExecutor
from netlib import Net, pred, parse, show
from renn_invert import invert
from datalog import parse_program, least_model, agreement

POPPER = "/home/claude/pop_v2.1.0/popper.py"
ENV = dict(os.environ, PYTHONPATH="/home/claude/build/pyswip/src")
pairs = {p["id"]: p for p in json.load(open("/home/claude/exp/pairs.json"))}

TASKS = {  # category -> (target, body preds, bias extras)
    "recursion/reachability": ("reach", 2, ["edge/2"], "enable_recursion.\nmax_vars(3).\nmax_body(2).\nmax_clauses(2).\n"),
    "relations/family:ancestor": ("ancestor", 2, ["parent/2"], "enable_recursion.\nmax_vars(3).\nmax_body(2).\nmax_clauses(2).\n"),
    "relations/family:grandparent": ("grandparent", 2, ["parent/2"], "max_vars(3).\nmax_body(2).\n"),
    "relations/family:sibling": ("sibling", 2, ["parent/2", "neq/2"], "max_vars(3).\nmax_body(3).\n"),
    "negation/stratified": ("flies", 1, ["bird/1", "penguin/1", "injured/1", "abnormal/1"], "max_vars(2).\nmax_body(3).\n"),
}

def task_of(p):
    if p["category"] == "relations/family":
        for t in ("ancestor", "grandparent", "sibling"):
            if t + "(" in p["program"]: return "relations/family:" + t
    return p["category"] if p["category"] in TASKS else None

def run_popper(d, timeout=120):
    t = time.time()
    try:
        r = subprocess.run(["timeout", str(timeout + 30), "python3", POPPER, d, "--timeout", str(timeout)],
                           capture_output=True, text=True, env=ENV, timeout=timeout + 60)
        out = r.stdout + r.stderr
    except subprocess.TimeoutExpired:
        out = ""
    m = re.search(r"\*+ SOLUTION \*+\n(.*?)\n(.*?)\*{10,}", out, re.S)
    if not m: return None, None, round(time.time() - t, 1)
    stats = m.group(1)
    prog = "\n".join(l.strip() for l in m.group(2).strip().splitlines() if l.strip())
    return prog, stats, round(time.time() - t, 1)

def one(pid, regime):
    p = pairs[pid]; tk = task_of(p)
    target, ar, body, extra = TASKS[tk]
    net = Net(f"/home/claude/exp/nets/{pid}/net.json")
    full_model, _ = net.forward(net.true_input)
    idb = [a for a in net.atoms if pred(a) not in net.edb_preds]
    obs = {a: (a in full_model) for a in idb} if regime == "F" else net.observation_from_queries(p["queries"])
    r = invert(net, obs, cap=1)
    inp = r["explanations"][0]
    model, _ = net.forward(inp)
    tgt_atoms = [a for a in net.atoms if pred(a) == (target, ar)]
    if regime == "F":
        # closed world: every tuple of constants is an example; atoms with no neuron can never fire
        import itertools
        cs = sorted({show(x) for a in net.atoms if parse(a)[0] == "cmp" for x in parse(a)[2]})
        alltup = [f"{target}({','.join(t)})" for t in itertools.product(cs, repeat=ar)]
        exs = {a: (a in model) for a in alltup}
    else:
        exs = {a: v for a, v in obs.items() if pred(a) == (target, ar)}
    d = f"/home/claude/exp/popper/{pid}_{regime}"; os.makedirs(d, exist_ok=True)
    consts = sorted({show(x) for a in net.atoms if parse(a)[0] == "cmp" for x in parse(a)[2]})
    bk = [a + "." for a in inp]
    if "neq/2" in body:
        bk += [f"neq({x},{y})." for x in consts for y in consts if x != y]
    # Popper needs every body predicate declared in BK, even if the recovered input has none of it
    bk += [f":- dynamic {b}." for b in body]
    open(f"{d}/bk.pl", "w").write("\n".join(bk) + "\n")
    open(f"{d}/exs.pl", "w").write("\n".join(f"{'pos' if v else 'neg'}({a})." for a, v in sorted(exs.items())) + "\n")
    open(f"{d}/bias.pl", "w").write(f"head_pred({target},{ar}).\n" + "".join(f"body_pred({b.split('/')[0]},{b.split('/')[1]}).\n" for b in body) + extra)
    prog, stats, secs = run_popper(d)
    res = {"id": pid, "task": tk, "regime": regime, "n_pos": sum(exs.values()), "n_neg": len(exs) - sum(exs.values()),
           "input_size": len(inp), "orig_input_size": len(net.true_input), "popper": prog, "stats": stats, "seconds": secs}
    if prog:
        orig_rules = [c for c in parse_program(p["program"]) if c[1]]
        learned = parse_program(prog.replace("neq(", "neq_(") )
        learned = [(h, [("neq", l[1][2][0], l[1][2][1]) if l[0] == "pos" and l[1][0] == "cmp" and l[1][1] == "neq_" else l for l in b]) for h, b in learned]
        # does the learned code reproduce the network on the ORIGINAL (unrecovered) input?
        m_net = {a for a in full_model if pred(a) == (target, ar)}
        m_learn = {a for a in least_model(learned, net.true_input) if pred(a) == (target, ar)}
        res["reproduces_network_on_original_input"] = m_net == m_learn
        edb = sorted({pred(a) for a in net.edb_atoms if pred(a)[0] in [x.split('/')[0] for x in body if x != "neq/2"]})
        cs = sorted({x for a in net.atoms for x in re.findall(r"[a-z]\w*", a.split("(", 1)[1]) } if "(" in net.atoms[0] else [])
        res["agreement_random_inputs"] = agreement(orig_rules, learned, edb, cs[:6], {(target, ar)}, trials=100)
    print(pid, regime, tk, (prog or "NO SOLUTION").replace("\n", " | "), res.get("reproduces_network_on_original_input"), res.get("agreement_random_inputs"), secs, flush=True)
    return res

if __name__ == "__main__":
    ids = [pid for pid, p in pairs.items() if not p["error"] and task_of(p)]
    if len(sys.argv) > 1: ids = [int(x) for x in sys.argv[1].split(",")]
    jobs = [(i, r) for i in ids for r in ("F", "Q")]
    with ThreadPoolExecutor(2) as ex:
        results = list(ex.map(lambda j: one(*j), jobs))
    out = "/home/claude/exp/results/stage2.json" if len(sys.argv) == 1 else "/home/claude/exp/results/stage2_probe.json"
    json.dump(results, open(out, "w"), indent=1)
