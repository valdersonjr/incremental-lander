"""v4c: triagem 3 - premium x1.10 (growth 2.0), max_per_run 6."""
import sys; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *
import importlib.util
sp = importlib.util.spec_from_file_location("v4b", "balance/sims/2026-09-29-prestige-shop-v4b.py"); v4b = importlib.util.module_from_spec(sp); sp.loader.exec_module(v4b)

def build_v4c(E):
    E = v4b.build_v4b(E)
    shop = {it["id"]: it for it in E["prestige"]["shop"]}
    shop["premium"]["effect"]["value"] = 1.10
    shop["premium"]["cost"] = {"type": "exp", "base": 8, "growth": 2.0}
    E["contracts"]["max_per_run"] = 6
    return E

if __name__ == "__main__":
    E = build_v4c(load("data/economy.json"))
    save(E, "balance/sims/economy-v4c-candidate.json")
    for p in ("engaged", "casual", "expert"):
        r = simulate(E, p, 40, seed=1); rep = pacing_report(E, r)
        pres = [(round(e["t"]/3600, 2), e["gain"]) for e in r.events if e["type"] == "prestige"]
        print(f"== {p}: fim {rep['finished_at_h']}h | planetas {rep['planet_unlock_h']} | run {rep.get('run_s_median')}s | prestigios {pres}")
        for w in rep["warnings"]: print("   AVISO:", w)
