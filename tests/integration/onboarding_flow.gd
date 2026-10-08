## Teste de integracao dos PRIMEIROS MINUTOS (auditoria FTUE, 2026-10-08; world.json > onboarding), numa pasta propria
## (user://itest_onboarding). Jogo novo comeca voando no 1o salto ja aceito (perto, relevo baixo, sem minijogo) ->
## aprendiz bate e tenta o mesmo salto de novo (run continua, gas do comeco do salto) -> pouso devagar fora da
## plataforma para no chao -> falhou o limite de tentativas: volta ao cartao de missoes -> fim do run com dinheiro vai para a NAVE (so PECAS, sem x10/MAX) -> Mapa mostra moedas e
## "!" na NAVE -> veterano que bate acaba o run. Imprime ONBOARDING_TEST OK ou FALHOU.
extends Node

const MAIN := preload("res://game/main.tscn")

var _fails: Array[String] = []


func _ready() -> void:
	Engine.time_scale = 4.0                                    # explosoes/telas escuras/descidas 4x (cabe nos 600 quadros
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
	_check(main._run != null and not map.visible and not main._offers.visible, "jogo novo deveria comecar voando")
	_check(main._first_hop, "1o salto deveria estar marcado")
	await _wait_ready(main)
	var flight: Flight = main._flight
	var first_m := float(WorldConfig.load_config()["onboarding"]["first_hop"]["distance_m"])
	_check(flight.gentle and is_equal_approx(flight.target_distance_m, first_m), "1o salto: perto e relevo baixo")
	_check(flight.minigame_total == 0, "1o salto sem minijogo (veio %d)" % flight.minigame_total)
	_check(flight.lander.ground_rest, "aprendiz: pouso fora da plataforma nao bate")
	# aprendiz bate: o mesmo salto recomeca com o gas do comeco dele
	var gas0 := flight.lander.gas
	flight.lander.state = Lander.State.FLYING
	flight.lander.gas = gas0 * 0.5
	flight.lander.crash_now("vertical_rapido")
	await _until(func() -> bool: return main._retries == 1 and flight.lander.visible)   # explosao + tela escura
	_check(not main._run.over, "aprendiz: batida nao deveria acabar o run")
	_check(main._flight == flight and flight.lander.visible, "aprendiz: a nave volta")
	_check(is_equal_approx(flight.lander.gas, gas0), "aprendiz: gas do comeco do salto (%.1f / %.1f)" % [
			flight.lander.gas, gas0])
	_check(flight.gentle and is_equal_approx(flight.target_distance_m, first_m), "aprendiz: o MESMO salto")
	# pouso devagar fora da plataforma: para no chao (sem batida)
	await _wait_ready(main)
	var l := flight.lander
	var pad: Dictionary = flight.terrain.pads[0]
	var x := float(pad["x"]) - float(pad["half_width"]) - 80.0
	l.state = Lander.State.FLYING
	l.rotation = 0.0
	l.vel_m = Vector2(0.0, 1.0)
	l.global_position = Vector2(x, TerrainGen.height_at(flight.terrain.ridge, x) - 12.0)
	var crashed := [false]
	l.crashed.connect(func(_r: String, _i: Dictionary) -> void: crashed[0] = true)
	await _until(func() -> bool: return crashed[0] or l.state != Lander.State.FLYING)
	_check(not crashed[0] and l.state == Lander.State.LANDED, "pouso devagar fora: parou no chao (estado %s)" % [
			Lander.State.keys()[l.state]])
	# bug do loop (2026-10-08): o aprendiz que falha o mesmo salto de novo e de novo volta ao cartao de missoes
	var tries := int(WorldConfig.load_config()["onboarding"]["retries_per_hop"])
	for k in tries:                                            # 1a batida ja foi; mais `tries` = passou do limite
		await _wait_ready(main)
		flight.lander.state = Lander.State.FLYING
		var before: int = main._retries
		flight.lander.crash_now("fora_da_plataforma")
		await _until(func() -> bool: return main._offers.visible or (main._retries > before and flight.lander.visible))
	_check(not main._run.over and main._offers.visible, "depois das tentativas: cartao de missoes (nao repete mais)")
	_check(is_equal_approx(flight.lander.gas, gas0) and flight.lander.visible
			and flight.lander.state == Lander.State.LANDED, "de volta na partida com o gas do comeco do salto")
	_check(flight.target_pad_id < 0, "sem alvo enquanto escolhe")
	main._on_offer_chosen(0)                                   # escolheu outra: voa normalmente
	await _wait_ready(main)
	_check(main._retries == 0 and not main._run.over, "missao nova zera as tentativas")
	# fim do run com dinheiro para uma peca: CONTINUAR vai para a NAVE (1a visita: so PECAS, x1)
	GameState.resources["credits"] = 100.0
	main._run.finish("sem_gas")
	main._end_run()
	await _frames(2)
	main._on_continue()
	await _frames(3)
	var hangar: Hangar = main._hangar
	_check(hangar.visible, "fim do run com dinheiro deveria abrir a NAVE")
	_check(not hangar._tabs.visible and not hangar._bulk_box.visible, "1a visita a NAVE: so PECAS, sem x10/MAX")
	main._open_map()
	await _frames(2)
	_check(map._coins_label.text == "100" and map._ship.text.ends_with("!"), "Mapa: moedas e '!' na NAVE (%s / %s)" % [
			map._coins_label.text, map._ship.text])
	# veterano: batida acaba o run
	GameState.stars = int(WorldConfig.load_config()["onboarding"]["apprentice_stars"])
	main._on_launch_requested()
	await _frames(3)
	_check(main._offers.visible, "veterano: escolhe o pedido no cartao")
	main._on_offer_chosen(0)
	await _wait_ready(main)
	main._flight.lander.state = Lander.State.FLYING
	main._flight.lander.crash_now("vertical_rapido")
	await _until(func() -> bool: return main._run.over)
	_check(main._run.over, "veterano: batida acaba o run")
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
