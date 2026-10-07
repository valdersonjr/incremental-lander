## Previa da interface do voo (HUD, ofertas, rodape, pausa) sobre o jogo real, sem o menu inicial.
## gdtool.py capture res://tests/visual/flight_ui_preview.tscn --frames 40 --every 39 -- --no_title [--pause]
## [--sandbox] [--missions] [--no_offers] [--select=slot] [--peek=kind] [--accept] [--hangar] [--hangar_menu [--confirm]: fim do run -> hangar -> Esc (menu do jogo)] [--delivered | --crashed] [--rep] [--records] [--world=<id>] [--dev_levels=thrust:20]. O SaveManager se desliga em tests/visual/ (nunca grava o save real).
extends Node

const MAIN := preload("res://game/main.tscn")


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if "--rep" in args:                                        # reputacao com o mineiro no nivel 2
		GameState.rep_points = {"simple": int(EconMath.reputation_levels()[1]["points"])}
	if "--sandbox" in args:                                    # sessao de sandbox (nave forte)
		Sandbox.begin("luna", true)
	if "--missions" in args:                                   # todos os ratinhos liberados (cartao com estrelas)
		GameState.mission_nodes.assign(["heavy1", "soft1", "fast1", "heavy2", "soft2", "passenger1", "fast2", "tow1",
				"soft3"])
	for a in args:                                             # --world=<id>: voa nesse mundo (v16; libera a parada)
		if a.begins_with("--world="):
			GameState.road_reached.append("world_" + a.get_slice("=", 1))
			GameState.select_world(a.get_slice("=", 1))
	var main := MAIN.instantiate()
	add_child(main)
	for i in 20:
		await get_tree().process_frame
	var hud := main.find_child("Hud", true, false) as Hud
	if "--records" in args:                                   # placar: recordes antigos + 5 entregas feitas neste run
		hud.set_records({"run_money": 900.0, "run_deliveries": 8.0, "run_distance": 9800.0, "run_perfect": 2.0,
				"best_delivery": 260.0})
		for i in 5:
			hud.run.complete_delivery(1400.0, 0.9, 10.0, [], 0.0, i % 2 == 0)
		(main.find_child("OfferPanel", true, false) as Control).visible = false
	if "--crashed" in args:
		hud._on_delivery_finished({"crashed": true, "reason": "vertical_rapido", "quality": 0.0, "gas_used": 54.9})
	if "--delivered" in args:                                  # aviso de entrega com plataforma e Reputacao
		hud.show_delivery({"rewards": {"credits": 721.0}, "quality": 0.86, "mult": 2.2, "rep": 1.2,
				"perfect": true, "rep_pts": 2})
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
