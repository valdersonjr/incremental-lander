## Ferramenta de calibracao (v15, economy-balance): o piloto do demo voa cada tipo de missao nas mesmas distancias
## COM e SEM o relevo da missao (TerrainGen.mission_shape) e imprime o gas gasto, para medir quanto o relevo muda o custo.
## gdtool.py run res://tests/tools/mission_gas_probe.tscn --frames 200000
extends Node

const FLIGHT := preload("res://game/flight/flight.tscn")
const KINDS := ["simple", "heavy", "soft", "fast", "tow", "passenger"]
const DISTANCES := [800.0, 3000.0]

var _cases: Array[Array] = []
var _flight: Flight = null
var _rows: Array[String] = []


func _ready() -> void:
	Telemetry.enabled = false
	WorldConfig.register_input()
	for k: String in KINDS:
		for d: float in DISTANCES:
			for shaped: bool in [true, false]:
				_cases.append([k, d, shaped])
	_next()


func _next() -> void:
	if _flight != null:
		_flight.queue_free()
		_flight = null
	if _cases.is_empty():
		print("GAS_PROBE " + JSON.stringify(_rows))
		get_tree().quit()
		return
	var c: Array = _cases.pop_front()
	var kind: String = c[0]
	var m := {"kind": kind, "star": 1, "parts": [{"kind": kind, "star": 1}]}
	_flight = FLIGHT.instantiate()
	add_child(_flight)
	_flight.start("luna", 11, EconMath.ship_stats({"thrust": 10, "tank": 15, "efficiency": 10}), true)
	if c[2]:
		_flight.begin_mission(11, c[1], "normal", 1, m)
	else:                                                      # mesmo voo, relevo de sempre
		_flight._reset_map(11)
		_flight.set_target(c[1], "normal", 1, m)
		_flight._place_on_start_pad()
		_flight._arrive()
	var gas0 := _flight.lander.gas
	_flight.delivery_finished.connect(func(r: Dictionary) -> void:
		_rows.append("%s|%d|%s|%.2f|%s" % [kind, int(c[1]), "relevo" if c[2] else "plano", gas0 - _flight.lander.gas,
				"bateu" if r["crashed"] else "ok"])
		_next.call_deferred())
