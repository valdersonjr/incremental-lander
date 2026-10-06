## Previa do menu inicial. gdtool.py capture res://tests/visual/title_preview.tscn [-- --progress --options --confirm --planet=id]
## --progress: com jogo salvo (Continuar + resumo). --options: volumes. --sandbox: tela do sandbox. --saves: lista de jogos salvos (pasta propria
## user://preview_saves com jogos 1, 3 e 4; nunca le o save real). --confirm: com --saves, apagar pedindo confirmacao.
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
	if "--saves" in args:
		_fake_saves()
		t._set_screen(TitleScreen.Screen.SAVES)
		if "--confirm" in args:
			t._on_delete(3)
	if "--sandbox" in args:
		t._set_screen(TitleScreen.Screen.SANDBOX)
	if "--options" in args:
		t._set_screen(TitleScreen.Screen.OPTIONS)


## Jogos 1 (em uso), 3 e 4 numa pasta de previa, escritos direto (o SaveManager fica desligado nas previas).
func _fake_saves() -> void:
	SaveManager.set_dir("user://preview_saves")
	for n in range(1, SaveManager.SLOTS + 1):
		SaveManager._remove_slot_files(n)
	var st := GameState.save_state().duplicate(true)
	var nodes: Array = EconMath.mission_spec().get("nodes", []).map(func(d: Dictionary) -> String: return str(d["id"]))
	for n: int in [1, 3, 4]:
		if n == 3:
			st["runs_done"] = 112
			st["resources"]["credits"] = 3.7e9
			st["play_seconds"] = 4.0 * 3600.0 + 125.0
			st["mission_nodes"] = nodes.slice(0, nodes.size() * 2 / 3)
		if n == 4:
			st["runs_done"] = 9
			st["resources"]["credits"] = 5400.0
			st["play_seconds"] = 900.0
			st["mission_nodes"] = nodes.slice(0, 2)
		var f := FileAccess.open(SaveManager.slot_files(n)["path"], FileAccess.WRITE)
		f.store_string(JSON.stringify(SaveData.serialize(st)))
		f.close()
