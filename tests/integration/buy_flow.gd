## Teste de integracao da COMPRA na NAVE depois de uma viagem na pista (bug 2026-10-11: o jogo fechava ao aprimorar a
## nave). Viagem -> fim -> NAVE -> compra a peca (x1, x10, MAX) -> decola de novo. Imprime BUY_FLOW_TEST OK ou FALHOU.
extends Node

const MAIN := preload("res://game/main.tscn")

var _fails: Array[String] = []


func _ready() -> void:
	SaveManager.set_dir("user://itest_buy")
	for n in range(1, SaveManager.SLOTS + 1):
		SaveManager.delete_slot(n)
	SaveManager.new_game(1)
	GameState.stars = 12                                       # veterano (sem aprendiz), passeios vistos
	GameState.tips.append_array(["tour_map", "tour_ship", "tour_assists", "tour_rep", "spot_ship", "spot_map"])
	var main := MAIN.instantiate()
	add_child(main)
	await _frames(3)
	(main.find_child("TitleScreen", true, false) as Control).visible = false
	main._on_launch_requested()
	await _frames(10)
	_check(main._flight != null and main._flight.track, "viagem na pista")
	main._run.finish("sem_gas")
	main._end_run()
	await _frames(2)
	GameState.resources["credits"] = 5000.0
	main._on_continue()
	await _frames(4)
	var hangar: Hangar = main._hangar
	_check(hangar.visible, "fim da viagem com dinheiro abre a NAVE")
	for i in 3:
		var b: Control = hangar.first_affordable_buy()
		_check(b != null, "tem peca para comprar (%d)" % i)
		if b == null:
			break
		(b as BaseButton).pressed.emit()
		await _frames(3)
	var lv := 0
	for id: String in ["thrust", "tank", "efficiency", "gear"]:
		lv += int(GameState.levels.get(id, 0))
	_check(lv >= 3, "compras subiram os niveis (%d)" % lv)
	for id: String in ["thrust", "tank", "efficiency", "gear"]:   # destaque de cada peca no desenho (bug do _draw)
		hangar._ship_view.highlight(id)
		await _frames(2)
	GameState.resources["credits"] = 1e9                      # degrau novo (a peca cresce): x10 e MAX
	for id: String in ["thrust", "tank", "efficiency", "gear"]:
		hangar._buy_part(id, 12)
		await _frames(3)
	main._open_map()                                           # NAVE aberta pelo Mapa (sem voo montado atras)
	await _frames(3)
	main._open_hangar()
	await _frames(3)
	for id: String in ["thrust", "tank"]:
		hangar._buy_part(id, 30)
		await _frames(3)
	main._on_launch_requested()
	await _frames(10)
	_check(main._flight != null and main._flight.track and not main._run.over, "decola de novo depois das compras")
	print("BUY_FLOW_TEST ", "OK" if _fails.is_empty() else "FALHOU " + "; ".join(_fails))
	get_tree().quit()


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails.append(msg)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
