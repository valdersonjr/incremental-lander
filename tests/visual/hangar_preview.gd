## Previa visual do hangar. gdtool.py capture res://tests/visual/hangar_preview.tscn [-- --top --planet=ares]
## Padrao: rolado ate o fim. --top: comeco. --planet: mundo (cor da interface). --late: meio de jogo (prestigio,
## expedicao). --tab=1|2|3: aba MUNDOS/PRESTIGIO/OPCOES.
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
	if "--late" in args:                                       # meio de jogo: 3 mundos, prestigio, expedicao
		GameState.resources = {"credits": 4.2e9, "ore": 1850.0, "stardust": 12.0}
		GameState.unlocked_planets = ["luna", "ares", "kronos"]
		GameState.current_planet = "kronos"
		GameState.prestige_points = 30.0
		GameState.levels = {"thrust": 42, "tank": 38, "efficiency": 35, "contracts": 30, "gear": 12,
				"refinery": 8, "fleet": 5, "autopilot": 3, "exp1_station": 1, "exp2_cryo": 1}
		GameState.cycle_earned = {"credits": 5.0e9}
	GameState.set_volume("Music", 0.75)
	var layer := CanvasLayer.new()
	add_child(layer)
	var h: Hangar = HANGAR_SCENE.instantiate()
	layer.add_child(h)
	h.open()
	for a in args:
		if a.begins_with("--tab="):
			h._set_tab(int(a.get_slice("=", 1)) as Hangar.Tab)
	await get_tree().process_frame
	await get_tree().process_frame
	if "--top" in args:
		return
	var scroll: ScrollContainer = h.find_child("Scroll", true, false)
	scroll.scroll_vertical = 100000
