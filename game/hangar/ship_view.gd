## Nave da tela NAVE: a nave "pôster" (80x70, mesma escala de pixel do resto do jogo: 1 pixel de arte = 1 pixel da tela)
## com as pecas que CRESCEM a cada degrau (ROADMAP 16.5, arte art/src/sprites/lander_parts.py): corpo do atlas
## assets/sprites/ship_poster.png pela versao do tanque/bocal/pernas e chama animada de ship_poster_flame.png pela versao
## do Motor, saindo da boca do bocal (ShipArt). highlight(id) contorna a peca em dourado (mouse sobre o cartao).
class_name ShipView
extends Control

const W := 80                           # quadro da nave poster
const H := 70
const FLAME_DROP := 38                  # quanto a chama da versao 3 passa do quadro (espaco embaixo)
const FLAME_FPS := 14.0

var levels: Dictionary = {}             # niveis das pecas (GameState.levels)
var hl := ""                            # peca em destaque
var _body: AtlasTexture
var _flame: AtlasTexture
var _flame_t := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(W, H + FLAME_DROP)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body = AtlasTexture.new()
	_body.atlas = load("res://assets/sprites/ship_poster.png")
	_flame = AtlasTexture.new()
	_flame.atlas = load("res://assets/sprites/ship_poster_flame.png")


func _process(delta: float) -> void:
	_flame_t += delta
	queue_redraw()


func highlight(id: String) -> void:
	hl = id
	queue_redraw()


## Pulinho quando uma peca sobe de degrau.
func bounce() -> void:
	pivot_offset = size * 0.5
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.1, 0.92), 0.08)
	tw.tween_property(self, "scale", Vector2(0.96, 1.06), 0.1)
	tw.tween_property(self, "scale", Vector2.ONE, 0.12)


func _draw() -> void:
	var t := ShipArt.tiers(levels)
	var o := Vector2(floorf((size.x - W) * 0.5), 0)
	_flame.region = ShipArt.poster_flame_region(t, int(_flame_t * FLAME_FPS))
	var fr := Rect2(o + Vector2(0, ShipArt.mouth(t, true)), _flame.region.size)
	draw_texture_rect(_flame, fr, false)
	_body.region = ShipArt.poster_region(t)
	draw_texture_rect(_body, Rect2(o, Vector2(W, H)), false)
	if hl == "":
		return
	var boxes: Array[Rect2] = [Rect2(fr.position + Vector2(28, 0), Vector2(24, 24 + 8 * int(t["thrust"])))] \
			if hl == "thrust" else ShipArt.poster_boxes(hl, t)
	for box: Rect2 in boxes:
		if hl != "thrust":
			box.position += o
		draw_rect(box.grow(2), UiKit.color("gold"), false, 1.0)
