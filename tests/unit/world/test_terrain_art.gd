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
	assert_true(TerrainArt.load_meta("titan").is_empty())


func test_parallax() -> void:
	assert_eq(TerrainArt.layer_offset(Vector2(1000, -500), 0.0, Vector2(0.1, 0.2)), Vector2(100, 100))
	assert_eq(TerrainArt.layer_offset(Vector2(1000, -500), 0.0, Vector2.ZERO), Vector2.ZERO)
