## Previa do Mapa das estrelas (v16). Uso: gdtool.py capture res://tests/visual/world_map_preview.tscn --frames 60
## [-- --all]: estado de exemplo com a Lua visitada (recorde), Nuvens aberto sem visita e o resto fechado (--all: todos
## abertos, Bolhas visitado). O SaveManager se desliga em tests/visual/ (nunca grava o save real).
extends Node


func _ready() -> void:
	GameState.reset()
	var all := "--all" in OS.get_cmdline_user_args()
	GameState.stars = 120 if all else 40
	GameState._check_road(true)
	GameState.records = {"luna": {"run_money": 12400.0}}
	if all:
		GameState.records["bolhas"] = {"run_money": 8300.0}
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UiKit.theme_for("luna")
	layer.add_child(root)
	var map := WorldMap.new()
	root.add_child(map)
	map.open()
