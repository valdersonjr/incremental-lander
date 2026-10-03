## Previa visual da tela de final (verificacao com gdtool capture, sem jogar ate o fim). --records: com recordes.
extends Node

const ENDING_SCENE := preload("res://game/ending/ending.tscn")


func _ready() -> void:
	GameState.runs_done = 42
	GameState.prestige_points = 285.0
	if "--records" in OS.get_cmdline_user_args():
		GameState.records = {"best_delivery": 3.4e12, "longest_hop": 38250.0, "best_combo": 5.0, "best_run": 1.9e13}
	var layer := CanvasLayer.new()
	add_child(layer)
	var e: Ending = ENDING_SCENE.instantiate()
	e.theme = UiKit.theme_for("titan")
	layer.add_child(e)
	e.show_ending(5.0 * 3600.0 + 17.0 * 60.0)
