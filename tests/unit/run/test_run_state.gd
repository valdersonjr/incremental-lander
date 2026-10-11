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
	assert_eq(a.offers.size(), 3, "so a Simples liberada: 3 pedidos (perto, medio, longe)")
	for d in a.offers:
		assert_between(d, 100.0, 15000.0)
	var lo := log(100.0)
	var third := (log(15000.0) - lo) / 3.0
	for i in 3:                                                # um pedido em cada faixa
		assert_between(log(a.offers[i]), lo + third * i - 1e-9, lo + third * (i + 1) + 1e-9)


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


func test_sem_teto_e_gas_cresce_por_entrega() -> void:
	var run := RunState.create("luna", stats, 5)
	var m := EconMath.simple_mission()
	var g0 := run.mission_gas(m, 800.0)
	for i in 10:
		run.complete_delivery(500.0, 0.8, 20.0)
	assert_false(run.over, "v15: sem teto de entregas")
	var k := float(EconMath.spec["contracts"]["run_fatigue"])
	assert_almost(run.mission_gas(m, 800.0), g0 * pow(k, 10), g0 * 1e-6, "gas da missao x fatigue^n")


func test_pista_sempre_acaba_pelo_gas() -> void:
	# v25: tanque enorme + todos os galoes (fixos, cada vez mais espacados): a viagem acaba
	var big := EconMath.ship_stats({"thrust": 60, "tank": 80, "efficiency": 60})
	var tank := float(big["tank"])
	var gas := tank
	var cans := EconMath.track_cans("luna", 1e6)
	var x := 0.0
	var ci := 0
	var n := 0
	while n < 500:
		var need := EconMath.estimated_hop_dv("luna", 180.0, big) / float(big["efficiency"])
		if need > gas:
			break
		gas -= need
		x += 180.0
		while ci < cans.size() and cans[ci] <= x:
			gas = minf(tank, gas + EconMath.track_can_gas(big))
			ci += 1
		n += 1
	assert_true(n < 500, "a viagem termina (%d pousos)" % n)
	assert_true(n > 3, "nave forte ainda faz varios pousos (%d)" % n)


func test_pista_paga_o_acumulado_e_estrelas_pela_nota() -> void:
	var run := RunState.create("luna", stats, 5)
	var near := run.complete_track_landing(0.0, 200.0, 0, 0.7, "normal", 20.0, false)
	var far := run.complete_track_landing(1000.0, 1200.0, 0, 0.7, "normal", 20.0, false)
	assert_true(float(far["credits"]) > float(near["credits"]) * 1.5, "200 m la longe valem mais que 200 m no comeco")
	var skip := run.complete_track_landing(1200.0, 1600.0, 1, 0.7, "normal", 20.0, false)
	assert_true(float(skip["credits"]) > float(far["credits"]) * 1.8, "o dobro de metros = quase o dobro")
	var accum := EconMath.track_accum("luna", 0.0, 200.0, stats)
	assert_true(is_equal_approx(float(near["credits"]), accum * EconMath.track_land_mult(0.7)), "banco = acumulado x pouso")
	assert_eq(int(run.deliveries[0]["stars"]), 2, "pouso bom = 2 estrelas")
	run.complete_track_landing(1600.0, 1800.0, 0, 0.95, "normal", 20.0, true)
	assert_eq(int(run.deliveries[-1]["stars"]), 3, "pouso perfeito = 3 estrelas")
	assert_eq(run.stars, 9)
	assert_eq(run.record_values()["run_distance"], 1800.0)


func test_numeros_do_run_para_recordes() -> void:
	var run := RunState.create("luna", stats, 5)
	run.complete_delivery(500.0, 0.8, 20.0, [], 0.0, true)
	run.complete_delivery(900.0, 0.9, 20.0, [], 0.0, false)
	var v := run.record_values()
	assert_eq(int(v["run_deliveries"]), 2)
	assert_almost(v["run_distance"], 1400.0, 1e-6)
	assert_eq(int(v["run_perfect"]), 1)
	assert_almost(v["run_money"], float(run.earned["credits"]), 1e-6)
	assert_almost(v["best_delivery"], maxf(float(run.deliveries[0]["rewards"]["credits"]),
			float(run.deliveries[1]["rewards"]["credits"])), 1e-6)


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


func test_jogador_escolhe_plataforma_e_estrela() -> void:
	var run := RunState.create("cogumelos", stats, 11, {"simple": 1, "soft": 3})
	assert_eq(run.offer_tiers.size(), run.offers.size())
	for i in range(1, run.offers.size()):
		assert_true(run.offers[i - 1] <= run.offers[i], "ordenadas por distancia")
	for t in run.offer_tiers:
		assert_eq(t, "normal", "pedido novo vem com plataforma normal")
	var i := run.offer_slot.find("soft0")
	assert_true(i >= 0, "um pedido do sapinho")
	assert_eq(run.stars_for(i), [1, 2, 3] as Array[int])
	var before: float = run.offer_info(i, 1e9)["pay_best"]
	run.set_choice(i, "tight", 3)
	assert_eq(run.offer_tiers[i], "tight")
	assert_eq(int(run.offer_mission[i]["star"]), 3)
	assert_true(run.offer_info(i, 1e9)["pay_best"] > before, "mais dificil paga mais")
	run.set_choice(i, "normal", 9)
	assert_eq(int(run.offer_mission[i]["star"]), 3, "estrela nao liberada e ignorada")


func test_tres_faixas_e_a_mesma_faixa_repoe() -> void:
	var run := RunState.create("sorvete", stats, 4, {"simple": 1, "fast": 1})
	assert_eq(run.offers.size(), 3, "3 pedidos do pinguim")
	var i := run.offer_slot.find("fast1")
	run.take_offer(i)
	assert_eq(run.offers.size(), 3)
	assert_eq(run.offer_slot.count("fast1"), 1, "a faixa do meio trouxe pedido novo")


func test_oferta_aceita_leva_o_tipo_e_paga_o_multiplicador() -> void:
	var run := RunState.create("luna", stats, 11)
	var i := 0
	run.set_choice(i, "tight", 1)
	var info := run.offer_info(i, 100.0)
	assert_eq(info["tier"], "tight")
	var d := run.take_offer(i)
	assert_eq(run.taken_tier, "tight")
	assert_eq(run.offer_tiers.size(), run.offers.size(), "regenerou com tipo")
	var cm := EconMath.mission_mult(run.taken_mission)             # a missao tambem multiplica (v12)
	var r := run.complete_delivery(d, 0.9, 30.0)
	assert_almost(r["credits"], EconMath.contract_pay("luna", d, stats, 0.9) * float(EconMath.pad_tier("tight")["mult"])
			* cm)
	assert_eq(run.taken_tier, "normal", "volta ao normal depois da entrega")


func test_reputacao_por_ratinho_soma_pontos() -> void:
	var run := RunState.create("luna", stats, 2)
	run.complete_delivery(500.0, 0.9, 20.0, [], 0.0, false)
	assert_eq(int(run.rep_points["simple"]), EconMath.reputation_points(true, false), "missao cumprida soma")
	run.complete_delivery(500.0, 0.9, 20.0, [], 0.0, true)
	assert_eq(int(run.rep_points["simple"]), EconMath.reputation_points(true, false) + EconMath.reputation_points(true, true),
			"pouso perfeito soma mais")
	assert_eq(int(run.deliveries[-1]["rep_pts"]), EconMath.reputation_points(true, true))


func test_reputacao_aumenta_o_pagamento_do_ratinho() -> void:
	var run := RunState.create("luna", stats, 2)
	var need := int(EconMath.reputation_levels()[1]["points"])
	run.rep_points = {"simple": need}                          # nivel 2 com o mineiro
	var r := run.complete_delivery(500.0, 0.9, 20.0)
	assert_almost(r["credits"], EconMath.contract_pay("luna", 500.0, stats, 0.9) * EconMath.reputation_mult(2), 1e-6)
	var run2 := RunState.create("luna", stats, 2)
	var r2 := run2.complete_delivery(500.0, 0.9, 20.0)
	assert_almost(r2["credits"], EconMath.contract_pay("luna", 500.0, stats, 0.9), 1e-6, "sem reputacao = sem bonus")


func test_missao_falhada_nao_da_reputacao() -> void:
	var run := RunState.create("luna", stats, 1)
	run.taken_mission = {"kind": "tow", "star": 1, "parts": [{"kind": "tow", "star": 1}]}
	run.complete_delivery(800.0, 0.9, 40.0, ["tow"], 0.0, true)
	assert_eq(int(run.rep_points.get("tow", 0)), 0)


func test_lua_tem_lados_e_so_missoes_liberadas() -> void:
	var run := RunState.create("luna", stats, 42)
	assert_eq(run.offer_dirs.size(), run.offers.size())
	assert_eq(run.offer_mission.size(), run.offers.size())
	var lados := {}
	for s in 30:
		var r := RunState.create("luna", stats, s)
		for i in r.offers.size():
			lados[r.offer_dirs[i]] = true
			assert_eq(r.offer_mission[i]["kind"], "simple", "sem nada liberado so aparece a Simples")
	assert_true(lados.has(-1) and lados.has(1), "Lua: pedidos para os dois lados")
	var a := RunState.create("luna", stats, 42, {"simple": 1, "heavy": 2, "soft": 1})
	var kinds := a.offer_mission.map(func(m: Dictionary) -> String: return m["kind"])
	assert_eq(kinds.count("simple"), 3, "v17: na Lua so o mineiro (3 faixas)")


func test_missao_cumprida_paga_mais_e_falha_paga_menos() -> void:
	var tow := {"kind": "tow", "star": 2, "parts": [{"kind": "tow", "star": 2}]}
	var run := RunState.create("luna", stats, 1)
	run.taken_mission = tow
	var ok: float = run.complete_delivery(800.0, 0.9, 40.0)["credits"]
	assert_almost(ok, EconMath.contract_pay("luna", 800.0, stats, 0.9) * EconMath.mission_mult(tow))
	var run2 := RunState.create("luna", stats, 1)
	run2.taken_mission = tow
	var bad: float = run2.complete_delivery(800.0, 0.9, 40.0, ["tow"])["credits"]
	assert_true(bad < ok, "regra falhou paga menos")
	assert_false(run2.over, "regra falhou nao acaba o run")
	assert_eq(run2.deliveries[-1]["mission"]["kind"], "tow")
	assert_eq(run2.taken_mission["kind"], "simple", "proxima entrega comeca Simples")
	assert_eq(run2.stars, 1, "1 estrela por entrega")


func test_passageiro_sem_segundo_trecho() -> void:
	for st in [1, 2, 3]:                                       # v17: estrelas = mais carneirinhos, sem taxi
		var m := {"kind": "passenger", "star": st, "parts": [{"kind": "passenger", "star": st}]}
		assert_almost(EconMath.mission_leg2(m), 0.0, 1e-9)


func test_pesada_gasta_mais_gas() -> void:
	var run := RunState.create("luna", stats, 1)
	var h3 := {"kind": "heavy", "star": 3, "parts": [{"kind": "heavy", "star": 3}]}
	assert_true(run.mission_gas(h3, 1000.0) > run.mission_gas(EconMath.simple_mission(), 1000.0))


func test_take_offer_leva_lado_e_missao() -> void:
	var run := RunState.create("luna", stats, 11, {"simple": 1, "fast": 1})
	var dir := run.offer_dirs[2]
	var m := run.offer_mission[2]
	run.take_offer(2)
	assert_eq(run.taken_dir, dir)
	assert_eq(run.taken_mission, m)
	assert_eq(run.offer_dirs.size(), run.offers.size())
	assert_eq(run.offer_mission.size(), run.offers.size())
