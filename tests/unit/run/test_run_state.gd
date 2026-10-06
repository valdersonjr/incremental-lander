## RunState: ofertas, pagamento via EconMath, teto de entregas e fim do run.
extends TestCase

var stats: Dictionary


func before_each() -> void:
	EconMath.load_spec()
	stats = EconMath.ship_stats({})


func test_ofertas_deterministicas_e_na_faixa() -> void:
	var a := RunState.create("luna", stats, 42)
	var b := RunState.create("luna", stats, 42)
	assert_eq(a.offers, b.offers)
	assert_eq(a.offers.size(), 8)
	for d in a.offers:
		assert_between(d, 100.0, 15000.0)


func test_pagamento_igual_economia() -> void:
	var run := RunState.create("luna", stats, 1)
	var r := run.complete_delivery(800.0, 0.9, 40.0)
	assert_almost(r["credits"], EconMath.contract_pay("luna", 800.0, stats, 0.9))
	assert_almost(run.earned["credits"], r["credits"])


func test_oferta_cumprida_e_substituida() -> void:
	var run := RunState.create("luna", stats, 3)
	var before := run.offers.size()
	run.take_offer(0)
	assert_eq(run.offers.size(), before, "regenerate: a lista mantem o tamanho")


func test_teto_de_entregas_encerra_run() -> void:
	var run := RunState.create("luna", stats, 5)
	for i in run.max_deliveries:
		run.complete_delivery(500.0, 0.8, 20.0)
	assert_true(run.over)
	assert_eq(run.end_reason, "limite_de_entregas")


func test_batida_encerra_e_mantem_ganhos() -> void:
	var run := RunState.create("luna", stats, 5)
	run.complete_delivery(500.0, 0.8, 20.0)
	var ganho: float = run.earned["credits"]
	run.crash("vertical_rapido")
	assert_true(run.over)
	assert_almost(run.summary()["earned"]["credits"], ganho)


func test_sem_gas_nao_continua() -> void:
	var run := RunState.create("luna", stats, 5)
	assert_true(run.can_continue(100.0))
	assert_false(run.can_continue(0.0))
	assert_eq(run.best_offer(0.0), -1)


func test_cada_oferta_tem_tipo_de_plataforma() -> void:
	var run := RunState.create("luna", stats, 11)
	assert_eq(run.offer_tiers.size(), run.offers.size())
	for i in range(1, run.offers.size()):
		assert_true(run.offers[i - 1] <= run.offers[i], "ordenadas por distancia")
	var seen := {}
	for s in 30:
		var r := RunState.create("luna", stats, s)
		for t in r.offer_tiers:
			seen[t] = true
	assert_true(seen.has("normal") and seen.has("narrow") and seen.has("tight"), "os tres tipos aparecem")


func test_oferta_aceita_leva_o_tipo_e_paga_o_multiplicador() -> void:
	var run := RunState.create("luna", stats, 11)
	var i := run.offer_tiers.find("tight")
	if i < 0:
		run.offer_tiers[0] = "tight"
		i = 0
	var info := run.offer_info(i, 100.0)
	assert_eq(info["tier"], "tight")
	var d := run.take_offer(i)
	assert_eq(run.taken_tier, "tight")
	assert_eq(run.offer_tiers.size(), run.offers.size(), "regenerou com tipo")
	var cm := EconMath.cargo_mult(run.taken_cargo, true)          # Lua: a carga tambem multiplica (v8)
	var r := run.complete_delivery(d, 0.9, 30.0)
	assert_almost(r["credits"], EconMath.contract_pay("luna", d, stats, 0.9) * float(EconMath.pad_tier("tight")["mult"])
			* cm)
	assert_eq(run.taken_tier, "normal", "volta ao normal depois da entrega")


func test_combo_soma_em_pouso_bom_e_zera_em_pouso_duro() -> void:
	var run := RunState.create("luna", stats, 2)
	run.complete_delivery(500.0, 0.9, 20.0)
	run.complete_delivery(500.0, 0.9, 20.0)
	assert_eq(run.streak, 2)
	var r := run.complete_delivery(500.0, 0.9, 20.0)
	assert_almost(r["credits"], EconMath.contract_pay("luna", 500.0, stats, 0.9) * EconMath.combo_mult(2), 1e-6,
			"terceira entrega paga o combo de 2 pousos bons")
	run.complete_delivery(500.0, 0.2, 20.0)
	assert_eq(run.streak, 0, "pouso duro zera")
	assert_false(run.deliveries[-1]["good"])


func test_lua_tem_lados_e_cargas_sem_mudar_as_distancias() -> void:
	# lado e carga usam sorteador proprio: as distancias de um seed continuam as mesmas da v7
	var run := RunState.create("luna", stats, 42)
	assert_eq(run.offer_dirs.size(), run.offers.size())
	assert_eq(run.offer_cargo.size(), run.offers.size())
	var lados := {}
	var cargas := {}
	for s in 30:
		var r := RunState.create("luna", stats, s)
		for i in r.offers.size():
			lados[r.offer_dirs[i]] = true
			cargas[r.offer_cargo[i]] = true
	assert_true(lados.has(-1) and lados.has(1), "Lua: pedidos para os dois lados")
	for k: Dictionary in EconMath.cargo_kinds("luna"):
		assert_true(cargas.has(k["id"]), "carga %s nunca sorteada" % k["id"])


func test_carga_cumprida_paga_mais_e_falha_paga_menos() -> void:
	var run := RunState.create("luna", stats, 1)
	run.taken_cargo = "towed"
	var ok: float = run.complete_delivery(800.0, 0.9, 40.0, true)["credits"]
	assert_almost(ok, EconMath.contract_pay("luna", 800.0, stats, 0.9) * EconMath.cargo_mult("towed", true))
	var run2 := RunState.create("luna", stats, 1)
	run2.taken_cargo = "towed"
	var bad: float = run2.complete_delivery(800.0, 0.9, 40.0, false)["credits"]
	assert_true(bad < ok, "carga estragada paga menos")
	assert_false(run2.over, "carga estragada nao acaba o run")
	assert_eq(run2.deliveries[-1]["cargo"], "towed")
	assert_eq(run2.taken_cargo, "box", "proxima entrega comeca sem carga especial")


func test_take_offer_leva_lado_e_carga() -> void:
	var run := RunState.create("luna", stats, 11)
	var dir := run.offer_dirs[2]
	var cargo := run.offer_cargo[2]
	run.take_offer(2)
	assert_eq(run.taken_dir, dir)
	assert_eq(run.taken_cargo, cargo)
	assert_eq(run.offer_dirs.size(), run.offers.size())
