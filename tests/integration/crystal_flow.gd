## Teste de integracao dos cristais: o salto cria os cristais no arco; passar por um coleta (estouro, nota que sobe,
## texto do ganho); a entrega leva a contagem no resultado e limpa os cristais. Imprime CRYSTAL_FLOW_TEST OK ou FALHOU.
extends Node

const FLIGHT := preload("res://game/flight/flight.tscn")

var _flight: Flight
var _f := 0
var _log: Array[String] = []
var _ok := true
var _result: Dictionary = {}


func _ready() -> void:
	Telemetry.enabled = false                                  # nao sujar a telemetria do jogador
	WorldConfig.register_input()
	_flight = FLIGHT.instantiate()
	add_child(_flight)
	_flight.start("luna", 7, EconMath.ship_stats({}), false)  # terreno pronto antes do 1o quadro de fisica
	_flight.delivery_finished.connect(func(r: Dictionary) -> void: _result = r)


func _check(what: String, cond: bool) -> void:
	_log.append("%s=%s" % [what, cond])
	_ok = _ok and cond


func _fly_to(i: int) -> void:
	var l := _flight.lander
	l.state = Lander.State.FLYING
	l.vel_m = Vector2.ZERO
	l.global_position = _flight._crystal_pos[i]


func _physics_process(_d: float) -> void:
	_f += 1
	match _f:
		2:
			_flight.set_target(1000.0, "narrow")
		4:
			_check("tres_cristais", _flight._crystal_pos.size() == 3 and _flight._crystal_nodes.size() == 3)
			_fly_to(0)
		7:
			_check("pegou_1", _flight.crystals_taken == 1)
			_check("som_1", int(Sound.played.get("crystal_1", 0)) >= 1)
			_check("texto_do_ganho", _flight.get_children().any(func(c: Node) -> bool: return c is Label))
			_fly_to(2)
		10:
			_check("pegou_2", _flight.crystals_taken == 2 and int(Sound.played.get("crystal_2", 0)) >= 1)
			_fly_to(2)                                         # o mesmo cristal nao conta duas vezes
		13:
			_check("nao_repete", _flight.crystals_taken == 2)
			var pad := _flight.target_pad()
			_flight._on_lander_landed(pad, 0.9, {"gas_used": 30.0, "flight_time_m": 40.0})
		16:
			_check("resultado_tem_cristais", int(_result.get("crystals", -1)) == 2)
			_check("tipo_no_resultado", str(_result.get("tier", "")) == "narrow")
			_check("cristais_limpos", _flight._crystal_pos.is_empty())
			print("CRYSTAL_FLOW_LOG ", " | ".join(_log))
			print("CRYSTAL_FLOW_TEST ", "OK" if _ok else "FALHOU")
			get_tree().quit()
