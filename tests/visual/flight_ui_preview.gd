## Previa da interface do voo (HUD, ofertas, rodape, pausa) sobre o jogo real, sem o menu inicial.
## gdtool.py capture res://tests/visual/flight_ui_preview.tscn --frames 40 --every 39 -- --no_title [--pause]
## [--sandbox] [--hangar] [--hangar_menu [--confirm]: fim do run -> hangar -> Esc (menu do jogo)] [--delivered | --crashed] [--planet=id --dev_levels=thrust:20] (mundo pesado pede motor, senao o run acaba). O SaveManager se desliga em tests/visual/ (nunca grava o save real).
extends Node

const MAIN := preload("res://game/main.tscn")


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if "--sandbox" in args:                                    # sessao de sandbox (Docelandia, nave forte)
		Sandbox.begin("kronos", true)
	var main := MAIN.instantiate()
	add_child(main)
	for i in 20:
		await get_tree().process_frame
	var hud := main.find_child("Hud", true, false) as Hud
	if "--delivered" in args or "--crashed" in args:
		var crashed := "--crashed" in args
		hud._on_delivery_finished({"crashed": crashed, "reason": "vertical_rapido", "quality": 0.86,
				"gas_used": 54.9})
	if "--pause" in args:
		(main.find_child("PauseMenu", true, false) as PauseMenu).open()
	if "--hangar" in args:
		main._on_continue()
	if "--hangar_menu" in args:
		main._on_continue()
		(main.find_child("Hangar", true, false) as Hangar)._request_menu()
		if "--confirm" in args:
			(main.find_child("PauseMenu", true, false) as PauseMenu)._on_new_game()
