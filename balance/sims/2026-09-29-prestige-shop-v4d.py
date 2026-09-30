"""v4d: pow 0.25 (dobrar exige 16x) + custo de Titan resolvido para engaged ~15h."""
import sys, time; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *
import importlib.util
sp = importlib.util.spec_from_file_location("v4c", "balance/sims/2026-09-29-prestige-shop-v4c.py"); v4c = importlib.util.module_from_spec(sp); sp.loader.exec_module(v4c)

def build_v4d(E):
    E = v4c.build_v4c(E)
    E["prestige"].update({"formula": "pow", "exponent": 0.25, "scale": 800})
    return E

if __name__ == "__main__":
    E = build_v4d(load("data/economy.json")); T = time.time()
    v = solve(E, "planets.titan.unlock.credits", lambda e: planet_unlock_hour(e, "titan", hours=40), 15.0, 1e9, 1e15, iters=12)
    set_path(E, "planets.titan.unlock.credits", float(f"{v:.2g}"))
    print("titan ->", fmt(v), f"({round(time.time()-T)}s)", flush=True)
    save(E, "balance/sims/economy-v4d-candidate.json")
    for p in ("engaged", "casual", "expert"):
        r = simulate(E, p, 40, seed=1); rep = pacing_report(E, r)
        pres = [(round(e["t"]/3600, 2), e["gain"]) for e in r.events if e["type"] == "prestige"]
        shop_ev = [(round(e["t"]/3600, 2), e["id"]) for e in r.events if e["type"] == "shop" and e["id"] != "premium"]
        print(f"== {p}: fim {rep['finished_at_h']}h | planetas {rep['planet_unlock_h']} | run {rep.get('run_s_median')}s | niveis {rep['levels_share_pct']}", flush=True)
        print("   prestigios:", pres, "| loja (sem premium):", shop_ev, flush=True)
        for w in rep["warnings"]: print("   AVISO:", w, flush=True)
