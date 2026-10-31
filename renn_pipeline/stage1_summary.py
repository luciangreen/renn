import json, collections
rows = json.load(open('/home/claude/exp/results/stage1.json'))
closed = [r for r in rows if r.get('closed')]
R = [r for r in rows if not r.get('closed')]
out = {"closed": len(closed), "closed_cats": collections.Counter(r['category'] for r in closed),
       "verified_forward_all": all(r['all_verified_forward'] for r in R),
       "orig_consistent_all": all(r['orig_consistent'] for r in R)}
print(out)
agg = collections.defaultdict(collections.Counter)
for r in R:
    c = agg[(r['category'], r['regime'])]
    c['n'] += 1; c['sat'] += r['status'] == 'sat'; c['minimal'] += r['orig_is_minimal_explanation']
    c['unique'] += r['orig_unique']; c['expl'] += r['n_explanations']; c['capped'] += r['capped']
    c['sec'] += r['seconds']; c['smaller'] += (r['min_size'] if r['min_size'] is not None else 99) < r['orig_size']
table = []
for k in sorted(agg):
    c = agg[k]
    table.append([k[0], k[1], c['n'], c['sat'], c['minimal'], c['unique'], c['smaller'], round(c['expl']/c['n'], 1), c['capped'], round(c['sec']/c['n'], 2)])
    print(f"{k[0]:30s} {k[1]} n={c['n']:3d} sat={c['sat']:3d} origMin={c['minimal']:3d} unique={c['unique']:3d} smaller={c['smaller']:3d} meanExpl={c['expl']/c['n']:.1f} capped={c['capped']} s={c['sec']/c['n']:.2f}")
tot = {}
for reg in 'QF':
    S = [r for r in R if r['regime'] == reg]
    tot[reg] = dict(n=len(S), sat=sum(r['status']=='sat' for r in S), unique=sum(r['orig_unique'] for r in S),
                    minimal=sum(r['orig_is_minimal_explanation'] for r in S), max_s=max(r['seconds'] for r in S))
    print(reg, tot[reg])
json.dump({"summary": out, "table": table, "totals": tot}, open('/home/claude/exp/results/stage1_summary.json', 'w'), indent=1, default=str)
