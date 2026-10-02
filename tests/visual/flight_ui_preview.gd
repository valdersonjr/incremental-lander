## Previa da interface do voo (HUD, ofertas, rodape, pausa) sobre o jogo real, sem o menu inicial.
## gdtool.py capture res://tests/visual/flight_ui_preview.tscn --frames 40 --every 39 -- --no_title [--pause]
## [--delivered | --crashed] [--planet=id --dev_levels=thrust:20] (mundo pesado pede motor, senao o run acaba). O SaveManager se desliga em tests/visual/ (nunca grava o save real).
extends Node

const MAIN := preload("res://game/main.tscn")


func _ready() -> void:
	var main := MAIN.instantiate()
	add_child(main)
	var args := OS.get_cmdline_user_args()
	for i in 20:
		await get_tree().process_frame
	var hud := main.find_child("Hud", true, false) as Hud
	if "--delivered" in args or "--crashed" in args:
		var crashed := "--crashed" in args
		hud._on_delivery_finished({"crashed": crashed, "reason": "vertical_rapido", "quality": 0.86,
				"gas_used": 54.9})
	if "--pause" in args:
		(main.find_child("PauseMenu", true, false) as PauseMenu).open()
