## Previa visual do hangar. gdtool.py capture res://tests/visual/hangar_preview.tscn [-- --top --planet=ares]
## Padrao: rolado ate o fim (opcoes). --top: comeco (planetas/upgrades). --planet: mundo (cor da interface).
extends Node

const HANGAR_SCENE := preload("res://game/hangar/hangar.tscn")


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	GameState.resources["credits"] = 5000.0
	for a in args:
		if a.begins_with("--planet="):
			GameState.current_planet = a.get_slice("=", 1)
			if not GameState.current_planet in GameState.unlocked_planets:
				GameState.unlocked_planets.append(GameState.current_planet)
	GameState.set_volume("Music", 0.75)
	var layer := CanvasLayer.new()
	add_child(layer)
	var h: Hangar = HANGAR_SCENE.instantiate()
	layer.add_child(h)
	h.open()
	await get_tree().process_frame
	await get_tree().process_frame
	if "--top" in args:
		return
	var scroll: ScrollContainer = h.find_child("Scroll", true, false)
	scroll.scroll_vertical = 100000
