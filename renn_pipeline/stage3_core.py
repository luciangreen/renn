"""Stage 3 (core experiment): unoptimised originals -> net -> input -> Popper -> optimisation algorithm via S2A.

Each base program from the dataset is inflated with one known redundancy. The inflated program is the
'original algorithm'. The net is compiled from it; the input is found from the net's output; Popper
learns code; the prover checks Popper's code against the base program; and Spec to Algorithm learns,
per redundancy type, the rewrite that turns an inflated program into its optimised form, from two
examples, then is tested on unseen programs (same shape renamed, and a different program shape)."""
import json, re
from pipeline import *
from netlib import Net, pred

BASES = {
    "reach": dict(facts="edge(a,b).\nedge(b,c).\nedge(c,d).\nedge(b,e).\n", rules=["reach(X,Y):-edge(X,Y)", "reach(X,Y):-edge(X,Z),reach(Z,Y)"],
                  head=("reach", 2), body=["edge/2"], edb=["edge/2"], recursive=True),
    "ancestor": dict(facts="parent(ann,bob).\nparent(bob,cy).\nparent(cy,dee).\nparent(bob,eli).\n", rules=["ancestor(X,Y):-parent(X,Y)", "ancestor(X,Y):-parent(X,Z),ancestor(Z,Y)"],
                  head=("ancestor", 2), body=["parent/2"], edb=["parent/2"], recursive=True),
    "grandparent": dict(facts="parent(ann,bob).\nparent(bob,cy).\nparent(ann,dee).\nparent(dee,eli).\n", rules=["grandparent(X,Y):-parent(X,Z),parent(Z,Y)"],
                  head=("grandparent", 2), body=["parent/2"], edb=["parent/2"], recursive=False),
    "sibling": dict(facts="parent(ann,bob).\nparent(ann,cy).\nparent(bob,dee).\n", rules=["sibling(X,Y):-parent(P,X),parent(P,Y),X\\=Y"],
                  head=("sibling", 2), body=["parent/2", "neq/2"], edb=["parent/2"], recursive=False),
}

def inflate(rules, op, head, edbp):
    r0 = rules[0]; h, b = r0.split(":-")
    if op == "dup_clause":     return rules + [r0]
    if op == "dup_literal":    return [h + ":-" + b + "," + split_top(b)[0]] + rules[1:]
    if op == "subsumed_clause":
        extra = f"{edbp}(Y,X)" if "X" in h else f"{edbp}(X,X)"
        return rules + [h + ":-" + b + "," + extra]
    if op == "unfolded_clause":            # semantically redundant 2-step clause (recursive bases only)
        p = head[0]
        return rules[:1] + [f"{p}(X,Y):-{edbp}(X,Z),{edbp}(Z,Y)"] + rules[1:]
    if op == "dup_then_subsumed":
        return inflate(inflate(rules, "dup_clause", head, edbp), "subsumed_clause", head, edbp)
    raise ValueError(op)

OPS = ["dup_clause", "dup_literal", "subsumed_clause", "unfolded_clause", "dup_then_subsumed"]

def popper_bias(base):
    return ("enable_recursion.\nmax_vars(3).\nmax_body(2).\nmax_clauses(2).\n" if base["recursive"]
            else "max_vars(3).\nmax_body(3).\n")

def run():
    results = []
    for bname, base in BASES.items():
        edbp = base["edb"][0].split("/")[0]
        for op in OPS:
            if op == "unfolded_clause" and not base["recursive"]: continue
            orig = inflate(base["rules"], op, base["head"], edbp)
            prog = base["facts"] + "".join(c + ".\n" for c in orig)
            name = f"core_{bname}_{op}"
            d, net = compile_net(name, prog)
            row = dict(base=bname, op=op, original=orig, optimised=base["rules"],
                       hidden=len(net.hidden), match=net_matches_program(d))
            obs, model = full_observation(net, {base["head"]})
            inv = invert_report(net, obs, net.true_input, cap=50)
            inp = inv["explanations"][0]
            row["inverse"] = dict(recovered=inp, original_input=net.true_input, n_minimal=inv["n_explanations"],
                                  proof=net_reproduces(d, inp, obs))
            consts = sorted({x for a in net.true_input for x in re.findall(r"[a-z]\w*", a.split("(", 1)[1])})
            for source, src in (("recovered", inp), ("original", net.true_input)):
                rm, _ = net.forward(src)
                exs = closed_world(net, *base["head"], rm)
                bk = list(src)
                if "neq/2" in base["body"]:
                    bk += [f"neq({x},{y})" for x in consts for y in consts if x != y]
                code = popper(f"{name}_{source}", bk, exs, base["head"], base["body"], popper_bias(base))
                ent = dict(code=code)
                if code:
                    code_eq = [c.replace("neq(", "neq(") for c in code]
                    ent["vs_optimised"] = equivalent(base["rules"], code_eq, [f"{base['head'][0]}/2"], base["edb"], ["a", "b", "c"])
                    ent["aligned_to_optimised"] = align(code, base["rules"])
                    ent["exact_after_alignment"] = sorted(ent["aligned_to_optimised"]) == sorted(r.replace(" ", "") for r in base["rules"])
                row[f"popper_{source}"] = ent
            row["original_vs_optimised"] = equivalent(orig, base["rules"], [f"{base['head'][0]}/2"], base["edb"], ["a", "b", "c"])
            results.append(row)
            print(bname, op, row["match"], row["inverse"]["proof"], row["popper_recovered"].get("code"), row["popper_original"].get("code"), row["original_vs_optimised"], flush=True)
    # S2A: learn each rewrite from reach + ancestor examples, test on renamed reach and on other shapes
    s2a = {}
    for op in OPS:
        by = {r["base"]: r for r in results if r["op"] == op}
        if "reach" not in by or "ancestor" not in by: continue
        train = [(by["reach"]["original"], by["reach"]["optimised"]), (by["ancestor"]["original"], by["ancestor"]["optimised"])]
        tests, expect, labels = [], [], []
        ren = lambda rs, a, b: [re.sub(rf"\b{a}\(", f"{b}(", re.sub(r"\bedge\(", "link(", c)) for c in rs]
        tests.append(ren(by["reach"]["original"], "reach", "path")); expect.append(ren(by["reach"]["optimised"], "reach", "path")); labels.append("same shape, renamed")
        for other in ("grandparent", "sibling"):
            if other in by:
                tests.append(by[other]["original"]); expect.append(by[other]["optimised"]); labels.append(f"different shape: {other}")
        s2a[op] = {}
        for grain in ("literal", "flat"):
            alg, outs = s2a_learn_and_apply(f"core_{op}", train, tests, grain)
            tl = []
            for lab, t, o, x in zip(labels, tests, outs, expect):
                e = dict(test=lab, input=t, output=o, expected=x,
                         exact=o is not None and sorted(c.replace(" ", "") for c in o) == sorted(c.replace(" ", "") for c in x))
                if o:
                    hp = x[0].split("(")[0]; ep = re.findall(r"(\w+)\(", x[0].split(":-")[1])[0]
                    e["proof"] = equivalent(t, o, [f"{hp}/2"], [f"{ep}/2"], ["a", "b", "c"])
                tl.append(e)
            s2a[op][grain] = dict(algorithm=alg, tests=tl)
            print("S2A", op, grain, [(e["test"], e["exact"], e.get("proof")) for e in tl], flush=True)
    # windowed S2A: learn each rewrite on a small window from reach/ancestor, slide it over unseen shapes
    win = {}
    def wpairs(op, o, p):
        if op == "dup_literal":
            return [([a], [b]) for a, b in zip(o, p) if a != b]
        removed = [c for c in o if c not in p or o.count(c) > p.count(c)]
        r = removed[-1]; keep = next(c for c in p if c.split(":-")[0] == r.split(":-")[0])
        return [([keep, r], [keep])]
    for op in ("dup_clause", "dup_literal", "subsumed_clause"):
        by = {r["base"]: r for r in results if r["op"] == op}
        tw = []
        for b in ("reach", "ancestor"):
            tw += wpairs(op, by[b]["original"], by[b]["optimised"])
        size = 1 if op == "dup_literal" else 2
        win[op] = []
        for other in ("grandparent", "sibling"):
            o = by[other]["original"]; x = by[other]["optimised"]
            grain = "clause" if op == "dup_clause" else "literal"
            chk = lambda a, b, h=other: equivalent(a, b, [f"{h}/2"], ["parent/2"], ["a", "b", "c"]).startswith("proved")
            out, trace = s2a_window_optimise(f"win_{op}", tw, o, size, grain)
            out_c, trace_c = s2a_window_optimise(f"win_{op}", tw, o, size, grain, check=chk)
            e = dict(test=other, grain=grain, input=o, output=out, expected=x, steps=trace,
                     exact=sorted(c.replace(" ", "") for c in out) == sorted(c.replace(" ", "") for c in x))
            e["proof"] = equivalent(o, out, [f"{other}/2"], ["parent/2"], ["a", "b", "c"])
            e["with_prover_guard"] = dict(output=out_c, steps=trace_c,
                exact=sorted(c.replace(" ", "") for c in out_c) == sorted(c.replace(" ", "") for c in x),
                proof=equivalent(o, out_c, [f"{other}/2"], ["parent/2"], ["a", "b", "c"]))
            win[op].append(e)
            print("WINDOW", op, other, e["exact"], e["proof"][:60], "| guarded:", e["with_prover_guard"]["exact"], e["with_prover_guard"]["proof"][:60], flush=True)
    json.dump({"cases": results, "s2a": s2a, "s2a_windowed": win}, open("/home/claude/exp/results/stage3_core.json", "w"), indent=1)

if __name__ == "__main__":
    run()
