## Obstaculos do ceu (SkyField + LandingRules.obstacle_bounce).
extends TestCase

var cfg: Dictionary


func before_each() -> void:
	cfg = WorldConfig.load_config()["sky_obstacles"]


func test_perto_do_chao_nao_tem_nada() -> void:
	assert_almost(SkyField.chance(0.0, cfg), 0.0)
	assert_almost(SkyField.chance(float(cfg["free_m"]), cfg), 0.0)


func test_mais_alto_mais_obstaculos() -> void:
	var free := float(cfg["free_m"])
	var full := float(cfg["full_m"])
	var mid := SkyField.chance((free + full) * 0.5, cfg)
	assert_true(mid > 0.0 and mid < SkyField.chance(full, cfg), "sobe com a altura")
	assert_almost(SkyField.chance(full * 3.0, cfg), float(cfg["max_p"]), 1e-6, "acima de full_m fica no maximo")


func test_celula_deterministica_e_densidade() -> void:
	var size := WorldConfig.m_to_px(float(cfg["cell_m"]))
	var ref_y := 0.0
	var low := 0
	var high := 0
	for i in 200:
		var a := SkyField.cell(i, -1, 7, ref_y, cfg)                    # logo acima do relevo: faixa livre
		low += 0 if a.is_empty() else 1
		var j := -int(ceilf(WorldConfig.m_to_px(float(cfg["full_m"])) / size)) - 2
		var b := SkyField.cell(i, j, 7, ref_y, cfg)
		high += 0 if b.is_empty() else 1
		assert_eq(b, SkyField.cell(i, j, 7, ref_y, cfg), "mesma seed = mesmo obstaculo")
	assert_eq(low, 0, "nada na faixa livre")
	assert_true(high > 100, "la no alto quase toda celula tem (%d/200)" % high)


func test_batida_devolve_normal_para_fora() -> void:
	var circles := [[0, 0, 6]]
	assert_eq(SkyField.hit_normal(Vector2(30, 0), 10.0, Vector2.ZERO, circles), Vector2.ZERO, "longe: nada")
	var n := SkyField.hit_normal(Vector2(12, 0), 10.0, Vector2.ZERO, circles)
	assert_almost(n.x, 1.0, 1e-6, "normal aponta da area para a nave")


func test_batida_no_obstaculo_sempre_quica() -> void:
	var sc: Dictionary = WorldConfig.load_config()["landing"]["scrape"]
	var v := LandingRules.obstacle_bounce(Vector2(-45.0, 0.0), Vector2.RIGHT, sc)   # rapido demais p/ raspao
	assert_true(v.x > 0.0, "volta para tras")
	assert_almost(v.x, 45.0 * float(sc["restitution"]), 1e-6)
