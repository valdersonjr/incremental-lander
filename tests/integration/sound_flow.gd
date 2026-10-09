## Teste de integracao da auditoria de som (2026-10-09): gramatica da interface (seta move o foco = "move";
## grab_focus de tela nova nao soa), musica de voo = base + camada do mundo sincronizadas (camada = 1/3 da base),
## pausa abafa musica e ambiencia (e volta), tique da contagem, previa de volume no proprio canal, todo som novo
## carrega, e a contagem do resumo termina no total com a vinheta.
## Imprime SOUND_FLOW_TEST OK ou FALHOU.
extends Node

const SUMMARY := preload("res://game/run/run_summary.tscn")

var _f := 0
var _log: Array[String] = []
var _ok := true
var _a: Button
var _b: Button
var _summary: RunSummary


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var box := VBoxContainer.new()
	add_child(box)
	_a = Button.new()
	_a.text = "A"
	_b = Button.new()
	_b.text = "B"
	box.add_child(_a)
	box.add_child(_b)


func _check(what: String, cond: bool) -> void:
	_log.append("%s=%s" % [what, cond])
	_ok = _ok and cond


func _key(code: Key) -> void:
	for p: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = code
		ev.physical_keycode = code
		ev.pressed = p
		Input.parse_input_event(ev)


func _played(name: String) -> int:
	return int(Sound.played.get(name, 0))


func _process(_delta: float) -> void:
	_f += 1
	match _f:
		2:
			var missing: Array[String] = []
			for n: String in Sound.STREAMS:
				if not ResourceLoader.exists(Sound.STREAMS[n]):
					missing.append(n)
			_check("todos_os_sons_existem", missing.is_empty())
			_a.grab_focus()                                    # foco de tela nova: nao soa
		4:
			_check("grab_focus_nao_soa", _played("move") == 0)
			_key(KEY_DOWN)                                     # o jogador anda com a seta
		7:
			_check("seta_soa_move", _played("move") == 1 and _b.has_focus())
			Sound.back()
			Sound.tally(0)
			Sound.tally(20)                                    # passou do fim: fica no ultimo grau
			Sound.preview("SFX")
			_check("voltar_tique_previa", _played("back") == 1 and _played("tally") == 2 and _played("crystal_2") == 1)
			Sound.music("flight", "bolhas")
		10:
			var s := Sound._music[0].stream as AudioStreamSynchronized
			_check("voo_com_camada_do_mundo", s != null and s.stream_count == 2)
			if s != null:
				var base := s.get_sync_stream(0).get_length()
				var layer := s.get_sync_stream(1).get_length()
				_check("camada_cabe_3x_na_base", absf(layer * 3.0 - base) < 0.01)
			Sound.music("flight", "bolhas")                    # o mesmo: nao reinicia
			_check("mesma_musica_nao_troca", Sound._music_name == "flight:bolhas")
			Sound.music("title")
			_check("titulo_sem_camada", not Sound._music[0].stream is AudioStreamSynchronized)
			Sound.muffle(true)
		40:
			var idx := AudioServer.get_bus_index(&"Music")
			var last := AudioServer.get_bus_effect_count(idx) - 1
			var lp := AudioServer.get_bus_effect(idx, last) as AudioEffectLowPassFilter
			_check("pausa_abafa", lp != null and AudioServer.is_bus_effect_enabled(idx, last) and lp.cutoff_hz < 1500.0)
			Sound.muffle(false)
		90:
			var idx := AudioServer.get_bus_index(&"Music")
			var last := AudioServer.get_bus_effect_count(idx) - 1
			_check("fim_da_pausa_desabafa", not AudioServer.is_bus_effect_enabled(idx, last))
			_summary = SUMMARY.instantiate()
			add_child(_summary)
			_summary.show_summary({"reason": "sem_gas", "rec_values": {"run_money": 1234.0}, "rec_start": {}})
		100:
			_check("contagem_comeca_do_zero", _big_text() != EconMath.fmt(1234.0))
		200:
			_check("contagem_termina_no_total", _big_text() == EconMath.fmt(1234.0))
			_check("tiques_na_contagem", _played("tally") > 4)
			_check("vinheta_no_fim", _played("summary_end") == 1)
			print("SOUND_FLOW_TEST %s %s" % ["OK" if _ok else "FALHOU", " ".join(_log)])
			get_tree().quit()


func _big_text() -> String:
	for l: Node in _summary.find_children("*", "Label", true, false):
		if (l as Label).theme_type_variation == &"BigMoneyLabel":
			return (l as Label).text
	return ""
