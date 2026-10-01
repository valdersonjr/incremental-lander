## Arte do terreno: faces por inclinacao, faixas cisalhadas, pedregulhos fora das plataformas, parallax.
extends TestCase


func test_face_por_inclinacao() -> void:
	assert_eq(TerrainArt.face_of(Vector2(0, 0), Vector2(16, -10), 0.15), "lit", "sobe p/ direita = luz")
	assert_eq(TerrainArt.face_of(Vector2(0, 0), Vector2(16, 10), 0.15), "shade", "desce = sombra")
	assert_eq(TerrainArt.face_of(Vector2(0, 0), Vector2(16, 1), 0.15), "flat")


func test_faixa_cisalhada_cobre_todos_os_segmentos() -> void:
	var ridge := PackedVector2Array([Vector2(0, 0), Vector2(16, -10), Vector2(32, -10), Vector2(48, 5)])
	var g := TerrainArt.band(ridge, 88.0, 0.15)
	var quads := 0
	for f: String in TerrainArt.FACES:
		quads += (g[f]["polygons"] as Array).size()
		assert_eq(g[f]["polygon"].size(), g[f]["uv"].size(), "um uv por vertice (%s)" % f)
	assert_eq(quads, 3)
	var lit: PackedVector2Array = g["lit"]["polygon"]
	# paralelogramo: lados verticais de altura 88 (coluna desce reta -> pixel-perfect)
	assert_almost(lit[3].y - lit[0].y, 88.0)
	assert_almost(lit[3].x, lit[0].x)
	assert_eq(g["lit"]["uv"][1], Vector2(16, 0), "uv x = x do mundo (textura repete)")


func test_pedregulhos_fora_das_plataformas_e_deterministicos() -> void:
	var t := TerrainGen.generate(7, "luna", [800.0] as Array[float])
	var pads: Array[Dictionary] = []
	pads.assign(t["pads"])
	var meta := TerrainArt.load_meta("luna")
	assert_false(meta.is_empty(), "luna tem arte")
	var a := TerrainArt.rock_spots(t["ridge"], pads, 7, meta)
	var b := TerrainArt.rock_spots(t["ridge"], pads, 7, meta)
	assert_true(a.size() > 10, "deveria espalhar pedregulhos")
	assert_eq(a, b)
	var half := float(meta["rock_cell"][0]) * 0.5
	for r in a:
		var cx: float = r["pos"].x + half
		for p in pads:
			assert_true(absf(cx - float(p["x"])) >= float(p["half_width"]) + 11.0, "pedra em cima de plataforma")


func test_planeta_sem_arte_usa_placeholder() -> void:
	assert_true(TerrainArt.load_meta("planeta_sem_arte").is_empty())


func test_parallax() -> void:
	assert_eq(TerrainArt.layer_offset(Vector2(1000, -500), 0.0, Vector2(0.1, 0.2)), Vector2(100, 100))
	assert_eq(TerrainArt.layer_offset(Vector2(1000, -500), 0.0, Vector2.ZERO), Vector2.ZERO)


func test_plataforma_alinhada_ao_topo_do_deck() -> void:
	var pad := {"x": 100.0, "y": 50.0, "half_width": 32.0}
	assert_eq(TerrainArt.pad_origin(pad), Vector2(60, 40), "deck de 64 px centrado; topo do deck na linha 10")
	assert_eq(TerrainArt.beam_origin(pad).y + 84.0, 50.0, "base do feixe encosta no deck")
	assert_true(TerrainArt.marker_origin(pad).y < TerrainArt.beam_origin(pad).y, "marcador acima do feixe")


func test_parallax_limitado() -> void:
	# camera muito alta: o deslocamento para no limite (a planicie nao sai da tela)
	assert_eq(TerrainArt.layer_offset(Vector2(0, -5000), 0.0, Vector2(0, 0.1), -90.0, 119.0).y, 119.0)
	assert_eq(TerrainArt.layer_offset(Vector2(0, 5000), 0.0, Vector2(0, 0.1), -90.0, 119.0).y, -90.0)
	assert_eq(TerrainArt.layer_offset(Vector2(0, -500), 0.0, Vector2(0, 0.1), -90.0, 119.0).y, 50.0)


func test_quadro_da_animacao_em_laco() -> void:
	assert_eq(TerrainArt.anim_frame(0.0, 100.0, 6), 0)
	assert_eq(TerrainArt.anim_frame(0.25, 100.0, 6), 2)
	assert_eq(TerrainArt.anim_frame(0.65, 100.0, 6), 0, "volta ao primeiro quadro")
	assert_eq(TerrainArt.anim_frame(0.0, 100.0, 6, 3), 3, "fase desincroniza")
	assert_eq(TerrainArt.anim_frame(5.0, 100.0, 1), 0, "sem animacao")

