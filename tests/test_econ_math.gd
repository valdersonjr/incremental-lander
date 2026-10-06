## Teste de paridade: EconMath (GDScript) x econ.py (Python), mesma spec data/economy.json.
## Rodar: python3 tests/test_econ_parity.py  (chama o Godot headless e compara com o Python)
extends SceneTree

func _init() -> void:
	EconMath.load_spec()
	var levels := {"thrust": 30, "tank": 26, "efficiency": 12, "contracts": 50, "gear": 5, "fleet": 3,
		"autopilot": 4}
	var st := EconMath.ship_stats(levels)
	var out := {
		"cost_tank_10": EconMath.upgrade_cost("tank", 10),
		"cost_fleet_2": EconMath.upgrade_cost("fleet", 2),
		"stats": st,
		"pay_luna": EconMath.contract_pay("luna", 3500.0, st, 0.8),
		"dv_luna": EconMath.estimated_hop_dv("luna", 5000.0, st),
		"pay_tight_combo": EconMath.delivery_pay("luna", 4200.0, st, 0.7, "tight", 3),
		"pay_narrow_combo9": EconMath.delivery_pay("luna", 900.0, st, 0.95, "narrow", 9),
		"pay_tow2_fail": EconMath.delivery_pay("luna", 1200.0, st, 0.8, "tight", 2,
				EconMath.mission_mult({"kind": "tow", "star": 2, "parts": [{"kind": "tow", "star": 2}]}, ["tow"])),
		"mission_passenger1": EconMath.mission_mult({"kind": "passenger", "star": 1, "parts": [{"kind": "passenger", "star": 1}]}),
		"mission_double": EconMath.mission_mult({"kind": "double", "star": 1, "parts": [{"kind": "heavy", "star": 3},
				{"kind": "tow", "star": 3}]}, ["tow"]),
		"mission_div_heavy2": EconMath.mission_thrust_div({"kind": "heavy", "star": 2, "parts": [{"kind": "heavy", "star": 2}]}),
		"mission_leg2_p3": EconMath.mission_leg2({"kind": "passenger", "star": 3, "parts": [{"kind": "passenger", "star": 3}]}),
		"mission_unlocked": EconMath.missions_unlocked(["heavy1", "heavy2", "soft1"]),
		"node_passenger1_no": EconMath.mission_node_ok(EconMath.mission_spec()["nodes"][5], ["heavy1"]),
		"node_passenger1_yes": EconMath.mission_node_ok(EconMath.mission_spec()["nodes"][5], ["heavy1", "fast1"]),
		"gift_pay_luna": EconMath.gift_value("luna", 4200.0, st, "gift"),
		"gift_gas": EconMath.gift_gas(st, "gas"),
		"slot_dist": [EconMath.slot_distance("luna", "simple0", 0.3), EconMath.slot_distance("luna", "simple2", 0.9),
				EconMath.slot_distance("luna", "heavy", 0.5)],
		"slots": EconMath.mission_slots({"simple": 1, "tow": 2, "heavy": 1}),
		"mission_kinds_luna": EconMath.mission_kinds("luna").size(),
		"fleet": EconMath.fleet_income_per_s(1e6, st),
		"bulk_tank": EconMath.bulk_cost(EconMath._find("upgrades", "tank")["cost"]["credits"], 5, 10),
		"maxaff_tank": EconMath.max_affordable(EconMath._find("upgrades", "tank")["cost"]["credits"], 5, 1e5),
		"avail_autopilot_yes": EconMath.upgrade_available("autopilot", 0, {"fleet": 1}),
		"avail_autopilot_no": EconMath.upgrade_available("autopilot", 0, {}),
		"fmt": [EconMath.fmt(999), EconMath.fmt(1234), EconMath.fmt(5.6e6), EconMath.fmt(1.5e15), EconMath.fmt(1e6), EconMath.fmt(1e9), EconMath.fmt(1e15), EconMath.fmt(1e40), EconMath.fmt(123456789, "sci")],
	}
	print("ECON_JSON=" + JSON.stringify(out))
	quit()
