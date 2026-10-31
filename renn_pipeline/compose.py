"""Combining nets: two separately compiled networks are joined by wiring the outputs of one into the
matching inputs of the other (shared atom neurons). The method then runs on the combined net only:
prove the combined net equals the union program, find the input from the end output, and let Popper
learn the end-to-end algorithm, which neither net contains on its own."""
import json, os
from pipeline import *
from netlib import Net, pred

DOM = "domain(c, [a,b,c,d,x,y,z,ok]).\n"
A = """f(a,b). f(b,c). f(c,d).
g(b,x). g(c,y). g(d,z).
t2(X,Z) :- f(X,Y), g(Y,Z).
"""
B = """h(x,ok). h(z,ok).
r(X,W) :- t2(X,Z), h(Z,W).
"""

def merge(ja, jb, out_json, out_pl, module):
    a, b = json.load(open(ja)), json.load(open(jb))
    def ren(d, tag):
        m = {}
        for n in d["neurons"]:
            if n["id"].startswith("hidden("):
                m[n["id"]] = f"hidden({tag}{n['id'][7:-1]})"
        f = lambda i: m.get(i, i)
        return ([dict(n, id=f(n["id"])) for n in d["neurons"]],
                [dict(e, **{"from": f(e["from"]), "to": f(e["to"])}) for e in d["edges"]])
    na, ea = ren(a, "1000"); nb, eb = ren(b, "2000")
    neurons = {n["id"]: n for n in na + nb}           # shared in/out atom neurons merge by name
    atoms = sorted(set(a["atoms"]) | set(b["atoms"]))
    rec = {(r["from"], r["to"]) for r in a["recurrent"] + b["recurrent"]}
    merged = {"mode": "step", "atoms": atoms, "neurons": list(neurons.values()), "edges": ea + eb,
              "recurrent": [{"from": x, "to": y} for x, y in sorted(rec)], "traces": []}
    json.dump(merged, open(out_json, "w"))
    with open(out_pl, "w") as f:
        f.write(f":- module({module}, [neuron/4, edge/3, recurrent/2]).\n")
        for n in merged["neurons"]:
            f.write(f"neuron({n['id']},{n['layer']},{n['activation']},{n['threshold']}).\n")
        for e in merged["edges"]:
            f.write(f"edge({e['from']},{e['to']},{e['weight']}).\n")
        for r in merged["recurrent"]:
            f.write(f"recurrent({r['from']},{r['to']}).\n")

def main():
    da, na = compile_net("compose_A", A, DOM)
    db, nb = compile_net("compose_B", B, DOM)
    d = f"{WORK}/compose_AB"; os.makedirs(d, exist_ok=True)
    merge(f"{da}/net.json", f"{db}/net.json", f"{d}/net.json", f"{d}/net.pl", "n_compose_ab")
    open(f"{d}/src.pl", "w").write(A + B)
    net = Net(f"{d}/net.json")
    res = {"net_A": dict(hidden=len(na.hidden), inputs=sorted(map(str, na.edb_preds))),
           "net_B": dict(hidden=len(nb.hidden), inputs=sorted(map(str, nb.edb_preds))),
           "combined": dict(hidden=len(net.hidden), inputs=sorted(map(str, net.edb_preds))),
           "combined_matches_union_program": net_matches_program(d)}
    obs, model = full_observation(net, {("r", 2)})
    inv = invert_report(net, obs, net.true_input, cap=50)
    inp = inv["explanations"][0]
    res["inverse"] = dict(observed_true=sorted(a for a, v in obs.items() if v), recovered=inp,
                          n_minimal=inv["n_explanations"], proof=net_reproduces(d, inp, obs))
    for source, src in (("recovered", inp), ("original", net.true_input)):
        rm, _ = net.forward(src)
        exs = closed_world(net, "r", 2, rm)
        code = popper("compose_AB_" + source, sorted(src), exs, ("r", 2), ["f/2", "g/2", "h/2"], "max_vars(4).\nmax_body(3).\n")
        res[f"popper_{source}"] = code
        if code:
            res[f"popper_{source}_vs_union"] = equivalent(rules_of(A + B), code + rules_of(A), ["r/2"], ["f/2", "g/2", "h/2"], ["a", "b", "c"])
    json.dump(res, open("/home/claude/exp/results/compose.json", "w"), indent=1)
    print(json.dumps(res, indent=1))

if __name__ == "__main__":
    main()
