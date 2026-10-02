## Previa do menu inicial. gdtool.py capture res://tests/visual/title_preview.tscn [-- --progress --options --confirm --planet=id]
## --progress: com jogo salvo (Continuar + Novo jogo + resumo). --options: volumes. --confirm: novo jogo pedindo confirmacao.
extends Node

const FLIGHT_SCENE := preload("res://game/flight/flight.tscn")
const TITLE_SCENE := preload("res://game/title/title_screen.tscn")


func _ready() -> void:
	WorldConfig.register_input()
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--planet="):
			GameState.current_planet = a.get_slice("=", 1)
	if "--progress" in args:
		GameState.runs_done = 37
		GameState.resources["credits"] = 4.2e6
	var flight: Flight = FLIGHT_SCENE.instantiate()
	add_child(flight)
	flight.start(GameState.current_planet, 7, GameState.ship_stats(), false)
	var layer := CanvasLayer.new()
	add_child(layer)
	var t: TitleScreen = TITLE_SCENE.instantiate()
	layer.add_child(t)
	t.open()
	if "--confirm" in args:
		t._on_new_game()
	if "--options" in args:
		t._set_options(true)
