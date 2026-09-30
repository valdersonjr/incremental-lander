## Cena de voo: terreno + lander + camera. Recebe stats/planeta ao comecar e devolve o resultado por sinal.
## Nao acessa GameState no meio do voo (skill godot-dev, architecture.md).
class_name Flight
extends Node2D

## Uma entrega terminou: pousou na plataforma alvo ou bateu. result = dados da entrega (ver _finish).
signal delivery_finished(result: Dictionary)

var planet_id := "luna"
var target_distance_m := 800.0
var stats: Dictionary = {}

@onready var lander: Lander = %Lander
@onready var terrain: Terrain = %Terrain
@onready var camera: Camera2D = %Camera


func _ready() -> void:
	lander.landed.connect(_on_lander_landed)
	lander.crashed.connect(_on_lander_crashed)


func _physics_process(_delta: float) -> void:
	camera.global_position = lander.global_position


## Gera o terreno, posiciona o lander na plataforma de partida e (opcional) liga o piloto automatico.
func start(p_planet_id: String, seed_value: int, p_target_distance_m: float, p_stats: Dictionary,
		demo: bool) -> void:
	planet_id = p_planet_id
	target_distance_m = p_target_distance_m
	stats = p_stats
	var data := terrain.build(seed_value, planet_id, [target_distance_m] as Array[float])
	terrain.target_pad_id = 1
	var planet := _planet_spec(planet_id)
	lander.setup(stats, planet, terrain.pads)
	var start_pad: Dictionary = terrain.pads[0]
	var feet := WorldConfig.m_to_px(float(WorldConfig.load_config()["lander"]["feet_offset_m"]))
	lander.global_position = Vector2(float(start_pad["x"]), float(start_pad["y"]) - feet - 0.5)
	lander.reset_physics_interpolation()
	camera.global_position = lander.global_position
	camera.reset_smoothing()
	if demo:
		var ap := Autopilot.new()
		ap.target = terrain.pads[1]
		ap.ridge = data["ridge"]
		lander.autopilot = ap


## Plataforma alvo desta entrega.
func target_pad() -> Dictionary:
	return terrain.pads[1]


func _planet_spec(pid: String) -> Dictionary:
	for p: Dictionary in EconMath.spec["planets"]:
		if p["id"] == pid:
			return p
	push_error("planeta '%s' nao existe na spec" % pid)
	return EconMath.spec["planets"][0]


func _on_lander_landed(pad: Dictionary, quality: float, info: Dictionary) -> void:
	if int(pad["id"]) == 0:
		return  # voltou para a partida: nao e entrega
	_finish(false, quality, "", info)


func _on_lander_crashed(reason: String, info: Dictionary) -> void:
	_finish(true, 0.0, reason, info)


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
		"crashed": crashed,
		"reason": reason,
	}
	Telemetry.record_delivery(result)
	delivery_finished.emit(result)
