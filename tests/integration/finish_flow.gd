## Teste de integracao da linha de chegada (v30: a Lua completa pela distancia, EconMath.finish_m), numa pasta propria
## (user://itest_finish): o HUD mostra a chegada e quanto falta -> pousar antes dela nao completa -> pousar depois dela
## completa a Lua (libera o proximo mundo, "chegou!"). Imprime FINISH_TEST OK ou FALHOU. --hold: para perto da chegada.
extends Node

const MAIN := preload("res://game/main.tscn")

var _fails: Array[String] = []


func _ready() -> void:
	SaveManager.enabled = true
	SaveManager.set_dir("user://itest_finish")
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
	var finish := EconMath.finish_m("luna")
	_check(finish > 0.0, "a Lua tem linha de chegada (%.0f m)" % finish)
	_check(flight.find_child("FinishLine", false, false) != null, "a bandeira de chegada esta na pista")
	await _frames(2)
	var hud: Hud = main._hud
	_check(hud._goal_row.visible and hud._goal.text == GameState.record_text("run_distance", finish)
			and hud._goal_left.text.begins_with("faltam"), "HUD: chegada e quanto falta (%s / %s)" % [hud._goal.text,
			hud._goal_left.text])
	if "--hold" in OS.get_cmdline_user_args():                 # captura: a nave parada no ar perto da chegada
		var fx := WorldConfig.m_to_px(finish)
		for i in 90:
			flight.lander.state = Lander.State.FLYING
			flight.lander.global_position = Vector2(fx - 120.0, TerrainGen.height_at(flight.terrain.ridge, fx) - 120.0)
			flight.lander.vel_m = Vector2.ZERO
			await get_tree().physics_frame
	var info := {"gas_used": 10.0, "flight_time_m": 20.0, "vy": 1.0, "tilt": 0.0}
	var before := -1
	var after := -1
	for i in flight.terrain.pads.size():
		var m := flight.track_pad_m(i)
		if m < finish:
			before = i
		elif after < 0:
			after = i
	flight.lander.gas = float(flight.lander.params["tank"])
	flight._track_landed(flight.terrain.pads[before], 0.7, info)
	await _frames(3)
	_check(not GameState.world_done("luna"), "pousar antes da chegada nao completa a Lua")
	flight.lander.gas = float(flight.lander.params["tank"])
	flight._track_landed(flight.terrain.pads[after], 0.7, info)
	await _frames(3)
	_check(GameState.world_done("luna") and GameState.worlds().size() >= 2,
			"pousar depois da chegada completa a Lua e libera o proximo mundo (%s)" % [GameState.worlds()])
	_check(hud._goal_left.text == "chegou!", "HUD: chegou! (%s)" % hud._goal_left.text)
	print("FINISH_TEST ", "OK" if _fails.is_empty() else "FALHOU " + "; ".join(_fails))
	get_tree().quit()


func _wait_ready(main: Node) -> void:
	for i in 400:
		await get_tree().process_frame
		var f: Flight = main._flight
		if f != null and f.lander.can_takeoff and not f.lander.arriving and f.lander.state == Lander.State.LANDED:
			return


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails.append(msg)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
