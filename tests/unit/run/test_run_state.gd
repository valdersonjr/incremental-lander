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
