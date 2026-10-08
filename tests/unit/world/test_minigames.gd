extends TestCase
## Minijogos do voo (v17): logica pura de scripts/world/minigames.gd.


func test_trilha_da_lua_no_arco_e_mais_alta_nas_estrelas_maiores() -> void:
	var a := {"x": 0.0, "y": 0.0}
	var b := {"x": 600.0, "y": 0.0}
	var low := Minigames.trail_points(a, b, 6, 1.0)
	var high := Minigames.trail_points(a, b, 6, 1.5)
	assert_eq(low.size(), 6)
	for i in low.size():
		assert_true(low[i].x > 0.0 and low[i].x < 600.0, "sem as pontas")
		assert_true(high[i].y < low[i].y, "estrela maior = trilha mais alta")
	assert_true(low[3].y < low[0].y, "o meio do arco e mais alto que a ponta")


func test_config_e_estrelas() -> void:
	var cfg := Minigames.spec("luna")
	assert_eq(str(cfg["verb"]), "Pegue!")
	assert_eq(int(Minigames.by_star(cfg["coins"], 1)), 6)
	assert_eq(int(Minigames.by_star(cfg["coins"], 9)), 11, "estrela maior que a lista = a ultima")
	assert_true(Minigames.spec("mundo_inventado").is_empty())


func test_encostar_pega() -> void:
	assert_true(Minigames.touches(Vector2(10, 10), Vector2(18, 10), 14.0))
	assert_false(Minigames.touches(Vector2(10, 10), Vector2(40, 10), 14.0))


func test_bonus_pela_fracao() -> void:
	var st := EconMath.ship_stats({})
	var full := EconMath.minigame_pay("luna", 800.0, st, 1.0)
	assert_true(full > 0.0)
	assert_almost(EconMath.minigame_pay("luna", 800.0, st, 0.5), full * 0.5, 1e-6)
	assert_almost(EconMath.minigame_pay("luna", 800.0, st, 2.0), full, 1e-6, "nunca passa do bonus inteiro")
