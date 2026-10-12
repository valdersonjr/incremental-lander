## Teste de integracao dos satelites do ceu (world.json > sky_obstacles), numa pasta propria (user://itest_sky):
## viagem na Lua -> perto do chao nao ha satelite -> la no alto ha varios -> encostar num satelite explode a nave
## (motivo "obstaculo"). Imprime SKY_TEST OK ou FALHOU.
## Com --hold (gdtool capture) fica parado no alto alguns segundos para a captura.
extends Node

const MAIN := preload("res://game/main.tscn")

var _fails: Array[String] = []


func _ready() -> void:
	SaveManager.enabled = true
	SaveManager.set_dir("user://itest_sky")
	for n in range(1, SaveManager.SLOTS + 1):
		SaveManager.delete_slot(n)
	var main := MAIN.instantiate()
	add_child(main)
	await _frames(3)
	(main.find_child("TitleScreen", true, false) as TitleScreen).new_game_requested.emit(1)
	await _frames(3)
	main._on_launch_requested()
	await _wait_ready(main)
	var flight: Flight = main._flight
	var sky: SkyObstacles = flight._sky
	_check(sky != null, "a Lua tem satelites")
	if sky == null:
		_end()
		return
	var cfg: Dictionary = WorldConfig.load_config()["sky_obstacles"]
	await _frames(2)
	var low := 0                                               # nenhum abaixo de free_m (os do topo da tela podem existir)
	for c: Dictionary in sky._cells.values():
		if not c.is_empty():
			var p: Vector2 = c["pos"]
			var ref := TerrainGen.highest_between(flight.terrain.ridge, p.x - WorldConfig.m_to_px(float(cfg["ref_span_m"])),
					p.x + WorldConfig.m_to_px(float(cfg["ref_span_m"])))
			low += 1 if WorldConfig.px_to_m(ref - p.y) < float(cfg["free_m"]) - float(cfg["cell_m"]) else 0
	_check(low == 0, "perto do chao nao tem satelite (%d)" % low)
	# la no alto: muitos
	var l := flight.lander
	var x := float(flight.terrain.pads[3]["x"])
	var top := TerrainGen.highest_between(flight.terrain.ridge, x - 400.0, x + 400.0)
	l.state = Lander.State.FLYING
	l.gas = float(l.params["tank"])
	l.global_position = Vector2(x, top - WorldConfig.m_to_px(float(cfg["full_m"]) + 100.0))
	l.vel_m = Vector2.ZERO
	await _frames(3)
	_check(sky.count() >= 8, "la no alto aparecem varios satelites (%d)" % sky.count())
	if "--hold" in OS.get_cmdline_user_args():
		for i in 120:
			l.global_position = Vector2(x, top - WorldConfig.m_to_px(float(cfg["full_m"]) + 100.0))
			l.vel_m = Vector2.ZERO
			await get_tree().physics_frame
	# encostar num satelite: explode na hora
	var reason := [""]
	l.crashed.connect(func(r: String, _i: Dictionary) -> void: reason[0] = r)
	var target := _nearest(sky, l.global_position)
	l.vel_m = Vector2(5.0, 0.0)
	l.global_position = (target["pos"] as Vector2) + Vector2(-4.0, 0.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(reason[0] == "obstaculo", "bater num satelite explode a nave (%s)" % reason[0])
	_end()


func _end() -> void:
	print("SKY_TEST ", "OK" if _fails.is_empty() else "FALHOU " + "; ".join(_fails))
	get_tree().quit()


func _nearest(sky: SkyObstacles, p: Vector2) -> Dictionary:
	var best: Dictionary = {}
	for c: Dictionary in sky._cells.values():
		if not c.is_empty() and (best.is_empty() or (c["pos"] as Vector2).distance_to(p) < (best["pos"] as Vector2).distance_to(p)):
			best = c
	return best


func _wait_ready(main: Node) -> void:
	for i in 400:
		await get_tree().process_frame
		var f: Flight = main._flight
		if f != null and f.lander.can_takeoff and not f.lander.arriving and f.lander.state == Lander.State.LANDED:
			return


func _until(cond: Callable, limit: int = 300) -> void:
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
