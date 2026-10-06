## Previa visual do presente no alto do morro (v10): a nave chega devagar e pega.
## Uso: gdtool.py capture res://tests/visual/gift_preview.tscn --frames 120 --every 12 [-- --kind=gas|gift]
extends Node

const FLIGHT_SCENE := preload("res://game/flight/flight.tscn")

var _flight: Flight


func _ready() -> void:
	WorldConfig.register_input()
	var kind := "gift"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--kind="):
			kind = a.get_slice("=", 1)
	_flight = FLIGHT_SCENE.instantiate()
	var flight := _flight
	add_child(flight)
	flight.start("luna", 7, GameState.ship_stats(), false)
	flight.set_target(900.0, "normal")
	flight._spawn_gift(kind)
	var lander := flight.lander
	lander.state = Lander.State.FLYING
	lander.gas = 30.0
	lander.global_position = flight._gift_pos + Vector2(-70, -60)
	lander.vel_m = Vector2(2.0, 1.0)
	lander.set_physics_process(false)                          # levada a mao ate o presente (devagar)


func _physics_process(_d: float) -> void:
	var l := _flight.lander
	var goal := _flight._gift_pos + Vector2(0, -14)
	l.global_position = l.global_position.move_toward(goal, 0.8)
