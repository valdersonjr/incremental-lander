## Compras de upgrades: custo da spec, disponibilidade, comprar maximo, alcance.
extends TestCase


func before_each() -> void:
	EconMath.load_spec()


func test_comprar_desconta_custo_da_spec() -> void:
	var res := {"credits": 1000.0}
	var lv := {}
	var custo: float = EconMath.upgrade_cost("tank", 0)["credits"]
	assert_true(Purchases.buy(res, lv, "tank"))
	assert_eq(lv["tank"], 1)
	assert_almost(res["credits"], 1000.0 - custo)


func test_sem_dinheiro_nao_compra() -> void:
	var res := {"credits": 1.0}
	var lv := {}
	assert_false(Purchases.buy(res, lv, "tank"))
	assert_false(lv.has("tank"))


func test_comprar_maximo_para_quando_acaba() -> void:
	var res := {"credits": 500.0}
	var lv := {}
	var n := Purchases.buy_max(res, lv, "tank")
	assert_true(n >= 3)
	assert_eq(lv["tank"], n)
	assert_false(Purchases.can_afford(res, EconMath.upgrade_cost("tank", n)))


func test_linhas_do_hangar_mostram_proximo_valor() -> void:
	var rows := Purchases.upgrade_rows({"credits": 0.0}, {})
	var ids := rows.map(func(r: Dictionary) -> String: return r["id"])
	assert_true("thrust" in ids and "tank" in ids)
	assert_true("fleet" in ids, "frota liberada por creditos")
	assert_false("autopilot" in ids, "piloto automatico exige 1 drone")
	var tank_eff: Dictionary = EconMath._find("upgrades", "tank")["effect"]   # efeito do proximo nivel, pela spec
	for r: Dictionary in rows:
		if r["id"] == "tank":
			var steps := float(tank_eff.get("step", 1))           # v20: o valor muda no proximo degrau
			var want: float = r["current"] + tank_eff["value"] * steps if tank_eff["op"] == "add" \
					else r["current"] * pow(tank_eff["value"], steps)
			assert_almost(r["next"], want, 1e-6)


func test_alcance_cresce_com_tanque() -> void:
	var s0 := EconMath.ship_stats({})
	var s5 := EconMath.ship_stats({"tank": 10})               # v20: a Gasolina melhora no degrau
	var r0 := Purchases.max_reach_m("luna", s0, float(s0["tank"]))
	var r5 := Purchases.max_reach_m("luna", s5, float(s5["tank"]))
	assert_true(r0 > 100.0)
	assert_true(r5 > r0)
	assert_almost(EconMath.estimated_hop_dv("luna", r0, s0) / float(s0["efficiency"]), float(s0["tank"]), 1e-3)


func test_decolar_exige_motor_e_alcance() -> void:
	var base := EconMath.ship_stats({})
	assert_true(Purchases.can_fly("luna", base))
	assert_true(Purchases.can_launch("luna", base), "nave inicial decola na Lua")


func test_marco_de_upgrade_para_o_jingle() -> void:
	var every := int(EconMath._find("upgrades", "thrust")["milestones"][0]["every"])   # v19: 10 (o degrau)
	assert_true(Purchases.milestone_crossed("thrust", every - 1, every), "nivel %d = marco" % every)
	assert_true(Purchases.milestone_crossed("thrust", 1, every * 2 + 1), "comprar max passando dois marcos")
	assert_false(Purchases.milestone_crossed("thrust", every, every + 1))
	assert_false(Purchases.milestone_crossed("gear", 0, 30), "sem marcos na spec")
	assert_false(Purchases.milestone_crossed("thrust", 5, 5), "nada comprado")


func test_bloqueados_mostram_o_que_vem_e_somem_ao_liberar() -> void:
	var ids := Purchases.locked_upgrades({}).map(func(r: Dictionary) -> String: return r["id"])
	assert_true("autopilot" in ids, "piloto automatico pede 1 drone")
	assert_false("fleet" in ids, "frota liberada por creditos desde o comeco")
	assert_false("thrust" in ids)
	assert_false(ids.any(func(id: String) -> bool: return EconMath._find("upgrades", id).has("assist")))
	assert_eq(Purchases.locked_upgrades({"fleet": 1}).size(), 0)


func test_bloqueado_diz_o_que_falta() -> void:
	for r: Dictionary in Purchases.locked_upgrades({}):
		if r["id"] == "autopilot":
			assert_eq(r["requires"], "fleet")
