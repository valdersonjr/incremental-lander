## Teste de integracao: a TELA acompanha a nave no 1o voo de um jogo novo (menu -> Jogar -> cartao vazio -> pedido ->
## decolar). A Flight nova entrava com a do fundo do menu ainda na arvore e a Camera2D (interpolacao de fisica) ficava
## sem processar: a nave subia e o canvas ficava parado ate um Esc. Mede o canvas_transform (o que se ve), nao a camera.
## Pasta propria (user://itest_cam). Imprime CAMERA_FOLLOW_TEST OK ou FALHOU.
extends Node

const MAIN := preload("res://game/main.tscn")

var _main: Node
var _f := 0
var _canvas_start := Vector2.ZERO
var _lander_start := Vector2.ZERO


func _ready() -> void:
	SaveManager.enabled = true
	SaveManager.set_dir("user://itest_cam")
	for n in range(1, SaveManager.SLOTS + 1):
		SaveManager.delete_slot(n)
	_main = MAIN.instantiate()
	add_child(_main)


func _process(_d: float) -> void:
	_f += 1
	var title: TitleScreen = _main._title
	match _f:
		10:
			(title.find_child("Play", true, false) as Button).pressed.emit()
		14:
			for b: Node in title.find_children("*", "Button", true, false):
				if b.get_meta(&"focus_key", "") == "slot:2":
					(b as Button).pressed.emit()
		40:
			_main._offers.offer_chosen.emit(0)
		200:
			_canvas_start = get_viewport().canvas_transform.origin
			_lander_start = (_main._flight as Flight).lander.global_position
			Input.action_press(&"thrust")
		320:
			Input.action_release(&"thrust")
			var climbed := _lander_start.y - (_main._flight as Flight).lander.global_position.y
			var scrolled := get_viewport().canvas_transform.origin.y - _canvas_start.y
			var ok := climbed > 60.0 and scrolled > climbed * 0.5
			for n in range(1, SaveManager.SLOTS + 1):
				SaveManager.delete_slot(n)
			print("CAMERA_FOLLOW_TEST " + ("OK" if ok else "FALHOU nave subiu %.0f px, tela andou %.0f px" % [climbed, scrolled]))
			get_tree().quit(0 if ok else 1)
