## Previa da interface do voo (HUD, ofertas, rodape, pausa) sobre o jogo real, sem o menu inicial.
## gdtool.py capture res://tests/visual/flight_ui_preview.tscn --frames 40 --every 39 -- --no_title [--pause]
## [--sandbox] [--hangar] [--hangar_menu [--confirm]: fim do run -> hangar -> Esc (menu do jogo)] [--delivered | --crashed] [--dev_levels=thrust:20]. O SaveManager se desliga em tests/visual/ (nunca grava o save real).
extends Node

const MAIN := preload("res://game/main.tscn")


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if "--sandbox" in args:                                    # sessao de sandbox (nave forte)
		Sandbox.begin("luna", true)
	var main := MAIN.instantiate()
	add_child(main)
	for i in 20:
		await get_tree().process_frame
	var hud := main.find_child("Hud", true, false) as Hud
	if "--crashed" in args:
		hud._on_delivery_finished({"crashed": true, "reason": "vertical_rapido", "quality": 0.0, "gas_used": 54.9})
	if "--delivered" in args:                                  # aviso de entrega com plataforma e combo
		hud.show_delivery({"rewards": {"credits": 721.0}, "quality": 0.86, "mult": 2.2, "combo": 1.2,
				"good": true}, 3)
	for a in args:                                             # --select=kind: cartao do pedido desse ratinho
		if a.begins_with("--select="):
			var offers := main.find_child("OfferPanel", true, false) as OfferPanel
			var i := offers._run.offer_slot.find(a.get_slice("=", 1))
			if i >= 0:
				offers._select(i)
				offers._choose(i, "narrow", offers._run.stars_for(i).back())
	if "--pause" in args:
		(main.find_child("PauseMenu", true, false) as PauseMenu).open()
	if "--hangar" in args:
		main._on_continue()
	if "--hangar_menu" in args:
		main._on_continue()
		(main.find_child("Hangar", true, false) as Hangar)._request_menu()
		if "--confirm" in args:
			(main.find_child("PauseMenu", true, false) as PauseMenu)._on_new_game()
