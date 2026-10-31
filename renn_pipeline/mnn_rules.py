"""Run the full method on each MNN optimisation rule: S2A, Starlog, PID, loop2, PLOp, AlgebraPLOp, Detlog, Piglog2.

For each rule: compile the ORIGINAL program with pl2ann; prove the net matches the Prolog; find the input
from the net's output; let Popper learn code from that input/output; prove what Popper's code is
equivalent to; then let Spec to Algorithm learn the rule's rewrite (original -> optimised) from two
renamed examples and apply it to two unseen renamed programs, proving each result equivalent."""
import json, re, sys
from pipeline import *
from netlib import pred

D = "/home/claude/research/datalog"

RULES = {
 "s2a": dict(title="Spec to Algorithm: generalise examples into address mappings",
     targets=[("out1", 2), ("out2", 2)],
     popper=[dict(label="out1", head=("out1", 2), body=["in1/2", "in2/2"], extra="max_vars(2).\nmax_body(1).\n"),
             dict(label="out2", head=("out2", 2), body=["in1/2", "in2/2"], extra="max_vars(2).\nmax_body(1).\n")],
     edb=["in1/2", "in2/2"], consts=["e1", "e2"], rename=["in1", "in2", "out1", "out2"]),
 "starlog": dict(title="Starlog: nest single-use intermediate results",
     targets=[("r", 2)],
     popper=[dict(label="base predicates", head=("r", 2), body=["f/2", "g/2", "h/2"], extra="max_vars(4).\nmax_body(3).\n")],
     edb=["f/2", "g/2", "h/2"], consts=["a", "b", "c"], rename=["f", "g", "h", "t1", "t2", "r"]),
 "pid": dict(title="Prolog Inductive Debugger: drop no-progress recursion, recurse after progress",
     targets=[("path", 2)],
     popper=[dict(label="recursive", head=("path", 2), body=["edge/2"], extra="enable_recursion.\nmax_vars(3).\nmax_body(2).\nmax_clauses(2).\n")],
     edb=["edge/2"], consts=["a", "b", "c"], rename=["edge", "path"]),
 "loop2b": dict(title="loop2: splice the generator into its caller",
     targets=[("col", 1)],
     popper=[dict(label="generator and wrapper available", head=("col", 1), body=["colour/1", "q/1"], extra="max_vars(1).\nmax_body(1).\n"),
             dict(label="generator only", head=("col", 1), body=["colour/1"], extra="max_vars(1).\nmax_body(1).\n")],
     edb=["colour/1"], consts=["red", "blue", "green"], rename=["colour", "q", "col"]),
 "plop": dict(title="PLOp: unfold helpers and compute the shared call once",
     targets=[("report", 2)],
     popper=[dict(label="base predicates only", head=("report", 2), body=["sub/2", "fin/2", "good/1", "lab/2"], extra="max_vars(4).\nmax_body(4).\n"),
             dict(label="helpers also available", head=("report", 2), body=["sub/2", "fin/2", "good/1", "lab/2", "exp/2", "row1/2", "row2/2"], extra="max_vars(4).\nmax_body(4).\n")],
     edb=["sub/2", "fin/2", "good/1", "lab/2"], consts=["a", "s1", "v1"], rename=["sub", "fin", "good", "lab", "exp", "row1", "row2", "report"]),
 "algebraplop": dict(title="AlgebraPLOp: replace a recurrence by its closed form and inverse",
     domain="range(n,0,9).\n", targets=[("val", 2), ("at", 2)],
     popper=[dict(label="val without arithmetic", head=("val", 2), body=["pos/1"], extra="max_vars(3).\nmax_body(3).\n"),
             dict(label="at from val", head=("at", 2), body=["val/2", "pos/1"], extra="max_vars(2).\nmax_body(1).\n")],
     edb=["pos/1"], consts=["0", "1", "2"], rename=["pos", "val", "at"]),
 "detlog": dict(title="Detlog: turn the cut's otherwise-branch into an explicit guard",
     domain="range(n,-2,2).\n", targets=[("cls", 2)],
     extra_bk=["lbl_pos(pos)", "lbl_nonpos(nonpos)"] + [f"gt0({i})" for i in (1, 2)] + [f"le0({i})" for i in (-2, -1, 0)],
     popper=[dict(label="with comparison stand-ins gt0/le0", head=("cls", 2),
                  body=["num/1", "pos/1", "gt0/1", "le0/1", "lbl_pos/1", "lbl_nonpos/1"],
                  extra="max_vars(2).\nmax_body(3).\nmax_clauses(2).\n")],
     edb=["num/1"], consts=["-2", "0", "2"], rename=["num", "pos", "cls"]),
 "piglog2": dict(title="Piglog2: group independent goals so they can run concurrently",
     targets=[("ok", 1)],
     popper=[dict(label="single rule", head=("ok", 1), body=["src/1", "wcheck/2", "wgood/1", "nccheck/2", "ngood/1"], extra="max_vars(3).\nmax_body(5).\n"),
             dict(label="predicate invention on", head=("ok", 1), body=["src/1", "wcheck/2", "wgood/1", "nccheck/2", "ngood/1"], extra="enable_pi.\nmax_vars(3).\nmax_body(3).\nmax_clauses(3).\n")],
     edb=["src/1", "wcheck/2", "wgood/1", "nccheck/2", "ngood/1"], consts=["s1", "w1", "n1"],
     rename=["src", "wcheck", "wgood", "nccheck", "ngood", "ok", "words_ok", "nums_ok"]),
}

def rename(rules, names, k):
    return [re.sub(r"\b(" + "|".join(sorted(names, key=len, reverse=True)) + r")\(", lambda m: f"{m.group(1)}_{k}(", c) for c in rules]

def run_rule(key):
    cfg = RULES[key]; res = {"rule": key, "title": cfg["title"]}
    orig_txt = open(f"{D}/{key}_orig.pl").read(); opt_txt = open(f"{D}/{key}_opt.pl").read()
    orig_rules, opt_rules = rules_of(orig_txt), rules_of(opt_txt)
    res["original"] = clauses_of(orig_txt); res["optimised_rules"] = opt_rules
    # stage 0: network
    d, net = compile_net(f"rule_{key}_orig", orig_txt, cfg.get("domain"))
    d2, net2 = compile_net(f"rule_{key}_opt", opt_txt, cfg.get("domain"))
    res["net"] = dict(atoms=len(net.atoms), hidden=len(net.hidden), edges=sum(len(v) for v in net.inc.values()),
                      input_preds=sorted(f"{p}/{a}" for p, a in net.edb_preds), match=net_matches_program(d))
    res["net_opt"] = dict(atoms=len(net2.atoms), hidden=len(net2.hidden), edges=sum(len(v) for v in net2.inc.values()),
                          match=net_matches_program(d2))
    # stage 1: input from output
    targets = set(cfg["targets"])
    obs, model = full_observation(net, targets)
    inv = invert_report(net, obs, net.true_input, cap=200)
    inp = inv["explanations"][0]
    res["inverse"] = dict(observed_true=sorted(a for a, v in obs.items() if v), n_observed=len(obs),
                          original_input=net.true_input, recovered=inp, n_minimal=inv["n_explanations"],
                          capped=inv["capped"], min_size=inv["min_size"], orig_size=inv["orig_size"],
                          original_is_minimal=inv["orig_is_minimal_explanation"],
                          proof=net_reproduces(d, inp, obs))
    # stage 2: Popper
    res["popper"] = []
    learned_all = []
    for run0 in cfg["popper"]:
      for source in ("recovered", "original"):
        run = dict(run0)
        src_inp = inp if source == "recovered" else net.true_input
        tgt = run["head"]
        rmodel, _ = net.forward(src_inp)
        exs = closed_world(net, tgt[0], tgt[1], rmodel)
        bk = [a for a in src_inp if pred(a) != tgt] + [a for a in rmodel if pred(a) in {(b.split('/')[0], int(b.split('/')[1])) for b in run["body"]} and pred(a) not in net.edb_preds] + cfg.get("extra_bk", [])
        bk = sorted(set(bk))
        code = popper(f"rule_{key}", bk, exs, tgt, run["body"], run["extra"])
        entry = dict(label=run["label"], input=source, head=f"{tgt[0]}/{tgt[1]}", body=run["body"], code=code,
                     n_pos=sum(exs.values()), n_neg=len(exs) - sum(exs.values()))
        if code:
            o = "[" + ",".join(f"{'true' if v else 'false'}({a})" for a, v in exs.items()) + "]"
            entry["reproduces_recovered"] = prove("R", f"program_reproduces({pl_list(code)},[{','.join(bk)}],{o},R)")
            learned_all += code
        res["popper"].append(entry)
    # stage 3: equivalences proved by prover.pl
    tg = [f"{p}/{a}" for p, a in cfg["targets"]]
    res["proof_original_vs_optimised"] = equivalent(orig_rules or facts_of(orig_txt), opt_rules, tg, cfg["edb"], cfg["consts"])
    for e in res["popper"]:
        if e["code"]:
            e["vs_optimised"] = equivalent([c for c in opt_rules if c.split("(")[0] == e["head"].split("/")[0]] or opt_rules,
                                           e["code"] + [c for c in opt_rules if c.split("(")[0] != e["head"].split("/")[0]],
                                           [e["head"]], cfg["edb"], cfg["consts"])
    # stage 4: S2A learns the rewrite from two renamed examples, applies it to two unseen ones
    if orig_rules:
        names = cfg["rename"]
        train = [(rename(orig_rules, names, k), rename(opt_rules, names, k)) for k in ("a", "b")]
        tests = [rename(orig_rules, names, k) for k in ("c", "d")]
        expect = [rename(opt_rules, names, k) for k in ("c", "d")]
        res["s2a"] = {}
        for grain in ("literal", "flat"):
            alg, outs = s2a_learn_and_apply(key, train, tests, grain)
            res["s2a"][grain] = g = dict(algorithm=alg, tests=[])
            run_s2a_tests(g, tests, outs, expect, cfg)
    else:
        res["s2a"] = None
    return res

def run_s2a_tests(g, tests, outs, expect, cfg):
        for t, o, x in zip(tests, outs, expect):
            ent = dict(input=t, output=o, expected=x, exact=(o is not None and [c.replace(" ", "") for c in o] == [c.replace(" ", "") for c in x]))
            if o:
                k = t[0].split("(")[0].split("_")[-1]
                ent["proof"] = equivalent(t, o, [f"{p}_{k}/{a}" for p, a in cfg["targets"]],
                                          [f"{e.split('/')[0]}_{k}/{e.split('/')[1]}" for e in cfg["edb"]], cfg["consts"])
            g["tests"].append(ent)

if __name__ == "__main__":
    keys = sys.argv[1:] or list(RULES)
    out = {}
    for k in keys:
        r = run_rule(k); out[k] = r
        print(json.dumps({k: {"net": r["net"], "inverse": {x: r["inverse"][x] for x in ("n_minimal", "min_size", "orig_size", "proof")},
                              "popper": [(p["label"], p["code"]) for p in r["popper"]],
                              "orig_vs_opt": r["proof_original_vs_optimised"],
                              "popper_vs_opt": [p.get("vs_optimised") for p in r["popper"]],
                              "s2a": r["s2a"] and {g: [(t["exact"], t.get("proof")) for t in v["tests"]] for g, v in r["s2a"].items()}}}, indent=None)[:1500], flush=True)
        json.dump(out, open(f"/home/claude/exp/results/mnn_{'_'.join(keys) if sys.argv[1:] else 'all'}.json", "w"), indent=1)
