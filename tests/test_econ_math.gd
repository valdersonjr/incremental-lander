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
		"pay_towed_fail": EconMath.delivery_pay("luna", 1200.0, st, 0.8, "tight", 2, EconMath.cargo_mult("towed", false)),
		"cargo_rescue_ok": EconMath.cargo_mult("rescue", true),
		"gift_pay_luna": EconMath.gift_value("luna", 4200.0, st, "gift"),
		"gift_gas": EconMath.gift_gas(st, "gas"),
		"cargo_kinds_luna": EconMath.cargo_kinds("luna").size(),
		"fleet": EconMath.fleet_income_per_s(1e6, st),
		"bulk_tank": EconMath.bulk_cost(EconMath._find("upgrades", "tank")["cost"]["credits"], 5, 10),
		"maxaff_tank": EconMath.max_affordable(EconMath._find("upgrades", "tank")["cost"]["credits"], 5, 1e5),
		"avail_autopilot_yes": EconMath.upgrade_available("autopilot", 0, {"fleet": 1}),
		"avail_autopilot_no": EconMath.upgrade_available("autopilot", 0, {}),
		"fmt": [EconMath.fmt(999), EconMath.fmt(1234), EconMath.fmt(5.6e6), EconMath.fmt(1.5e15), EconMath.fmt(1e6), EconMath.fmt(1e9), EconMath.fmt(1e15), EconMath.fmt(1e40), EconMath.fmt(123456789, "sci")],
	}
	print("ECON_JSON=" + JSON.stringify(out))
	quit()
