## Previa do feixe dos discos na Lua fofa (war.peaceful): voo congelado com um disco parado em cima de um alvo.
## gdtool.py capture res://tests/visual/beam_preview.tscn --frames 90 --every 15 [-- --target=N]
extends Node

const FLIGHT := preload("res://game/flight/flight.tscn")


func _ready() -> void:
	WorldConfig.register_input()
	Telemetry.enabled = false
	var want := 0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--target="):
			want = int(a.trim_prefix("--target="))
	var flight := FLIGHT.instantiate() as Flight
	add_child(flight)
	flight.start("luna", 7, EconMath.ship_stats({"thrust": 40, "tank": 30}), false)
	var l := flight.lander
	l.set_physics_process(false)
	l.state = Lander.State.FLYING
	flight.set_physics_process(false)
	flight.set_camera_lift(0.0)
	var war: WarFx = flight.backdrop.find_children("*", "WarFx", true, false)[0]
	var target: Vector2 = war._targets[mini(want, war._targets.size() - 1)]
	# anda com a camera ate o alvo ficar no meio da tela (a camada mid rola com a camera)
	var base := l.global_position + Vector2(0, -260)
	for dx in range(0, 60000, 10):
		flight.camera.global_position = base + Vector2(dx, 0)
		flight.backdrop.follow(flight.camera.global_position)
		if absf(WarMath.screen_x(target.x, war.scroll_x, war._period) - 300.0) < 6.0:
			break
	l.global_position = flight.camera.global_position + Vector2(-150, 40)
	for i in war._saucers.size():
		var s: Dictionary = war._saucers[i]
		s["far"] = i > 0
		s["speed"] = 0.0 if i == 0 else s["speed"]
	var s0: Dictionary = war._saucers[0]
	s0["base_y"] = target.y - 70.0
	s0["pos"] = Vector2(target.x - 12.0, target.y - 70.0)
	s0["cool"] = 0.0
	print("BEAM_PREVIEW alvo ", target)
