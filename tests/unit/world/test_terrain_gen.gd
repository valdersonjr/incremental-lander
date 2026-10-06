## Terreno: deterministico por seed e plano nas plataformas.
extends TestCase


func test_mesmo_seed_mesmo_terreno() -> void:
	var a := TerrainGen.generate(7, "luna", [800.0] as Array[float])
	var b := TerrainGen.generate(7, "luna", [800.0] as Array[float])
	assert_eq(a["ridge"], b["ridge"])
	var c := TerrainGen.generate(8, "luna", [800.0] as Array[float])
	assert_true(a["ridge"] != c["ridge"], "seed diferente deveria mudar o relevo")


func test_plataformas_planas() -> void:
	var t := TerrainGen.generate(3, "luna", [500.0, 1200.0] as Array[float])
	assert_eq(t["pads"].size(), 3, "partida + 2 entregas")
	for p: Dictionary in t["pads"]:
		for dx in [-0.9, -0.5, 0.0, 0.5, 0.9]:
			var x: float = p["x"] + dx * p["half_width"]
			assert_almost(TerrainGen.height_at(t["ridge"], x), p["y"], 1e-3, "pad %d em dx %s" % [p["id"], dx])


func test_pad_at() -> void:
	var t := TerrainGen.generate(1, "luna", [800.0] as Array[float])
	assert_eq(TerrainGen.pad_at(t["pads"], 0.0)["id"], 0)
	assert_true(TerrainGen.pad_at(t["pads"], 400.0).is_empty())


func test_crista_entre_plataformas_exige_subir() -> void:
	# entre duas plataformas a 1000 m, o relevo no meio passa de 12% da distancia acima da mais alta
	var t := TerrainGen.generate(5, "luna", [1000.0] as Array[float])
	var a: Dictionary = t["pads"][0]
	var b: Dictionary = t["pads"][1]
	var top := TerrainGen.highest_between(t["ridge"], float(a["x"]) + 40.0, float(b["x"]) - 40.0)
	var need := minf(float(a["y"]), float(b["y"])) - WorldConfig.m_to_px(120.0) * 0.95
	assert_true(top <= need, "crista baixa demais: topo %s, precisava <= %s" % [top, need])
	# ...mas um arco de 45 graus (sobe d/4) passa com folga sobre todo o trecho
	for i in range(1, 20):
		var x := lerpf(float(a["x"]), float(b["x"]), i / 20.0)
		var u := (x - float(a["x"])) / (float(b["x"]) - float(a["x"]))
		var arc_y := lerpf(float(a["y"]), float(b["y"]), u) - (x - float(a["x"])) * (1.0 - u)
		assert_true(arc_y < TerrainGen.height_at(t["ridge"], x) - 20.0, "arco raspa a crista em x=%s" % x)


func test_salto_curto_sem_crista() -> void:
	var t := TerrainGen.generate(5, "luna", [150.0] as Array[float])
	var flat := TerrainGen.generate(5, "luna", [150.0] as Array[float])
	assert_eq(t["ridge"], flat["ridge"], "deterministico")
	var a: Dictionary = t["pads"][0]
	var top := TerrainGen.highest_between(t["ridge"], float(a["x"]) + 40.0, float(a["x"]) + 110.0)
	assert_true(top > float(a["y"]) - 60.0, "salto curto nao ganha crista alta")


func test_tipos_de_plataforma_largura_e_elevacao() -> void:
	var t := TerrainGen.generate(9, "luna", [800.0, 1800.0, 2900.0] as Array[float],
			["normal", "narrow", "tight"] as Array[String])
	var pads: Array = t["pads"]
	assert_eq(pads[1]["tier"], "normal")
	assert_almost(float(pads[2]["half_width"]), WorldConfig.m_to_px(20.0), 1e-3, "estreita: 40 m")
	assert_almost(float(pads[3]["half_width"]), WorldConfig.m_to_px(14.0), 1e-3, "apertada: 28 m")
	# estreita fica num vale (bordas mais altas que a plataforma); apertada no alto de um pico
	var n: Dictionary = pads[2]
	var side := float(n["half_width"]) + WorldConfig.m_to_px(20.0)
	assert_true(TerrainGen.height_at(t["ridge"], float(n["x"]) + side) < float(n["y"]) - 5.0, "vale")
	var k: Dictionary = pads[3]
	side = float(k["half_width"]) + WorldConfig.m_to_px(20.0)
	assert_true(TerrainGen.height_at(t["ridge"], float(k["x"]) - side) > float(k["y"]) + 5.0, "pico")
	for p: Dictionary in pads:
		for dx in [-0.9, 0.0, 0.9]:
			assert_almost(TerrainGen.height_at(t["ridge"], float(p["x"]) + dx * float(p["half_width"])),
					float(p["y"]), 1e-3, "topo plano pad %d" % p["id"])


func test_vizinha_perto_demais_tira_a_elevacao() -> void:
	var t := TerrainGen.generate(9, "luna", [90.0] as Array[float], ["tight"] as Array[String])
	assert_eq(float(t["pads"][1]["lift"]), 0.0)


func test_plataforma_nova_nao_muda_as_antigas() -> void:
	# o lander pode estar pousado numa plataforma quando a proxima entrega e criada (terreno regenerado)
	var cases := [[[1402.0], ["tight"]], [[600.0, 1300.0], ["narrow", "tight"]]]
	for c: Array in cases:
		var d: Array[float] = []
		d.assign(c[0])
		var t: Array[String] = []
		t.assign(c[1])
		var before := TerrainGen.generate(7, "luna", d, t)
		for extra: float in [100.0, 127.0, 900.0]:            # 100 m = menor distancia do jogo (Lua)
			for tier: String in ["normal", "narrow", "tight"]:
				var d2 := d.duplicate()
				d2.append(d[d.size() - 1] + extra)
				var t2 := t.duplicate()
				t2.append(tier)
				var after := TerrainGen.generate(7, "luna", d2, t2)
				for i in before["pads"].size():
					var p0: Dictionary = before["pads"][i]
					var p1: Dictionary = after["pads"][i]
					assert_almost(float(p1["y"]), float(p0["y"]), 1e-3, "pad %d mudou de altura (+%s %s)" % [i, extra, tier])
					assert_almost(float(p1["lift"]), float(p0["lift"]), 1e-3)
					for dx in [-0.9, 0.0, 0.9]:
						var x: float = float(p0["x"]) + dx * float(p0["half_width"])
						assert_almost(TerrainGen.height_at(after["ridge"], x), float(p0["y"]), 1e-3,
								"topo do pad %d mudou (+%s %s)" % [i, extra, tier])


func test_estender_o_mapa_nao_muda_o_que_existia() -> void:
	# a nave voou para longe: o terreno cresce dos dois lados e nada do que ja existia muda
	var d: Array[float] = [900.0, 2100.0]
	var t: Array[String] = ["tight", "narrow"]
	var a := TerrainGen.generate(3, "luna", d, t)
	var b := TerrainGen.generate(3, "luna", d, t, Vector2(2400.0, 4800.0))
	var ra: PackedVector2Array = a["ridge"]
	var rb: PackedVector2Array = b["ridge"]
	assert_true(rb[0].x < ra[0].x - 2000.0 and rb[rb.size() - 1].x > ra[ra.size() - 1].x + 4000.0, "cresceu")
	for x in range(int(ra[0].x) + 1, int(ra[ra.size() - 1].x), 37):
		assert_almost(TerrainGen.height_at(rb, x), TerrainGen.height_at(ra, x), 1e-3, "relevo mudou em x=%d" % x)
	for i in a["pads"].size():
		assert_eq(a["pads"][i], b["pads"][i])
	var meta := TerrainArt.load_meta("luna")
	var pads: Array[Dictionary] = []
	pads.assign(a["pads"])
	var rocks_a := TerrainArt.rock_spots(ra, pads, 3, meta)
	var rocks_b := TerrainArt.rock_spots(rb, pads, 3, meta)
	for r in rocks_a:
		assert_true(rocks_b.has(r), "pedra mudou de lugar ao estender")


## Busca binaria da altura = interpolacao linear do contorno (antes era busca linear; o resultado nao pode mudar).
func test_altura_por_busca_binaria_igual_a_linear() -> void:
	var d: Array[float] = [900.0, 2500.0]
	var t: Array[String] = ["narrow", "tight"]
	var ridge: PackedVector2Array = TerrainGen.generate(5, "luna", d, t, Vector2(2400, 4800))["ridge"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 300:
		var x := rng.randf_range(ridge[0].x - 50.0, ridge[ridge.size() - 1].x + 50.0)
		var expected := ridge[0].y if x <= ridge[0].x else ridge[ridge.size() - 1].y
		for j in range(1, ridge.size()):
			if ridge[j].x >= x and x > ridge[0].x:
				var a := ridge[j - 1]
				var b := ridge[j]
				expected = lerpf(a.y, b.y, (x - a.x) / maxf(b.x - a.x, 0.0001))
				break
		assert_almost(TerrainGen.height_at(ridge, x), expected)


func test_pedido_a_esquerda_plano_e_com_crista() -> void:
	# Lua (2026-10-05): plataforma a esquerda da partida — topo plano e crista no meio do trecho, como a direita
	var t := TerrainGen.generate(5, "luna", [-1000.0] as Array[float])
	var b: Dictionary = t["pads"][1]
	assert_almost(float(b["x"]), WorldConfig.m_to_px(-1000.0), 1e-3)
	for dx in [-0.9, 0.0, 0.9]:
		assert_almost(TerrainGen.height_at(t["ridge"], float(b["x"]) + dx * float(b["half_width"])), float(b["y"]), 1e-3)
	var a: Dictionary = t["pads"][0]
	var top := TerrainGen.highest_between(t["ridge"], float(b["x"]) + 40.0, float(a["x"]) - 40.0)
	var need := minf(float(a["y"]), float(b["y"])) - WorldConfig.m_to_px(120.0) * 0.95
	assert_true(top <= need, "crista baixa demais a esquerda: topo %s, precisava <= %s" % [top, need])


func test_voltar_por_cima_de_plataformas_nao_muda_as_antigas() -> void:
	# ida para a direita e volta para a esquerda passando por cima da partida: nenhuma plataforma antiga muda
	var d: Array[float] = [700.0, 1500.0]
	var t: Array[String] = ["normal", "narrow"]
	var before := TerrainGen.generate(9, "luna", d, t)
	var d2 := d.duplicate()
	d2.append(-600.0)
	var t2 := t.duplicate()
	t2.append("tight")
	var after := TerrainGen.generate(9, "luna", d2, t2)
	for i in before["pads"].size():
		var p0: Dictionary = before["pads"][i]
		for dx in [-0.9, 0.0, 0.9]:
			var x: float = float(p0["x"]) + dx * float(p0["half_width"])
			assert_almost(TerrainGen.height_at(after["ridge"], x), float(p0["y"]), 1e-3, "topo do pad %d mudou" % i)


## Relevo de cada tipo de missao (v15): deterministico, plataformas planas e sem paredoes mais ingremes que as do
## relevo de sempre (as bordas das plataformas ja tem degraus curtos) nem que a encosta das mesas.
func test_relevo_das_missoes() -> void:
	var base := _steepest(TerrainGen.generate(9, "luna", [1500.0] as Array[float])["ridge"])
	var limit := maxf(base, float(WorldConfig.load_config()["terrain"]["pad_side_slope"])) + 0.05
	for kind: String in ["simple", "heavy", "soft", "fast", "tow", "passenger", "taxi"]:
		var k := "passenger" if kind == "taxi" else kind
		var shape := TerrainGen.mission_shape({"kind": k, "star": 1, "parts": [{"kind": k, "star": 1}]},
				1 if kind == "taxi" else 0)
		var a := TerrainGen.generate(9, "luna", [1500.0] as Array[float], ["normal"] as Array[String], Vector2.ZERO, shape)
		var b := TerrainGen.generate(9, "luna", [1500.0] as Array[float], ["normal"] as Array[String], Vector2.ZERO, shape)
		assert_eq(a["ridge"], b["ridge"], kind + ": mesma seed deveria dar o mesmo relevo")
		for p: Dictionary in a["pads"]:
			for dx in [-0.9, 0.0, 0.9]:
				assert_almost(TerrainGen.height_at(a["ridge"], float(p["x"]) + dx * float(p["half_width"])),
						float(p["y"]), 1e-3, "%s: plataforma %d plana" % [kind, p["id"]])
		var steep := _steepest(a["ridge"])
		assert_true(steep <= limit, "%s: encosta de %.2f (limite %.2f)" % [kind, steep, limit])


func _steepest(r: PackedVector2Array) -> float:
	var steep := 0.0
	for j in range(1, r.size()):
		if r[j].x - r[j - 1].x > 0.5:
			steep = maxf(steep, absf(r[j].y - r[j - 1].y) / (r[j].x - r[j - 1].x))
	return steep


func test_relevo_das_missoes_muda_o_trecho() -> void:
	var plain := TerrainGen.generate(9, "luna", [1500.0] as Array[float])
	var heavy := TerrainGen.generate(9, "luna", [1500.0] as Array[float], ["normal"] as Array[String], Vector2.ZERO,
			{"rise_m": 80.0})
	assert_true(float(heavy["pads"][1]["y"]) < float(plain["pads"][1]["y"]) - WorldConfig.m_to_px(70.0),
			"Pesada: o alvo deveria ficar ~80 m mais alto")
	var soft := TerrainGen.generate(9, "luna", [1500.0] as Array[float], ["normal"] as Array[String], Vector2.ZERO,
			{"target_lift_m": 70.0})
	assert_almost(float(soft["pads"][1]["lift"]), WorldConfig.m_to_px(70.0), 0.01, "Suave: alvo numa mesa")
	var tow := TerrainGen.generate(9, "luna", [1500.0] as Array[float], ["normal"] as Array[String], Vector2.ZERO,
			{"crest_scale": 0.0, "basin_m": 60.0})
	var mid := WorldConfig.m_to_px(750.0)
	assert_true(TerrainGen.height_at(tow["ridge"], mid) > TerrainGen.height_at(plain["ridge"], mid),
			"Cabo: o meio do caminho deveria ficar mais baixo (cratera, sem crista)")
	assert_eq(TerrainGen.mission_shape({"kind": "simple", "star": 1, "parts": []}), {}, "Simples: relevo de sempre")
