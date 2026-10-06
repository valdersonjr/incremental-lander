## Presentes no alto do morro (v10): posicao, toque, sorteio e pagamento junto com a entrega.
extends TestCase


func test_presente_fica_no_ponto_mais_alto_do_meio_do_salto() -> void:
	var t := TerrainGen.generate(5, "luna", [1000.0] as Array[float])
	var a: Dictionary = t["pads"][0]
	var b: Dictionary = t["pads"][1]
	var p := Gifts.place(a, b, t["ridge"])
	var d := float(b["x"]) - float(a["x"])
	assert_between(p.x, float(a["x"]) + d * 0.2 - 1.0, float(a["x"]) + d * 0.8 + 1.0, "no meio do salto")
	assert_almost(p.y, roundf(TerrainGen.height_at(t["ridge"], p.x)), 1.0, "assentado no chao")
	for i in 30:
		var x := lerpf(float(a["x"]) + d * 0.2, float(a["x"]) + d * 0.8, i / 29.0)
		assert_true(TerrainGen.height_at(t["ridge"], x) >= p.y - 1.0, "nada mais alto no meio")


func test_presente_para_a_esquerda_tambem() -> void:
	var t := TerrainGen.generate(5, "luna", [1000.0] as Array[float])
	var a: Dictionary = t["pads"][1]
	var b: Dictionary = t["pads"][0]
	var p := Gifts.place(a, b, t["ridge"])
	assert_between(p.x, float(b["x"]), float(a["x"]))


func test_encostar_devagar_pega_rapido_ou_longe_nao() -> void:
	var g := Vector2(100, 200)
	assert_true(Gifts.touches(g + Vector2(3, -12), Vector2(1, 1), g))
	assert_false(Gifts.touches(g + Vector2(3, -12), Vector2(20, 0), g), "rapido demais")
	assert_false(Gifts.touches(g + Vector2(0, -120), Vector2.ZERO, g), "longe")


func test_sorteio_deterministico_e_perto_da_chance() -> void:
	var n := 0
	for i in 400:
		var k := EconMath.draw_gift("luna", Gifts.rng_for(3, i))
		assert_eq(k, EconMath.draw_gift("luna", Gifts.rng_for(3, i)), "mesmo seed, mesmo presente")
		if k != "":
			n += 1
			assert_true(k in ["gas", "gift"])
	var chance := float(EconMath.spec["contracts"]["gifts"]["chance"])
	assert_between(n / 400.0, chance - 0.1, chance + 0.1)


func test_presente_soma_ao_pagamento_da_entrega() -> void:
	var st := EconMath.ship_stats({})
	var run := RunState.create("luna", st, 2)
	var plain := RunState.create("luna", st, 2)
	var extra := EconMath.gift_value("luna", 800.0, st, "gift")
	assert_true(extra > 0.0)
	var a: float = run.complete_delivery(800.0, 0.9, 40.0, true, extra)["credits"]
	var b: float = plain.complete_delivery(800.0, 0.9, 40.0, true)["credits"]
	assert_almost(a, b + extra, 1e-6)
	assert_almost(run.deliveries[-1]["gift_pay"], extra)
