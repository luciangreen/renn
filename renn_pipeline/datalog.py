"""Tiny bottom-up evaluator for the Datalog programs in this study (stratified \\+, \\=, neq), used to
compare learned programs with the original ones on held-out random inputs."""
import itertools, random, re
from netlib import parse, show

def split_top(s, sep=","):
    out, depth, cur = [], 0, ""
    for ch in s:
        if ch in "([": depth += 1
        if ch in ")]": depth -= 1
        if ch == sep and depth == 0: out.append(cur.strip()); cur = ""
        else: cur += ch
    if cur.strip(): out.append(cur.strip())
    return out

def parse_program(text):
    text = re.sub(r"%.*", "", text)
    clauses = []
    for c in re.split(r"\.\s*(?:\n|$)", text):
        c = c.strip()
        if not c: continue
        if ":-" in c:
            h, b = c.split(":-", 1)
            body = []
            for lit in split_top(b):
                neg = lit.startswith("\\+")
                if neg: lit = lit[2:].strip()
                if "\\=" in lit and not lit.startswith("neq"):
                    x, y = [t.strip() for t in lit.split("\\=")]
                    body.append(("neq", parse(x), parse(y)))
                elif re.match(r"^\w+ = \w+$|^\w+=\w+$", lit):
                    x, y = [t.strip() for t in lit.split("=")]
                    body.append(("eq", parse(x), parse(y)))
                else:
                    body.append(("neg" if neg else "pos", parse(lit)))
            clauses.append((parse(h.strip()), body))
        else:
            clauses.append((parse(c), []))
    return clauses

def subst(t, b):
    if t[0] == "var": return b.get(t[1], t)
    if t[0] == "cmp": return ("cmp", t[1], tuple(subst(a, b) for a in t[2]))
    return t

def unify_into(pat, fact, b):
    from netlib import match
    return match(subst(pat, b), fact, dict(b))

def pkey(t): return (t[1], len(t[2])) if t[0] == "cmp" else (t[1], 0)

def strata(clauses):
    preds = {pkey(h) for h, _ in clauses}
    s = {p: 0 for p in preds}
    for _ in range(len(preds) + 2):
        for h, body in clauses:
            for lit in body:
                if lit[0] in ("pos", "neg") and pkey(lit[1]) in s:
                    need = s[pkey(lit[1])] + (1 if lit[0] == "neg" else 0)
                    if s[pkey(h)] < need: s[pkey(h)] = need
    return s

def least_model(clauses, facts):
    """facts: iterable of atom strings. Returns set of atom strings."""
    db = {show(parse(f)) for f in facts}
    tdb = {parse(a) for a in db}
    st = strata(clauses)
    for level in range(max(st.values(), default=0) + 1):
        rules = [c for c in clauses if st[pkey(c[0])] == level]
        while True:
            new = set()
            for h, body in rules:
                body = sorted(body, key=lambda l: l[0] != "pos")   # bind variables before tests
                for b in solve(body, tdb, {}):
                    g = subst(h, b)
                    if g not in tdb: new.add(g)
            if not new: break
            tdb |= new
    return {show(t) for t in tdb}

def solve(body, tdb, b):
    if not body:
        yield b; return
    lit, rest = body[0], body[1:]
    if lit[0] == "pos":
        for f in tdb:
            b2 = unify_into(lit[1], f, b)
            if b2 is not None: yield from solve(rest, tdb, b2)
    elif lit[0] == "neg":
        g = subst(lit[1], b)
        if any(unify_into(g, f, {}) is not None for f in tdb): return
        yield from solve(rest, tdb, b)
    elif lit[0] == "neq":
        x, y = subst(lit[1], b), subst(lit[2], b)
        if x != y: yield from solve(rest, tdb, b)
    elif lit[0] == "eq":
        x, y = subst(lit[1], b), subst(lit[2], b)
        if x[0] == "var": b2 = dict(b); b2[x[1]] = y; yield from solve(rest, tdb, b2)
        elif y[0] == "var": b2 = dict(b); b2[y[1]] = x; yield from solve(rest, tdb, b2)
        elif x == y: yield from solve(rest, tdb, b)

def agreement(orig_rules, learned_rules, edb_preds, consts, target_preds, trials=100, seed=0, density=0.3):
    """Fraction of random inputs on which both programs give identical target relations."""
    rng = random.Random(seed); same = 0
    for _ in range(trials):
        facts = []
        for (p, ar) in edb_preds:
            for args in itertools.product(consts, repeat=ar):
                if rng.random() < density: facts.append(f"{p}({','.join(args)})" if ar else p)
        m1 = least_model(orig_rules, facts); m2 = least_model(learned_rules, facts)
        f1 = {a for a in m1 if pkey(parse(a)) in target_preds}; f2 = {a for a in m2 if pkey(parse(a)) in target_preds}
        same += f1 == f2
    return same / trials
