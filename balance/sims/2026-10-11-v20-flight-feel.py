"""v20 (2026-10-11): auditoria do voo. (1) pecas so melhoram no degrau (effect.step 10);
(2) empuxo sentido com teto suave (physics.feel: aceleracao liquida ate knee igual, depois -> max).
Compara a v19 (base) com variantes na triagem de 6 h (3 perfis, seeds 1-2)."""
import sys, copy, statistics as st
sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *

BASE = load("data/economy.json")


def variant(step=True, feel=(3.5, 8.0)):
    E = copy.deepcopy(BASE)
    for u in E["upgrades"]:
        if u["id"] in ("thrust", "tank", "efficiency", "gear") and step:
            u["effect"]["step"] = 10
    if feel:
        E["physics"]["feel"] = {"knee": feel[0], "max": feel[1]}
    return E


def metrics(E, r):
    rep = pacing_report(E, r)
    ev = [e for e in r.events if e["type"] == "upgrade"]
    gaps = [e["gap_s"] / 60 for e in ev if e["gap_s"] > 0]
    worlds = {e["id"]: round(e["t"] / 3600, 2) for e in r.events if e["type"] in ("world", "planet", "road")
              and str(e.get("id", "")).startswith("complete_")}
    first = next((round(e["t"]) for e in ev), None)
    return {"1a_compra_s": first, "gap_med_min": round(st.median(gaps), 1) if gaps else None,
            "gap_p90_min": round(sorted(gaps)[int(len(gaps) * .9)], 1) if gaps else None,
            "pior_parede": max((w["gap_min"] for w in rep["walls"]), default=0),
            "mundos_h": worlds, "niveis": {k: v for k, v in r.final["levels"].items() if k in ("thrust", "tank", "efficiency", "gear")}}


if __name__ == "__main__":
    cases = {"v19": BASE, "degrau": variant(feel=None), "v20": variant()}
    jobs = [(p, 6.0, s) for p in ("casual", "engaged", "expert") for s in (1, 2)]
    for name, E in cases.items():
        rs = simulate_many(E, jobs)
        print("=====", name)
        for (p, _, s), r in zip(jobs, rs):
            print(f"  {p:8s} s{s}", metrics(E, r))
