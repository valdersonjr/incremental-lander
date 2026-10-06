## Teste de integracao: cada missao no seu mapa (v15). begin_mission gera um terreno novo (seed da missao) com a
## partida em x=0 e o alvo na distancia pedida; mesma seed = mesmo mapa; a nave desce do ceu sem gastar gas e so pode
## decolar depois de tocar a partida. Imprime MISSION_MAP_FLOW_TEST OK.
extends Node

const FLIGHT := preload("res://game/flight/flight.tscn")

var _flight: Flight
var _f := 0
var _ok := true
var _log: Array[String] = []
var _gas0 := 0.0
var _ridge_a := PackedVector2Array()


func _ready() -> void:
	Telemetry.enabled = false
	WorldConfig.register_input()
	_flight = FLIGHT.instantiate()
	add_child(_flight)
	_flight.start("luna", 7, EconMath.ship_stats({}), false)
	_gas0 = _flight.lander.gas
	_flight.begin_mission(101, 900.0, "narrow", 1)
	_ridge_a = _flight.terrain.ridge.duplicate()


func _check(what: String, cond: bool) -> void:
	if not cond:
		_log.append(what)
	_ok = _ok and cond


func _physics_process(_d: float) -> void:
	_f += 1
	var l := _flight.lander
	var start: Dictionary = _flight.terrain.pads[0]
	match _f:
		2:
			_check("partida_em_x0", absf(float(start["x"])) < 0.5)
			_check("alvo_na_distancia", absf(_flight.target_pad()["x"] - WorldConfig.m_to_px(900.0)) < 1.0)
			_check("descendo", l.arriving and not l.can_takeoff and l.global_position.y < float(start["y"]) - 40.0)
		120:
			_check("pousou_na_partida", not l.arriving and l.can_takeoff and l.state == Lander.State.LANDED)
			_check("sem_gastar_gas", absf(l.gas - _gas0) < 0.001)
			_flight.begin_mission(202, 900.0, "narrow", 1)
			_check("outro_mapa", _flight.terrain.ridge != _ridge_a)
			_flight.begin_mission(101, 900.0, "narrow", 1)
			_check("mesma_seed_mesmo_mapa", _flight.terrain.ridge == _ridge_a)
		121:
			print("MISSION_MAP_FLOW_LOG ", ", ".join(_log))
			print("MISSION_MAP_FLOW_TEST ", "OK" if _ok else "FALHOU " + ", ".join(_log))
			get_tree().quit()
