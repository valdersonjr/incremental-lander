import sys; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
# Auditoria dos primeiros minutos (C4): 1a compra do perfil novato com e sem a regra do aprendiz (1 h, seeds 1-5).
from econ import *
E = load("data/economy.json")
jobs = [(p, 1.0, s) for p in ("novice", "casual", "engaged") for s in (1, 2, 3, 4, 5)]
res = simulate_many(E, jobs)
for r, (p, _, s) in zip(res, jobs):
    rep = pacing_report(E, r)
    ups = [e for e in r.events if e["type"] == "upgrade"]
    print(f"{p:8s} s{s} first_buy={rep['first_purchase_s']}s ups<=5min={sum(1 for e in ups if e['t']<=300)} ups<=15min={sum(1 for e in ups if e['t']<=900)}")
# sem a regra do aprendiz (antes desta auditoria)
nv = profile_from(E, "novice"); nv.apprentice = 0
res2 = [simulate(E, nv, 1.0, s) for s in (1, 2, 3, 4, 5)]
for s, r in zip((1,2,3,4,5), res2):
    rep = pacing_report(E, r)
    print(f"novato SEM aprendiz s{s} first_buy={rep['first_purchase_s']}s")
