## Previa visual do hangar. gdtool.py capture res://tests/visual/hangar_preview.tscn [-- --top]
## Padrao: rolado ate o fim. --top: comeco. --late: meio de jogo (frota, recordes). --tab=1|2: aba PEDIDOS/AJUDAS.
## --missions: parte da arvore de missoes liberada e estrelas para gastar.
## --assists: ja tem parte da arvore. --menu: menu do jogo (Esc), como a Main abre.
## --keys: simula navegacao por teclado (foco no 1o botao de compra, depois de uma compra) e tooltip de custo.
extends Node

const HANGAR_SCENE := preload("res://game/hangar/hangar.tscn")


func _ready() -> void:
	print("PREVIEW_SAVE_ENABLED ", SaveManager.enabled)        # deve ser false: o SaveManager se desliga em tests/visual/
	SaveManager.enabled = false                                # e, por garantia, a previa nunca grava o save real
	WorldConfig.register_input()
	var args := OS.get_cmdline_user_args()
	GameState.resources["credits"] = 5000.0
	if "--late" in args:                                       # meio de jogo: frota e recordes
		GameState.resources = {"credits": 4.2e7}
		GameState.levels = {"thrust": 42, "tank": 38, "efficiency": 35, "contracts": 30, "gear": 12,
				"fleet": 5, "autopilot": 3}
		GameState.records = {"best_delivery": 9.1e4, "longest_hop": 1.2e4, "best_combo": 5.0, "best_run": 4.4e5}
	if "--missions" in args:                                   # arvore pela metade: liberadas, compraveis, bloqueadas
		GameState.mission_nodes = ["heavy1", "soft1", "heavy2", "fast1", "passenger1"]
		GameState.stars = 4
	if "--assists" in args:                                    # arvore pela metade: comprada, desligada, compravel, bloqueada
		GameState.levels.merge({"nav_color": 1, "nav_trail": 1, "land_shadow": 1})
		GameState.set_assist("land_shadow", false)
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
	if "--menu" in args:                                       # Esc no hangar: o hangar some e o menu abre
		var menu: PauseMenu = preload("res://game/pause/pause_menu.tscn").instantiate()
		layer.add_child(menu)
		h.menu_requested.connect(func() -> void:
			h.visible = false
			menu.open(PauseMenu.Mode.HANGAR))
		h._request_menu()
		if "--confirm" in args:
			menu._on_new_game()
	if "--top" in args:
		return
	var scroll: ScrollContainer = h.find_child("Scroll", true, false)
	scroll.scroll_vertical = 100000
