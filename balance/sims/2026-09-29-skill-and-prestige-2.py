"""Iteracao 2: B mais forte (quality_bonus 1.5, max_per_run 20) + expert com regra 'dobrar' (prestige_ratio 1.0)."""
import sys, copy, json, statistics as st; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *
E0 = load("data/economy.json")
def build(prestige=True, qb=1.5, mpr=20):
    E = copy.deepcopy(E0)
    set_path(E, "prestige.scale", 4e4); set_path(E, "prestige.min_gain", 10)
    E["prestige"]["bonuses"] = [{"stat": "pay_mult", "per_point": 0.02}, {"stat": "thrust", "per_point": 0.002}]
    C = E["contracts"]; C["regenerate"] = True; C["max_per_run"] = mpr; C["quality_bonus"] = qb; C["quality_exp"] = 2.0
    E["profiles_override"] = {"expert": {"prestige_ratio": 1.0}}
    if not prestige: E.pop("prestige")
    return E
def row(E, label, seeds=(1, 2)):
    out = {}
    for p in ["casual", "engaged", "expert"]:
        rs = [simulate(E, p, 40, seed=s) for s in seeds]
        out[p] = round(st.mean(r.finished_at_h or 99 for r in rs), 2)
        if p == "engaged":
            pres = [e for e in rs[0].events if e["type"] == "prestige"]
            out["eng_1st_prestige"] = (round(pres[0]["t"]/3600, 2), pres[0]["gain"]) if pres else None
            out["eng_run_s"] = pacing_report(E, rs[0]).get("run_s_median")
    luna = E["planets"][0]; gap = []
    for lv in (0, 10):
        s_ = ship_stats(E, {u["id"]: lv for u in E["upgrades"] if u["id"] != "refinery"})
        inc = {p: expected_income(E, luna, s_, profile_from(E, p))["credits"] for p in ("casual", "expert")}
        gap.append(round(inc["expert"] / inc["casual"], 2))
    out["skill_gap_lv0_lv10"] = gap; out["casual/expert"] = round(out["casual"] / out["expert"], 2)
    print(f"{label:24s}", json.dumps(out, ensure_ascii=False), flush=True)
    return build
row(build(), "A+B2 (qb1.5 mpr20)")
row(build(prestige=False), "A+B2 sem prestigio", seeds=(1,))
