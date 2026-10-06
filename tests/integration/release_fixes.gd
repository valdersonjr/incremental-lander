## Teste de integracao das correcoes da auditoria de lancamento (2026-10-03), numa pasta propria (user://itest_fixes):
## recomeco com Cartas de navegacao volta a um mundo em que a nave decola; hangar nao decola num mundo impossivel;
## R na tela final nao comeca run; abrir o hangar esconde as ofertas (teclas nao vazam); E precisa de 2 toques;
## Espaco nao confirma menus; o relogio do run para na pausa; save ilegivel e guardado a parte com aviso; recordes;
## audio: musica por tela, ambiencia do mundo, jingles dos eventos e alarme de gas baixo.
## Imprime RELEASE_FIXES_TEST OK ou FALHOU.
extends Node

const MAIN := preload("res://game/main.tscn")

var _main: Node
var _f := 0
var _log: Array[String] = []
var _ok := true
var _t0 := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SaveManager.enabled = true
	SaveManager.set_dir("user://itest_fixes")
	for n in range(1, SaveManager.SLOTS + 1):
		SaveManager.delete_slot(n)
	_main = MAIN.instantiate()
	_main.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_main)


func _key(code: Key) -> void:
	for p: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = code
		ev.physical_keycode = code
		ev.pressed = p
		Input.parse_input_event(ev)


func _check(what: String, cond: bool) -> void:
	_log.append("%s=%s" % [what, cond])
	_ok = _ok and cond


func _process(_d: float) -> void:
	_f += 1
	var hangar: Hangar = _main._hangar
	match _f:
		5:
			# Espaco (propulsor) nao confirma botoes; Enter sim
			var space := InputEventKey.new()
			space.physical_keycode = KEY_SPACE
			space.keycode = KEY_SPACE
			_check("espaco_fora_do_ui_accept", not InputMap.event_is_action(space, &"ui_accept"))
			_check("espaco_e_propulsor", InputMap.event_is_action(space, &"thrust"))
			GameState.reset()
			_main._title.visible = false
			_main._open_hangar()
		8:
			_check("hangar_decola_na_lua", not hangar._launch.disabled)
			hangar.launch_requested.emit()
		12:
			var offers: OfferPanel = _main._offers
			_check("run_comecou", offers.visible)
			_check("musica_de_voo", Sound._music_name == "flight" and Sound._ambience_name == "luna")
			# alarme de gas: em voo com gas abaixo de 15% toca; pousado nao
			var l: Lander = _main._flight.lander
			l.state = Lander.State.FLYING
			l.gas = float(l.params["tank"]) * 0.1
			set_meta(&"lander", l)
			# E precisa de 2 toques
			_key(KEY_E)
		14:
			_check("um_E_nao_encerra", not _main._run.over and _main._offers.end_armed > 0.0)
			var l: Lander = get_meta(&"lander")
			_check("alarme_de_gas_toca", l._alarm.playing)
			l.state = Lander.State.LANDED
			l.gas = float(l.params["tank"])
			# relogio do run para com o jogo pausado
			_t0 = _main._run_time
			get_tree().paused = true
		24:
			_check("relogio_parado_na_pausa", is_equal_approx(_main._run_time, _t0))
			get_tree().paused = false
			# abrir o hangar por cima de um run esconde as ofertas; tecla 1 nao escolhe entrega escondida
			_main._open_hangar()
		26:
			_check("hangar_esconde_ofertas", not _main._offers.visible)
			_check("hangar_toca_musica_do_menu", Sound._music_name == "title")
			_check("alarme_para_ao_pousar", not (get_meta(&"lander") as Lander)._alarm.playing)
			_key(KEY_1)
		28:
			_check("tecla_1_nao_vaza", _main._flight.target_pad_id < 0)
		31:
			# recordes: a primeira marca nao e "novo recorde"; superar depois e
			GameState.records = {}
			_check("primeira_marca_nao_anuncia", not GameState.note_record("best_combo", 2.0))
			_check("superar_anuncia", GameState.note_record("best_combo", 3.0))
			_check("pior_nao_anuncia", not GameState.note_record("best_combo", 1.0))
			# save ilegivel: guardado a parte, aviso para o jogador, nunca sobrescrito
			var files := SaveManager.slot_files(2)
			var f := FileAccess.open(files["path"], FileAccess.WRITE)
			f.store_string("{isto nao e json")
			f.close()
			SaveManager.load_slot(2)
			_check("aviso_de_save_ilegivel", SaveManager.load_warning != "")
			SaveManager.save_game()
			var kept := str(files["path"]).get_basename() + ".unreadable.json"
			_check("ilegivel_guardado_a_parte", FileAccess.file_exists(kept)
					and FileAccess.get_file_as_string(kept) == "{isto nao e json")
			_check("save_novo_valido", SaveManager.slot_summary(2)["ok"])
			for n in range(1, SaveManager.SLOTS + 1):
				SaveManager.delete_slot(n)
			if FileAccess.file_exists(kept):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(kept))
			print("RELEASE_FIXES_TEST " + ("OK" if _ok else "FALHOU " + ", ".join(_log)))
			get_tree().quit(0 if _ok else 1)
