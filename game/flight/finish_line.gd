## Linha de chegada da pista (v30: pousar depois dela completa o mundo; EconMath.finish_m). Faixa quadriculada que sobe
## do chao (da para ver cruzando ate voando alto), bandeira grande no alto do mastro e a placa "CHEGADA".
## Placeholder em codigo (cores da Resurrect 64) ate ter arte propria (skill pixel-art).
class_name FinishLine
extends Node2D

const HEIGHT := 130.0                    # px de faixa acima do chao (bandeira e placa ficam na tela ao chegar)
const CELL := 4.0


func _draw() -> void:
	var ink := Color("#2e222f")
	var white := Color("#ffffff")
	var n := int(HEIGHT / CELL)
	draw_rect(Rect2(-CELL - 1, -HEIGHT - 1, CELL * 2 + 2, HEIGHT + 1), ink)
	for i in n:
		for k in 2:
			draw_rect(Rect2(-CELL + k * CELL, -(i + 1) * CELL, CELL, CELL), white if (i + k) % 2 == 0 else ink)
	FinishFlagIcon.draw(self, Vector2(CELL + 1, -HEIGHT), 4)
