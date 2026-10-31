"""Stage 1b: trivial, edge and interesting inversion cases, each compiled from Prolog with pl2ann."""
import json, os, subprocess
from netlib import Net, pred
from renn_invert import report

REACH = "reach(X, Y) :- edge(X, Y).\nreach(X, Y) :- edge(X, Z), reach(Z, Y).\n"
FLIES = "flies(X) :- bird(X), \\+ penguin(X).\n"

def compile_net(name, prog, opts=()):
    d = f"/home/claude/exp/cases/{name}"; os.makedirs(d, exist_ok=True)
    open(f"{d}/src.pl", "w").write(prog)
    r = subprocess.run(["swipl", "bin/prolog2ann.pl", "convert", f"{d}/src.pl", *opts, "--out", f"{d}/net.pl",
                        "--module", f"c_{name}", "--json", f"{d}/net.json"], cwd="/home/claude/pl2ann",
                       capture_output=True, text=True)
    assert r.returncode == 0, r.stderr
    return Net(f"{d}/net.json")

def full(net, true_atoms):
    return {a: (a in true_atoms) for a in net.atoms if pred(a) not in net.edb_preds}

cases = []
def case(name, kind, prog, obs_fn, note, opts=()):
    net = compile_net(name, prog, opts)
    obs = obs_fn(net)
    missing = [a for a in obs if a not in net.atoms]
    if missing:
        cases.append({"case": name, "kind": kind, "note": note, "status": "no such output neuron", "missing": missing}); return
    r = report(net, obs, net.true_input)
    r.update({"case": name, "kind": kind, "note": note, "observation": {a: v for a, v in obs.items() if v},
              "n_obs": len(obs), "original_input": net.true_input})
    cases.append(r)

# trivial
case("T1_single_edge", "trivial", "edge(a, b).\n" + REACH,
     lambda n: {"reach(a,b)": True}, "one output, one input")
case("T2_and_gate", "trivial", "bit(0).\nbit(1).\nand(X, Y) :- bit(X), bit(Y), X = 1, Y = 1.\n",
     lambda n: {"and(1,1)": True}, "AND gate output needs bit(1) only")
# edge cases
case("E1_empty_output", "edge", "edge(a, b).\nedge(b, c).\n" + REACH,
     lambda n: full(n, set()), "nothing active: the empty input explains it")
case("E2_impossible_output", "edge", "edge(a, b).\nedge(b, c).\n" + REACH,
     lambda n: {"reach(a,b)": True, "reach(b,c)": True, "reach(a,c)": False},
     "not transitively closed, so no input can produce it")
case("E3_self_loop", "edge", "edge(a, a).\nedge(b, c).\n" + REACH,
     lambda n: full(n, {"reach(a,a)", "reach(b,c)"}), "a self-reach needs a cycle")
case("E4_unknown_neuron", "edge", "edge(a, b).\n" + REACH,
     lambda n: {"reach(a,z)": True}, "observation names an atom the network has no neuron for")
case("E5_exception_hidden", "edge", "bird(tweety).\nbird(pingu).\npenguin(pingu).\n" + FLIES,
     lambda n: {"flies(tweety)": True, "flies(pingu)": False},
     "negation: a silent exception is dropped by minimality")
case("E6_exception_revealed", "edge", "bird(tweety).\nbird(pingu).\npenguin(pingu).\n" + FLIES,
     lambda n: {"flies(tweety)": True, "flies(pingu)": False, "bird(pingu)": True},
     "observing one input forces the exception back")
case("E7_step_limited", "edge", "edge(a, b).\nedge(b, c).\n" + REACH,
     lambda n: {"reach(a,c)": True}, "network built with --step-limit 1; weights carry no step limit",
     opts=("--step-limit", "1"))
# interesting
case("I1_shortcut_lost", "interesting", "edge(a, b).\nedge(b, c).\nedge(a, c).\n" + REACH,
     lambda n: full(n, {"reach(a,b)", "reach(b,c)", "reach(a,c)"}), "the shortcut edge is invisible in the output")
case("I2_cycle_ambiguity", "interesting", "edge(a, b).\nedge(b, c).\nedge(c, a).\n" + REACH,
     lambda n: full(n, {f"reach({x},{y})" for x in "abc" for y in "abc"}), "a full closure has several minimal cycles")
case("I3_xor", "interesting", "bit(0).\nbit(1).\nsame(X, Y) :- bit(X), bit(Y), X = Y.\nxor(X, Y) :- bit(X), bit(Y), \\+ same(X, Y).\n",
     lambda n: {"xor(0,1)": True}, "XOR true needs both bits present")
case("I4_grandparent", "interesting", "parent(ann, bob).\nparent(bob, cy).\nparent(ann, dee).\ngrandparent(X, Y) :- parent(X, Z), parent(Z, Y).\n",
     lambda n: full(n, {"grandparent(ann,cy)"}), "the middle person must be invented")

json.dump(cases, open("/home/claude/exp/results/stage1_cases.json", "w"), indent=1)
for c in cases:
    print(c["case"], c.get("status"), "min", c.get("min_size"), "n", c.get("n_explanations"),
          "orig", c.get("orig_size"), "origMin", c.get("orig_is_minimal_explanation"), c.get("explanations", [])[:4])
