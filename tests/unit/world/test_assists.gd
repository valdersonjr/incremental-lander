## Ajudas de voo (Painel de bordo): arco ideal, queda prevista, cor da setinha, gas na chegada e regras de compra.
extends TestCase

const IDS := ["nav_color", "nav_trail", "nav_route", "land_shadow", "land_level", "land_predict", "gas_need"]


func _feet() -> float:
	return WorldConfig.m_to_px(float(WorldConfig.load_config()["lander"]["feet_offset_m"]))


func test_arco_liga_as_plataformas_e_passa_acima_da_crista() -> void:
	var t := TerrainGen.generate(5, "luna", [1000.0] as Array[float])
	var a: Dictionary = t["pads"][0]
	var b: Dictionary = t["pads"][1]
	var pts := Assists.arc(a, b, 20)
	assert_eq(pts.size(), 21)
	assert_almost(pts[0].x, float(a["x"]))
	assert_almost(pts[-1].x, float(b["x"]))
	for i in range(1, pts.size() - 1):
		assert_true(pts[i].y < TerrainGen.height_at(t["ridge"], pts[i].x) - _feet(), "arco acima do relevo")
	assert_true(pts[10].y < pts[3].y and pts[10].y < pts[17].y, "o meio e o mais alto")


func test_queda_prevista_cai_na_plataforma_devagar() -> void:
	var t := TerrainGen.generate(5, "luna", [1000.0] as Array[float])
	var b: Dictionary = t["pads"][1]
	var params := {"gravity": 1.62, "planet_drag": 0.0}
	var tol := {"max_vy": 7.0, "max_vx": 5.0, "max_tilt": 0.35}
	var start := Vector2(float(b["x"]), float(b["y"]) - _feet() - WorldConfig.m_to_px(5.0))
	var f := Assists.fall(start, Vector2.ZERO, params, t["ridge"])
	assert_true(f["hit"], "toca o chao")
	assert_almost((f["points"] as Array[Vector2])[-1].y, float(b["y"]) - _feet(), 1.0, "para nos pes, no topo do pad")
	assert_eq(Assists.verdict(f, b, 13.0, tol), "good")


func test_queda_rapida_ou_fora_da_plataforma() -> void:
	var t := TerrainGen.generate(5, "luna", [1000.0] as Array[float])
	var b: Dictionary = t["pads"][1]
	var params := {"gravity": 1.62, "planet_drag": 0.0}
	var tol := {"max_vy": 7.0, "max_vx": 5.0, "max_tilt": 0.35}
	var high := Vector2(float(b["x"]), float(b["y"]) - _feet() - WorldConfig.m_to_px(120.0))
	assert_eq(Assists.verdict(Assists.fall(high, Vector2.ZERO, params, t["ridge"]), b, 13.0, tol), "hard")
	var side := Vector2(float(b["x"]) - 300.0, float(b["y"]) - _feet() - WorldConfig.m_to_px(5.0))
	assert_eq(Assists.verdict(Assists.fall(side, Vector2.ZERO, params, t["ridge"]), b, 13.0, tol), "miss")
	var up := Assists.fall(high, Vector2(0, -400.0), params, t["ridge"])
	assert_eq(Assists.verdict(up, b, 13.0, tol), "", "subindo rapido: nao toca no tempo previsto")


func test_cor_da_setinha_pela_distancia() -> void:
	assert_eq(Assists.arrow_tier(1.0), "far")
	assert_eq(Assists.arrow_tier(0.5), "mid")
	assert_eq(Assists.arrow_tier(0.1), "near")


func test_gas_na_chegada_cai_com_a_distancia() -> void:
	var st := EconMath.ship_stats({})
	var near := Assists.gas_left_at_arrival("luna", 300.0, st, float(st["tank"]))
	var far := Assists.gas_left_at_arrival("luna", 3000.0, st, float(st["tank"]))
	assert_true(near > far)
	assert_true(near < float(st["tank"]))


func test_ajudas_sao_arvore_compra_unica_e_sobrevivem_ao_prestigio() -> void:
	for id: String in IDS:
		var u := EconMath._find("upgrades", id)
		assert_true(u.has("assist"), id + " e ajuda")
		assert_eq(int(u["max_level"]), 1, id + " compra unica")
	var res := {"credits": 1e9}
	var lv := {}
	assert_false(Purchases.buy(res, lv, "nav_trail", ["luna"], {}), "rastro exige a setinha colorida")
	assert_true(Purchases.buy(res, lv, "nav_color", ["luna"], {}))
	assert_true(Purchases.buy(res, lv, "nav_trail", ["luna"], {}))
	var keep: Array = EconMath.prestige_reset_state({})["keep_upgrades"]
	for id: String in IDS:
		assert_true(id in keep, id + " fica depois do prestigio")
