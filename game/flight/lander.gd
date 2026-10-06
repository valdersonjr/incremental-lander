## Lander: fisica propria (LanderPhysics) em unidades do modelo, pouso/batida por LandingRules.
## Controlado pelo teclado ou por um Autopilot (modo --demo). Visual: AnimatedSprite2D %Visual com
## assets/sprites/lander_frames.tres (skill pixel-art, gatinho astronauta): "idle" (pisca) / "thrust".
class_name Lander
extends CharacterBody2D

signal took_off
signal landed(pad: Dictionary, quality: float, info: Dictionary)
signal crashed(reason: String, info: Dictionary)

enum State {LANDED, FLYING, CRASHED}


var state: State = State.LANDED
var vel_m := Vector2.ZERO               # velocidade em m/s do modelo
var gas := 0.0
var params: Dictionary = {}             # gravity, thrust, efficiency, drag, tank, gear, planet_drag
var pads: Array[Dictionary] = []
var ridge := PackedVector2Array()       # contorno do terreno (px): altitude para o ar denso perto do chao
var env_accel := Vector2.ZERO           # perigos do mundo neste passo (o Flight calcula antes do lander mover)
var env_drag := 0.0
var autopilot: Autopilot = null
var thrusting := false
var turbo_on := false                   # Turbo (habilidade) ligado neste passo
var load_div := 1.0                     # missao Pesada: o motor rende thrust / load_div (EconMath.mission_thrust_div)
var can_takeoff := true                 # falso enquanto nao ha entrega escolhida
var flight_time_m := 0.0                # segundos do modelo desde a decolagem
var gas_at_takeoff := 0.0

const THRUST_START := preload("res://assets/audio/sfx/thruster_start.wav")
const THRUST_STOP := preload("res://assets/audio/sfx/thruster_stop.wav")
const GAS_ALARM := preload("res://assets/audio/sfx/gas_alarm.wav")
## Alarme de gas: toca em voo abaixo desta fracao do tanque (mesmo limite da barra vermelha do HUD).
const ALARM_FRAC := 0.15
## Alarme que nao irrita: comeca forte e, depois de ALARM_LOUD_S, cai para ALARM_QUIET_DB (o jogador ja sabe).
const ALARM_LOUD_S := 3.0
const ALARM_QUIET_DB := -14.0

@onready var _visual: AnimatedSprite2D = %Visual
@onready var _thrust_loop: AudioStreamPlayer2D = %ThrustLoop
@onready var _thrust_fx: AudioStreamPlayer2D = %ThrustFx
var _was_thrusting := false
var _alarm: AudioStreamPlayer
var _alarm_t := 0.0


## Configura a nave (stats do EconMath + planeta da spec) e as plataformas do terreno.
func setup(stats: Dictionary, planet: Dictionary, terrain_pads: Array[Dictionary]) -> void:
	params = {
		"gravity": float(planet["gravity"]),
		"planet_drag": float(planet.get("drag", 0.0)),
		"drag": float(planet.get("drag", 0.0)) * float(WorldConfig.load_config()["drag_scale"]),
		"thrust": float(stats["thrust"]),
		"efficiency": float(stats["efficiency"]),
		"tank": float(stats["tank"]),
		"gear": float(stats.get("gear", 1.0)),
		"stabilizer": float(stats.get("stabilizer", 0.0)) >= 1.0,
		"turbo": float(stats.get("turbo", 0.0)) >= 1.0,
	}
	gas = params["tank"]
	pads = terrain_pads
	state = State.LANDED
	vel_m = Vector2.ZERO
	rotation = 0.0


func _ready() -> void:
	_alarm = AudioStreamPlayer.new()
	_alarm.stream = GAS_ALARM
	_alarm.bus = &"SFX"
	add_child(_alarm)


func _physics_process(delta: float) -> void:
	if state == State.CRASHED:
		return
	var cfg: Dictionary = WorldConfig.load_config()
	var controls := _read_controls()
	if state == State.LANDED:
		if controls["thrust"] and gas > 0.0 and can_takeoff:
			state = State.FLYING
			flight_time_m = 0.0
			gas_at_takeoff = gas
			took_off.emit()
		else:
			thrusting = false
			queue_redraw()
			return
	rotation += float(controls["rotate"]) * float(cfg["rotate_speed"]) * delta
	var dt_m := delta * float(cfg["time_scale"])
	params["drag"] = LanderPhysics.drag_at(float(params["planet_drag"]), altitude_m(), cfg) + env_drag
	params["extra_accel"] = env_accel
	turbo_on = bool(controls.get("turbo", false)) and controls["thrust"]
	var p := params
	if turbo_on or load_div != 1.0:                           # Turbo: empuxo x turbo_mult; carga pesada: / load_div
		p = params.duplicate()
		p["thrust"] = float(params["thrust"]) / load_div \
				* (float(cfg["abilities"]["turbo_mult"]) if turbo_on else 1.0)
	var r := LanderPhysics.step(vel_m, rotation, controls["thrust"], gas, p, dt_m)
	vel_m = r["velocity"]
	gas = r["gas"]
	thrusting = float(r["gas_used"]) > 0.0
	flight_time_m += dt_m
	# recovery_as_collision=true: encostado e descendo devagar tambem conta como toque (senao o pouso lento nunca e detectado)
	var col := move_and_collide(vel_m * float(cfg["px_per_m"]) * dt_m, false, 0.08, true)
	if col:
		_on_touch()
	queue_redraw()


func _process(delta: float) -> void:
	var anim := &"thrust" if thrusting else &"idle"
	if _visual.animation != anim:
		_visual.play(anim)
	_visual.speed_scale = 2.0 if turbo_on and thrusting else 1.0   # Turbo: chama tremendo mais rapido
	_update_thrust_sound()
	_update_gas_alarm(delta)


## Gas baixo em voo: bipe em loop que baixa de volume depois de alguns segundos; para ao pousar/bater/sem gas.
func _update_gas_alarm(delta: float) -> void:
	var tank := float(params.get("tank", 0.0))
	var low := state == State.FLYING and tank > 0.0 and gas > 0.0 and gas / tank < ALARM_FRAC and autopilot == null
	if not low:
		if _alarm.playing:
			_alarm.stop()
		_alarm_t = 0.0
		return
	if not _alarm.playing:
		_alarm.play()
	_alarm_t += delta
	_alarm.volume_db = 0.0 if _alarm_t < ALARM_LOUD_S else lerpf(0.0, ALARM_QUIET_DB,
			clampf((_alarm_t - ALARM_LOUD_S) / 1.5, 0.0, 1.0))


## Propulsor (sound-design: plasma suave): ignicao por cima do loop ao ligar; corte ao desligar.
## O autopiloto liga/desliga em pulsos rapidos (sigma-delta): a ignicao so toca se o motor ficou parado > 0,25 s.
var _off_time := 1.0


func _exit_tree() -> void:
	# sons tocando ao fechar o jogo deixam "playbacks" vivos (o Godot acusa recursos em uso na saida)
	for p: AudioStreamPlayer2D in [_thrust_loop, _thrust_fx]:
		p.stop()
		p.stream = null
	if _alarm != null:
		_alarm.stop()
		_alarm.stream = null


func _update_thrust_sound() -> void:
	if thrusting and not _was_thrusting:
		if _off_time > 0.25:
			_thrust_fx.stream = THRUST_START
			_thrust_fx.play()
		if not _thrust_loop.playing:
			_thrust_loop.play()
	elif not thrusting and _was_thrusting:
		_off_time = 0.0
	if not thrusting:
		_off_time += get_process_delta_time()
		if _thrust_loop.playing and _off_time > 0.12:
			_thrust_loop.stop()
			_thrust_fx.stream = THRUST_STOP
			_thrust_fx.play()
	if state == State.CRASHED and _thrust_loop.playing:
		_thrust_loop.stop()
	_was_thrusting = thrusting


## Altura (m do modelo) dos pes acima do relevo logo abaixo (0 sem terreno conhecido).
func altitude_m() -> float:
	if ridge.is_empty():
		return 0.0
	var feet := float(WorldConfig.load_config()["lander"]["feet_offset_m"])
	return WorldConfig.px_to_m(TerrainGen.height_at(ridge, global_position.x) - global_position.y) - feet


## Estado do voo atual (m/s do modelo, rad, gas gasto desde a decolagem, tempo do modelo).
func info() -> Dictionary:
	return {"vx": vel_m.x, "vy": vel_m.y, "tilt": wrapf(rotation, -PI, PI),
			"gas_used": gas_at_takeoff - gas, "flight_time_m": flight_time_m}


func _read_controls() -> Dictionary:
	if autopilot != null:
		var ap_params := params
		if load_div != 1.0:                                   # o piloto do demo pilota com o motor que a carga deixa
			ap_params = params.duplicate()
			ap_params["thrust"] = float(params["thrust"]) / load_div
		return autopilot.control(global_position, vel_m, rotation, ap_params)
	var rot := Input.get_axis(&"rotate_left", &"rotate_right")
	if params.get("stabilizer", false) and Input.is_action_pressed(&"stabilize"):
		rot = stabilize_input(rotation, float(WorldConfig.load_config()["abilities"]["stabilize_gain"]))
	return {
		"rotate": rot,
		"thrust": Input.is_action_pressed(&"thrust"),
		"turbo": params.get("turbo", false) and Input.is_action_pressed(&"turbo"),
	}


## Estabilizador (habilidade): giro que leva a nave de volta a ficar de pe (-1..1, proporcional a inclinacao).
static func stabilize_input(rot: float, gain: float) -> float:
	return clampf(-wrapf(rot, -PI, PI) * gain, -1.0, 1.0)


## Destruida por um perigo (brinquedo caindo): mesma saida de uma batida.
func crash_now(reason: String) -> void:
	if state == State.CRASHED:
		return
	state = State.CRASHED
	thrusting = false
	crashed.emit(reason, info())


func _on_touch() -> void:
	var cfg: Dictionary = WorldConfig.load_config()
	var half := WorldConfig.m_to_px(float(cfg["lander"]["half_width_m"]))
	var pad := TerrainGen.pad_at(pads, global_position.x)
	var on_pad := not pad.is_empty() and absf(global_position.x - float(pad["x"])) <= float(pad["half_width"]) - half * 0.5
	var tol := LandingRules.tolerances(cfg["landing"], float(params["gear"]))
	var inf := info()
	var reason := LandingRules.crash_reason(inf["vy"], inf["vx"], inf["tilt"], on_pad, tol)
	if reason == "":
		var offset := (global_position.x - float(pad["x"])) / float(pad["half_width"])
		var q := LandingRules.quality(inf["vy"], inf["vx"], inf["tilt"], offset, tol, cfg["landing"]["weights"])
		state = State.LANDED
		vel_m = Vector2.ZERO
		thrusting = false
		landed.emit(pad, q, inf)
	else:
		state = State.CRASHED
		thrusting = false
		crashed.emit(reason, inf)
