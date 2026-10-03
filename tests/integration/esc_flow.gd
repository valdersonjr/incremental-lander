## Teste de integracao do Esc como um jogador (teclas reais): hangar -> Esc abre o MENU do jogo com o hangar escondido
## -> R nao decola -> Esc volta ao hangar -> Esc + "Menu inicial" vai ao titulo; no voo Esc pausa e Esc retoma;
## no voo, Esc + "Menu inicial" vai ao titulo (sem Novo jogo; arvore despausada).
## Tambem: filtro CRT ligado por padrao e o botao do menu liga/desliga a camada. Imprime ESC_FLOW_TEST OK ou FALHOU.
extends Node

const MAIN := preload("res://game/main.tscn")

var _main: Node
var _f := 0
var _log: Array[String] = []
var _ok := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SaveManager.set_dir("user://itest_esc")
	GameState.runs_done = 1                                    # com progresso: Continuar leva ao hangar
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
	var title: TitleScreen = _main._title
	var hangar: Hangar = _main._hangar
	var menu: PauseMenu = _main._pause
	match _f:
		10:
			title.play_requested.emit()                        # Continuar
		20:
			_check("hangar", hangar.visible)
			_key(KEY_ESCAPE)
		30:
			var crt := get_tree().root.get_node("Crt") as CanvasLayer
			_check("crt_padrao_ligado", crt.visible)
			var toggle: Button = menu.find_children("*", "Button", true, false).filter(func(b: Node) -> bool:
				return b.get_meta(&"focus_key", "") == "crt")[0]
			toggle.pressed.emit()
			_check("crt_desliga_pelo_menu", not crt.visible and toggle.text == "Desligado")
			toggle.pressed.emit()
			_check("esc_no_hangar_abre_menu", menu.visible and not hangar.visible and menu.mode == PauseMenu.Mode.HANGAR)
			_check("menu_nao_pausa", not get_tree().paused)
			_key(KEY_R)
		40:
			_check("r_nao_decola", menu.visible and _main._hud == null)
			_key(KEY_ESCAPE)
		50:
			_check("esc_volta_ao_hangar", hangar.visible and not menu.visible)
			_key(KEY_ESCAPE)
		60:
			(menu.find_child("MenuButton", true, false) as Button).pressed.emit()
		70:
			_check("menu_inicial", title.visible and not hangar.visible and not menu.visible)
			title.play_requested.emit()
		80:
			hangar.launch_requested.emit()
		90:
			_key(KEY_ESCAPE)
		100:
			_check("esc_no_voo_pausa", menu.visible and menu.mode == PauseMenu.Mode.FLIGHT and get_tree().paused)
			_key(KEY_ESCAPE)
		110:
			_check("esc_retoma", not menu.visible and not get_tree().paused and not hangar.visible)
			_key(KEY_ESCAPE)
		120:
			var mb := menu.find_child("MenuButton", true, false) as Button
			_check("voo_tem_menu_inicial", mb.is_visible_in_tree()
					and not (menu.find_child("NewGameRow", true, false) as Control).visible)
			mb.pressed.emit()
		130:
			_check("voo_volta_ao_titulo", title.visible and not menu.visible and not get_tree().paused
					and _main._hud == null and not hangar.visible)
			print("ESC_FLOW_LOG ", " | ".join(_log))
			print("ESC_FLOW_TEST ", "OK" if _ok else "FALHOU")
			get_tree().quit()
