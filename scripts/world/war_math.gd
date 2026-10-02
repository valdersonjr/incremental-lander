## Matematica pura da guerra no fundo (WarFx): laco horizontal e linhas pixel-perfect. Testavel.
class_name WarMath
extends RefCounted


## Menor deslocamento de a ate b num laco de tamanho period (ex.: 630 -> 10 em 640 = +20).
static func wrap_dx(a: float, b: float, period: float) -> float:
	return fposmod(b - a + period * 0.5, period) - period * 0.5


## x na tela de um ponto do laco, com a camada rolada em scroll (0..period).
static func screen_x(x: float, scroll: float, period: float) -> float:
	return fposmod(x - scroll, period)


## Pontos de uma linha de 1 px (Bresenham) entre a e b, inclusive.
static func line_points(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var pts: Array[Vector2i] = []
	var dx := absi(b.x - a.x)
	var dy := -absi(b.y - a.y)
	var sx := 1 if a.x < b.x else -1
	var sy := 1 if a.y < b.y else -1
	var err := dx + dy
	var p := a
	while true:
		pts.append(p)
		if p == b:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			p.x += sx
		if e2 <= dx:
			err += dx
			p.y += sy
	return pts
