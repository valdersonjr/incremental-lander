"""Compara EconMath (GDScript, via Godot headless) com econ.py (Python) na mesma spec.
Rodar da raiz do projeto: python3 tests/test_econ_parity.py   (sai com codigo 1 se divergir)"""
import sys, json, math, subprocess
sys.path.insert(0, ".claude/skills/economy-balance/scripts")
from econ import *

E = load("data/economy.json")
gd = subprocess.run(["godot", "--headless", "--path", ".", "--script", "res://tests/test_econ_math.gd"],
                    capture_output=True, text=True, timeout=120)
line = next((l for l in gd.stdout.splitlines() if l.startswith("ECON_JSON=")), None)
if not line:
    print(gd.stdout[-2000:], gd.stderr[-2000:]); sys.exit("ERRO: Godot nao imprimiu ECON_JSON")
G = json.loads(line[len("ECON_JSON="):])

levels = {"thrust": 30, "tank": 26, "efficiency": 12, "contracts": 50, "gear": 5, "fleet": 3, "autopilot": 4,
          "exp1_station": 1, "exp2_cryo": 1}
shop = {"premium": 3, "capital": 1}
st = ship_stats(E, levels, 37.0, shop)
u = {x["id"]: x for x in E["upgrades"]}
planets = {p["id"]: p for p in E["planets"]}
C = E["contracts"]
P = {
    "cost_tank_10": {k: cost_at(s, 10) for k, s in u["tank"]["cost"].items()},
    "cost_exp3": {k: cost_at(s, 0) for k, s in u["exp3_shield"]["cost"].items()},
    "shop_pilot_2": cost_at(next(i for i in shop_items(E) if i["id"] == "pilot_file")["cost"], 2),
    "stats": st,
    "prestige_1e9": prestige_gain(E["prestige"], 1e9),
    "pay_ares": contract_pay(E, planets["ares"], 3500.0, st) * (1 + C["quality_bonus"] * 0.8 ** C.get("quality_exp", 1)),
    "dv_kronos": hop_dv(planets["kronos"], 5000.0, st, Profile("x", waste=1.0, hover_s=0.0)),
    "fleet": 1e6 * st["drones"] * st["autopilot"],
    "bulk_tank": bulk_cost(u["tank"]["cost"]["credits"], 5, 10),
    "maxaff_tank": max_affordable(u["tank"]["cost"]["credits"], 5, 1e5),
    "avail_exp2_yes": True, "avail_exp2_no": False, "titan_no": False, "titan_yes": True,
    "fmt": [fmt(999), fmt(1234), fmt(5.6e6), fmt(1.5e15), fmt(1e40), fmt(123456789, "sci")],
}

fails = []
def cmp(key, a, b):
    if isinstance(b, dict):
        for k in b:
            cmp(f"{key}.{k}", a.get(k) if isinstance(a, dict) else None, b[k])
    elif isinstance(b, list):
        for i, (x, y) in enumerate(zip(a, b)):
            cmp(f"{key}[{i}]", x, y)
    elif isinstance(b, bool) or isinstance(b, str):
        if a != b: fails.append(f"{key}: godot={a!r} python={b!r}")
    else:
        if a is None or not math.isclose(float(a), float(b), rel_tol=1e-9, abs_tol=1e-9):
            fails.append(f"{key}: godot={a!r} python={b!r}")
for k, v in P.items():
    cmp(k, G.get(k), v)
print("reset_state (godot):", G["reset"])
if fails:
    print("DIVERGENCIAS:"); [print("  -", f) for f in fails]; sys.exit(1)
print(f"OK: {len(P)} grupos de valores identicos entre GDScript e Python")
