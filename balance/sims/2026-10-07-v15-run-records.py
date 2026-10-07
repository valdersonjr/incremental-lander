"""v15: run sem teto de entregas + cansaco do gas (contracts.run_fatigue). Triagem de k."""
import sys; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
import copy, statistics as st
from econ import *
E = load("data/economy.json")


def variant(k, cap):
    e = copy.deepcopy(E)
    set_path(e, "contracts.max_per_run", cap)
    set_path(e, "contracts.run_fatigue", k)
    return e


def phases(r):
    out = []
    for lo, hi in [(0, 0.25), (0.25, 1), (1, 3), (3, 6)]:
        ss = [s for s in r.samples if lo * 3600 <= s["t"] < hi * 3600]
        if ss:
            out.append(f"{lo}-{hi}h: {st.median(s['deliveries'] for s in ss):.0f} ent/{st.median(s['run_s'] for s in ss):.0f}s")
    return " | ".join(out)


if __name__ == "__main__":
    vs = [("base cap6", 1.0, 6)] + [(f"k={k}", k, 400) for k in (1.4, 1.6, 1.8, 2.0)]
    jobs = [(variant(k, c), p) for _, k, c in vs for p in ("casual", "engaged", "expert")]
    res = parallel_map(lambda a: simulate(a[0], a[1], 6, 1), jobs)
    for i, (name, k, c) in enumerate(vs):
        print("==", name)
        for j, p in enumerate(("casual", "engaged", "expert")):
            r = res[i * 3 + j]
            rep = pacing_report(jobs[i * 3 + j][0], r)
            walls = max((w["gap_min"] for w in rep["walls"]), default=0)
            print(f"  {p:8s} lv {r.final["levels"].get("thrust",0)}/{r.final["levels"].get("tank",0)}/{r.final["levels"].get("efficiency",0)} "
                  f"parede {walls} min | {phases(r)}")
