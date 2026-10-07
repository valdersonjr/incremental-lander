## Teste de integracao dos mundos paralelos (v16): a Estrada libera mundos; escolher mundo fechado nao vale; recordes
## por mundo; bonus de recorde; DECOLAR com 2+ mundos abre o Mapa das estrelas e voar comeca o run no mundo escolhido;
## o save guarda o mundo e os recordes por mundo (pasta propria user://itest_worlds). Imprime WORLDS_TEST OK ou FALHOU.
extends Node

const MAIN := preload("res://game/main.tscn")

var _main: Node
var _f := 0
var _fails: Array[String] = []


func _check(what: String, cond: bool) -> void:
	if not cond:
		_fails.append(what)


func _ready() -> void:
	SaveManager.enabled = true
	SaveManager.set_dir("user://itest_worlds")
	for n in range(1, SaveManager.SLOTS + 1):
		SaveManager.delete_slot(n)
	GameState.reset()
	_check("so_a_lua_no_inicio", GameState.worlds() == ["luna"])
	_check("mundo_fechado_nao_escolhe", not GameState.select_world("nuvens"))
	GameState.stars = int(EconMath.road_stop("world_nuvens")["stars"])
	GameState._check_road(true)
	_check("estrada_libera_nuvens", GameState.worlds() == ["luna", "nuvens"])
	_check("escolhe_nuvens", GameState.select_world("nuvens") and GameState.current_planet == "nuvens")
	GameState.note_record("run_money", 500.0)
	_check("recorde_por_mundo", float(GameState.world_records("nuvens").get("run_money", 0.0)) == 500.0
			and GameState.world_records("luna").is_empty())
	var b := EconMath.spec["contracts"]["record_bonus"] as Dictionary
	_check("bonus_primeira_visita", is_equal_approx(EconMath.record_bonus(100.0, 0.0), 100.0 * float(b["first_frac"])))
	_check("bonus_so_bate_marca", EconMath.record_bonus(400.0, 500.0) == 0.0 and EconMath.record_bonus(600.0, 500.0) > 0.0)
	SaveManager.load_slot(1)
	GameState.stars = int(EconMath.road_stop("world_nuvens")["stars"])
	GameState._check_road(true)
	GameState.select_world("nuvens")
	GameState.note_record("run_money", 500.0)
	SaveManager.save_game()
	GameState.reset()
	SaveManager.load_game()
	_check("save_guarda_mundo", GameState.current_planet == "nuvens")
	_check("save_guarda_recorde_do_mundo", float(GameState.world_records("nuvens").get("run_money", 0.0)) == 500.0)
	GameState.select_world("luna")
	_main = MAIN.instantiate()
	add_child(_main)


func _process(_d: float) -> void:
	_f += 1
	match _f:
		5:
			_main._title.visible = false
			_main._open_hangar()
		8:
			_main._hangar.launch_requested.emit()
		10:
			var map: WorldMap = _main._world_map
			_check("decolar_abre_mapa", map.visible)
			map._select("nuvens")
			map._go()
		14:
			_check("run_no_mundo_escolhido", _main._run != null and _main._run.planet_id == "nuvens"
					and _main._flight.planet_id == "nuvens")
			print("WORLDS_TEST " + ("OK" if _fails.is_empty() else "FALHOU " + "; ".join(_fails)))
			get_tree().quit(0 if _fails.is_empty() else 1)
