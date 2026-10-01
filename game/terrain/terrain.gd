## Terreno em poligono: gera relevo por seed (TerrainGen), colisao e visual.
## Com arte do planeta (assets/bg/<planeta>_layers.json): faixas cisalhadas lit/flat/shade + pedregulhos
## (TerrainArt). Sem arte: placeholder (poligono solido + linha clara). Plataformas: sprites animados (todos os planetas).
class_name Terrain
extends Node2D

const COLOR_FILL := Color("#3e3546")      # shadow
const COLOR_SURFACE := Color("#9babb2")   # steel
const PAD_FRAMES := preload("res://assets/sprites/landing_pad_frames.tres")

var ridge := PackedVector2Array()
var pads: Array[Dictionary] = []
## Plataforma alvo (-1 = nenhuma): ganha luzes vivas, feixe de luz e marcador.
var target_pad_id := -1:
	set(value):
		target_pad_id = value
		if is_node_ready():
			_sync_target()

var _rocks: Array[Dictionary] = []
var _rock_tex: Texture2D
var _rock_cell := Vector2.ZERO
var _rock_frames := 1
var _rock_ms := 200.0
var _time := 0.0

@onready var _fill: Polygon2D = %Fill
@onready var _surface: Line2D = %Surface
@onready var _collision: CollisionShape2D = %Collision
@onready var _bands: Dictionary = {"lit": %BandLit, "flat": %BandFlat, "shade": %BandShade}
@onready var _pads_root: Node2D = %Pads
@onready var _beam: AnimatedSprite2D = %Beam
@onready var _marker: AnimatedSprite2D = %Marker


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
		_rock_frames = 1
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
	_build_pads()
	queue_redraw()
	return data


## Um sprite por plataforma (arte da pixel-art: landing_pad.py; contrato em TerrainArt.PAD_ORIGIN).
func _build_pads() -> void:
	for c in _pads_root.get_children():
		c.queue_free()
	for p in pads:
		var s := AnimatedSprite2D.new()
		s.sprite_frames = PAD_FRAMES
		s.centered = false
		s.position = TerrainArt.pad_origin(p)
		s.set_meta("pad_id", int(p["id"]))
		_pads_root.add_child(s)
	_sync_target()


func _sync_target() -> void:
	var target: Dictionary = {}
	for s: AnimatedSprite2D in _pads_root.get_children():
		if s.is_queued_for_deletion():
			continue
		var is_target := int(s.get_meta("pad_id")) == target_pad_id
		s.play(&"target" if is_target else &"idle")
	for p in pads:
		if int(p["id"]) == target_pad_id:
			target = p
	_beam.visible = not target.is_empty()
	_marker.visible = _beam.visible
	if _beam.visible:
		_beam.position = TerrainArt.beam_origin(target)
		_marker.position = TerrainArt.marker_origin(target)
		_beam.play(&"pulse")
		_marker.play(&"bob")


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
	_rock_frames = int(meta.get("rock_frames", 1))
	_rock_ms = float(meta.get("rock_ms", 200.0))


func _process(delta: float) -> void:
	_time += delta
	if _rock_frames > 1:
		queue_redraw()                                         # enfeites animados (vento, pirulitos girando)


func _draw() -> void:
	for r in _rocks:
		var f := TerrainArt.anim_frame(_time, _rock_ms, _rock_frames, int(r.get("phase", 0)))
		var src := Rect2(Vector2(_rock_cell.x * int(r["frame"]), _rock_cell.y * f), _rock_cell)
		draw_texture_rect_region(_rock_tex, Rect2(r["pos"], _rock_cell), src)
