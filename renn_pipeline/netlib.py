"""Weights-only view of a pl2ann network, a Prolog-term parser, and an independent forward simulator.

Nothing here reads the source program, network_rule/4 facts or trace facts: only neurons,
thresholds, weighted edges and recurrent links (the JSON weight export)."""
import json, re
from functools import lru_cache

# ---------- minimal Prolog term parser (atoms, numbers, compounds, lists, variables) ----------
TOK = re.compile(r"\s*(?:(-?\d+)|([a-z][A-Za-z0-9_]*|'(?:[^'\\]|\\.)*')|([A-Z_][A-Za-z0-9_]*)|(\[|\]|\(|\)|,|\|))")

def parse(s):
    toks, pos = [], 0
    s = re.sub(r"(\w+) (xor|mod|rem) (\w+)", r"\2(\1,\3)", s.strip())
    while pos < len(s):
        m = TOK.match(s, pos)
        if not m or m.end() == pos:
            raise ValueError(f"bad token at {s[pos:]!r} in {s!r}")
        toks.append(m.groups()); pos = m.end()
    i = 0
    def term():
        nonlocal i
        num, atom, var, punct = toks[i]; i += 1
        if num is not None: return ("num", int(num))
        if var is not None: return ("var", var)
        if punct == "[":
            items, tail = [], ("atom", "[]")
            if toks[i][3] == "]": i += 1; return tail
            while True:
                items.append(term())
                p = toks[i][3]; i += 1
                if p == ",": continue
                if p == "|": tail = term(); i += 1; break
                if p == "]": break
            for it in reversed(items): tail = ("cmp", ".", (it, tail))
            return tail
        name = atom
        if i < len(toks) and toks[i][3] == "(":
            i += 1; args = []
            while True:
                args.append(term()); p = toks[i][3]; i += 1
                if p == ")": break
            return ("cmp", name, tuple(args))
        return ("atom", name)
    t = term()
    return t

def show(t):
    k = t[0]
    if k == "num": return str(t[1])
    if k in ("atom", "var"): return t[1]
    if t[1] == "." and len(t[2]) == 2:
        items = []
        while t[0] == "cmp" and t[1] == ".":
            items.append(show(t[2][0])); t = t[2][1]
        return "[" + ",".join(items) + ("" if t == ("atom", "[]") else "|" + show(t)) + "]"
    return f"{t[1]}(" + ",".join(show(a) for a in t[2]) + ")"

def match(pat, t, b=None):
    b = {} if b is None else b
    if pat[0] == "var":
        if pat[1] == "_": return b
        if pat[1] in b: return b if b[pat[1]] == t else None
        b[pat[1]] = t; return b
    if pat[0] != t[0]: return None
    if pat[0] in ("num", "atom"): return b if pat[1] == t[1] else None
    if pat[1] != t[1] or len(pat[2]) != len(t[2]): return None
    for x, y in zip(pat[2], t[2]):
        b = match(x, y, b)
        if b is None: return None
    return b

def pred(atom_str):
    t = parse(atom_str)
    return (t[1], len(t[2])) if t[0] == "cmp" else (t[1], 0)

# ---------- network from weights ----------
class Net:
    def __init__(self, path):
        d = json.load(open(path))
        self.atoms = [show(parse(a)) for a in d["atoms"]]
        N = self.nid
        self.thr = {N(n["id"]): n["threshold"] for n in d["neurons"]}
        self.layer = {N(n["id"]): n["layer"] for n in d["neurons"]}
        self.inc = {}   # target -> [(source, weight)]
        for e in d["edges"]:
            self.inc.setdefault(N(e["to"]), []).append((N(e["from"]), e["weight"]))
        self.rec = {N(e["from"]): N(e["to"]) for e in d["recurrent"]}
        self.hidden = [n for n, l in self.layer.items() if l == "hidden"]
        # hidden -> output atom it feeds
        self.feeds = {}
        for tgt, srcs in self.inc.items():
            if tgt.startswith("out("):
                for s, w in srcs: self.feeds.setdefault(s, []).append((self.atom_of(tgt), w))
        self.bias = [h for h in self.hidden if not self.inc.get(h) and 0 > self.thr[h]]
        # an input (EDB) predicate: every hidden unit feeding any of its atoms is a bias-only unit
        feeders = {}
        for h, outs in self.feeds.items():
            for a, w in outs: feeders.setdefault(pred(a), set()).add(h)
        preds = {pred(a) for a in self.atoms}
        self.edb_preds = {p for p in preds if all(h in self.bias for h in feeders.get(p, ()))}
        self.edb_atoms = [a for a in self.atoms if pred(a) in self.edb_preds]
        self.true_input = sorted({a for h in self.bias for a, w in self.feeds.get(h, []) if pred(a) in self.edb_preds})
        self.strata = self._strata()

    @staticmethod
    def nid(i):
        if i.startswith("hidden("): return i
        k = i.index("(")
        return i[:k] + "(" + show(parse(i[k + 1:-1])) + ")"

    @staticmethod
    def atom_of(nid):
        return show(parse(nid[nid.index("(") + 1:-1]))

    def hidden_inputs(self, h):
        """[(atom, weight)] for a hidden unit (in(A) neurons fed back from out(A) by recurrent links)."""
        return [(self.atom_of(s), w) for s, w in self.inc.get(h, [])]

    def _strata(self):
        s = {a: 0 for a in self.atoms}
        for _ in range(len(self.atoms) + 2):
            changed = False
            for h, outs in self.feeds.items():
                need = 0
                for b, w in self.hidden_inputs(h):
                    need = max(need, s[b] + (1 if w < 0 else 0))
                for a, _w in outs:
                    if s[a] < need: s[a] = need; changed = True
            if not changed: break
        return s

    def forward(self, inputs, max_rounds=None):
        """Least-model semantics from weights: clamp input atoms, run each stratum to a fixpoint."""
        on = {a for a in inputs if pred(a) in self.edb_preds}      # clamped input layer
        mx = max(self.strata.values(), default=0)
        rounds = 0
        idb = [a for a in self.atoms if pred(a) not in self.edb_preds]
        for st in range(mx + 1):
            layer = [a for a in idb if self.strata[a] == st]
            while True:
                rounds += 1
                act = {}
                new = set(on)
                for a in layer:
                    tot = 0.0
                    for h, w in self.inc.get("out(" + a + ")", []):
                        if h not in act:
                            act[h] = sum(wi for b, wi in self.hidden_inputs(h) if b in on) > self.thr[h]
                        if act[h]: tot += w
                    if tot > self.thr["out(" + a + ")"]: new.add(a)
                if new == on: break
                on = new
                if max_rounds and rounds > max_rounds: return on, False
        return on, True

    def observation_from_queries(self, queries):
        """Turn the dataset's query answers into true/false literals over network atoms."""
        lits = {}
        for q in queries:
            ans = q["answer"]
            if ans.startswith("error"): continue
            pat = parse(q["query"])
            if ans in ("true", "false"):
                lits[show(pat)] = (ans == "true")
            else:
                listed = {show(parse(x)) for x in split_list(ans)}
                for a in self.atoms:
                    if match(pat, parse(a)) is not None:
                        lits[a] = a in listed
                for a in listed: lits[a] = True
        return lits

def split_list(s):
    s = s.strip()[1:-1]
    out, depth, cur = [], 0, ""
    for ch in s:
        if ch in "([": depth += 1
        if ch in ")]": depth -= 1
        if ch == "," and depth == 0: out.append(cur); cur = ""
        else: cur += ch
    if cur.strip(): out.append(cur)
    return out
