## Bandeirinha quadriculada (linha de chegada) desenhada em codigo com cores da Resurrect 64 (placeholder godot-dev:
## o kit de UI nao tem bandeira). Icone do HUD (12x12) e bandeira grande da pista (FinishLine).
class_name FinishFlagIcon
extends Control

const INK := Color("#2e222f")
const WHITE := Color("#ffffff")
const STEEL := Color("#9babb2")


func _init() -> void:
	custom_minimum_size = Vector2(12, 12)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	draw(self, Vector2(1, 1), 2)


## Bandeira com o mastro em at (canto de cima), quadradinhos de cell px (4 x 3 casas).
static func draw(ci: CanvasItem, at: Vector2, cell: int) -> void:
	var w := 4 * cell
	var h := 3 * cell
	ci.draw_rect(Rect2(at.x - 1, at.y - 1, 1, h + cell * 2 + 2), INK)              # contorno do mastro
	ci.draw_rect(Rect2(at.x, at.y - 1, 1, h + cell * 2 + 1), STEEL)
	ci.draw_rect(Rect2(at.x + 1, at.y - 1, w + 2, h + 2), INK)                      # contorno do pano
	for gy in 3:
		for gx in 4:
			ci.draw_rect(Rect2(at.x + 2 + gx * cell, at.y + gy * cell, cell, cell), WHITE if (gx + gy) % 2 == 0 else INK)
