## Nave da PROGRESSAO (v13): o lander grande com as pecas que CRESCEM a cada degrau de 10 niveis (chama do Motor,
## tanque da Gasolina, bocal da Eficiencia, pes da Resistencia). Placeholder em _draw com cores Resurrect 64 ate a
## arte final (Fase 16.5, skill pixel-art). highlight(id) faz a peca brilhar (mouse sobre o cartao).
class_name ShipView
extends Control

const SCALE := 3                        # pixels de tela por pixel de arte (inteiro)
const PAD_L := 10                       # espaco a esquerda (art px) para o tanque crescer
const NOZZLE_COLORS := ["steel", "ice", "aqua", "violet", "lavender", "gold", "coral", "white"]

var levels: Dictionary = {}             # niveis das pecas (GameState.levels)
var hl := ""                            # peca em destaque
var _tex: AtlasTexture
var _flame_t := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2((32 + PAD_L * 2) * SCALE, 40 * SCALE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tex = AtlasTexture.new()
	_tex.atlas = load("res://assets/sprites/lander.png")
	_tex.region = Rect2(0, 0, 32, 32)


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


func _stage(id: String) -> int:
	return int(levels.get(id, 0)) / RoadText.STAGE


func _draw() -> void:
	var o := Vector2(roundf((size.x - (32 + PAD_L * 2) * SCALE) * 0.5) + PAD_L * SCALE, 0)
	var m := _stage("thrust")
	var t := _stage("tank")
	var e := _stage("efficiency")
	var g := _stage("gear")
	var ink := UiKit.color("ink")
	# tanque (Gasolina): capsula do lado esquerdo, mais comprida a cada degrau
	var tw := 3 + int(t * 1.2)
	var th := 4 + t / 2
	var tank := Rect2(o + Vector2((3 - tw) * SCALE, (18 - th / 2) * SCALE), Vector2(tw * SCALE, th * SCALE))
	draw_rect(tank.grow(1), ink)
	draw_rect(tank, UiKit.color("aqua"))
	for i in range(1, tw):
		if i % 2 == 0:
			draw_rect(Rect2(tank.position + Vector2(i * SCALE, SCALE), Vector2(SCALE, (th - 2) * SCALE)), UiKit.color("ice"))
	_hl(tank, "tank")
	# chama (Motor): maior a cada degrau, tremendo
	var fsz := (8 + m * 2) * SCALE * (1.0 + 0.06 * sin(_flame_t * 40.0))
	var fl := UiKit.kid("flame_s" if m < 3 else "flame_b")
	var fr := Rect2(o + Vector2(16 * SCALE - fsz * 0.5, 22 * SCALE), Vector2(fsz, fsz))
	draw_texture_rect(fl, fr, false)
	_hl(fr, "thrust")
	draw_texture_rect(_tex, Rect2(o, Vector2(32, 32) * SCALE), false)
	# bocal (Eficiencia): mais largo e de cor nova a cada degrau
	var nw := 4 + e
	var noz := Rect2(o + Vector2((16 - nw / 2.0) * SCALE, 21 * SCALE), Vector2(nw * SCALE, 2 * SCALE))
	draw_rect(noz.grow(1), ink)
	draw_rect(noz, UiKit.color(NOZZLE_COLORS[mini(e, NOZZLE_COLORS.size() - 1)]))
	_hl(noz, "efficiency")
	# pes (Resistencia): sapatas mais largas a cada degrau
	var fw := 5 + g * 3
	for cx: float in [5.5, 26.5]:
		var foot := Rect2(o + Vector2((cx - fw / 2.0) * SCALE, 25 * SCALE), Vector2(fw * SCALE, 2 * SCALE))
		draw_rect(foot.grow(1), ink)
		draw_rect(foot, UiKit.color("steel"))
		_hl(foot, "gear")


func _hl(r: Rect2, id: String) -> void:
	if hl == id:
		draw_rect(r.grow(3), UiKit.color("gold"), false, 2.0)
