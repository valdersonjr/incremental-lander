"""v4b: triagem 2 - cbrt, loja mais barata, max_per_run 8, min_gain 12."""
import sys, copy; sys.path.insert(0, ".claude/skills/economy-balance/scripts"); sys.path.insert(0, "balance/sims")
from econ import *
import importlib.util
spec_ = importlib.util.spec_from_file_location("v4", "balance/sims/2026-09-29-prestige-shop-v4.py"); v4 = importlib.util.module_from_spec(spec_); spec_.loader.exec_module(v4)

def build_v4b(E):
    E = v4.build_v4(E)
    P = E["prestige"]
    P.update({"formula": "cbrt", "scale": 1e4, "min_gain": 12})
    shop = {it["id"]: it for it in P["shop"]}
    shop["capital"].update({"max_level": 3, "cost": {"type": "exp", "base": 2, "growth": 2.0}})
    shop["pilot_file"].update({"max_level": 3, "cost": {"type": "exp", "base": 4, "growth": 2.0}})
    shop["star_charts"]["cost"]["base"] = 20
    shop["warp_drive"]["cost"]["base"] = 60
    shop["premium"]["cost"] = {"type": "exp", "base": 8, "growth": 1.5}
    E["contracts"]["max_per_run"] = 8
    return E

if __name__ == "__main__":
    E = build_v4b(load("data/economy.json"))
    save(E, "balance/sims/economy-v4b-candidate.json")
    for p in ("engaged", "casual", "expert"):
        r = simulate(E, p, 40, seed=1); rep = pacing_report(E, r)
        pres = [(round(e["t"]/3600, 2), e["gain"]) for e in r.events if e["type"] == "prestige"]
        shop_ev = [(round(e["t"]/3600, 2), e["id"], e["level"]) for e in r.events if e["type"] == "shop"]
        print(f"== {p}: fim {rep['finished_at_h']}h | planetas {rep['planet_unlock_h']} | run {rep.get('run_s_median')}s")
        print("   prestigios (h, pontos):", pres)
        print("   loja:", shop_ev)
        for w in rep["warnings"]: print("   AVISO:", w)
