"""Diagnostico: por que casual termina junto com expert? Isola prestigio x habilidade."""
import sys, copy, json; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *
E = load("data/economy.json")
PROFS = ["casual", "engaged", "expert"]

def finish(E, p, seed, **over):
    prof = profile_from(E, p)
    for k, v in over.items(): setattr(prof, k, v)
    r = simulate(E, prof, 40, seed=seed)
    return r.finished_at_h, len([e for e in r.events if e["type"] == "prestige"])

print("A) linha de base (cada perfil com seu prestige_ratio)")
for p in PROFS: print("  ", p, [finish(E, p, s) for s in (1, 2, 3)])
print("B) mesmo prestige_ratio=1.0 para todos (isola habilidade)")
for p in PROFS: print("  ", p, [finish(E, p, s, prestige_ratio=1.0) for s in (1, 2, 3)])
print("C) sem prestigio")
E2 = copy.deepcopy(E); E2.pop("prestige")
for p in PROFS: print("  ", p, [finish(E2, p, s) for s in (1, 2)])
print("D) contribuicao da habilidade numa run (Lua, nave inicial e nave nivel 10 em tudo)")
luna = E["planets"][0]
for lv in (0, 10):
    st_ = ship_stats(E, {u["id"]: lv for u in E["upgrades"] if u["id"] != "refinery"})
    for p in PROFS:
        inc = expected_income(E, luna, st_, profile_from(E, p))["credits"] * 60
        print(f"   nivel {lv:2d} {p:8s} renda/min = {fmt(inc)}")
print("E) bonus do prestigio: pay_mult x", [round(1 + 0.05 * pts, 2) for pts in (3, 15, 67, 137)], "(pontos 3/15/67/137)")
