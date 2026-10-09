## "Tente de novo" sem precisar ler (validacao do aprendiz contra os mais vendidos, 2026-10-08; prototipo escolhido:
## art/previews/dicas/dicas.html, variantes B + C). Mostra o movimento CERTO para o motivo da batida:
## - Fantasma (B): logo depois da batida, uma nave pontilhada refaz o fim do voo em cima da plataforma alvo e ganha um
##   visto (como o fantasma do Mario Kart). Nao vale para "sem_gas" (o erro e o voo inteiro, nao o pouso).
## - Balao (C): de volta na partida, um balao em cima da nave mostra a mesma cena em miniatura ate a nave decolar.
## Placeholder em _draw com a nave do jogo e cores da Resurrect 64 (godot-dev); arte final passa pela pixel-art.
class_name RetryHint
extends Node2D

const SHIP_FRAMES := preload("res://assets/sprites/lander_frames.tres")
const INK := Color("#2e222f")
const WHITE := Color("#ffffff")
const SHADOW := Color("#3e3546")
const COPPER := Color("#e6904e")
const ICE := Color("#8ff8e2")
const MIST := Color("#c7dcd0")
const GREEN := Color("#1ebc73")
const YELLOW := Color("#f9c22b")
const RED := Color("#e83b3b")
## Duracao de uma volta da cena (s); o ultimo quarto e a nave parada com o visto.
const LOOP_S := 2.4
## Espera antes do fantasma comecar (a camera chega na plataforma alvo).
const PAN_S := 0.6
const GHOST_SCALE := 2.2                           # unidades da pose -> px do mundo (fantasma)
const MINI_SCALE := 1.05                           # unidades da pose -> px do balao
const BALLOON := Vector2(116.0, 76.0)
## Motivos com fantasma (o "sem_gas" so tem o balao).
const GHOST_REASONS := ["vertical_rapido", "fora_da_plataforma", "horizontal_rapido", "inclinado"]

var flight: Flight = null
var reason := ""
var _ghost_on := false
var _ghost_t := 0.0                                 # segundos do fantasma (negativo = esperando a camera)
var _balloon := false
var _t := 0.0
var _ghost: Node2D = null


func _ready() -> void:
	z_index = 5
	_ghost = Node2D.new()
	_ghost.name = "Ghost"
	UiKit.ghost(_ghost)
	_ghost.draw.connect(_draw_ghost_ship)
	add_child(_ghost)


func _process(delta: float) -> void:
	_t += delta
	if _ghost_on:
		_ghost_t += delta
		_ghost_on = _ghost_t < LOOP_S
	if _balloon and flight != null and flight.lander.state != Lander.State.LANDED:
		_balloon = false                               # decolou: o balao some
	_ghost.queue_redraw()
	queue_redraw()


## Fantasma do movimento certo em cima da plataforma alvo; devolve false se o motivo nao tem fantasma.
func play_ghost(p_reason: String) -> bool:
	reason = p_reason
	if not p_reason in GHOST_REASONS or flight == null or flight.target_pad_id < 0:
		return false
	_ghost_on = true
	_ghost_t = -PAN_S
	return true


## Balao com a cena em miniatura em cima da nave (some quando ela decola).
func show_balloon(p_reason: String) -> void:
	reason = p_reason
	_balloon = UiKit.CRASH_TIP.has(p_reason)


func hide_all() -> void:
	_ghost_on = false
	_balloon = false


func ghost_playing() -> bool:
	return _ghost_on and _ghost_t >= 0.0


func balloon_visible() -> bool:
	return _balloon


## Onde o fantasma aparece (centro da plataforma alvo, nave pousada): a camera olha para ca durante o fantasma.
func ghost_focus() -> Vector2:
	var pad: Dictionary = flight.terrain.pads[flight.target_pad_id]
	return Vector2(float(pad["x"]), float(pad["y"]) - _feet_px())


## Pose do movimento certo para cada motivo (u = 0..1 da volta). Unidades relativas a nave pousada no centro da
## plataforma (x para a direita, y para baixo). meter = fracao do limite de descida (medidor), level = inclinacao para
## a linha do Nivelador, arc = desenhar o caminho em arco, done = parada com o visto.
static func pose(p_reason: String, u: float) -> Dictionary:
	var h := 34.0
	var x := 0.0
	var y := -h
	var a := 0.0
	var thr := false
	var meter := -1.0
	var level := -1.0
	var land := minf(1.0, u / 0.75)
	match p_reason:
		"vertical_rapido":
			y = -h * (1.0 - _ease(land))
			thr = land > 0.25 and land < 1.0
			meter = 1.7 - 1.4 * land
		"fora_da_plataforma":
			x = -28.0 * (1.0 - _ease(minf(1.0, land / 0.5)))
			y = -h if land < 0.5 else -h * (1.0 - _ease((land - 0.5) / 0.5))
			thr = land < 1.0
		"horizontal_rapido":
			var s := minf(1.0, land / 0.55)
			x = -34.0 * (1.0 - _ease(s))
			a = -0.45 * sin(PI * s) if land < 0.55 else 0.0
			y = -h if land < 0.55 else -h * (1.0 - _ease((land - 0.55) / 0.45))
			thr = land < 1.0
		"inclinado":
			var s := minf(1.0, land / 0.5)
			a = 0.6 * (1.0 - _ease(s))
			y = -h * 0.7 if land < 0.5 else -h * 0.7 * (1.0 - _ease((land - 0.5) / 0.5))
			thr = land < 1.0
			level = absf(a)
		"sem_gas":
			x = -44.0 + 44.0 * land
			y = -sin(PI * land) * h * 1.1
			thr = land < 0.18 or (land > 0.82 and land < 1.0)
			a = 0.35 * cos(PI * land) if land < 1.0 else 0.0
	return {"x": x, "y": y, "a": a, "thr": thr, "meter": meter, "level": level, "arc": p_reason == "sem_gas",
			"done": u >= 0.75}


static func _ease(u: float) -> float:
	return 1.0 - (1.0 - u) * (1.0 - u)


func _feet_px() -> float:
	return WorldConfig.m_to_px(float(WorldConfig.load_config()["lander"]["feet_offset_m"])) + 0.5


func _draw() -> void:
	if flight == null:
		return
	if ghost_playing():
		var p := pose(reason, _ghost_t / LOOP_S)
		var at := to_local(ghost_focus()) + Vector2(p["x"], p["y"]) * GHOST_SCALE
		if float(p["meter"]) >= 0.0:
			_draw_meter(at + Vector2(22.0, 0.0), float(p["meter"]), 30.0)
		if float(p["level"]) >= 0.0:
			_draw_level(at + Vector2(0.0, _feet_px() + 4.0), float(p["a"]), float(p["level"]), 16.0)
		if p["done"]:
			_draw_check(at + Vector2(-8.0, -40.0), 2.0)
	if _balloon:
		_draw_balloon(to_local(flight.lander.global_position) + Vector2(0.0, -24.0))


## Nave do fantasma (filho com o shader de xadrez branco).
func _draw_ghost_ship() -> void:
	if not ghost_playing() or flight == null:
		return
	var p := pose(reason, _ghost_t / LOOP_S)
	var at := to_local(ghost_focus()) + Vector2(p["x"], p["y"]) * GHOST_SCALE
	_ship(_ghost, at, float(p["a"]), bool(p["thr"]), 1.0)


func _ship(on: CanvasItem, at: Vector2, a: float, thr: bool, s: float) -> void:
	var tex := SHIP_FRAMES.get_frame_texture(&"thrust" if thr else &"idle", int(_t / 0.07) % 4 if thr else 0)
	on.draw_set_transform(at.round(), a, Vector2(s, s))
	on.draw_texture(tex, -tex.get_size() * 0.5)
	on.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Balao branco com a ponta para baixo (bottom = ponta em cima da nave) e a cena em miniatura dentro.
func _draw_balloon(bottom: Vector2) -> void:
	var r := Rect2((bottom - Vector2(BALLOON.x * 0.5, BALLOON.y + 6.0)).round(), BALLOON)
	draw_rect(r, INK)
	draw_rect(r.grow(-1.0), WHITE)
	var tip := Vector2(roundf(bottom.x), r.end.y)
	draw_rect(Rect2(tip + Vector2(-4.0, -1.0), Vector2(8.0, 4.0)), INK)
	draw_rect(Rect2(tip + Vector2(-3.0, -1.0), Vector2(6.0, 3.0)), WHITE)
	draw_rect(Rect2(tip + Vector2(-1.0, 3.0), Vector2(2.0, 2.0)), INK)
	_draw_mini(r.grow(-4.0))


## Cena em miniatura: chao, plataforma alvo (e a de partida no "sem_gas"), nave fazendo o certo, visto no fim.
func _draw_mini(box: Rect2) -> void:
	draw_rect(box, SHADOW)
	draw_rect(Rect2(box.position.x, box.end.y - 8.0, box.size.x, 8.0), COPPER)
	var pad := Vector2(box.position.x + box.size.x * 0.66, box.end.y - 10.0)
	_pad(pad, 34.0)
	var p := pose(reason, fmod(_t, LOOP_S) / LOOP_S)
	var k := MINI_SCALE
	if p["arc"]:
		_pad(Vector2(pad.x - 44.0 * k, pad.y), 22.0)
		for i in 11:
			var q := pose(reason, i / 10.0 * 0.75)
			draw_rect(Rect2((pad + Vector2(q["x"], q["y"]) * k - Vector2(0.0, 8.0)).round(), Vector2(1.0, 1.0)), MIST)
	var at := pad + Vector2(p["x"], p["y"]) * k - Vector2(0.0, _feet_px() * 0.7)
	_ship(self, at, float(p["a"]), bool(p["thr"]), 0.7)
	if float(p["meter"]) >= 0.0:
		_draw_meter(Vector2(box.end.x - 7.0, box.position.y + box.size.y * 0.45), float(p["meter"]), 26.0)
	if float(p["level"]) >= 0.0:
		_draw_level(at + Vector2(0.0, 7.0), float(p["a"]), float(p["level"]), 10.0)
	if p["done"]:
		_draw_check(box.position + Vector2(4.0, 4.0), 2.0)


func _pad(center_top: Vector2, w: float) -> void:
	draw_rect(Rect2((center_top - Vector2(w * 0.5, 0.0)).round(), Vector2(w, 3.0)), INK)
	draw_rect(Rect2((center_top - Vector2(w * 0.5 - 1.0, 0.0)).round(), Vector2(w - 2.0, 2.0)), ICE)


## Medidor de descida (o mesmo do Coach): verde em cima, vermelho embaixo; ponteiro na fracao f do limite.
func _draw_meter(center: Vector2, f: float, h: float) -> void:
	var top := roundf(center.y - h * 0.5)
	var x := roundf(center.x)
	draw_rect(Rect2(x - 1.0, top - 1.0, 6.0, h + 2.0), INK)
	draw_rect(Rect2(x, top, 4.0, h * 0.3), GREEN)
	draw_rect(Rect2(x, top + h * 0.3, 4.0, h * 0.2), YELLOW)
	draw_rect(Rect2(x, top + h * 0.5, 4.0, h * 0.5), RED)
	var ny := roundf(top + h * clampf(f * 0.5, 0.0, 1.0))
	draw_rect(Rect2(x - 6.0, ny - 1.0, 5.0, 3.0), INK)
	draw_rect(Rect2(x - 5.0, ny, 3.0, 1.0), WHITE)


## Linha do Nivelador (verde reta, amarela no limite, vermelha torta).
func _draw_level(center: Vector2, a: float, tilt: float, half: float) -> void:
	var c := GREEN if tilt < 0.15 else (YELLOW if tilt < 0.3 else RED)
	var d := Vector2.RIGHT.rotated(a) * half
	draw_line(center - d, center + d, INK, 3.0)
	draw_line(center - d, center + d, c, 1.0)


## Visto verde com contorno (cada ponto do traco = s px).
func _draw_check(at: Vector2, s: float) -> void:
	var pts := [Vector2(0, 3), Vector2(1, 4), Vector2(2, 5), Vector2(3, 4), Vector2(4, 3), Vector2(5, 2), Vector2(6, 1),
			Vector2(7, 0)]
	for p: Vector2 in pts:
		draw_rect(Rect2(at.round() + p * s - Vector2(s, s), Vector2(3.0 * s, 3.0 * s)), INK)
	for p: Vector2 in pts:
		draw_rect(Rect2(at.round() + p * s, Vector2(s, s)), GREEN)
