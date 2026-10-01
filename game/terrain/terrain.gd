## Terreno em poligono: gera relevo por seed (TerrainGen), colisao e visual.
## Com arte do planeta (assets/bg/<planeta>_layers.json): faixas cisalhadas lit/flat/shade + pedregulhos
## (TerrainArt). Sem arte: placeholder (poligono solido + linha clara).
class_name Terrain
extends Node2D

const COLOR_FILL := Color("#3e3546")      # shadow
const COLOR_SURFACE := Color("#9babb2")   # steel
const COLOR_PAD := Color("#fbb954")       # honey
const COLOR_TARGET := Color("#1ebc73")    # emerald

var ridge := PackedVector2Array()
var pads: Array[Dictionary] = []
var target_pad_id := -1

var _rocks: Array[Dictionary] = []
var _rock_tex: Texture2D
var _rock_cell := Vector2.ZERO

@onready var _fill: Polygon2D = %Fill
@onready var _surface: Line2D = %Surface
@onready var _collision: CollisionShape2D = %Collision
@onready var _bands: Dictionary = {"lit": %BandLit, "flat": %BandFlat, "shade": %BandShade}


## Gera o terreno e devolve os dados (ridge, pads, polygon).
func build(seed_value: int, planet_id: String, pad_distances_m: Array[float]) -> Dictionary:
	var data := TerrainGen.generate(seed_value, planet_id, pad_distances_m)
	ridge = data["ridge"]
	var look: Dictionary = WorldConfig.load_config()["terrain"]["planets"].get(planet_id, {})
	RenderingServer.set_default_clear_color(Color(str(look.get("sky", "#2e222f"))))
	pads.assign(data["pads"])
	_fill.polygon = data["polygon"]
	var meta := TerrainArt.load_meta(planet_id)
	if meta.is_empty():
		_fill.color = Color(str(look.get("fill", "#3e3546")))
		_surface.default_color = Color(str(look.get("surface", "#9babb2")))
		_surface.points = ridge
		_surface.visible = true
		for b: Polygon2D in _bands.values():
			b.visible = false
		_rocks.clear()
	else:
		_apply_art(planet_id, seed_value, meta)
	# colisao por segmentos da superficie: leve e robusta para terrenos de varios km
	var segs := PackedVector2Array()
	for i in ridge.size() - 1:
		segs.append(ridge[i])
		segs.append(ridge[i + 1])
	var shape := ConcavePolygonShape2D.new()
	shape.segments = segs
	_collision.shape = shape
	queue_redraw()
	return data


func _apply_art(planet_id: String, seed_value: int, meta: Dictionary) -> void:
	_fill.color = Color(str(meta["deep_color"]))
	_surface.visible = false
	var geo := TerrainArt.band(ridge, float(meta["strip_depth"]), float(meta["face_slope"]))
	for face: String in _bands:
		var b: Polygon2D = _bands[face]
		var g: Dictionary = geo[face]
		b.texture = load("res://assets/tiles/%s_ground_%s.png" % [planet_id, face]) as Texture2D
		b.polygons = []
		b.polygon = g["polygon"]
		b.uv = g["uv"]
		b.polygons = g["polygons"]
		b.visible = true
	_rock_tex = load("res://assets/sprites/%s_rocks.png" % planet_id) as Texture2D
	var cell: Array = meta["rock_cell"]
	_rock_cell = Vector2(float(cell[0]), float(cell[1]))
	_rocks = TerrainArt.rock_spots(ridge, pads, seed_value, meta)


func _draw() -> void:
	for r in _rocks:
		var src := Rect2(Vector2(_rock_cell.x * int(r["frame"]), 0), _rock_cell)
		draw_texture_rect_region(_rock_tex, Rect2(r["pos"], _rock_cell), src)
	for p in pads:
		var c := COLOR_TARGET if int(p["id"]) == target_pad_id else COLOR_PAD
		var x0 := float(p["x"]) - float(p["half_width"])
		var x1 := float(p["x"]) + float(p["half_width"])
		var y := float(p["y"])
		draw_line(Vector2(x0, y), Vector2(x1, y), c, 2.0)
		draw_line(Vector2(x0, y), Vector2(x0, y - 6.0), c, 1.0)
		draw_line(Vector2(x1, y), Vector2(x1, y - 6.0), c, 1.0)
