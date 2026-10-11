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

levels = {"thrust": 30, "tank": 26, "efficiency": 12, "gear": 5, "fleet": 3, "autopilot": 4}
st = ship_stats(E, levels)
u = {x["id"]: x for x in E["upgrades"]}
planets = {p["id"]: p for p in E["planets"]}
C = E["contracts"]
P = {
    "cost_tank_10": {k: cost_at(s, 10) for k, s in u["tank"]["cost"].items()},
    "cost_fleet_2": {k: cost_at(s, 2) for k, s in u["fleet"]["cost"].items()},
    "stats": st,
    "pay_luna": contract_pay(E, planets["luna"], 3500.0, st) * (1 + C["quality_bonus"] * 0.8 ** C.get("quality_exp", 1)),
    "pay_tight_rep": delivery_pay(E, planets["luna"], 4200.0, st, 0.7, "tight", 2),
    "pay_narrow_norep": delivery_pay(E, planets["luna"], 900.0, st, 0.95, "narrow", 0),
    "pay_tow2_fail": delivery_pay(E, planets["luna"], 1200.0, st, 0.8, "tight", 3,
                                  mission_mult(E, {"kind": "tow", "star": 2, "parts": [{"kind": "tow", "star": 2}]}, ["tow"])),
    "mission_passenger1": mission_mult(E, {"kind": "passenger", "star": 1, "parts": [{"kind": "passenger", "star": 1}]}),
    "mission_double": mission_mult(E, {"kind": "double", "star": 1, "parts": [{"kind": "heavy", "star": 3},
                                                                              {"kind": "tow", "star": 3}]}, ["tow"]),
    "mission_div_heavy2": mission_thrust_div(E, {"kind": "heavy", "star": 2, "parts": [{"kind": "heavy", "star": 2}]}),
    "mission_leg2_p3": mission_leg2(E, {"kind": "passenger", "star": 3, "parts": [{"kind": "passenger", "star": 3}]}),
    "mission_unlocked": missions_unlocked(E, {"heavy1", "heavy2", "soft1"}),
    "node_passenger1_no": node_ok(E, mission_spec(E)["nodes"][5], {"heavy1"}),
    "node_passenger1_yes": node_ok(E, mission_spec(E)["nodes"][5], {"heavy1", "fast1"}),
    "gift_pay_luna": gift_value(E, planets["luna"], 4200.0, st, next(k for k in gift_kinds(E, "luna") if k["id"] == "gift")),
    "gift_gas": gift_gas(st, next(k for k in gift_kinds(E, "luna") if k["id"] == "gas")),
    "run_fatigue_5": run_fatigue_mult(E, 5),
    "minigame_pay": [minigame_pay(E, planets["luna"], 900.0, st, 0.5), minigame_pay(E, planets["nuvens"], 900.0, st, 1.0)],
    "minigame_pay_star": [minigame_pay(E, planets["luna"], 900.0, st, 0.8, 3),
                          minigame_pay(E, planets["cogumelos"], 900.0, st, 2 / 3, 2)],
    "mission_partial": [mission_mult(E, {"kind": "passenger", "star": 3, "parts": [{"kind": "passenger", "star": 3}]},
                                     ["passenger"], {"passenger": 0.6}),
                        mission_mult(E, {"kind": "heavy", "star": 2, "parts": [{"kind": "heavy", "star": 2}]},
                                     ["heavy"], {})],
    "takeoff_twr": [takeoff_twr(planets["jardim"], "heavy", 2), takeoff_twr(planets["bolhas"], "tow", 3),
                    takeoff_twr(planets["bolhas"], "simple", 1), takeoff_twr(planets["luna"], "simple", 1)],
    "road_nuvens": [s["id"] for s in road_spec(E, "nuvens")],
    "road_reached_cog": [s["id"] for s in road_reached_now(E, 11, {"soft1"}, "cogumelos")],
    "next_world": [next_world(E, "luna"), next_world(E, "jardim"), next_world(E, "bolhas")],
    "slots_sorvete": mission_slots(E, {"fast": 2}, planets["sorvete"]),
    "slot_dist_sig": [slot_distance(E, planets["nuvens"], "passenger0", 0.5), slot_distance(E, planets["bolhas"], "tow2", 0.25)],
    "slot_kind": [slot_kind("passenger2"), slot_kind("simple0"), slot_kind("tow")],
    "record_bonus": [record_bonus(E, 1000.0, 0.0), record_bonus(E, 1000.0, 800.0), record_bonus(E, 700.0, 800.0)],
    "world_of_stop": [world_of_stop({"id": "world_jardim", "type": "world"}), world_of_stop({"id": "heavy1", "type": "mission"})],
    "slot_dist": [slot_distance(E, planets["luna"], "simple0", 0.3), slot_distance(E, planets["luna"], "simple2", 0.9),
                  slot_distance(E, planets["luna"], "heavy", 0.5)],
    "rep_levels": [reputation_level(E, 0), reputation_level(E, 5), reputation_level(E, 14), reputation_level(E, 99)],
    "rep_pts": [reputation_points(E, False, True), reputation_points(E, True, False), reputation_points(E, True, True)],
    "road_now": [s["id"] for s in road_reached_now(E, 9, {"start", "heavy1"})],
    "road_buy": [road_can_buy(E, "fleet", set()), road_can_buy(E, "fleet", {"fleet"}),
                 road_can_buy(E, "turbo", {"turbo"}), road_can_buy(E, "thrust", set())],
    "slots": mission_slots(E, {"simple": 1, "tow": 2, "heavy": 1}),
    "mission_kinds_luna": len(mission_kinds(E, "luna")),
    "dv_luna": hop_dv(planets["luna"], 5000.0, st, Profile("x", skill=1.0, waste=1.0, hover_s=0.0)),
    "felt": [felt_thrust(E, 4.0, 1.62), felt_thrust(E, 28.0, 1.62), felt_thrust(E, 46.0, 4.9)],
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
