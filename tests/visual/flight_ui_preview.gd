## Previa da interface do voo (HUD, ofertas, rodape, pausa) sobre o jogo real, sem o menu inicial.
## gdtool.py capture res://tests/visual/flight_ui_preview.tscn --frames 40 --every 39 -- --no_title [--pause]
## [--sandbox] [--missions] [--no_offers] [--select=slot] [--peek=kind] [--accept] [--hangar] [--hangar_menu [--confirm]: fim do run -> hangar -> Esc (menu do jogo)] [--delivered | --crashed] [--dev_levels=thrust:20]. O SaveManager se desliga em tests/visual/ (nunca grava o save real).
extends Node

const MAIN := preload("res://game/main.tscn")


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if "--sandbox" in args:                                    # sessao de sandbox (nave forte)
		Sandbox.begin("luna", true)
	if "--missions" in args:                                   # todos os ratinhos liberados (cartao com estrelas)
		GameState.mission_nodes.assign(["heavy1", "soft1", "fast1", "heavy2", "soft2", "passenger1", "fast2", "tow1",
				"soft3"])
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
	var offers := main.find_child("OfferPanel", true, false) as OfferPanel
	for a in args:                                             # --select=slot: janela do ratinho desse pedido
		if a.begins_with("--select="):                         # (simple2 = mineiro, longe; plataforma estreita)
			var i := offers._run.offer_slot.find(a.get_slice("=", 1))
			if i >= 0:
				var kind := str(offers._run.offer_mission[i]["kind"])
				offers._select(kind)
				offers._choose_dist((offers._groups[kind] as Array).find(i))
				offers._choose("narrow", offers._run.stars_for(i).back())
		elif a.begins_with("--peek="):                         # --peek=kind: ratinho ainda nao liberado sob o mouse
			offers._peek_locked(a.get_slice("=", 1))
	if "--accept" in args:                                     # joinha + comemoracao (sem partir)
		offers._on_accept()
	if "--no_offers" in args:                                  # so o mapa (fundo das maquetes da janela de conversa)
		(main.find_child("OfferPanel", true, false) as Control).visible = false
		(main.find_child("Hud", true, false) as CanvasItem).visible = false
	if "--pause" in args:
		(main.find_child("PauseMenu", true, false) as PauseMenu).open()
	if "--hangar" in args:
		main._on_continue()
	if "--hangar_menu" in args:
		main._on_continue()
		(main.find_child("Hangar", true, false) as Hangar)._request_menu()
		if "--confirm" in args:
			(main.find_child("PauseMenu", true, false) as PauseMenu)._on_new_game()
