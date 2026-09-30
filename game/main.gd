## Entrada do jogo: Main -> World (voo) + GUI (HUD). Le args: --demo (piloto automatico), --seed=N,
## --planet=id, --distance=m. Fase 1: um voo de entrega; R reinicia.
extends Node

const FLIGHT_SCENE := preload("res://game/flight/flight.tscn")
const HUD_SCENE := preload("res://game/hud/hud.tscn")

var _args: Dictionary = {}
var _flight: Flight = null
var _hud: Hud = null

@onready var _world: Node2D = %World
@onready var _gui: CanvasLayer = %GUI


func _ready() -> void:
	EconMath.load_spec()
	WorldConfig.load_config()
	WorldConfig.register_input()
	_args = _parse_args(OS.get_cmdline_user_args())
	_start_flight()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"restart"):
		_start_flight()


func _start_flight() -> void:
	if _flight != null:
		_flight.queue_free()
		_hud.queue_free()
	var demo_cfg: Dictionary = WorldConfig.load_config()["demo"]
	_flight = FLIGHT_SCENE.instantiate()
	_world.add_child(_flight)
	_hud = HUD_SCENE.instantiate()
	_gui.add_child(_hud)
	_hud.bind(_flight)
	_flight.delivery_finished.connect(_on_delivery_finished)
	var stats := EconMath.ship_stats({})
	_flight.start(
		str(_args.get("planet", "luna")),
		int(_args.get("seed", demo_cfg["seed"])),
		float(_args.get("distance", demo_cfg["target_distance_m"])),
		stats,
		_args.has("demo"))


func _on_delivery_finished(result: Dictionary) -> void:
	# linha para verificacao automatica (gdtool run/capture)
	print("DELIVERY_RESULT ", JSON.stringify(result))


func _parse_args(args: PackedStringArray) -> Dictionary:
	var out := {}
	for a in args:
		var s := a.trim_prefix("--")
		if "=" in s:
			out[s.get_slice("=", 0)] = s.get_slice("=", 1)
		else:
			out[s] = true
	return out
