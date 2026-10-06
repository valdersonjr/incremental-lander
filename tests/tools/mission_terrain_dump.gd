## Ferramenta de verificacao (v15): imprime o relevo de cada tipo de missao (TerrainGen.mission_shape) num salto de
## 1200 m, em JSON, para plotar fora do Godot.  gdtool.py run res://tests/tools/mission_terrain_dump.tscn
extends Node


func _ready() -> void:
	var out := {}
	for kind: String in ["simple", "heavy", "soft", "fast", "tow", "passenger", "taxi"]:
		var k := "passenger" if kind == "taxi" else kind
		var m := {"kind": k, "star": 1, "parts": [{"kind": k, "star": 1}]}
		var g := TerrainGen.generate(11, "luna", [1200.0] as Array[float], ["normal"] as Array[String], Vector2.ZERO,
				TerrainGen.mission_shape(m, 1 if kind == "taxi" else 0))
		var pts := []
		for p: Vector2 in g["ridge"]:
			pts.append([snappedf(p.x, 0.1), snappedf(-p.y, 0.1)])
		out[kind] = {"ridge": pts, "pads": g["pads"]}
	print("TERRAIN_JSON=" + JSON.stringify(out))
	get_tree().quit()
