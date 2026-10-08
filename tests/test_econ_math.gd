## Teste de paridade: EconMath (GDScript) x econ.py (Python), mesma spec data/economy.json.
## Rodar: python3 tests/test_econ_parity.py  (chama o Godot headless e compara com o Python)
extends SceneTree

func _init() -> void:
	EconMath.load_spec()
	var levels := {"thrust": 30, "tank": 26, "efficiency": 12, "gear": 5, "fleet": 3,
		"autopilot": 4}
	var st := EconMath.ship_stats(levels)
	var out := {
		"cost_tank_10": EconMath.upgrade_cost("tank", 10),
		"cost_fleet_2": EconMath.upgrade_cost("fleet", 2),
		"stats": st,
		"pay_luna": EconMath.contract_pay("luna", 3500.0, st, 0.8),
		"dv_luna": EconMath.estimated_hop_dv("luna", 5000.0, st),
		"pay_tight_rep": EconMath.delivery_pay("luna", 4200.0, st, 0.7, "tight", 2),
		"pay_narrow_norep": EconMath.delivery_pay("luna", 900.0, st, 0.95, "narrow", 0),
		"pay_tow2_fail": EconMath.delivery_pay("luna", 1200.0, st, 0.8, "tight", 3,
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
		"run_fatigue_5": EconMath.run_fatigue_mult(5),
		"road_nuvens": EconMath.road("nuvens").map(func(s: Dictionary) -> String: return s["id"]),
		"road_reached_cog": EconMath.road_reached_now(11, ["soft1"], "cogumelos").map(func(s: Dictionary) -> String: return s["id"]),
		"next_world": [EconMath.next_world("luna"), EconMath.next_world("jardim"), EconMath.next_world("bolhas")],
		"slots_sorvete": EconMath.mission_slots({"fast": 2}, "sorvete"),
		"slot_dist_sig": [EconMath.slot_distance("nuvens", "passenger0", 0.5), EconMath.slot_distance("bolhas", "tow2", 0.25)],
		"slot_kind": [EconMath.slot_kind("passenger2"), EconMath.slot_kind("simple0"), EconMath.slot_kind("tow")],
		"record_bonus": [EconMath.record_bonus(1000.0, 0.0), EconMath.record_bonus(1000.0, 800.0),
				EconMath.record_bonus(700.0, 800.0)],
		"world_of_stop": [EconMath.world_of_stop({"id": "world_jardim", "type": "world"}),
				EconMath.world_of_stop({"id": "heavy1", "type": "mission"})],
		"slot_dist": [EconMath.slot_distance("luna", "simple0", 0.3), EconMath.slot_distance("luna", "simple2", 0.9),
				EconMath.slot_distance("luna", "heavy", 0.5)],
		"rep_levels": [EconMath.reputation_level(0), EconMath.reputation_level(5), EconMath.reputation_level(14),
				EconMath.reputation_level(99)],
		"rep_pts": [EconMath.reputation_points(false, true), EconMath.reputation_points(true, false),
				EconMath.reputation_points(true, true)],
		"road_now": EconMath.road_reached_now(9, ["start", "heavy1"]).map(func(x: Dictionary) -> String: return x["id"]),
		"road_buy": [EconMath.road_can_buy("fleet", []), EconMath.road_can_buy("fleet", ["fleet"]),
				EconMath.road_can_buy("turbo", ["turbo"]), EconMath.road_can_buy("thrust", [])],
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
