## Previa visual do resumo do run. gdtool.py capture res://tests/visual/summary_preview.tscn [-- --crash]
extends Node

const SUMMARY_SCENE := preload("res://game/run/run_summary.tscn")


func _ready() -> void:
	var planet := "luna"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = a.get_slice("=", 1)
	var layer := CanvasLayer.new()
	add_child(layer)
	var s: RunSummary = SUMMARY_SCENE.instantiate()
	s.theme = UiKit.theme_for(planet)
	layer.add_child(s)
	var reason := "batida:vertical_rapido" if "--crash" in OS.get_cmdline_user_args() else "sem_gas"
	s.show_summary({"reason": reason, "deliveries": 6, "avg_quality": 0.84,
			"earned": {"credits": 12450.0}, "fleet": {"credits": 3100.0}})
