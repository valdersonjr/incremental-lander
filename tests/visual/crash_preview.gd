## Previa visual da batida (explosao) e da poeira do pouso, sem depender do autopiloto errar.
## Uso: gdtool.py capture res://tests/visual/crash_preview.tscn --frames 84 --every 6 --cols 7 [-- --dust]
## --dust: pouso suave (mostra a poeira) em vez da batida.
extends Node

const FLIGHT_SCENE := preload("res://game/flight/flight.tscn")


func _ready() -> void:
	WorldConfig.register_input()
	var flight: Flight = FLIGHT_SCENE.instantiate()
	add_child(flight)
	flight.start("luna", 7, GameState.ship_stats(), false)
	flight.delivery_finished.connect(func(r: Dictionary) -> void: print("CRASH_PREVIEW ", r["reason"]))
	# solta a nave de 40 px acima da plataforma de partida, inclinada e caindo rapido -> batida
	var lander := flight.lander
	lander.state = Lander.State.FLYING
	if "--dust" in OS.get_cmdline_user_args():
		lander.global_position += Vector2(0, -2)
		lander.vel_m = Vector2(0, 0.5)
		return
	lander.global_position += Vector2(0, -40)
	lander.rotation = 0.6
	lander.vel_m = Vector2(4, 14)
