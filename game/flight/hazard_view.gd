## Desenho dos perigos do salto (arte: art/src/sprites/hazards.py; contrato no docstring de la). Logica em Hazards.
## O Flight passa as zonas, o relogio do modelo (t) e o retangulo visivel (para prender o "!" na borda da tela).
class_name HazardView
extends Node2D

const LEAF := preload("res://assets/sprites/hazard_leaf_frames.tres")
const STREAK := preload("res://assets/sprites/hazard_streak_frames.tres")
const SYRUP_COL := preload("res://assets/sprites/syrup_column_frames.tres")
const SYRUP_CAP := preload("res://assets/sprites/syrup_cap_frames.tres")
const SYRUP_BUB := preload("res://assets/sprites/syrup_bubbles_frames.tres")
const FAN := preload("res://assets/sprites/fan_frames.tres")
const AIR := preload("res://assets/sprites/air_streak_frames.tres")
const TOY := preload("res://assets/sprites/toy_block_frames.tres")
const SHADOW := preload("res://assets/sprites/toy_shadow_frames.tres")
const ALERT := preload("res://assets/sprites/toy_alert_frames.tres")

var zones: Array[Dictionary] = []
var t := 0.0                          # segundos reais (mesmo relogio de Hazards.cycle)
var view := Rect2()                   # area visivel no mundo (px)
var real_t := 0.0                     # segundos reais (animacao dos sprites)


func _process(delta: float) -> void:
	real_t += delta
	if not zones.is_empty():
		queue_redraw()


func _draw() -> void:
	for z in zones:
		match str(z["type"]):
			"gust":
				_draw_gust(z)
			"geyser":
				_draw_geyser(z)
			"fan":
				_draw_fan(z)
			"toy":
				_draw_toy(z)


func _tex(frames: SpriteFrames, anim: StringName, offset: int = 0) -> Texture2D:
	var n := frames.get_frame_count(anim)
	var ms := 1000.0 / maxf(frames.get_animation_speed(anim), 0.001)
	var i := (int(real_t * 1000.0 / ms) + offset) % n
	return frames.get_frame_texture(anim, i)


func _blit(tex: Texture2D, center: Vector2) -> void:
	draw_texture(tex, (center - tex.get_size() * 0.5).round())


## Rajada: folhas e tracos atravessando a faixa no sentido do vento (rapido ligada, devagar no aviso).
func _draw_gust(z: Dictionary) -> void:
	var c := Hazards.cycle(z, t)
	if c == "off":
		return
	var r: Rect2 = z["rect"]
	var dir := signf(float(z["accel"].x))
	var speed := 260.0 if c == "on" else 45.0
	var n := 22 if c == "on" else 7
	for i in n:
		var span := r.size.x + 40.0
		var x := fposmod(i * 61.0 + real_t * speed * (1.0 + (i % 3) * 0.25), span) - 20.0
		x = r.position.x + (x if dir > 0.0 else span - 40.0 - x)
		var y := r.position.y + fposmod(i * 37.0, r.size.y) + sin(real_t * 3.0 + i) * 6.0
		_blit(_tex(LEAF, &"flutter", i), Vector2(x, y))
		if c == "on" and i % 3 == 0:
			_blit(_tex(STREAK, &"swirl", i), Vector2(x - dir * 18.0, y + 4.0))


## Geiser: bolhas no chao no aviso; ligado, a coluna de calda sobe do chao ate o topo da zona (e cresce rapido).
func _draw_geyser(z: Dictionary) -> void:
	var r: Rect2 = z["rect"]
	var cx := r.get_center().x
	var ground := r.end.y
	var c := Hazards.cycle(z, t)
	if c == "warn":
		var b := _tex(SYRUP_BUB, &"bubble")
		draw_texture(b, Vector2(cx - b.get_width() * 0.5, ground - b.get_height()).round())
	elif c == "on":
		var since := fposmod(t + float(z["phase"]), float(z["period_s"]))
		var h := r.size.y * clampf(since / 0.35, 0.15, 1.0)
		var seg := _tex(SYRUP_COL, &"flow")
		var y := ground - seg.get_height()
		while y > ground - h:
			draw_texture(seg, Vector2(cx - 16.0, y).round())
			y -= seg.get_height()
		draw_texture(_tex(SYRUP_CAP, &"splash"), Vector2(cx - 16.0, ground - h - 12.0).round())


## Ventilador: sempre ligado; riscos de ar subindo na coluna.
func _draw_fan(z: Dictionary) -> void:
	var r: Rect2 = z["rect"]
	var f := _tex(FAN, &"spin")
	var air := AIR.get_frame_texture(&"rise", 0)
	for i in 16:
		var x := r.position.x + 8.0 + fposmod(i * 23.0, r.size.x - 16.0)
		var y := r.end.y - 30.0 - fposmod(i * 47.0 + real_t * 150.0 * (1.0 + (i % 4) * 0.2), r.size.y - 30.0)
		draw_texture(air, Vector2(x, y).round())
	draw_texture(f, Vector2(r.get_center().x - f.get_width() * 0.5, r.end.y - f.get_height() + 2.0).round())


## Brinquedo: aviso = sombra pulsando no chao + "!" (preso na borda de cima da tela); caindo = bloco girando.
func _draw_toy(z: Dictionary) -> void:
	var c := Hazards.cycle(z, t)
	if c == "off":
		return
	var x := float(z["x"])
	var ground := float(z["ground"])
	_blit(_tex(SHADOW, &"warn"), Vector2(x, ground - 2.0))
	if c == "warn":
		var top := float(z["top"])
		var ay := clampf(top, view.position.y + 24.0, ground - 40.0) if view.size.y > 0.0 else top
		_blit(_tex(ALERT, &"blink"), Vector2(x, ay))
	else:
		_blit(_tex(TOY, &"tumble"), Hazards.toy_pos(z, t))
