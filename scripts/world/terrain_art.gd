## Arte do terreno e do fundo (assets da skill pixel-art) — logica pura, testavel.
## Contrato: res://assets/bg/<planeta>_layers.json (gerado por art/src/bg/<planeta>_scene.py).
## Faixa do terreno: textura aplicada CISALHADA abaixo do contorno (cada coluna desce reta, sem girar pixels);
## cada segmento do contorno usa a textura da sua face (lit/flat/shade) conforme a inclinacao.
class_name TerrainArt
extends RefCounted

const FACES: Array[String] = ["lit", "flat", "shade"]


## Metadados de arte do planeta ({} se o planeta ainda nao tem arte -> placeholder).
static func load_meta(planet_id: String) -> Dictionary:
	var path := "res://assets/bg/%s_layers.json" % planet_id
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## Face do segmento a->b com luz de cima-esquerda: subindo para a direita = "lit", descendo = "shade".
static func face_of(a: Vector2, b: Vector2, threshold: float) -> String:
	var slope := (b.y - a.y) / maxf(b.x - a.x, 0.001)
	if slope < -threshold:
		return "lit"
	if slope > threshold:
		return "shade"
	return "flat"


## Geometria das faixas: {face: {"polygon": PackedVector2Array, "uv": PackedVector2Array, "polygons": Array}}.
## Cada segmento vira um quad (paralelogramo) de altura depth; UV x = x do mundo (repete), UV y = 0..depth.
static func band(ridge: PackedVector2Array, depth: float, threshold: float) -> Dictionary:
	var out := {}
	for f in FACES:
		out[f] = {"polygon": PackedVector2Array(), "uv": PackedVector2Array(), "polygons": []}
	for i in ridge.size() - 1:
		var a := ridge[i]
		var b := ridge[i + 1]
		var g: Dictionary = out[face_of(a, b, threshold)]
		var poly: PackedVector2Array = g["polygon"]
		var uv: PackedVector2Array = g["uv"]
		var n := poly.size()
		poly.append_array([a, b, b + Vector2(0, depth), a + Vector2(0, depth)])
		uv.append_array([Vector2(a.x, 0), Vector2(b.x, 0), Vector2(b.x, depth), Vector2(a.x, depth)])
		g["polygon"] = poly
		g["uv"] = uv
		(g["polygons"] as Array).append(PackedInt32Array([n, n + 1, n + 2, n + 3]))
	return out


## Pedregulhos sobre o contorno, fora das plataformas: [{"pos": canto sup. esq. da celula, "frame": int}].
static func rock_spots(ridge: PackedVector2Array, pads: Array[Dictionary], seed_value: int,
		meta: Dictionary) -> Array[Dictionary]:
	var spots: Array[Dictionary] = []
	if meta.is_empty() or ridge.size() < 2:
		return spots
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cell: Array = meta["rock_cell"]
	var base_row := float(meta["rock_base_row"])
	var count := int(meta["rock_count"])
	var x := ridge[0].x + rng.randf_range(4.0, 30.0)
	while x < ridge[ridge.size() - 1].x:
		var clear := true
		for p in pads:
			if absf(x - float(p["x"])) < float(p["half_width"]) + 12.0:
				clear = false
				break
		if clear:
			var y := TerrainGen.height_at(ridge, x) + float(rng.randi_range(0, 2))
			spots.append({"pos": Vector2(roundf(x - float(cell[0]) * 0.5), roundf(y - base_row)),
				"frame": rng.randi_range(0, count - 1)})
		x += rng.randf_range(14.0, 46.0)
	return spots


## Deslocamento de uma camada de fundo (coordenadas de tela) para a camera em cam:
## x = quanto rolar a textura (repete); y = quanto descer a camada quando a camera sobe acima de ref_y.
static func layer_offset(cam: Vector2, ref_y: float, factor: Vector2) -> Vector2:
	return Vector2(roundf(cam.x * factor.x), roundf((ref_y - cam.y) * factor.y))
