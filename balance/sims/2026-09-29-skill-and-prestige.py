"""Questao 2: habilidade deve pesar mais que o timing do prestigio.
A = prestigio forte (1o reset ~x2); B = habilidade relevante (ofertas regeneram, bonus de precisao q^2)."""
import sys, copy, json, statistics as st; sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *
E0 = load("data/economy.json")
PROFS = ["casual", "engaged", "expert"]; SEEDS = (1, 2)

def apply_A(E):
    set_path(E, "prestige.scale", 4e4); set_path(E, "prestige.min_gain", 10)
    E["prestige"]["bonuses"] = [{"stat": "pay_mult", "per_point": 0.02}, {"stat": "thrust", "per_point": 0.002}]
def apply_B(E):
    C = E["contracts"]; C["regenerate"] = True; C["max_per_run"] = 12; C["quality_bonus"] = 1.0; C["quality_exp"] = 2.0

def variant(a, b, prestige=True):
    E = copy.deepcopy(E0)
    if a: apply_A(E)
    if b: apply_B(E)
    if not prestige: E.pop("prestige")
    return E

def row(E, label):
    out = {}
    for p in PROFS:
        rs = [simulate(E, p, 40, seed=s) for s in SEEDS]
        fins = [r.finished_at_h or 99 for r in rs]
        out[p] = round(st.mean(fins), 2)
        if p == "engaged":
            r = rs[0]; pres = [e for e in r.events if e["type"] == "prestige"]
            out["eng_1st_prestige"] = (round(pres[0]["t"]/3600, 2), pres[0]["gain"]) if pres else None
            out["eng_run_s"] = pacing_report(E, r).get("run_s_median")
    luna = E["planets"][0]
    gap = []
    for lv in (0, 10):
        s_ = ship_stats(E, {u["id"]: lv for u in E["upgrades"] if u["id"] != "refinery"})
        inc = {p: expected_income(E, luna, s_, profile_from(E, p))["credits"] for p in ("casual", "expert")}
        gap.append(round(inc["expert"] / inc["casual"], 2))
    out["skill_gap_lv0_lv10"] = gap
    out["casual/expert"] = round(out["casual"] / out["expert"], 2)
    print(f"{label:22s}", json.dumps(out, ensure_ascii=False), flush=True)
    return out

row(variant(0, 0), "base")
row(variant(1, 0), "A prestigio forte")
row(variant(1, 0, prestige=False), "A sem prestigio")
row(variant(0, 1), "B habilidade")
row(variant(1, 1), "A+B")
row(variant(1, 1, prestige=False), "A+B sem prestigio")
