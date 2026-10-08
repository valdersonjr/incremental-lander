## Previa do Mapa das estrelas (v16). Uso: gdtool.py capture res://tests/visual/world_map_preview.tscn --frames 60
## [-- --all | --travel]: estado de exemplo com a Lua visitada (recorde), Nuvens aberto sem visita e o resto fechado (--all: todos
## abertos, Bolhas visitado). O SaveManager se desliga em tests/visual/ (nunca grava o save real).
extends Node


func _ready() -> void:
	GameState.reset()
	var all := "--all" in OS.get_cmdline_user_args()
	# --all: Lua, Nuvens e Cogumelos completos (Sorvete aberto, no meio da Estrada); senao Lua no comeco
	var done: Array = ["luna", "nuvens", "cogumelos"] if all else []
	for w: String in done:
		GameState.world_stars[w] = int(EconMath.road(w)[-1]["stars"])
	if all:
		GameState.world_stars["sorvete"] = 9
		GameState.current_planet = "sorvete"
	GameState.stars = 90 if all else 3
	GameState.world_stars["luna"] = maxi(int(GameState.world_stars.get("luna", 0)), 3)
	GameState._check_road(true)
	GameState.records = {"luna": {"run_money": 12400.0}, "nuvens": {"run_money": 8300.0}}
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UiKit.theme_for("luna")
	layer.add_child(root)
	var map := WorldMap.new()
	root.add_child(map)
	if "--travel" in OS.get_cmdline_user_args():                 # Lua acabou de ficar completa: viagem ate as Nuvens
		GameState.world_stars["luna"] = int(EconMath.road("luna")[-1]["stars"])
		GameState._check_road(true)
		GameState.select_world("nuvens")
		map.open("luna")
	else:
		map.open()
