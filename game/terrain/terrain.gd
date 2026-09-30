## Terreno em poligono: gera relevo por seed (TerrainGen), colisao e visual placeholder.
class_name Terrain
extends Node2D

const COLOR_FILL := Color("#3e3546")      # shadow
const COLOR_SURFACE := Color("#9babb2")   # steel
const COLOR_PAD := Color("#fbb954")       # honey
const COLOR_TARGET := Color("#1ebc73")    # emerald

var ridge := PackedVector2Array()
var pads: Array[Dictionary] = []
var target_pad_id := -1

@onready var _fill: Polygon2D = %Fill
@onready var _surface: Line2D = %Surface
@onready var _collision: CollisionShape2D = %Collision


## Gera o terreno e devolve os dados (ridge, pads, polygon).
func build(seed_value: int, planet_id: String, pad_distances_m: Array[float]) -> Dictionary:
	var data := TerrainGen.generate(seed_value, planet_id, pad_distances_m)
	ridge = data["ridge"]
	pads.assign(data["pads"])
	_fill.polygon = data["polygon"]
	_surface.points = ridge
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


func _draw() -> void:
	for p in pads:
		var c := COLOR_TARGET if int(p["id"]) == target_pad_id else COLOR_PAD
		var x0 := float(p["x"]) - float(p["half_width"])
		var x1 := float(p["x"]) + float(p["half_width"])
		var y := float(p["y"])
		draw_line(Vector2(x0, y), Vector2(x1, y), c, 2.0)
		draw_line(Vector2(x0, y), Vector2(x0, y - 6.0), c, 1.0)
		draw_line(Vector2(x1, y), Vector2(x1, y - 6.0), c, 1.0)
