## Teste de integracao: o mapa nao acaba. Leva a nave 18 km para a direita e 10 km para a esquerda (alem das bordas
## iniciais) e confere que sempre ha chao embaixo e que a plataforma de partida nao mudou. Imprime EDGE_FLOW_TEST OK.
extends Node

const FLIGHT := preload("res://game/flight/flight.tscn")

var _flight: Flight
var _f := 0
var _ok := true
var _log: Array[String] = []
var _pad0: Dictionary


func _ready() -> void:
	Telemetry.enabled = false
	WorldConfig.register_input()
	_flight = FLIGHT.instantiate()
	add_child(_flight)
	_flight.start("luna", 7, EconMath.ship_stats({}), false)
	_flight.set_target(900.0, "normal")
	_pad0 = _flight.terrain.pads[0].duplicate()
	var l := _flight.lander
	l.set_physics_process(false)                               # a nave e levada a mao (sem cair)
	l.state = Lander.State.FLYING


func _check(what: String, cond: bool) -> void:
	if not cond:
		_log.append(what)
	_ok = _ok and cond


func _covered() -> bool:
	var r := _flight.terrain.ridge
	var x := _flight.lander.global_position.x
	return r[0].x < x - 300.0 and r[r.size() - 1].x > x + 300.0


func _physics_process(_d: float) -> void:
	_f += 1
	var l := _flight.lander
	if _f <= 60:
		l.global_position.x += 300.0                           # 18 km para a direita
		_check("chao_a_direita_%d" % _f, _f < 3 or _covered())
	elif _f <= 160:
		l.global_position.x -= 280.0                           # volta e passa 10 km para a esquerda
		_check("chao_a_esquerda_%d" % _f, _covered())
	else:
		_check("partida_igual", _flight.terrain.pads[0] == _pad0)
		_check("lander_ve_o_relevo", _flight.lander.ridge == _flight.terrain.ridge)
		print("EDGE_FLOW_LOG ", "falhas: " + ", ".join(_log) if not _log.is_empty() else "tudo ok")
		print("EDGE_FLOW_TEST ", "OK" if _ok else "FALHOU")
		get_tree().quit()
