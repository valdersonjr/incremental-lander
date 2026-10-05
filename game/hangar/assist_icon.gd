## Figurinha de uma ajuda de voo no cartao da arvore (aba AJUDAS): mostra o que a ajuda desenha no voo, sem texto
## (uma crianca entende olhando). Placeholder em _draw com cores da Resurrect 64 ate a arte da pixel-art.
class_name AssistIcon
extends Control

const SIZE := Vector2(48, 24)
const SKY := Color("#323353")
const INK := Color("#2e222f")
const WHITE := Color("#ffffff")
const MIST := Color("#c7dcd0")
const GROUND := Color("#ab947a")
const PAD := Color("#a884f3")
const BLUE := Color("#4d9be6")
const GOLD := Color("#f9c22b")
const GREEN := Color("#1ebc73")
const RED := Color("#e83b3b")
const SHADOW := Color("#3e3546")

var kind := ""
var _t := 0.0


func _init(p_kind: String = "") -> void:
	kind = p_kind
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	if kind in ["nav_color", "land_predict"]:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), INK)
	draw_rect(Rect2(Vector2.ONE, SIZE - Vector2(2, 2)), SKY)
	if kind != "gas_need":
		draw_rect(Rect2(1, 20, 46, 3), GROUND)
	match kind:
		"nav_arrow":
			_ship(Vector2(14, 10))
			_arrow(Vector2(30, 11), WHITE)
		"nav_color":
			_ship(Vector2(8, 10))
			var c: Array[Color] = [BLUE, GOLD, GREEN]
			for i in 3:
				_arrow(Vector2(20 + i * 9, 11), c[i] if int(_t * 2.0) % 3 >= i else MIST)
		"nav_trail":
			_pad(Vector2(5, 19))
			_ship(Vector2(16, 7))
			for x in [22, 27, 32]:
				_dot(Vector2(x, 6 + (x - 22) / 4))
		"nav_route":
			_pad(Vector2(5, 19))
			_pad(Vector2(37, 19))
			for i in range(1, 8):
				var u := i / 8.0
				_dot(Vector2(9 + 32 * u, 17 - 13 * 4.0 * u * (1.0 - u)))
		"land_shadow":
			_ship(Vector2(22, 4))
			for y in [11, 15]:
				draw_rect(Rect2(24, y, 1, 2), MIST)
			draw_rect(Rect2(19, 19, 10, 1), SHADOW)
			draw_rect(Rect2(21, 18, 6, 1), SHADOW)
		"land_level":
			_pad(Vector2(16, 19))
			_ship(Vector2(22, 7))
			draw_line(Vector2(15, 15), Vector2(33, 15), INK, 3.0)
			draw_line(Vector2(16, 15), Vector2(32, 15), GREEN, 1.0)
		"land_predict":
			_pad(Vector2(28, 19))
			_ship(Vector2(6, 3))
			var k := int(_t * 4.0) % 6
			for i in 6:
				var u := (i + 1) / 7.0
				if i <= k:
					draw_rect(Rect2(Vector2(10 + 22 * u, 8 + 11 * u * u).round(), Vector2(2, 2)), GREEN)
			draw_line(Vector2(30, 15), Vector2(36, 19), GREEN, 1.0)
			draw_line(Vector2(36, 15), Vector2(30, 19), GREEN, 1.0)
		"gas_need":
			draw_rect(Rect2(6, 9, 36, 7), INK)
			draw_rect(Rect2(7, 10, 34, 5), Color("#0b5e65"))
			draw_rect(Rect2(7, 10, 24, 5), Color("#30e1b9"))
			draw_rect(Rect2(15, 7, 3, 11), INK)
			draw_rect(Rect2(16, 8, 1, 9), GOLD)


## Navezinha 6x6 com pezinhos (forma simples, legivel no tamanho do cartao).
func _ship(at: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(-1, -1), Vector2(8, 7)), INK)
	draw_rect(Rect2(at, Vector2(6, 5)), WHITE)
	draw_rect(Rect2(at + Vector2(2, 1), Vector2(2, 2)), BLUE)
	draw_rect(Rect2(at + Vector2(0, 6), Vector2(1, 2)), INK)
	draw_rect(Rect2(at + Vector2(5, 6), Vector2(1, 2)), INK)


func _arrow(at: Vector2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([at + Vector2(6, 0), at + Vector2(-3, -6), at + Vector2(-3, 6)]), INK)
	draw_colored_polygon(PackedVector2Array([at + Vector2(4, 0), at + Vector2(-2, -4), at + Vector2(-2, 4)]), color)


func _pad(at: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(-1, -1), Vector2(10, 2)), PAD)


func _dot(at: Vector2) -> void:
	draw_rect(Rect2(at.round() - Vector2(1, 1), Vector2(3, 3)), INK)
	draw_rect(Rect2(at.round(), Vector2(1, 1)), GOLD)
