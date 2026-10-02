## Teste de integracao dos CONTROLES como um jogador: abre o jogo normal (sem demo), injeta teclas reais
## (eventos de teclado como o SO manda) e verifica se a nave responde. Imprime CONTROLS_TEST OK ou FALHOU.
## Cenarios: menu inicial (Enter em Jogar) -> W antes de escolher (nao decola, aviso pisca) -> escolhe com CLIQUE do mouse -> W (decola) -> A (gira).
## Com -- --numpad: escolhe com a tecla 1 do teclado numerico.
extends Node

const MAIN := preload("res://game/main.tscn")

var _main: Node
var _step := 0
var _frames := 0
var _log: Array[String] = []
var _hint_ok := false
var _sound_ok := false
var _title_ok := false


func _ready() -> void:
	SaveManager.set_dir("user://itest_controls")
	_main = MAIN.instantiate()
	add_child(_main)


func _key(code: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _lander() -> Lander:
	return _main.find_child("Lander", true, false) as Lander


func _physics_process(_delta: float) -> void:
	_frames += 1
	var title := _main.find_child("TitleScreen", true, false) as TitleScreen
	if title != null and title.visible:                        # o jogo abre no menu inicial: Enter em "Jogar"
		if _frames == 10:
			_key(KEY_ENTER, true)
		elif _frames == 12:
			_key(KEY_ENTER, false)
		elif _frames > 60:
			_log.append("menu inicial: Enter nao iniciou o jogo")
			_frames = 0
		return
	if not _title_ok:
		_title_ok = true
		_log.append("menu inicial: Enter em Jogar iniciou o run")
		_frames = 0
	var l := _lander()
	if l == null:
		return
	match _step:
		0:
			if _frames > 20:
				_key(KEY_W, true)
				_step = 1
				_frames = 0
		1:
			if _frames > 30:
				_key(KEY_W, false)
				var panel := _main.find_child("OfferPanel", true, false) as OfferPanel
				_log.append("W antes de escolher: estado=%s aviso=%s" % [Lander.State.keys()[l.state], panel.hint_flash > 0.0])
				_hint_ok = panel.hint_flash > 0.0 and l.state == Lander.State.LANDED
				if "--numpad" in OS.get_cmdline_user_args():
					_key(KEY_KP_1, true); _key(KEY_KP_1, false)
				else:
					var click := InputEventMouseButton.new()
					click.button_index = MOUSE_BUTTON_LEFT
					click.position = panel.offer_line_center(0)
					click.global_position = click.position
					click.pressed = true
					Input.parse_input_event(click)
					var up := click.duplicate() as InputEventMouseButton
					up.pressed = false
					Input.parse_input_event(up)
				_step = 2
				_frames = 0
		2:
			if _frames == 5:
				_key(KEY_W, true)
			if _frames > 40:
				_key(KEY_W, false)
				_log.append("W depois de escolher: estado=%s y=%.1f" % [Lander.State.keys()[l.state], l.global_position.y])
				_sound_ok = (l.find_child("ThrustLoop") as AudioStreamPlayer2D).playing and Sound.played.has("click")
				_log.append("som: propulsor=%s clique=%s" % [(l.find_child("ThrustLoop") as AudioStreamPlayer2D).playing,
						Sound.played.get("click", 0)])
				_key(KEY_A, true)
				_step = 3
				_frames = 0
		3:
			if _frames > 15:
				_key(KEY_A, false)
				_log.append("A: rotacao=%.2f" % l.rotation)
				var flying := l.state == Lander.State.FLYING
				var rotated := l.rotation < -0.1
				print("CONTROLS_LOG ", " | ".join(_log))
				var ok := _title_ok and flying and rotated and _hint_ok and _sound_ok
				print("CONTROLS_TEST ", "OK" if ok else "FALHOU (menu=%s aviso=%s decolou=%s girou=%s som=%s)" % [_title_ok,
						_hint_ok, flying, rotated, _sound_ok])
				get_tree().quit()
