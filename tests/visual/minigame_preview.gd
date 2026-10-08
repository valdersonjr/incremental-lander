## Previa dos minijogos (v17): a nave ja comeca perto do alvo de um mundo e cai/desliza sozinha (sem teclado).
## Uso: gdtool.py capture res://tests/visual/minigame_preview.tscn --frames 240 --every 40 -- --world=sorvete [--star=2]
extends Node

const FLIGHT_SCENE := preload("res://game/flight/flight.tscn")
const MISSION := {"luna": "simple", "nuvens": "passenger", "cogumelos": "soft", "sorvete": "fast", "jardim": "heavy",
		"bolhas": "tow"}


func _ready() -> void:
	WorldConfig.register_input()
	var world := "sorvete"
	var star := 2
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--world="):
			world = a.get_slice("=", 1)
		if a.begins_with("--star="):
			star = int(a.get_slice("=", 1))
	var f: Flight = FLIGHT_SCENE.instantiate()
	add_child(f)
	f.start(world, 7, EconMath.ship_stats({"thrust": 30, "tank": 20, "efficiency": 10}), false)
	var k: String = MISSION.get(world, "simple")
	f.begin_mission(11, 500.0, "normal", 1, {"kind": k, "star": star, "parts": [{"kind": k, "star": star}]})
	await get_tree().create_timer(1.3).timeout                 # depois da chegada
	var pad: Dictionary = f.terrain.pads[f.target_pad_id]
	f.lander.global_position = Vector2(float(pad["x"]) - float(pad["half_width"]) * 0.8, float(pad["y"]) - 12.0)
	f.lander.vel_m = Vector2(9.0, 1.0)
	f.lander.rotation = 0.0
	f.lander.state = Lander.State.FLYING
	f.camera.global_position = f.lander.global_position
	f.lander.crashed.connect(func(r: String, _i: Dictionary) -> void: print("PREVIEW crash ", r, " ice=", f.lander.ice_pad_id, " target=", f.target_pad_id))
	f.delivery_finished.connect(func(r: Dictionary) -> void: print("PREVIEW entrega q=", r["quality"]))
