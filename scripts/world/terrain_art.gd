## Arte do terreno e do fundo (assets da skill pixel-art) — logica pura, testavel.
## Contrato: res://assets/bg/<planeta>_layers.json (gerado por art/src/bg/<planeta>_scene.py).
## Faixa do terreno: textura aplicada CISALHADA abaixo do contorno (cada coluna desce reta, sem girar pixels);
## cada segmento do contorno usa a textura da sua face (lit/flat/shade) conforme a inclinacao.
class_name TerrainArt
extends RefCounted

const FACES: Array[String] = ["lit", "flat", "shade"]
# contrato com art/src/sprites/landing_pad.py (pad 80x28 com topo do deck na linha 10; feixe 64x84; marcador 11x9)
const PAD_ORIGIN := Vector2(-40, -10)
const BEAM_ORIGIN := Vector2(-32, -84)
const MARKER_ORIGIN := Vector2(-5, -92)


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


## Faixa unica (todas as faces) de altura depth abaixo do contorno: {"polygon", "uv", "polygons"}.
## world_uv = true -> UV = posicao no mundo (textura NAO cisalha: corpo rochoso); senao UV como em band().
static func band_all(ridge: PackedVector2Array, depth: float, world_uv: bool) -> Dictionary:
	var poly := PackedVector2Array()
	var uv := PackedVector2Array()
	var polygons: Array = []
	for i in ridge.size() - 1:
		var a := ridge[i]
		var b := ridge[i + 1]
		var n := poly.size()
		var quad := [a, b, b + Vector2(0, depth), a + Vector2(0, depth)]
		poly.append_array(quad)
		if world_uv:
			uv.append_array(quad)
		else:
			uv.append_array([Vector2(a.x, 0), Vector2(b.x, 0), Vector2(b.x, depth), Vector2(a.x, depth)])
		polygons.append(PackedInt32Array([n, n + 1, n + 2, n + 3]))
	return {"polygon": poly, "uv": uv, "polygons": polygons}


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
	var spacing: Array = meta.get("rock_spacing", [14.0, 46.0])
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
				"frame": rng.randi_range(0, count - 1), "phase": rng.randi_range(0, 7)})
		x += rng.randf_range(float(spacing[0]), float(spacing[1]))
	return spots


## Deslocamento de uma camada de fundo (coordenadas de tela) para a camera em cam:
## x = quanto rolar a textura (repete); y = quanto descer a camada quando a camera sobe acima de ref_y,
## limitado a [min_y, max_y] (a planicie nunca sai da tela nem descobre o fim da textura).
static func layer_offset(cam: Vector2, ref_y: float, factor: Vector2, min_y: float = -INF,
		max_y: float = INF) -> Vector2:
	return Vector2(roundf(cam.x * factor.x), clampf(roundf((ref_y - cam.y) * factor.y), min_y, max_y))


## Canto sup. esq. do sprite da plataforma (topo do deck = altura da plataforma).
static func pad_origin(pad: Dictionary) -> Vector2:
	return Vector2(float(pad["x"]), float(pad["y"])) + PAD_ORIGIN


## Canto sup. esq. do feixe do alvo (base encostada no topo do deck).
static func beam_origin(pad: Dictionary) -> Vector2:
	return Vector2(float(pad["x"]), float(pad["y"])) + BEAM_ORIGIN


## Canto sup. esq. do marcador (acima do feixe).
static func marker_origin(pad: Dictionary) -> Vector2:
	return Vector2(float(pad["x"]), float(pad["y"])) + MARKER_ORIGIN


## Quadro atual de uma animacao em laco (arte da pixel-art: quadros empilhados). phase desincroniza copias.
static func anim_frame(time_s: float, frame_ms: float, frames: int, phase: int = 0) -> int:
	if frames <= 1:
		return 0
	return (int(time_s * 1000.0 / frame_ms) + phase) % frames

