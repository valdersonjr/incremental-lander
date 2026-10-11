## Teste de integracao do modo sandbox: menu inicial -> sandbox (Docelandia, nave forte) -> hangar com tudo liberado e
## recursos de teste -> compra -> o save no disco NAO muda -> Esc -> "Sair do sandbox" -> o jogo verdadeiro volta
## intacto -> sandbox no Quarto (sem tela de final). Pasta propria (user://itest_sandbox), nunca o save real.
## Imprime SANDBOX_FLOW_TEST OK ou FALHOU.
extends Node

const MAIN := preload("res://game/main.tscn")

var _main: Node
var _f := 0
var _log: Array[String] = []
var _ok := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SaveManager.set_dir("user://itest_sandbox")
	SaveManager.enabled = true                                 # aqui o save grava de verdade (na pasta do teste)
	for f: String in ["save.json", "save.bak", "settings.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://itest_sandbox".path_join(f)))
	GameState.reset()
	Telemetry.enabled = true                                   # jogo de verdade grava (testes desligam; aqui nao ha voo)
	GameState.runs_done = 5                                    # o "jogo verdadeiro"
	GameState.resources["credits"] = 123.0
	SaveManager.save_game()
	_main = MAIN.instantiate()
	_main.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_main)


func _check(what: String, cond: bool) -> void:
	_log.append("%s=%s" % [what, cond])
	_ok = _ok and cond


func _disk_credits() -> float:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(SaveManager.slot_files(1)["path"]))
	var back := SaveData.deserialize(d)
	return float(back["state"]["resources"]["credits"]) if back["ok"] else -1.0


func _key(code: Key) -> void:
	for p: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = code
		ev.physical_keycode = code
		ev.pressed = p
		Input.parse_input_event(ev)


func _process(_d: float) -> void:
	_f += 1
	var title: TitleScreen = _main._title
	var hangar: Hangar = _main._hangar
	var menu: PauseMenu = _main._pause
	match _f:
		10:
			title.sandbox_requested.emit("luna", true)
		20:
			_check("mapa", _main._world_map.visible and Sandbox.active())
			_check("mundo", GameState.current_planet == "luna" and GameState.worlds().size() == EconMath.spec["planets"].size())
			_check("recursos", GameState.amount("credits") >= 1e14)
			_check("nave_forte", int(GameState.levels.get("thrust", 0)) == 42)
			_check("sem_telemetria", not Telemetry.enabled)
			_check("compra", GameState.buy_upgrade("tank"))
			SaveManager.save_game()
		30:
			_check("disco_intacto", is_equal_approx(_disk_credits(), 123.0))
			_key(KEY_ESCAPE)
		40:
			_check("menu_sair", menu.visible and (menu.find_child("MenuButton", true, false) as Button).text == "Sair do modo livre")
			_check("sem_novo_jogo", not (menu.find_child("NewGameRow", true, false) as Control).visible)
			(menu.find_child("MenuButton", true, false) as Button).pressed.emit()
		50:
			_check("titulo", title.visible and not Sandbox.active())
			_check("jogo_volta", GameState.runs_done == 5 and is_equal_approx(GameState.amount("credits"), 123.0)
					and GameState.current_planet == "luna")
			_check("telemetria_volta", Telemetry.enabled)
			_check("disco_ainda_intacto", is_equal_approx(_disk_credits(), 123.0))
			title.sandbox_requested.emit("luna", false)
		60:
			_check("nave_basica", int(GameState.levels.get("thrust", 0)) == 0 and _main._world_map.visible)
			_main._show_title()
		70:
			_check("saiu_de_novo", not Sandbox.active() and GameState.runs_done == 5)
			print("SANDBOX_FLOW_LOG ", " | ".join(_log))
			print("SANDBOX_FLOW_TEST ", "OK" if _ok else "FALHOU")
			get_tree().quit()
