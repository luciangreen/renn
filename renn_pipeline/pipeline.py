"""One pipeline used for every experiment and every MNN rule chapter:

  original Prolog --pl2ann--> network (weights)
  network + observed output --RENN inverse (ASP over weights)--> input facts
  input facts + output --Popper--> learned code
  (original, optimised) pairs --Spec to Algorithm--> pattern-matching optimisation algorithm
  prover.pl checks every claim (net<->program, input reproduces output, code equivalence)."""
import itertools, json, os, re, subprocess, textwrap
from netlib import Net, pred, parse, show
from renn_invert import report as invert_report, invert
from datalog import parse_program, split_top

PL2ANN = "/home/claude/pl2ann"
PROVER = "/home/claude/exp/prover/prover.pl"
S2A_DIR = "/home/claude/Philosophy/s2a"
POPPER = "/home/claude/pop_v2.1.0/popper.py"
WORK = "/home/claude/exp/work"
os.makedirs(WORK, exist_ok=True)

# ------------------------------------------------------------------ Prolog helpers
def clauses_of(text):
    """Split program text into clause strings (no trailing dot)."""
    text = re.sub(r"%.*", "", text)
    return [c.strip() for c in re.split(r"\.(?=\s|$)", text) if c.strip()]

def rules_of(text):
    return [c for c in clauses_of(text) if ":-" in c]

def facts_of(text):
    return [c for c in clauses_of(text) if ":-" not in c]

def pl_list(clauses):
    return "[" + ",".join(f"({c})" for c in clauses) + "]"

def swipl(goal, files=(), cwd=None, timeout=600):
    loads = ",".join(f"consult('{f}')" for f in files)
    g = (loads + "," if loads else "") + goal + ",halt"
    r = subprocess.run(["swipl", "-q", "-g", g, "-t", "halt(1)"], capture_output=True, text=True,
                       cwd=cwd, timeout=timeout)
    return r.stdout.strip(), r.stderr

def prove(goal_vars, goal):
    """Run a prover goal that binds R; return the printed result term."""
    out, err = swipl(f"use_module('{PROVER}'),({goal} -> print(R) ; print(goal_failed)),nl", ())
    return out.splitlines()[-1] if out else "error: " + err[-300:]

# ------------------------------------------------------------------ stage 0: pl2ann
def compile_net(name, program, domain=None, opts=()):
    d = f"{WORK}/{name}"; os.makedirs(d, exist_ok=True)
    open(f"{d}/src.pl", "w").write(program)
    cmd = ["swipl", "bin/prolog2ann.pl", "convert", f"{d}/src.pl"]
    if domain:
        open(f"{d}/domain.pl", "w").write(domain); cmd += ["--domain", f"{d}/domain.pl"]
    cmd += [*opts, "--out", f"{d}/net.pl", "--module", "n_" + re.sub(r"\W", "_", name), "--json", f"{d}/net.json"]
    r = subprocess.run(cmd, cwd=PL2ANN, capture_output=True, text=True, timeout=600)
    if r.returncode != 0: raise RuntimeError(r.stderr[-500:])
    return d, Net(f"{d}/net.json")

def net_matches_program(d):
    return prove("R", f"read_program('{d}/src.pl',P),net_matches_program('{d}/net.pl',P,R)")

# ------------------------------------------------------------------ stage 1: inverse
def full_observation(net, targets):
    model, _ = net.forward(net.true_input)
    return {a: (a in model) for a in net.atoms if pred(a) in targets}, model

def net_reproduces(d, inp, obs):
    o = "[" + ",".join(f"{'true' if v else 'false'}({a})" for a, v in obs.items()) + "]"
    return prove("R", f"net_reproduces('{d}/net.pl',[{','.join(inp)}],{o},R)")

# ------------------------------------------------------------------ stage 2: Popper
RESERVED = {"pos": "zpos", "neg": "zneg"}   # Popper's example file uses pos/1 and neg/1 itself

def _res(s, back=False):
    for a, b in RESERVED.items():
        x, y = (b, a) if back else (a, b)
        s = re.sub(rf"\b{x}(?=[(/]|$)", y, s)
    return s

def popper(name, bk, exs, head, body, extra="", timeout=120):
    bk = [_res(a) for a in bk]; body = [_res(b) for b in body]
    exs = {_res(a): v for a, v in exs.items()}; head = (_res(head[0]), head[1])
    code = _popper(name, bk, exs, head, body, extra, timeout)
    return [_res(c, back=True) for c in code] if code else code

def _popper(name, bk, exs, head, body, extra="", timeout=120):
    d = f"{WORK}/{name}/popper"; os.makedirs(d, exist_ok=True)
    open(f"{d}/bk.pl", "w").write("\n".join([a + "." for a in bk] + [f":- dynamic {b}." for b in body]) + "\n")
    open(f"{d}/exs.pl", "w").write("\n".join(f"{'pos' if v else 'neg'}({a})." for a, v in sorted(exs.items(), key=lambda kv: (not kv[1], kv[0]))) + "\n")
    open(f"{d}/bias.pl", "w").write(f"head_pred({head[0]},{head[1]}).\n" +
        "".join(f"body_pred({b.split('/')[0]},{b.split('/')[1]}).\n" for b in body) + extra)
    env = dict(os.environ, PYTHONPATH="/home/claude/build/pyswip/src")
    try:
        r = subprocess.run(["timeout", str(timeout + 30), "python3", POPPER, d, "--timeout", str(timeout)],
                           capture_output=True, text=True, env=env, timeout=timeout + 60)
        out = r.stdout + r.stderr
    except subprocess.TimeoutExpired:
        out = ""
    m = re.search(r"\*+ SOLUTION \*+\n(.*?)\n(.*?)\*{10,}", out, re.S)
    if not m: return None
    return [l.strip().rstrip(".") for l in m.group(2).strip().splitlines() if l.strip()]

def closed_world(net, target, ar, model):
    cs = sorted({show(x) for a in net.atoms if parse(a)[0] == "cmp" for x in parse(a)[2]})
    return {f"{target}({','.join(t)})" if ar else target: (f"{target}({','.join(t)})" if ar else target) in model
            for t in itertools.product(cs, repeat=ar)}

# ------------------------------------------------------------------ program normalisation
def canon_clause(c):
    """Rename variables in order of first appearance (head first) to A,B,C..."""
    names = {}
    def sub(m):
        v = m.group(0)
        if v == "_": return v
        if v not in names: names[v] = "V" + str(len(names))
        return names[v]
    return re.sub(r"\b[A-Z_][A-Za-z0-9_]*\b", sub, c.replace(" ", ""))

def align(learned, target):
    """Rename/reorder each learned clause to the variant of a target clause where one exists."""
    target = [re.sub(r"([A-Z]\w*)\\=([A-Z]\w*)", r"neq(\1,\2)", t.replace(" ", "")) for t in target]
    out = []
    for c in learned:
        h, b = c.replace(" ", "").split(":-") if ":-" in c else (c, "")
        lits = split_top(b) if b else []
        hit = None
        for t in target:
            th, tb = t.replace(" ", "").split(":-") if ":-" in t else (t, "")
            tl = split_top(tb) if tb else []
            if len(tl) != len(lits): continue
            for perm in itertools.permutations(lits):
                cand = h + (":-" + ",".join(perm) if perm else "")
                if canon_clause(cand) == canon_clause(t):
                    hit = t; break
            if hit: break
        out.append(hit if hit else c.replace(" ", ""))
    return out

# ------------------------------------------------------------------ stage 3: Spec to Algorithm
S2A_LIB = r"""
xs_reset :-
  retractall(num_s2a(_)),assertz(num_s2a(1)),retractall(vars_s2a(_)),assertz(vars_s2a([])),
  retractall(vars_base_s2a(_)),assertz(vars_base_s2a('A')),
  retractall(character_breakdown_mode(_)),assertz(character_breakdown_mode(off)),
  (catch(algs(As),_,fail)->forall(member(A0,As),retractall(A0));true),
  retractall(algs(_)),assertz(algs([])),
  retractall(vars_table_s2a(_)),assertz(vars_table_s2a([])).
xs_learn(Name,Specs) :- xs_reset,
  ( catch(spec_to_algorithm(Name,Specs,off,Alg),_,fail) -> format("ALG ~q~n",[Alg]) ; (format("GENFAIL~n"), fail) ).
xs_apply(Name,In) :-
  retractall(vars_table_s2a(_)),assertz(vars_table_s2a([])),
  retractall(character_breakdown_mode(_)),assertz(character_breakdown_mode(off)),
  G=..[Name,[In],Out], ( catch(G,_,fail) -> format("OUT ~q~n",[Out]) ; format("NOOUT~n") ).
"""

class FlatTokens:
    """Finer grain: each clause is a flat list of predicate tokens and variable tokens,
    so S2A can rebuild literals whose argument order changed (decoded using arities)."""
    def __init__(self, prefix): self.prefix, self.p2i, self.i2p, self.arity = prefix, {}, {}, {}
    def pid(self, p, ar):
        if p not in self.p2i:
            i = f"{self.prefix}{len(self.p2i) + 1}"; self.p2i[p] = i; self.i2p[i] = p; self.arity[i] = ar
        return self.p2i[p]
    def lit(self, l):
        try:
            t = parse(l)
        except (ValueError, IndexError):
            return [self.pid(l, 0)]          # arithmetic or other syntax: keep the literal whole
        if t[0] != "cmp": return [self.pid(t[1], 0)]
        return [self.pid(t[1], len(t[2]))] + ["v" + show(a).lower() if a[0] == "var" else show(a) for a in t[2]]
    def encode(self, rules):
        enc = []
        for c in rules:
            h, b = c.replace(" ", "").split(":-") if ":-" in c else (c.replace(" ", ""), "")
            toks = self.lit(h)
            for l in (split_top(b) if b else []): toks += self.lit(l)
            enc.append(toks)
        return enc
    def decode(self, enc):
        out = []
        for toks in enc:
            lits, i = [], 0
            while i < len(toks):
                p = toks[i]; ar = self.arity.get(p)
                if ar is None: return None
                args = [a[1:].upper() if a.startswith("v") else a for a in toks[i + 1:i + 1 + ar]]
                lits.append(self.i2p[p] + ("(" + ",".join(args) + ")" if ar else "")); i += 1 + ar
            out.append(lits[0] + (":-" + ",".join(lits[1:]) if len(lits) > 1 else ""))
        return out

class ClauseTokens:
    """Coarsest grain: a whole clause is one token, so clause-level rewrites ignore clause length."""
    def __init__(self, prefix): self.prefix, self.t2i, self.i2t = prefix, {}, {}
    def encode(self, rules):
        out = []
        for c in rules:
            c = c.replace(" ", "")
            if c not in self.t2i:
                i = f"{self.prefix}{len(self.t2i) + 1}"; self.t2i[c] = i; self.i2t[i] = c
            out.append(self.t2i[c])
        return out
    def decode(self, enc):
        flat = []
        def walk(x):
            if isinstance(x, list):
                for e in x: walk(e)
            else: flat.append(x)
        walk(enc)
        if any(t not in self.i2t for t in flat): return None
        return [self.i2t[t] for t in flat]

class Tokens:
    """Opaque ids for literal strings, so S2A sees structure, not Prolog syntax."""
    def __init__(self, prefix): self.prefix, self.t2i, self.i2t = prefix, {}, {}
    def id(self, lit):
        lit = lit.replace(" ", "")
        if lit not in self.t2i:
            i = f"{self.prefix}{len(self.t2i) + 1}"; self.t2i[lit] = i; self.i2t[i] = lit
        return self.t2i[lit]
    def encode(self, rules):
        enc = []
        for c in rules:
            h, b = c.replace(" ", "").split(":-")
            enc.append([self.id(h)] + [self.id(l) for l in split_top(b)])
        return enc
    def decode(self, enc):
        return [self.i2t.get(c[0], c[0]) + ":-" + ",".join(self.i2t.get(x, x) for x in c[1:]) for c in enc]

def to_pl(x):
    return "[" + ",".join(to_pl(e) for e in x) + "]" if isinstance(x, list) else x

def from_brackets(out):
    """S2A prints nested output as a flat token list with "[" and "]" strings."""
    toks = re.findall(r'"\["|"\]"|[a-z]\w*', out)
    stack = [[]]
    for t in toks:
        if t == '"["': stack.append([])
        elif t == '"]"': top = stack.pop(); stack[-1].append(top)
        else: stack[-1].append(t)
    return stack[0]

def s2a_learn_and_apply(name, train, tests, grain="literal"):
    """train: [(orig_rules, opt_rules)], tests: [orig_rules]. Returns (algorithm text, [decoded outputs])."""
    specs, tabs = [], []
    for k, (o, p) in enumerate(train):
        tk = {"literal": Tokens, "flat": FlatTokens, "clause": ClauseTokens}[grain](f"t{k}x"); ei, eo = tk.encode(o), tk.encode(p)
        specs.append(f"[[input,[['A',{to_pl(ei)}]]],[output,[['B',{to_pl(eo)}]]]]")
    tst = []
    for k, o in enumerate(tests):
        tk = {"literal": Tokens, "flat": FlatTokens, "clause": ClauseTokens}[grain](f"h{k}x"); tst.append((tk, tk.encode(o)))
    pname = "opt_" + re.sub(r"\W", "_", name) + "_" + grain
    script = S2A_LIB + f"\nrun_it :- (xs_learn({pname},[{','.join(specs)}]) -> " + \
        "(" + ",".join(f"xs_apply({pname},{to_pl(e)})" for _, e in tst) + ") ; true).\n"
    f = f"{WORK}/s2a_{pname}.pl"; open(f, "w").write(script)
    out, err = swipl("run_it", ("spec_to_algorithm", f), cwd=S2A_DIR, timeout=900)
    alg = re.search(r"^ALG (.*)$", out, re.M)
    outs = re.findall(r"^(OUT .*|NOOUT)$", out, re.M)
    decoded = []
    for (tk, _), o in zip(tst, outs):
        if o == "NOOUT" or "'C" in o: decoded.append(None); continue   # unbound pattern variable = no rebuild
        nested = from_brackets(o[4:])
        if grain == "clause":
            decoded.append(tk.decode(nested)); continue
        # S2A wraps the result once; unwrap to a list of clauses
        while len(nested) == 1 and isinstance(nested[0], list) and nested[0] and isinstance(nested[0][0], list):
            nested = nested[0]
        if nested and not isinstance(nested[0], list): nested = [nested]
        decoded.append(tk.decode(nested))
    return (alg.group(1) if alg else None), decoded

def equivalent(a_rules, b_rules, targets, edb, consts):
    t = "[" + ",".join(targets) + "]"
    return prove("R", f"equivalent({pl_list(a_rules)},{pl_list(b_rules)},{t},edb([{','.join(edb)}],[{','.join(consts)}]),R)")

# ------------------------------------------------------------------ windowed S2A driver
def windows(prog, size):
    if size == 1: return [[c] for c in prog]
    return [[prog[i], prog[j]] for i in range(len(prog)) for j in range(len(prog)) if i != j]

def splice(prog, w, o, size):
    if size == 1:
        return [o[0] if c == w[0] else c for c in prog]
    first = min(prog.index(w[0]), prog.index(w[1]))
    new = list(prog)
    for c in w: new.remove(c)
    return new[:first] + o + new[first:]

def s2a_window_optimise(name, train_windows, prog, size, grain="literal", rounds=4, check=None):
    """Slide a window over the program; where the S2A-learned rewrite fires, splice its output in.
    With check(old, new) -> bool (the prover), a proposed rewrite is kept only if it is proved."""
    trace = []
    for _ in range(rounds):
        wins = windows(prog, size)
        if not wins: break
        alg, outs = s2a_learn_and_apply(name, train_windows, wins, grain)
        applied = False
        for w, o in zip(wins, outs):
            if o is None or o == w: continue
            cand = splice(prog, w, o, size)
            ok = check(prog, cand) if check else True
            trace.append(dict(window=w, output=o, accepted=bool(ok)))
            if ok:
                prog = cand; applied = True; break
        if not applied: break
    return prog, trace
