## Frota: media da renda do jogador e pagamento pela formula da spec.
extends TestCase


func before_each() -> void:
	EconMath.load_spec()


func test_media_usa_ultimos_runs() -> void:
	var h := []
	for i in 7:
		h.append({"earned": {"credits": 100.0 * (i + 1)}, "seconds": 10.0})
	var avg := Fleet.average_income(h)
	assert_almost(avg["credits"], (300.0 + 400.0 + 500.0 + 600.0 + 700.0) / 50.0)


func test_sem_drones_frota_nao_paga() -> void:
	var h := [{"earned": {"credits": 1000.0}, "seconds": 10.0}]
	assert_true(Fleet.payout(EconMath.ship_stats({}), h, 100.0).is_empty())


func test_pagamento_igual_formula_da_spec() -> void:
	var st := EconMath.ship_stats({"fleet": 3, "autopilot": 2})
	var h := [{"earned": {"credits": 1000.0}, "seconds": 10.0}]
	var p := Fleet.payout(st, h, 50.0)
	assert_almost(p["credits"], EconMath.fleet_income_per_s(100.0, st) * 50.0)
