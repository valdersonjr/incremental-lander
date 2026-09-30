## Previa visual do hangar (rolado ate o fim: opcoes). gdtool.py capture res://tests/visual/hangar_preview.tscn
extends Node

const HANGAR_SCENE := preload("res://game/hangar/hangar.tscn")


func _ready() -> void:
	GameState.resources["credits"] = 5000.0
	GameState.set_volume("Music", 0.75)
	var layer := CanvasLayer.new()
	add_child(layer)
	var h: Hangar = HANGAR_SCENE.instantiate()
	layer.add_child(h)
	h.open()
	await get_tree().process_frame
	await get_tree().process_frame
	var scroll: ScrollContainer = h.find_child("Scroll", true, false)
	scroll.scroll_vertical = 100000
