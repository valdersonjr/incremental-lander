## Cena de voo: terreno + lander + camera. Encadeia entregas: set_target() cria a proxima plataforma a partir
## da atual e estende o terreno. Devolve cada entrega por sinal; nao acessa GameState (godot-dev).
class_name Flight
extends Node2D

## Uma entrega terminou: pousou na plataforma alvo ou bateu. result = dados da entrega (ver _finish).
signal delivery_finished(result: Dictionary)
## Pousou fora do alvo sem gas para decolar de novo.
signal stranded

var planet_id := "luna"
var stats: Dictionary = {}
var target_distance_m := 0.0
var current_pad_id := 0
var target_pad_id := -1

const EXPLOSION_FRAMES := preload("res://assets/sprites/explosion_frames.tres")
const DUST_FRAMES := preload("res://assets/sprites/landing_dust_frames.tres")

var _seed := 0
var _pad_positions_m: Array[float] = [0.0]
var _pad_tiers: Array[String] = []                 # tipo de cada plataforma de entrega (sem a partida)
var target_tier := "normal"
var _demo := false

@onready var lander: Lander = %Lander
@onready var terrain: Terrain = %Terrain
@onready var camera: Camera2D = %Camera
@onready var backdrop: Backdrop = %Backdrop


func _ready() -> void:
	lander.landed.connect(_on_lander_landed)
	lander.crashed.connect(_on_lander_crashed)


func _physics_process(delta: float) -> void:
	camera.global_position = lander.global_position
	var cam: Dictionary = WorldConfig.load_config()["camera"]
	var alt := TerrainGen.height_at(terrain.ridge, lander.global_position.x) - lander.global_position.y
	var target := -CameraMath.lift(alt, float(cam["ground_lift_px"]), float(cam["lift_fade_alt_px"]))
	camera.offset.y = lerpf(camera.offset.y, target, clampf(float(cam["lift_speed"]) * delta, 0.0, 1.0))


func _process(_delta: float) -> void:
	backdrop.follow(camera.get_screen_center_position())


## Gera o terreno inicial e posiciona o lander na plataforma de partida (sem alvo ainda).
func start(p_planet_id: String, seed_value: int, p_stats: Dictionary, demo: bool) -> void:
	planet_id = p_planet_id
	stats = p_stats
	_seed = seed_value
	_demo = demo
	_pad_positions_m = [0.0]
	_pad_tiers = []
	current_pad_id = 0
	target_pad_id = -1
	_rebuild_terrain()
	lander.setup(stats, _planet_spec(planet_id), terrain.pads)
	lander.ridge = terrain.ridge
	lander.visible = true
	lander.can_takeoff = false
	var start_pad: Dictionary = terrain.pads[0]
	var feet := WorldConfig.m_to_px(float(WorldConfig.load_config()["lander"]["feet_offset_m"]))
	lander.global_position = Vector2(float(start_pad["x"]), float(start_pad["y"]) - feet - 0.5)
	lander.reset_physics_interpolation()
	camera.global_position = lander.global_position
	var cam: Dictionary = WorldConfig.load_config()["camera"]
	camera.offset.y = -float(cam["ground_lift_px"])
	camera.reset_smoothing()
	camera.force_update_scroll()                              # ja no 1o quadro com o enquadramento certo
	backdrop.setup(planet_id, camera.global_position.y + camera.offset.y)


## Define a proxima entrega: plataforma do tipo tier (normal/narrow/tight) a distance_m a frente da atual.
func set_target(distance_m: float, tier: String = "normal") -> void:
	target_distance_m = distance_m
	target_tier = tier
	_pad_positions_m.append(_pad_positions_m[current_pad_id] + distance_m)
	_pad_tiers.append(tier)
	target_pad_id = _pad_positions_m.size() - 1
	_rebuild_terrain()
	lander.pads = terrain.pads
	lander.ridge = terrain.ridge
	lander.can_takeoff = true
	if _demo:
		var ap := Autopilot.new()
		ap.target = terrain.pads[target_pad_id]
		ap.ridge = terrain.ridge
		lander.autopilot = ap


## Plataforma alvo atual (ou a atual, se nao ha alvo).
func target_pad() -> Dictionary:
	return terrain.pads[target_pad_id if target_pad_id >= 0 else current_pad_id]


func _rebuild_terrain() -> void:
	var distances: Array[float] = []
	for i in range(1, _pad_positions_m.size()):
		distances.append(_pad_positions_m[i])
	terrain.target_pad_id = target_pad_id
	terrain.build(_seed, planet_id, distances, _pad_tiers)


func _planet_spec(pid: String) -> Dictionary:
	for p: Dictionary in EconMath.spec["planets"]:
		if p["id"] == pid:
			return p
	push_error("planeta '%s' nao existe na spec" % pid)
	return EconMath.spec["planets"][0]


func _on_lander_landed(pad: Dictionary, quality: float, info: Dictionary) -> void:
	# poeira (pixel-art: explosion.py): linha 15 do sprite = chao, x 24 = centro do lander
	_spawn_fx(DUST_FRAMES, &"puff", Vector2(lander.global_position.x - 24.0, float(pad["y"]) - 15.0), false)
	Sound.sfx("landing")
	current_pad_id = int(pad["id"])
	if current_pad_id == target_pad_id:
		Sound.sfx("delivered")
		lander.can_takeoff = false
		target_pad_id = -1
		terrain.target_pad_id = -1
		_finish(false, quality, "", info)
	elif lander.gas <= 0.001:
		stranded.emit()


func _on_lander_crashed(reason: String, info: Dictionary) -> void:
	# a nave some e explode; o resultado so sai depois da explosao (senao o resumo a cobre)
	lander.visible = false
	Sound.sfx("crash")
	var fx := _spawn_fx(EXPLOSION_FRAMES, &"boom", lander.global_position, true)
	await fx.animation_finished
	_finish(true, 0.0, reason, info)


## Efeito de uma vez (AnimatedSprite2D) no mundo, por cima do lander; se apaga ao terminar.
func _spawn_fx(frames: SpriteFrames, anim: StringName, pos: Vector2, centered: bool) -> AnimatedSprite2D:
	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = frames
	fx.centered = centered
	add_child(fx)
	fx.global_position = pos
	fx.play(anim)
	fx.animation_finished.connect(fx.queue_free)
	return fx


func _finish(crashed: bool, quality: float, reason: String, info: Dictionary) -> void:
	var result := {
		"planet": planet_id,
		"distance": target_distance_m,
		"thrust": stats["thrust"],
		"efficiency": stats["efficiency"],
		"tank": stats["tank"],
		"gas_used": info["gas_used"],
		"hop_time_s": info["flight_time_m"],
		"quality": quality,
		"tier": target_tier,
		"crashed": crashed,
		"reason": reason,
	}
	Telemetry.record_delivery(result)
	delivery_finished.emit(result)
