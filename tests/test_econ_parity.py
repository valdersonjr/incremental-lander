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

levels = {"thrust": 30, "tank": 26, "efficiency": 12, "contracts": 50, "gear": 5, "fleet": 3, "autopilot": 4}
st = ship_stats(E, levels)
u = {x["id"]: x for x in E["upgrades"]}
planets = {p["id"]: p for p in E["planets"]}
C = E["contracts"]
P = {
    "cost_tank_10": {k: cost_at(s, 10) for k, s in u["tank"]["cost"].items()},
    "cost_fleet_2": {k: cost_at(s, 2) for k, s in u["fleet"]["cost"].items()},
    "stats": st,
    "pay_luna": contract_pay(E, planets["luna"], 3500.0, st) * (1 + C["quality_bonus"] * 0.8 ** C.get("quality_exp", 1)),
    "pay_tight_combo": delivery_pay(E, planets["luna"], 4200.0, st, 0.7, "tight", 3),
    "pay_narrow_combo9": delivery_pay(E, planets["luna"], 900.0, st, 0.95, "narrow", 9),
    "pay_towed_fail": delivery_pay(E, planets["luna"], 1200.0, st, 0.8, "tight", 2, cargo_mult(E, "towed", False)),
    "cargo_rescue_ok": cargo_mult(E, "rescue", True),
    "gift_pay_luna": gift_value(E, planets["luna"], 4200.0, st, next(k for k in gift_kinds(E, "luna") if k["id"] == "gift")),
    "gift_gas": gift_gas(st, next(k for k in gift_kinds(E, "luna") if k["id"] == "gas")),
    "cargo_kinds_luna": len(cargo_kinds(E, "luna")),
    "dv_luna": hop_dv(planets["luna"], 5000.0, st, Profile("x", skill=1.0, waste=1.0, hover_s=0.0)),
    "fleet": 1e6 * st["drones"] * st["autopilot"],
    "bulk_tank": bulk_cost(u["tank"]["cost"]["credits"], 5, 10),
    "maxaff_tank": max_affordable(u["tank"]["cost"]["credits"], 5, 1e5),
    "avail_autopilot_yes": True, "avail_autopilot_no": False,
    "fmt": [fmt(999), fmt(1234), fmt(5.6e6), fmt(1.5e15), fmt(1e6), fmt(1e9), fmt(1e15), fmt(1e40), fmt(123456789, "sci")],
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
if fails:
    print("DIVERGENCIAS:"); [print("  -", f) for f in fails]; sys.exit(1)
print(f"OK: {len(P)} grupos de valores identicos entre GDScript e Python")
