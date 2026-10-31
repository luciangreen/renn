"""Stage 1: given only a network's weights and an observed output, find the inputs that produce it.

The weights are compiled into an answer-set program: every hidden unit fires when its weighted input
sum exceeds its threshold; every output atom fires when an incoming hidden unit fires; recurrent
links feed outputs back as inputs. Input atoms are free choices. Stable-model semantics gives the
least fixpoint, so recursive cycles cannot support themselves (a plain SAT encoding would let
reach(a,a) "prove itself"). Observed literals become constraints and a #minimize statement asks for
the fewest input facts. All optimal answer sets are enumerated (capped)."""
import clingo, json
from netlib import Net, pred

SCALE = 1000

def q(a):
    return '"' + a.replace('\\', '\\\\').replace('"', '\\"') + '"'

def encode(net, obs, minimize=True):
    L = []
    hid_ix = {h: i for i, h in enumerate(net.hidden)}
    for a in net.edb_atoms:
        L.append(f"{{ on({q(a)}) }}.")
    for h in net.hidden:
        outs = net.feeds.get(h, [])
        if not outs: continue
        if h in net.bias and all(pred(a) in net.edb_preds for a, _ in outs):
            continue                      # an input unit: replaced by the free choice above
        elems = "; ".join(f"{int(round(w*SCALE))},{q(b)},{j} : on({q(b)})" for j, (b, w) in enumerate(net.hidden_inputs(h)))
        L.append(f"h({hid_ix[h]}) :- #sum{{ {elems} }} > {int(round(net.thr[h]*SCALE))}.")
    for a in net.atoms:
        if pred(a) in net.edb_preds: continue
        srcs = net.inc.get("out(" + a + ")", [])
        if not srcs: continue
        elems = "; ".join(f"{int(round(w*SCALE))},{hid_ix[h]},{j} : h({hid_ix[h]})" for j, (h, w) in enumerate(srcs))
        L.append(f"on({q(a)}) :- #sum{{ {elems} }} > {int(round(net.thr['out(' + a + ')']*SCALE))}.")
    for a, v in obs.items():
        L.append(f":- {'not ' if v else ''}on({q(a)}).")
    for a in net.edb_atoms:
        L.append(f"in({q(a)}) :- on({q(a)}).")
    if minimize:
        L.append("#minimize { 1,A : in(A) }.")
    L.append("#show in/1.")
    return "\n".join(L)

def invert(net, obs, cap=2000, timeout=60):
    ctl = clingo.Control(["--opt-mode=optN", "--opt-strategy=usc", "0", "--warn=none"])
    ctl.add("base", [], encode(net, obs))
    ctl.ground([("base", [])])
    best = []
    with ctl.solve(yield_=True, async_=True) as h:
        h.resume()
        done = h.wait(timeout)
        while True:
            if not done: h.cancel(); return {"status": "timeout", "explanations": best, "capped": True}
            m = h.model()
            if m is None: break
            if m.optimality_proven:
                best.append(sorted(str(s.arguments[0].string) for s in m.symbols(shown=True)))
                if len(best) >= cap: h.cancel(); return {"status": "sat", "explanations": best, "capped": True}
            h.resume(); done = h.wait(timeout)
        res = h.get()
    if res.unsatisfiable:
        return {"status": "unsat", "explanations": [], "capped": False}
    return {"status": "sat", "explanations": best, "capped": False}

def report(net, obs, original=None, cap=2000):
    r = invert(net, obs, cap)
    out = {"status": r["status"], "n_explanations": len(r["explanations"]), "capped": r["capped"],
           "min_size": len(r["explanations"][0]) if r["explanations"] else None,
           "explanations": r["explanations"][:20]}
    # independent check: every explanation reproduces the observation under the forward simulator
    ok = True
    for e in r["explanations"]:
        model, _ = net.forward(e)
        if any((a in model) != v for a, v in obs.items()): ok = False
    out["all_verified_forward"] = ok
    if original is not None:
        orig = sorted(original)
        out["orig_size"] = len(orig)
        out["orig_is_minimal_explanation"] = orig in r["explanations"]
        out["orig_unique"] = r["explanations"] == [orig]
        m, _ = net.forward(orig)
        out["orig_consistent"] = all((a in m) == v for a, v in obs.items())
    return out
