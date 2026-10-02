## Previa visual do hangar. gdtool.py capture res://tests/visual/hangar_preview.tscn [-- --top --planet=ares]
## Padrao: rolado ate o fim. --top: comeco. --planet: mundo (cor da interface). --late: meio de jogo (prestigio,
## expedicao). --tab=1|2|3: aba MUNDOS/PRESTIGIO/OPCOES. --pending: recomeco em andamento (so loja + concluir).
## --keys: simula navegacao por teclado (foco no 1o botao de compra, depois de uma compra) e tooltip de custo.
extends Node

const HANGAR_SCENE := preload("res://game/hangar/hangar.tscn")


func _ready() -> void:
	print("PREVIEW_SAVE_ENABLED ", SaveManager.enabled)        # deve ser false: o SaveManager se desliga em tests/visual/
	SaveManager.enabled = false                                # e, por garantia, a previa nunca grava o save real
	WorldConfig.register_input()
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
	if "--pending" in args:
		GameState.prestige_pending = true
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
	if "--keys" in args:                                       # setas ate a 1a compra + Enter (compra e mantem o foco)
		h._keyboard_nav = true
		var buy: Button = null
		for b: Node in h.find_children("*", "Button", true, false):
			if str(b.get_meta(&"focus_key", "")).begins_with("buy:") and not (b as Button).disabled:
				buy = b
				break
		buy.grab_focus()
		await get_tree().process_frame
		buy.pressed.emit()
		await get_tree().process_frame
		await get_tree().process_frame
		var f := get_viewport().gui_get_focus_owner()
		print("KEYS_FOCUS ", f.get_meta(&"focus_key", "?") if f != null else "nenhum")
	if "--top" in args:
		return
	var scroll: ScrollContainer = h.find_child("Scroll", true, false)
	scroll.scroll_vertical = 100000
