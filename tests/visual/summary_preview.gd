## Previa visual do resumo do run. gdtool.py capture res://tests/visual/summary_preview.tscn [-- --crash] [-- --first]
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
	# --first = primeiro run (sem recordes); senao bate dinheiro, entregas, distancia e maior entrega (perfeitos nao)
	var start := {} if "--first" in OS.get_cmdline_user_args() else {"run_money": 12400.0, "run_deliveries": 8.0,
			"run_distance": 9800.0, "run_perfect": 3.0, "best_delivery": 2600.0}
	s.show_summary({"reason": reason, "deliveries": 10, "avg_quality": 0.84, "stars": 10,
			"earned": {"credits": 15300.0}, "fleet": {"credits": 3100.0},
			"rec_values": {"run_money": 15300.0, "run_deliveries": 10.0, "run_distance": 11200.0, "run_perfect": 2.0,
					"best_delivery": 3100.0}, "rec_start": start})
