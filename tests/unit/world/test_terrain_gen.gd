## Terreno: deterministico por seed e plano nas plataformas.
extends TestCase


func test_mesmo_seed_mesmo_terreno() -> void:
	var a := TerrainGen.generate(7, "luna", [800.0] as Array[float])
	var b := TerrainGen.generate(7, "luna", [800.0] as Array[float])
	assert_eq(a["ridge"], b["ridge"])
	var c := TerrainGen.generate(8, "luna", [800.0] as Array[float])
	assert_true(a["ridge"] != c["ridge"], "seed diferente deveria mudar o relevo")


func test_plataformas_planas() -> void:
	var t := TerrainGen.generate(3, "ares", [500.0, 1200.0] as Array[float])
	assert_eq(t["pads"].size(), 3, "partida + 2 entregas")
	for p: Dictionary in t["pads"]:
		for dx in [-0.9, -0.5, 0.0, 0.5, 0.9]:
			var x: float = p["x"] + dx * p["half_width"]
			assert_almost(TerrainGen.height_at(t["ridge"], x), p["y"], 1e-3, "pad %d em dx %s" % [p["id"], dx])


func test_pad_at() -> void:
	var t := TerrainGen.generate(1, "luna", [800.0] as Array[float])
	assert_eq(TerrainGen.pad_at(t["pads"], 0.0)["id"], 0)
	assert_true(TerrainGen.pad_at(t["pads"], 400.0).is_empty())
