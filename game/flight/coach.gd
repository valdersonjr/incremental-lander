## Treinador sem texto (auditoria dos primeiros minutos, 2026-10-08; world.json > onboarding): ensina na hora em que
## falta e some no 1o uso (Andersen 2012: ajuda no contexto; Super Guide: so para quem precisa).
## - Tecla do motor: aprendiz parado na partida hint_idle_s -> teclinha piscando "apertando" em cima da nave.
## - Teclas de girar: aprendiz no ar rotate_after_s sem girar -> as duas teclinhas.
## Dica aprendida (GameState.learn_tip) nunca volta. Desenho em placeholder com cores da Resurrect 64 (godot-dev).
## - Medidor de descida (todo jogador): ao lado da nave, descendo perto do chao (meter_alt_m): verde / amarelo /
##   vermelho como os numeros do HUD, com o ponteiro na velocidade de agora; pisca no vermelho bem perto do chao.
class_name Coach
extends Node2D

const INK := Color("#2e222f")
const WHITE := Color("#ffffff")
const STEEL := Color("#9babb2")
const GREEN := Color("#1ebc73")
const YELLOW := Color("#f9c22b")
const RED := Color("#e83b3b")
const KEY := 15.0                                   # lado da teclinha (px)
const METER_H := 30.0
const METER_W := 4.0
const ARROWS := {"Up": Vector2.UP, "Left": Vector2.LEFT, "Right": Vector2.RIGHT}

var flight: Flight = null
var _idle := 0.0                                    # segundos parado na partida, pronto para decolar
var _air := 0.0                                     # segundos no ar sem ter girado
var _show_thrust := false
var _show_rotate := false
var _meter := false
var _meter_frac := 0.0                              # velocidade de descida / limite (0..2)
var _flash := false
var _t := 0.0


func _ready() -> void:
	z_index = 5                                        # por cima do lander e do minijogo


func _process(delta: float) -> void:
	if flight == null:
		return
	_t += delta
	var l := flight.lander
	var cfg: Dictionary = WorldConfig.load_config()
	var onb: Dictionary = cfg.get("onboarding", {})
	var coaching := GameState.apprentice() and l.autopilot == null and not flight.dog_busy
	var thrust_now := Input.is_action_pressed(&"thrust")
	var rotate_now := Input.is_action_pressed(&"rotate_left") or Input.is_action_pressed(&"rotate_right")
	if coaching and thrust_now and l.state == Lander.State.FLYING:
		GameState.learn_tip("thrust")
	if coaching and rotate_now and l.state == Lander.State.FLYING:
		GameState.learn_tip("rotate")
	var ready := l.state == Lander.State.LANDED and l.can_takeoff and not l.arriving and flight.target_pad_id >= 0
	_idle = _idle + delta if coaching and ready and not GameState.tip_done("thrust") else 0.0
	var was_thrust := _show_thrust
	_show_thrust = _idle >= float(onb.get("hint_idle_s", 2.5))
	_air = _air + delta if coaching and l.state == Lander.State.FLYING and not GameState.tip_done("rotate") else 0.0
	var was_rotate := _show_rotate
	_show_rotate = _air >= float(onb.get("rotate_after_s", 2.5))
	if _show_thrust and not was_thrust:
		Telemetry.event("tip", "thrust")
	if _show_rotate and not was_rotate:
		Telemetry.event("tip", "rotate")
	_update_meter(l, cfg, float(onb.get("meter_alt_m", 60.0)))
	queue_redraw()


func _update_meter(l: Lander, cfg: Dictionary, show_alt: float) -> void:
	var tol := LandingRules.tolerances(cfg["landing"], float(l.params.get("gear", 1.0)))
	var limit: float = tol["max_vy"]
	var soft := EconMath.mission_has(flight.mission, "soft")
	if flight.target_pad_id >= 0 and soft > 0 and flight.taxi_stage != 1:   # Pouso suave: o limite e o da estrela
		limit = minf(limit, Flight.soft_vy_limit(soft))
	var alt := l.altitude_m()
	_meter = l.state == Lander.State.FLYING and l.vel_m.y > 0.3 and alt < show_alt
	_meter_frac = clampf(l.vel_m.y / maxf(limit, 0.01), 0.0, 2.0)
	_flash = _meter_frac > 1.0 and alt < show_alt * 0.4 and fmod(_t, 0.25) < 0.125


func _draw() -> void:
	if flight == null:
		return
	var at := to_local(flight.lander.global_position)
	if _show_thrust and flight.retry_hint.balloon_visible():      # balao do "tente de novo" em cima: tecla ao lado
		_draw_keys(at + Vector2(-72.0, -44.0), ["thrust"])
	elif _show_thrust:
		_draw_keys(at + Vector2(0.0, -36.0), ["thrust"])
	elif _show_rotate:
		_draw_keys(at + Vector2(0.0, -36.0), ["rotate_left", "rotate_right"])
	if _meter and not _flash:
		_draw_meter(at + Vector2(22.0, 0.0))


## Teclinhas (uma por acao) centradas em pos, "apertando" no ritmo de 2 por segundo.
func _draw_keys(pos: Vector2, actions: Array) -> void:
	var gap := 4.0
	var w := actions.size() * KEY + (actions.size() - 1) * gap
	var down := fmod(_t, 0.5) < 0.25
	for i in actions.size():
		var x := pos.x - w * 0.5 + i * (KEY + gap)
		_draw_key(Vector2(x, pos.y - KEY * 0.5), str(actions[i]), down)


func _draw_key(top_left: Vector2, action: String, down: bool) -> void:
	var p := top_left + (Vector2(0.0, 1.0) if down else Vector2.ZERO)
	draw_rect(Rect2(top_left + Vector2(0.0, 2.0), Vector2(KEY, KEY)), INK)           # sombra/base da tecla
	draw_rect(Rect2(p, Vector2(KEY, KEY)), INK)
	draw_rect(Rect2(p + Vector2(1.0, 1.0), Vector2(KEY - 2.0, KEY - 2.0)), WHITE)
	draw_rect(Rect2(p + Vector2(1.0, KEY - 3.0), Vector2(KEY - 2.0, 2.0)), STEEL)
	var center := p + Vector2(KEY * 0.5, KEY * 0.5 - 1.0)
	var key := _arrow_key(action)
	if key != "":                                              # seta desenhada (a fonte bitmap nao tem setas)
		var d: Vector2 = ARROWS[key]
		var side := Vector2(-d.y, d.x)
		draw_colored_polygon(PackedVector2Array([center + d * 4.0, center - d * 3.0 + side * 4.0,
				center - d * 3.0 - side * 4.0]), INK)
		return
	var names := GameState.keys_for(action)
	var label := WorldConfig.key_label(str(names[0])) if not names.is_empty() else "?"
	var font := UiKit.theme_for("luna").default_font
	var size := UiKit.FONT_SIZE
	var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, center + Vector2(-tw * 0.5, 4.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, INK)


## A seta da acao, se ela tem uma tecla de seta (o desenho mais claro para crianca); senao "" (mostra a 1a tecla).
func _arrow_key(action: String) -> String:
	for k: Variant in GameState.keys_for(action):
		if ARROWS.has(str(k)):
			return str(k)
	return ""


## Barra vertical: em cima devagar (verde), no meio no limite (amarelo), embaixo rapido demais (vermelho).
func _draw_meter(center: Vector2) -> void:
	var top := center.y - METER_H * 0.5
	var r := Rect2(center.x - METER_W * 0.5, top, METER_W, METER_H)
	draw_rect(r.grow(1.0), INK)
	var g := METER_H * 0.3                                     # 0..0,6 do limite
	var y := METER_H * 0.2                                     # 0,6..1
	draw_rect(Rect2(r.position, Vector2(METER_W, g)), GREEN)
	draw_rect(Rect2(r.position + Vector2(0.0, g), Vector2(METER_W, y)), YELLOW)
	draw_rect(Rect2(r.position + Vector2(0.0, g + y), Vector2(METER_W, METER_H - g - y)), RED)
	var ny := top + METER_H * (_meter_frac * 0.5)
	var tip := Vector2(r.position.x - 2.0, ny)
	draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-5.0, -3.0), tip + Vector2(-5.0, 3.0)]), INK)
	draw_colored_polygon(PackedVector2Array([tip + Vector2(-1.0, 0.0), tip + Vector2(-4.0, -1.5),
			tip + Vector2(-4.0, 1.5)]), WHITE)
