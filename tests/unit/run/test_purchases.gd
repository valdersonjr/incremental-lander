## Compras de upgrades: custo da spec, disponibilidade, comprar maximo, alcance.
extends TestCase


func before_each() -> void:
	EconMath.load_spec()


func test_comprar_desconta_custo_da_spec() -> void:
	var res := {"credits": 1000.0}
	var lv := {}
	var custo: float = EconMath.upgrade_cost("tank", 0)["credits"]
	assert_true(Purchases.buy(res, lv, "tank", ["luna"], {}))
	assert_eq(lv["tank"], 1)
	assert_almost(res["credits"], 1000.0 - custo)


func test_sem_dinheiro_nao_compra() -> void:
	var res := {"credits": 1.0}
	var lv := {}
	assert_false(Purchases.buy(res, lv, "tank", ["luna"], {}))
	assert_false(lv.has("tank"))


func test_comprar_maximo_para_quando_acaba() -> void:
	var res := {"credits": 500.0}
	var lv := {}
	var n := Purchases.buy_max(res, lv, "tank", ["luna"], {})
	assert_true(n >= 3)
	assert_eq(lv["tank"], n)
	assert_false(Purchases.can_afford(res, EconMath.upgrade_cost("tank", n)))


func test_linhas_do_hangar_mostram_proximo_valor() -> void:
	var rows := Purchases.upgrade_rows({"credits": 0.0}, {}, ["luna"], {}, 0.0)
	var ids := rows.map(func(r: Dictionary) -> String: return r["id"])
	assert_true("thrust" in ids and "tank" in ids)
	assert_false("fleet" in ids, "frota exige Motor de dobra")
	for r: Dictionary in rows:
		if r["id"] == "tank":
			assert_almost(r["next"], r["current"] * 1.12, 1e-6)


func test_alcance_cresce_com_tanque() -> void:
	var s0 := EconMath.ship_stats({})
	var s5 := EconMath.ship_stats({"tank": 5})
	var r0 := Purchases.max_reach_m("luna", s0, float(s0["tank"]))
	var r5 := Purchases.max_reach_m("luna", s5, float(s5["tank"]))
	assert_true(r0 > 100.0)
	assert_true(r5 > r0)
	assert_almost(EconMath.estimated_hop_dv("luna", r0, s0) / float(s0["efficiency"]), float(s0["tank"]), 1e-3)


func test_liberar_ares_desconta_e_libera() -> void:
	var res := {"credits": 1e6}
	var unlocked := ["luna"]
	var custo: float = EconMath._find("planets", "ares")["unlock"]["credits"]
	assert_true(Purchases.unlock_planet(res, unlocked, "ares", {}, {}))
	assert_true("ares" in unlocked)
	assert_almost(res["credits"], 1e6 - custo)


func test_kronos_exige_ares() -> void:
	var res := {"credits": 1e12, "ore": 1e9}
	assert_false(Purchases.unlock_planet(res, ["luna"], "kronos", {}, {}))
	assert_true(Purchases.unlock_planet(res, ["luna", "ares"], "kronos", {}, {}))


func test_motor_base_nao_voa_em_ares() -> void:
	assert_true(Purchases.can_fly("luna", EconMath.ship_stats({})))
	assert_false(Purchases.can_fly("ares", EconMath.ship_stats({})), "motor 4 < 1,05 x gravidade 5")
	assert_true(Purchases.can_fly("ares", EconMath.ship_stats({"thrust": 3})))


func test_decolar_exige_motor_e_alcance() -> void:
	var base := EconMath.ship_stats({})
	assert_true(Purchases.can_launch("luna", base), "nave inicial decola na Lua")
	assert_false(Purchases.can_launch("kronos", base), "motor 4 nao vence a gravidade 9")
	var forte := EconMath.ship_stats({"thrust": 42, "tank": 38, "efficiency": 35})
	assert_true(Purchases.can_launch("kronos", forte))


func test_melhor_mundo_para_decolar_apos_recomeco() -> void:
	# Cartas de navegacao mantem os mundos, mas a nave volta ao inicio: so a Lua serve
	var base := EconMath.ship_stats({})
	assert_eq(Purchases.best_launchable(["luna", "ares", "kronos"], base), "luna")
	var forte := EconMath.ship_stats({"thrust": 42, "tank": 38, "efficiency": 35})
	assert_eq(Purchases.best_launchable(["luna", "ares", "kronos"], forte), "kronos")


func test_marco_de_upgrade_para_o_jingle() -> void:
	assert_true(Purchases.milestone_crossed("thrust", 24, 25), "nivel 25 = marco")
	assert_true(Purchases.milestone_crossed("thrust", 10, 60), "comprar max passando dois marcos")
	assert_false(Purchases.milestone_crossed("thrust", 25, 26))
	assert_false(Purchases.milestone_crossed("gear", 0, 30), "sem marcos na spec")
	assert_true(Purchases.milestone_crossed("exp1_station", 0, 1), "etapa da Expedicao")
	assert_false(Purchases.milestone_crossed("thrust", 5, 5), "nada comprado")


func test_bloqueados_mostram_o_que_vem_e_somem_ao_liberar() -> void:
	var ids := Purchases.locked_upgrades({}, ["luna"], {}).map(func(r: Dictionary) -> String: return r["id"])
	assert_false("refinery" in ids, "refinaria saiu do jogo (v9)")
	assert_true("fleet" in ids)
	assert_false("thrust" in ids)
	assert_false(ids.any(func(id: String) -> bool: return id.begins_with("exp")))   # Expedicao fica surpresa
	var depois := Purchases.locked_upgrades({}, ["luna", "ares"], {"warp_drive": 1})
	assert_eq(depois.size(), 0)


func test_bloqueado_diz_o_que_falta() -> void:
	for r: Dictionary in Purchases.locked_upgrades({}, ["luna"], {}):
		if r["id"] == "fleet":
			assert_eq(r["requires_shop"], "warp_drive")
