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


func test_refinaria_so_com_ares() -> void:
	var res := {"credits": 1e9, "ore": 1e9}
	assert_false(Purchases.buy(res, {}, "refinery", ["luna"], {}))
	assert_true(Purchases.buy(res, {}, "refinery", ["luna", "ares"], {}))


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
	assert_false("refinery" in ids, "refinaria exige Ares")
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
