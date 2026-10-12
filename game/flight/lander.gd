## Lander: fisica propria (LanderPhysics) em unidades do modelo, pouso/batida por LandingRules.
## Controlado pelo teclado ou por um Autopilot (modo --demo). Visual: AnimatedSprite2D %Visual com o corpo
## (assets/sprites/lander_body_frames.tres, gatinho astronauta; animacao b_<tanque><bocal><pernas> pela versao das
## pecas, idle com piscar) e %Flame atras dele com a chama (lander_flame_frames.tres, flame_<motor>), que comeca na boca
## do bocal. stats["parts"] = ShipArt.tiers(levels) (o Main manda no setup) escolhe as versoes (ROADMAP 16.5).
class_name Lander
extends CharacterBody2D

signal took_off
signal landed(pad: Dictionary, quality: float, info: Dictionary)
signal crashed(reason: String, info: Dictionary)
## Aprendiz (ground_rest): tocou o chao fora de uma plataforma devagar e reto -> parou ali (decola de novo).
signal rested(info: Dictionary)
## Raspao (world.json landing.scrape): encostou fora da plataforma devagar o bastante -> quicou e segue voando.
## count = amassados neste salto; at = ponto do contato (px do mundo).
signal scraped(count: int, at: Vector2)

enum State {LANDED, FLYING, CRASHED}


var state: State = State.LANDED
var vel_m := Vector2.ZERO               # velocidade em m/s do modelo
var ice_pad_id := -1                    # v17 Sorvete: plataforma de gelo (pousar de lado vale: tolera max_vx x ice_vx_mult)
var ice_vx_mult := 1.0
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
var arriving := false                   # descendo do ceu ate a partida (Flight._arrive): chama acesa, sem fisica
var flight_time_m := 0.0                # segundos do modelo desde a decolagem
var gas_at_takeoff := 0.0
var ground_rest := false                # aprendiz (world.json > onboarding): pouso devagar fora da plataforma nao bate
var scrapes := 0                        # amassados (raspoes) neste salto; zera na decolagem
var _scrape_t := 1e9                    # tempo desde o ultimo raspao (contatos logo depois so quicam)
var _rot_hold := 0.0                    # quanto tempo o jogador segura o giro no mesmo sentido (rampa)
var _rot_dir := 0.0

const THRUST_START := preload("res://assets/audio/sfx/thruster_start.wav")
const THRUST_STOP := preload("res://assets/audio/sfx/thruster_stop.wav")
const GAS_ALARM := preload("res://assets/audio/sfx/gas_alarm.wav")
const RCS_LOOP := preload("res://assets/audio/sfx/rcs_loop.wav")
const SPUTTER := preload("res://assets/audio/sfx/sputter.wav")
## Jatinhos de giro: chiado bem baixo (toca o tempo todo que gira: nao pode cansar).
const RCS_DB := -15.0
## Turbo: o loop do propulsor sobe um tom inteiro (2 semitons), ganha volume e o filtro do bus Engine abre.
const TURBO_PITCH := 1.122
const TURBO_DB := 2.5
const ENGINE_CUTOFF := 4000.0
const TURBO_CUTOFF := 8000.0
## Alarme de gas: toca em voo abaixo desta fracao do tanque (mesmo limite da barra vermelha do HUD).
const ALARM_FRAC := 0.15
## Alarme que nao irrita: comeca forte e, depois de ALARM_LOUD_S, cai para ALARM_QUIET_DB (o jogador ja sabe).
const ALARM_LOUD_S := 3.0
const ALARM_QUIET_DB := -14.0

@onready var _visual: AnimatedSprite2D = %Visual
@onready var _flame: AnimatedSprite2D = %Flame
var parts: Dictionary = {}                 # versao de cada peca (ShipArt.tiers); vazio = tudo de serie
@onready var _thrust_loop: AudioStreamPlayer2D = %ThrustLoop
@onready var _thrust_fx: AudioStreamPlayer2D = %ThrustFx
var _was_thrusting := false
var _alarm: AudioStreamPlayer
var _alarm_t := 0.0
var _rcs: AudioStreamPlayer
var _rotating := false
var _engine_lp: AudioEffectLowPassFilter = null


## Configura a nave (stats do EconMath + planeta da spec) e as plataformas do terreno.
func setup(stats: Dictionary, planet: Dictionary, terrain_pads: Array[Dictionary]) -> void:
	params = {
		"gravity": float(planet["gravity"]),
		"planet_drag": float(planet.get("drag", 0.0)),
		"drag": float(planet.get("drag", 0.0)) * float(WorldConfig.load_config()["drag_scale"]),
		"thrust": float(stats["thrust"]),
		"efficiency": float(stats["efficiency"]),
		"tank": float(stats["tank"]),
		"gear": float(stats.get("gear", 1.0)),           # thrust = empuxo CRU; o voo usa EconMath.felt_thrust
		"stabilizer": float(stats.get("stabilizer", 0.0)) >= 1.0,
		"turbo": float(stats.get("turbo", 0.0)) >= 1.0,
	}
	gas = params["tank"]
	set_parts(stats.get("parts", {}))                          # versao das pecas no desenho (Main manda; vazio = de serie)
	pads = terrain_pads
	state = State.LANDED
	vel_m = Vector2.ZERO
	rotation = 0.0


func _ready() -> void:
	_alarm = AudioStreamPlayer.new()
	_alarm.stream = GAS_ALARM
	_alarm.bus = &"SFX"
	add_child(_alarm)
	_rcs = AudioStreamPlayer.new()
	_rcs.stream = RCS_LOOP
	_rcs.bus = &"SFX"
	_rcs.volume_db = RCS_DB
	add_child(_rcs)
	var bus := AudioServer.get_bus_index(&"Engine")
	if bus >= 0 and AudioServer.get_bus_effect_count(bus) > 0:
		_engine_lp = AudioServer.get_bus_effect(bus, 0) as AudioEffectLowPassFilter


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
			scrapes = 0
			_scrape_t = 1e9
			took_off.emit()
		else:
			thrusting = arriving
			queue_redraw()
			return
	_apply_rotation(float(controls["rotate"]), bool(controls.get("assisted", true)), cfg, delta)
	_scrape_t += delta
	var dt_m := delta * float(cfg["time_scale"])
	params["drag"] = LanderPhysics.drag_at(float(params["planet_drag"]), altitude_m(), cfg) + env_drag
	params["extra_accel"] = env_accel
	turbo_on = bool(controls.get("turbo", false)) and controls["thrust"]
	# empuxo sentido: cru / carga pesada -> teto suave (economy.json physics.feel) -> x Turbo
	var p := params.duplicate()
	p["thrust"] = felt_thrust() * (float(cfg["abilities"]["turbo_mult"]) if turbo_on else 1.0)
	var r := LanderPhysics.step(vel_m, rotation, controls["thrust"], gas, p, dt_m)
	vel_m = r["velocity"]
	var had_gas := gas > 0.0
	gas = r["gas"]
	if had_gas and gas <= 0.0 and controls["thrust"]:          # acabou o gas com o motor ligado: o motor tosse
		_thrust_fx.stream = SPUTTER                            # (no lugar do corte: sem gas o _update nao toca o stop)
		_thrust_fx.play()
	thrusting = float(r["gas_used"]) > 0.0
	flight_time_m += dt_m
	# recovery_as_collision=true: encostado e descendo devagar tambem conta como toque (senao o pouso lento nunca e detectado)
	var col := move_and_collide(vel_m * float(cfg["px_per_m"]) * dt_m, false, 0.08, true)
	if col:
		_on_touch(col.get_normal(), col.get_position())
	queue_redraw()


## Empuxo que o voo usa agora (m/s2): o motor cru dividido pela carga Pesada, com o teto suave do EconMath.
func felt_thrust() -> float:
	return EconMath.felt_thrust(float(params["thrust"]) / load_div, float(params["gravity"]))


## Giro. Jogador (assisted = false): rampa (toque = ajuste fino, segurar = virada rapida) e ima do em pe ao soltar
## perto da vertical (world.json > rotation). Piloto automatico e Estabilizador: velocidade fixa rotate_speed.
func _apply_rotation(rot: float, assisted: bool, cfg: Dictionary, delta: float) -> void:
	_rotating = absf(rot) > 0.05
	if assisted:
		rotation += rot * float(cfg["rotate_speed"]) * delta
		return
	var rc: Dictionary = cfg["rotation"]
	if _rotating:
		if signf(rot) != _rot_dir:
			_rot_dir = signf(rot)
			_rot_hold = 0.0
		_rot_hold += delta
		rotation += rot * rotation_speed(_rot_hold, rc) * delta
		return
	_rot_dir = 0.0
	_rot_hold = 0.0
	var tilt := wrapf(rotation, -PI, PI)
	if absf(tilt) < float(rc["snap_rad"]):
		rotation = move_toward(tilt, 0.0, float(rc["snap_speed"]) * delta)


## Velocidade de giro (rad/s) depois de segurar a tecla por held segundos: start_speed -> max_speed em ramp_s.
static func rotation_speed(held: float, rc: Dictionary) -> float:
	var k := clampf(held / maxf(float(rc["ramp_s"]), 1e-3), 0.0, 1.0)
	return lerpf(float(rc["start_speed"]), float(rc["max_speed"]), k)


## Versoes das pecas no desenho (corpo com tanque/bocal/pernas; chama do motor a partir da boca do bocal).
func set_parts(t: Dictionary) -> void:
	parts = t
	_visual.play(ShipArt.body_anim(t))
	_flame.play(ShipArt.flame_anim(t))
	_flame.position = Vector2(-16, ShipArt.mouth(t) - 16)


func _process(delta: float) -> void:
	if not _visual.is_playing():
		_visual.play(ShipArt.body_anim(parts))
	_flame.visible = thrusting
	if thrusting and not _flame.is_playing():
		_flame.play(ShipArt.flame_anim(parts))
	_flame.speed_scale = 2.0 if turbo_on and thrusting else 1.0    # Turbo: chama tremendo mais rapido
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
	for p: AudioStreamPlayer in [_alarm, _rcs]:
		if p != null:
			p.stop()
			p.stream = null
	if _engine_lp != null:
		_engine_lp.cutoff_hz = ENGINE_CUTOFF


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
			if gas > 0.0:                                      # sem gas quem fala e a tosse (sputter)
				_thrust_fx.stream = THRUST_STOP
				_thrust_fx.play()
	if state == State.CRASHED and _thrust_loop.playing:
		_thrust_loop.stop()
	_was_thrusting = thrusting
	# Turbo: mais agudo, mais alto e mais brilhante (desliza para nao "pular")
	var turbo := turbo_on and thrusting
	var k := clampf(get_process_delta_time() * 10.0, 0.0, 1.0)
	_thrust_loop.pitch_scale = lerpf(_thrust_loop.pitch_scale, TURBO_PITCH if turbo else 1.0, k)
	_thrust_loop.volume_db = lerpf(_thrust_loop.volume_db, TURBO_DB if turbo else 0.0, k)
	if _engine_lp != null:
		_engine_lp.cutoff_hz = lerpf(_engine_lp.cutoff_hz, TURBO_CUTOFF if turbo else ENGINE_CUTOFF, k)
	# jatinhos de giro: so em voo
	var rcs := _rotating and state == State.FLYING
	if rcs and not _rcs.playing:
		_rcs.play()
	elif not rcs and _rcs.playing:
		_rcs.stop()


## Altura (m do modelo) dos pes acima do relevo logo abaixo (0 sem terreno conhecido).
func altitude_m() -> float:
	if ridge.is_empty():
		return 0.0
	var feet := float(WorldConfig.load_config()["lander"]["feet_offset_m"])
	return WorldConfig.px_to_m(TerrainGen.height_at(ridge, global_position.x) - global_position.y) - feet


## Estado do voo atual (m/s do modelo, rad, gas gasto desde a decolagem, tempo do modelo).
func info() -> Dictionary:
	return {"vx": vel_m.x, "vy": vel_m.y, "tilt": wrapf(rotation, -PI, PI),
			"gas_used": gas_at_takeoff - gas, "flight_time_m": flight_time_m, "scrapes": scrapes}


func _read_controls() -> Dictionary:
	if autopilot != null:
		var ap_params := params.duplicate()                    # o piloto do demo pilota com o motor que o voo sente
		ap_params["thrust"] = felt_thrust()
		return autopilot.control(global_position, vel_m, rotation, ap_params)
	var rot := Input.get_axis(&"rotate_left", &"rotate_right")
	var assisted := false
	if params.get("stabilizer", false) and Input.is_action_pressed(&"stabilize"):
		rot = stabilize_input(rotation, float(WorldConfig.load_config()["abilities"]["stabilize_gain"]))
		assisted = true
	return {
		"rotate": rot,
		"assisted": assisted,
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


## Toque no terreno. normal = normal do contato (sai do chao), at = ponto do contato (px do mundo).
func _on_touch(normal: Vector2 = Vector2.UP, at: Vector2 = Vector2.ZERO) -> void:
	var cfg: Dictionary = WorldConfig.load_config()
	var half := WorldConfig.m_to_px(float(cfg["lander"]["half_width_m"]))
	var pad := TerrainGen.pad_at(pads, global_position.x)
	var on_pad := not pad.is_empty() and absf(global_position.x - float(pad["x"])) <= float(pad["half_width"]) - half * 0.5
	var tol := LandingRules.tolerances(cfg["landing"], float(params["gear"]))
	if on_pad and int(pad["id"]) == ice_pad_id:                # curling: chegar deslizando de lado e o jeito certo
		tol["max_vx"] = float(tol["max_vx"]) * ice_vx_mult
	var inf := info()
	var reason := LandingRules.crash_reason(inf["vy"], inf["vx"], inf["tilt"], on_pad, tol)
	if reason == "fora_da_plataforma" and ground_rest \
			and LandingRules.crash_reason(inf["vy"], inf["vx"], inf["tilt"], true, tol) == "":
		state = State.LANDED                                   # aprendiz: parou no chao, sem batida
		vel_m = Vector2.ZERO
		thrusting = false
		rested.emit(inf)
		return
	if reason == "fora_da_plataforma" and _try_scrape(normal, at, cfg):
		return
	if reason != "" and on_pad:                                # pouso duro: um fio alem da tolerancia ainda vale
		var hard_tol := tol.duplicate()
		var mult := float(cfg["landing"].get("hard", {}).get("mult", 1.0))
		for k: String in ["max_vy", "max_vx", "max_tilt"]:
			hard_tol[k] = float(tol[k]) * mult
		if LandingRules.crash_reason(inf["vy"], inf["vx"], inf["tilt"], true, hard_tol) == "":
			reason = ""
			inf["hard"] = true
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


## Bateu num obstaculo do ceu (Flight/SkyObstacles): explode na hora (usuario 2026-10-11: "tem que explodir a nave
## ao bater"), motivo "obstaculo".
func bump(_normal: Vector2, _at: Vector2) -> void:
	if state == State.FLYING:
		crash_now("obstaculo")


## Raspao fora da plataforma: quica se o impacto contra o chao cabe no casco e ainda ha amassado sobrando.
## Retorna true se quicou (o voo segue). Regra pura em LandingRules.scrape_bounce.
func _try_scrape(normal: Vector2, at: Vector2, cfg: Dictionary) -> bool:
	var sc: Dictionary = cfg["landing"].get("scrape", {})
	if sc.is_empty():
		return false
	var grace := _scrape_t < float(sc["grace_s"])
	var r := LandingRules.scrape_bounce(vel_m, normal, float(params["gear"]), scrapes, grace, sc)
	if not bool(r["ok"]):
		return false
	vel_m = r["velocity"]
	global_position += normal * 0.5                            # descola do chao (o proximo passo nao gruda)
	if not grace:
		scrapes += 1
		_scrape_t = 0.0
		scraped.emit(scrapes, at)
	return true
