## Ferramenta de verificacao: imprime o contorno do terreno (JSON) para plotar fora do Godot.
## godot --headless --path . --script res://tests/tools/dump_terrain.gd
extends SceneTree

func _init() -> void:
	var out := {}
	var cases := {
		"luna_868": ["luna", [868.0], ["normal"]],
		"luna_tiers": ["luna", [700.0, 1500.0, 2600.0], ["narrow", "tight", "normal"]],
		"kronos_3000": ["kronos", [3000.0], ["tight"]],
	}
	for k: String in cases:
		var c: Array = cases[k]
		var d: Array[float] = []
		d.assign(c[1])
		var t: Array[String] = []
		t.assign(c[2])
		var g := TerrainGen.generate(7, c[0], d, t)
		var pts := []
		for p: Vector2 in g["ridge"]:
			pts.append([p.x, -p.y])
		out[k] = {"ridge": pts, "pads": g["pads"]}
	print("TERRAIN_JSON=" + JSON.stringify(out))
	quit()
