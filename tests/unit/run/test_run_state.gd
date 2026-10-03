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
	var r := run.complete_delivery(d, 0.9, 30.0)
	assert_almost(r["credits"], EconMath.contract_pay("luna", d, stats, 0.9) * float(EconMath.pad_tier("tight")["mult"]))
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


func test_cristais_somam_ao_pagamento() -> void:
	var run := RunState.create("luna", stats, 2)
	var r := run.complete_delivery(800.0, 0.5, 20.0, 2)
	var base := EconMath.contract_pay("luna", 800.0, stats, 0.5)
	assert_almost(r["credits"], base + 2.0 * EconMath.pickup_value("luna", 800.0, stats))
	assert_eq(run.deliveries[-1]["crystals"], 2)
