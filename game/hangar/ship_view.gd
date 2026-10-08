## Nave da tela NAVE: a nave "pôster" do titulo (assets/sprites/title_lander.png, 80x70, mesma escala de pixel do
## resto do jogo: 1 pixel de arte = 1 pixel da tela) com as pecas que CRESCEM a cada degrau de 10 niveis (chama do
## Motor, tanque da Gasolina, bocal da Eficiencia, sapatas da Resistencia). Pecas em _draw com cores Resurrect 64 e
## tamanhos inteiros (auditoria de UX 2026-10-08: antes era o lander de voo ampliado 3x, outra escala e outro desenho).
## highlight(id) faz a peca brilhar (mouse sobre o cartao).
class_name ShipView
extends Control

const W := 80                           # quadro da nave pôster (title_lander)
const H := 70
const PAD_L := 14                       # espaco a esquerda para o tanque crescer
const PAD_B := 26                       # espaco embaixo para a chama
const NOZZLE_COLORS := ["steel", "ice", "aqua", "violet", "lavender", "gold", "coral", "white"]
## Geometria da nave pôster (art/src/title/title_concepts.py big_lander): bocal, sapatas e casco.
const NOZZLE := Vector2i(40, 42)        # centro x, topo y do bocal
const FEET := [12, 69]                  # centros x das sapatas
const FOOT_Y := 59
const HULL_Y := 36                      # meio do disco (onde o tanque encosta)
const HULL_X := 6                       # ponta esquerda do disco

var levels: Dictionary = {}             # niveis das pecas (GameState.levels)
var hl := ""                            # peca em destaque
var _tex: AtlasTexture
var _flame_t := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(W + PAD_L * 2, H + PAD_B)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tex = AtlasTexture.new()
	_tex.atlas = load("res://assets/sprites/title_lander.png")
	_tex.region = Rect2(0, 0, W, H)


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
	var o := Vector2(floorf((size.x - W) * 0.5), 0)
	var m := _stage("thrust")
	var t := _stage("tank")
	var e := _stage("efficiency")
	var g := _stage("gear")
	var ink := UiKit.color("ink")
	# chama (Motor): figura 24 px; dobra (2x inteiro) a partir do degrau 6; treme 1 px
	var fl := UiKit.kid("flame_s" if m < 3 else "flame_b")
	var fs := 24 * (2 if m >= 6 else 1)
	var shake := 1.0 if int(_flame_t * 20.0) % 2 == 0 else 0.0
	var fr := Rect2(o + Vector2(NOZZLE.x - fs / 2, NOZZLE.y + 4 + shake), Vector2(fs, fs))
	draw_texture_rect(fl, fr, false)
	_hl(fr, "thrust")
	draw_texture_rect(_tex, Rect2(o, Vector2(W, H)), false)
	# tanque (Gasolina): capsula encostada na ponta esquerda do disco, mais comprida a cada degrau
	var tw := 4 + t * 2
	var th := 5 + mini(t, 6) / 2 * 2
	var tank := Rect2(o + Vector2(HULL_X - tw, HULL_Y - th / 2), Vector2(tw, th))
	draw_rect(tank.grow(1), ink)
	draw_rect(tank, UiKit.color("aqua"))
	draw_rect(Rect2(tank.position, Vector2(tw, 1)), UiKit.color("ice"))
	_hl(tank, "tank")
	# bocal (Eficiencia): mais largo e de cor nova a cada degrau
	var nw := 14 + e * 2
	var noz := Rect2(o + Vector2(NOZZLE.x - nw / 2, NOZZLE.y), Vector2(nw, 3))
	draw_rect(noz.grow(1), ink)
	draw_rect(noz, UiKit.color(NOZZLE_COLORS[mini(e, NOZZLE_COLORS.size() - 1)]))
	_hl(noz, "efficiency")
	# sapatas (Resistencia): mais largas a cada degrau
	var fw := 10 + g * 2
	for cx: int in FEET:
		var foot := Rect2(o + Vector2(cx - fw / 2, FOOT_Y), Vector2(fw, 3))
		draw_rect(foot.grow(1), ink)
		draw_rect(foot, UiKit.color("steel"))
		draw_rect(Rect2(foot.position, Vector2(fw, 1)), UiKit.color("mist"))
		_hl(foot, "gear")


func _hl(r: Rect2, id: String) -> void:
	if hl == id:
		draw_rect(r.grow(2), UiKit.color("gold"), false, 1.0)
