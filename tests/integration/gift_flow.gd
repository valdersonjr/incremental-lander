## Teste de integracao: presente no alto do morro (v10). Galao: encostar devagar enche o tanque (sem passar do cheio) e
## nao pega de novo; passar rapido nao pega; presente de creditos vai no resultado da entrega. Imprime GIFT_FLOW_TEST OK.
extends Node

const FLIGHT := preload("res://game/flight/flight.tscn")

var _flight: Flight
var _f := 0
var _ok := true
var _log: Array[String] = []
var _gas0 := 10.0


func _ready() -> void:
	Telemetry.enabled = false
	WorldConfig.register_input()
	_flight = FLIGHT.instantiate()
	add_child(_flight)
	_flight.start("luna", 7, EconMath.ship_stats({}), false)
	_flight.set_target(900.0, "normal")
	_flight._spawn_gift("gas")
	var l := _flight.lander
	l.set_physics_process(false)                               # a nave e levada a mao
	l.state = Lander.State.FLYING
	l.gas = _gas0
	l.global_position = Vector2(_flight._gift_pos.x, _flight._gift_pos.y - 400.0)
	l.vel_m = Vector2.ZERO


func _check(what: String, cond: bool) -> void:
	if not cond:
		_log.append(what)
	_ok = _ok and cond


func _physics_process(_d: float) -> void:
	_f += 1
	var l := _flight.lander
	match _f:
		2:
			_check("longe_nao_pega", not _flight.gift_taken)
			l.global_position = _flight._gift_pos + Vector2(4, -10)   # encostou devagar
		4:
			_check("pegou_galao", _flight.gift_taken)
			var add := EconMath.gift_gas(_flight.stats, "gas")
			_check("gas_subiu", absf(l.gas - minf(float(l.params["tank"]), _gas0 + add)) < 0.01)
			var g := l.gas
			_flight._tick_gift()                                      # de novo no mesmo lugar: nao soma
			_check("uma_vez", l.gas == g)
			_flight._spawn_gift("gift")
			l.global_position = _flight._gift_pos + Vector2(0, -10)
			l.vel_m = Vector2(30.0, 0.0)                              # rapido demais
		6:
			_check("rapido_nao_pega", not _flight.gift_taken)
			l.vel_m = Vector2(1.0, 0.5)
		8:
			_check("pegou_presente", _flight.gift_taken and _flight.gift_kind == "gift")
			var got := {}
			_flight.delivery_finished.connect(func(r: Dictionary) -> void: got.merge(r))
			var pad := _flight.target_pad()
			_flight._on_lander_landed(pad, 0.9, {"vy": 1.0, "vx": 0.0, "tilt": 0.0, "gas_used": 5.0, "flight_time_m": 20.0})
			_check("resultado_com_presente", str(got.get("gift", "")) == "gift" and float(got.get("gift_pay", 0.0))
					> 0.0)
			_check("limpou", _flight.gift_kind == "" and not _flight.gift_taken)
		10:
			print("GIFT_FLOW_LOG ", "falhas: " + ", ".join(_log) if not _log.is_empty() else "tudo ok")
			print("GIFT_FLOW_TEST ", "OK" if _ok else "FALHOU")
			get_tree().quit()
