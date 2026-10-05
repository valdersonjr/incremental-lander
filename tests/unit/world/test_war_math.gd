## Guerra no fundo: laco horizontal e linhas pixel-perfect (WarMath).
extends TestCase


func test_menor_caminho_no_laco() -> void:
	assert_almost(WarMath.wrap_dx(630.0, 10.0, 640.0), 20.0, 1e-6, "atravessa a emenda para a direita")
	assert_almost(WarMath.wrap_dx(10.0, 630.0, 640.0), -20.0, 1e-6, "atravessa a emenda para a esquerda")
	assert_almost(WarMath.wrap_dx(100.0, 300.0, 640.0), 200.0)


func test_x_na_tela_com_rolagem() -> void:
	assert_almost(WarMath.screen_x(100.0, 150.0, 640.0), 590.0)
	assert_almost(WarMath.screen_x(100.0, -1300.0, 640.0), fposmod(1400.0, 640.0))


func test_linha_inclusiva_e_continua() -> void:
	var pts := WarMath.line_points(Vector2i(0, 0), Vector2i(5, -3))
	assert_eq(pts[0], Vector2i(0, 0))
	assert_eq(pts[pts.size() - 1], Vector2i(5, -3))
	for i in pts.size() - 1:
		var d := pts[i + 1] - pts[i]
		assert_true(absi(d.x) <= 1 and absi(d.y) <= 1, "sem buracos na linha")


func test_contrato_da_guerra_na_lua() -> void:
	var war: Dictionary = TerrainArt.load_meta("luna").get("war", {})
	assert_false(war.is_empty(), "luna tem guerra no fundo")
	assert_true((war["targets"] as Array).size() > 0)
	if bool(war.get("peaceful", false)):
		assert_eq((war["muzzles"] as Array).size(), 0, "lua fofa: sem torres atirando")
	else:
		assert_true((war["muzzles"] as Array).size() > 0)
	for key: String in war["sprites"]:
		assert_true(ResourceLoader.exists(str(war["sprites"][key])), "sprite %s existe" % key)


func test_disco_pacifico_so_solta_feixe_em_cima_do_alvo() -> void:
	var cfg: Dictionary = (TerrainArt.load_meta("luna")["war"] as Dictionary).duplicate(true)
	cfg["targets"] = [[300, 200]]
	cfg["saucers"] = 1
	var fx := WarFx.new()
	fx.setup(cfg, 1)
	var s: Dictionary = fx._saucers[0]
	s["far"] = false
	s["speed"] = 0.0
	s["pos"] = Vector2(200, 120)                                  # longe (100 px): nada de feixe
	s["base_y"] = 120.0
	s["cool"] = 0.0
	fx._step(0.016)
	assert_eq(fx._lasers.size(), 0, "longe do alvo nao solta feixe")
	s["pos"] = Vector2(290, 120)                                  # centro do disco em x=302: em cima
	s["cool"] = 0.0
	var fired := false
	for i in 200:
		fx._step(0.016)
		fired = fired or fx._lasers.size() > 0
	assert_true(fired, "solta o feixe em cima do alvo")
	assert_eq(fx._blasts.size(), 0, "modo pacifico: sem explosoes")
	assert_eq(fx._tracers.size(), 0, "modo pacifico: sem tracantes")
	fx.free()
