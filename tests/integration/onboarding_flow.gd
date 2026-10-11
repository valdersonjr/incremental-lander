## Teste de integracao dos PRIMEIROS MINUTOS na pista "Mais longe" (v21; world.json > onboarding), numa pasta propria
## (user://itest_onboarding). Jogo novo abre o Mapa (passeio ate o VOAR) -> VOAR = viagem direto na pista (sem cartao,
## nome do mundo no alto) -> aprendiz bate e volta para a ultima plataforma com o gas do comeco do salto -> pouso a
## frente paga (pulo paga mais; para tras nao paga) -> fim do run com dinheiro vai para a NAVE (passeio ate o Compre!)
## -> botao MAPA volta ao Mapa (moedas e "!") -> aprendiz sem compra volta ao Mapa -> veterano que bate acaba a viagem.
## Imprime ONBOARDING_TEST OK ou FALHOU.
extends Node

const MAIN := preload("res://game/main.tscn")

var _fails: Array[String] = []


func _ready() -> void:
	Engine.time_scale = 8.0                                    # explosoes/fantasma/telas escuras/descidas 8x (cabe nos 600 quadros
	SaveManager.enabled = true                                 # do gdtool test; a fisica roda os mesmos passos)
	SaveManager.set_dir("user://itest_onboarding")
	for n in range(1, SaveManager.SLOTS + 1):
		SaveManager.delete_slot(n)
	var main := MAIN.instantiate()
	add_child(main)
	await _frames(3)
	var title := main.find_child("TitleScreen", true, false) as TitleScreen
	title.new_game_requested.emit(1)
	await _frames(3)
	var map := main.find_child("WorldMap", true, false) as WorldMap
	_check(map.visible and main._run == null, "jogo novo deveria abrir o Mapa (mapa=%s)" % map.visible)
	# 1a vez no Mapa: passeio (mundos, Estrada, moedas/estrelas, NAVE) que termina no VOAR
	_check(main._spotlight.visible and main._spotlight._target == map._worlds_area and not main._spotlight._act,
			"jogo novo: passeio do Mapa comeca nos mundos")
	var seen: Array = []
	for i in 6:
		if main._spotlight._act:
			break
		seen.append(main._spotlight._target)
		main._spotlight._next_step()                           # clique avanca (o alvo nao e apertado)
		await _frames(1)
	_check(seen.has(map._road) and seen.has(map._counts_area) and seen.has(map._ship),
			"passeio do Mapa mostra Estrada, moedas/estrelas e NAVE (%d passos)" % seen.size())
	_check(main._spotlight.visible and main._spotlight._target == map._fly and main._spotlight._act,
			"passeio do Mapa termina no VOAR")
	_check(map.visible and main._run == null, "passeio nao aperta nada sozinho")
	map._fly.pressed.emit()
	await _frames(3)
	var flight: Flight = main._flight
	_check(main._run != null and not map.visible and not main._offers.visible and flight.track,
			"VOAR: a viagem na pista comeca direto, sem cartao")
	_check(not main._spotlight.visible, "VOAR: o destaque fecha")
	await _frames(2)
	_check(main._hud._world_label != null and main._hud._world_label.text == "LUA", "chegada: nome do mundo no alto")
	_check(flight.lander.can_takeoff and flight.target_pad_id == 1, "pista: pode decolar, alvo = proxima plataforma")
	_check(flight.lander.ground_rest, "aprendiz: pouso fora da plataforma nao bate")
	# aprendiz bate: volta para a ultima plataforma paga com o gas do comeco do salto
	var gas0 := flight.lander.gas
	flight.lander.state = Lander.State.FLYING
	flight.lander.gas = gas0 * 0.5
	flight.lander.crash_now("vertical_rapido")
	var back := func() -> bool:
		return flight.lander.visible and main._fade.modulate.a < 0.05 and flight.lander.state == Lander.State.LANDED
	await _until(back)
	_check(not main._run.over, "aprendiz: batida nao acaba a viagem")
	_check(is_equal_approx(flight.lander.gas, gas0), "aprendiz: gas do comeco do salto (%.1f / %.1f)" % [
			flight.lander.gas, gas0])
	_check(absf(flight.lander.global_position.x - float(flight.terrain.pads[0]["x"])) < 2.0,
			"aprendiz: de volta na ultima plataforma")
	# bug 2026-10-11 (2): gas do comeco do salto nao alcanca a proxima plataforma -> bater acaba a viagem (sem repetir)
	# gas que o piloto ideal alcancaria, mas um jogador nao: tambem nao repete (2a correcao)
	var d_m := WorldConfig.px_to_m(float(flight.terrain.pads[1]["x"]) - flight.track_last_px())
	main._hop_gas = EconMath.estimated_hop_dv("luna", d_m, flight.stats) / float(flight.lander.params["efficiency"]) * 1.1
	var r0: int = main._retries
	flight.lander.state = Lander.State.FLYING
	flight.lander.crash_now("vertical_rapido")
	await _until(func() -> bool: return main._run.over)
	_check(main._run.over and main._retries == r0, "sem gas para a proxima: nao oferece tente de novo")
	main._summary.visible = false
	main._on_launch_requested()
	await _frames(3)
	flight = main._flight
	# 2026-10-11: pousou com pouco gas -> a viagem NAO acaba sozinha (a estimativa "o gas nao da" errava);
	# o jogador termina no botao TERMINAR VIAGEM (2 toques)
	flight.lander.gas = 0.3
	var info0 := {"gas_used": 10.0, "flight_time_m": 20.0, "vy": 1.0, "tilt": 0.0}
	flight._track_landed(flight.terrain.pads[1], 0.7, info0)
	await _frames(3)
	_check(not main._run.over, "pouco gas no pouso: a viagem continua")
	_check(main._hud.can_end() and main._hud._end_button.visible, "nave parada: botao TERMINAR VIAGEM aparece")
	main._hud.request_end()
	await _frames(2)
	_check(not main._run.over and main._hud._end_button.text.begins_with("TERMINAR?"), "1o toque so pede confirmacao")
	main._hud.request_end()
	await _until(func() -> bool: return main._run.over and main._summary.visible)
	_check(main._run.over and main._run.end_reason == "encerrado", "2o toque: fim da viagem (%s)" % main._run.end_reason)
	main._summary.visible = false
	main._on_launch_requested()
	await _frames(3)
	flight = main._flight
	# tanque vazio de verdade: a viagem acaba sozinha
	flight.lander.gas = 0.0
	flight._track_landed(flight.terrain.pads[0], 0.7, info0)    # a mesma plataforma: nao paga (nao mexe na Estrada)
	await _until(func() -> bool: return main._run.over and main._summary.visible)
	_check(main._run.over and main._run.end_reason == "sem_gas", "pousou com tanque vazio: fim da viagem (%s)" % main._run.end_reason)
	_check(not flight.lander.can_takeoff, "viagem encerrada: a nave nao decola mais")
	main._summary.visible = false
	main._on_launch_requested()
	await _frames(3)
	flight = main._flight
	GameState.stars = 0
	# bug 2026-10-11 ("sem gasolina e o jogo fica me dando tente de novo"): passou das tentativas = fim da viagem
	var tries := int(WorldConfig.load_config()["onboarding"]["retries_per_hop"])
	var saved_retries: int = main._retries
	main._retries = tries
	var over := [false]
	flight.lander.state = Lander.State.FLYING
	flight.lander.crash_now("vertical_rapido")
	await _until(func() -> bool: return main._run.over)
	_check(main._run.over, "aprendiz: depois de %d tentativas a viagem acaba (nao repete para sempre)" % tries)
	main._summary.visible = false
	main._on_launch_requested()                                   # viagem nova para seguir o teste
	await _frames(3)
	flight = main._flight
	main._retries = saved_retries * 0
	# pouso numa plataforma a frente: paga pela distancia do comeco e da as estrelas da nota
	var info := {"gas_used": 10.0, "flight_time_m": 20.0, "vy": 1.0, "tilt": 0.0}
	flight._track_landed(flight.terrain.pads[1], 0.7, info)
	await _frames(2)
	_check(main._run.deliveries.size() == 1 and float(main._run.earned.get("credits", 0.0)) > 0.0,
			"pouso na proxima plataforma paga")
	_check(GameState.stars == 2 and flight.target_pad_id == 2, "pouso bom = 2 estrelas; alvo anda (estrelas %d, alvo %d)" % [
			GameState.stars, flight.target_pad_id])
	var pay1 := float(main._run.earned["credits"])
	flight._track_landed(flight.terrain.pads[3], 0.7, info)      # pulou a 2: paga mais (mais longe + pulo)
	await _frames(2)
	_check(float(main._run.deliveries[-1]["rewards"]["credits"]) > pay1 and int(main._run.deliveries[-1]["skipped"]) == 1,
			"pular uma plataforma paga mais")
	# moeda no ar / marco: so paga no proximo POUSO (bug 2026-10-11: "so por andar pra frente ja ganho gold")
	var before := GameState.amount("credits")
	main._on_track_pickup("marker", 50.0, Vector2.ZERO)
	await _frames(1)
	_check(is_equal_approx(GameState.amount("credits"), before) and is_equal_approx(main._pending, 50.0),
			"marco passado: fica a receber, nao paga voando")
	flight._track_landed(flight.terrain.pads[4], 0.7, info)
	await _frames(2)
	_check(is_equal_approx(main._pending, 0.0) and float(main._run.deliveries[-1].get("bonus", 0.0)) == 50.0,
			"pousou: o que estava a receber entra")
	main._on_track_pickup("coin", 30.0, Vector2.ZERO)
	var after_land := GameState.amount("credits")
	flight._track_landed(flight.terrain.pads[1], 0.9, info)      # voltar para tras nao paga
	await _frames(1)
	_check(main._run.deliveries.size() == 3 and is_equal_approx(GameState.amount("credits"), after_land),
			"plataforma para tras nao paga (nem o que estava a receber)")
	# fim do run com dinheiro para uma peca: CONTINUAR vai para a NAVE (1a visita: so PECAS, x1)
	main._run.finish("sem_gas")
	main._end_run()
	await _frames(2)
	GameState.resources["credits"] = 100.0                     # depois do fim do run (o bonus de recorde ja pagou)
	main._on_continue()
	await _frames(4)
	var hangar: Hangar = main._hangar
	_check(hangar.visible, "fim do run com dinheiro deveria abrir a NAVE")
	_check(main._spotlight.visible and main._spotlight._target == hangar.tour_target("card:thrust"),
			"1a NAVE: passeio comeca no cartao da peca")
	_check(not hangar._tabs.visible and not hangar._bulk_box.visible, "1a visita a NAVE: so PECAS, sem x10/MAX")
	for i in 5:
		if main._spotlight._act:
			break
		main._spotlight._next_step()
		await _frames(1)
	_check(main._spotlight.visible and main._spotlight._target == hangar.first_affordable_buy(),
			"passeio da NAVE termina no 'Compre!' da peca que da para comprar")
	hangar.first_affordable_buy().pressed.emit()               # comprou: nada de "Mapa!" (nao ha o que fazer la)
	await _frames(4)
	_check(not main._spotlight.visible, "NAVE: depois da compra, nenhum destaque mandando ao Mapa")
	GameState.resources["credits"] = 100.0
	hangar.map_button().pressed.emit()
	await _frames(4)
	_check(map.visible and not hangar.visible, "botao MAPA volta ao Mapa")
	_check(not main._spotlight.visible, "Mapa de novo: o destaque do VOAR nao volta")
	_check(map._coins_label.text == "100" and map._ship.text.ends_with("!"), "Mapa: moedas e '!' na NAVE (%s / %s)" % [
			map._coins_label.text, map._ship.text])
	# aprendiz sem dinheiro: o fim do run volta ao Mapa (nao voa de novo direto)
	main._on_launch_requested()
	await _frames(3)
	GameState.resources["credits"] = 0.0
	main._run.finish("sem_gas")
	main._end_run()
	await _frames(2)
	GameState.resources["credits"] = 0.0
	main._on_continue()
	await _frames(3)
	_check(map.visible and not main._hangar.visible and not main._run_active,
			"aprendiz sem compra: fim do run volta ao Mapa (mapa=%s)" % map.visible)
	# veterano: batida acaba a viagem
	GameState.stars = int(WorldConfig.load_config()["onboarding"]["apprentice_stars"])
	main._on_launch_requested()
	await _frames(3)
	_check(main._flight.track and not main._offers.visible, "veterano: viagem direto na pista")
	main._flight.lander.state = Lander.State.FLYING
	main._flight.lander.crash_now("vertical_rapido")
	await _until(func() -> bool: return main._run.over)
	_check(main._run.over, "veterano: batida acaba a viagem")
	Engine.time_scale = 1.0
	print("ONBOARDING_TEST ", "OK" if _fails.is_empty() else "FALHOU " + "; ".join(_fails))
	get_tree().quit()


## Espera a nave pousar na partida pronta para decolar (fim da tela escura e da descida do ceu).
func _wait_ready(main: Node) -> void:
	for i in 300:
		await get_tree().process_frame
		var f: Flight = main._flight
		if f != null and f.lander.can_takeoff and not f.lander.arriving and f.target_pad_id >= 0 \
				and f.lander.state == Lander.State.LANDED:
			return


## Espera ate cond() ficar verdadeira (no maximo limit quadros).
func _until(cond: Callable, limit: int = 240) -> void:
	for i in limit:
		await get_tree().process_frame
		if cond.call():
			return


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails.append(msg)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
