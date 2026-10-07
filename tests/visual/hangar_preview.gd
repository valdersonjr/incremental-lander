## Previa visual da PROGRESSAO (v13). gdtool.py capture res://tests/visual/hangar_preview.tscn [-- opcoes]
## --stars=N: total de estrelas (anda na estrada, sem festa). --late: meio de jogo (pecas em degraus, recordes,
## moedas). --tab=1|2: AJUDAS/FROTA. --news=N: o jogador volta de um voo com N estrelas a mais (navezinha anda,
## parada nova festeja). --sel=id: balao da parada. --bulk=10|0: seletor ×10/MAX. --hl=peca: peca brilhando.
## --keys: navegacao por teclado (foco no 1o botao de compra, compra e mantem o foco). --menu: menu do jogo (Esc).
extends Node

const HANGAR_SCENE := preload("res://game/hangar/hangar.tscn")


func _ready() -> void:
	print("PREVIEW_SAVE_ENABLED ", SaveManager.enabled)        # deve ser false: o SaveManager se desliga em tests/
	SaveManager.enabled = false
	WorldConfig.register_input()
	var args := OS.get_cmdline_user_args()
	var opt := {}
	for a in args:
		if a.begins_with("--") and "=" in a:
			opt[a.get_slice("=", 0).trim_prefix("--")] = a.get_slice("=", 1)
	GameState.resources["credits"] = 5000.0
	if "--late" in args:
		GameState.resources = {"credits": 4.2e5}
		GameState.levels.merge({"thrust": 34, "tank": 21, "efficiency": 12, "gear": 9}, true)
		GameState.records = {"best_delivery": 9.1e4, "longest_hop": 1.2e4, "best_perfect": 4.0, "best_run": 4.4e5}
		GameState.rep_points = {"simple": 31, "heavy": 16, "soft": 6, "fast": 2}
	var stars := int(opt.get("stars", "40" if "--late" in args else "0"))
	var news := int(opt.get("news", "0"))
	GameState.stars = maxi(0, stars - news)
	GameState._check_road(true)
	GameState.set_volume("Music", 0.75)
	var layer := CanvasLayer.new()
	add_child(layer)
	var h: Hangar = HANGAR_SCENE.instantiate()
	layer.add_child(h)
	if opt.has("bulk"):
		h._bulk = int(opt["bulk"])
	h.open()                                                  # 1a abertura: guarda as estrelas vistas
	if news > 0:                                              # volta do voo com estrelas novas
		h.visible = false
		GameState.add_stars(news)
		h.open()
	if opt.has("tab"):
		h._set_tab(int(opt["tab"]) as Hangar.Tab)
	await get_tree().process_frame
	await get_tree().process_frame
	if opt.has("sel"):
		h._toggle_balloon(str(opt["sel"]))
	if opt.has("hl") and h._ship_view != null:
		h._ship_view.highlight(str(opt["hl"]))
	if "--keys" in args:                                       # foco no 1o botao de compra + Enter (compra e mantem)
		h._keyboard_nav = true
		var buy: Button = null
		for b: Node in h.find_children("*", "Button", true, false):
			if str(b.get_meta(&"focus_key", "")).begins_with("buy:") and not (b as Button).disabled:
				buy = b
				break
		if buy != null:
			buy.grab_focus()
			await get_tree().process_frame
			buy.pressed.emit()
			await get_tree().process_frame
			await get_tree().process_frame
		var f := get_viewport().gui_get_focus_owner()
		print("KEYS_FOCUS ", f.get_meta(&"focus_key", "?") if f != null else "nenhum")
	if "--menu" in args:                                       # Esc: a tela some e o menu do jogo abre
		var menu: PauseMenu = preload("res://game/pause/pause_menu.tscn").instantiate()
		layer.add_child(menu)
		h.menu_requested.connect(func() -> void:
			h.visible = false
			menu.open(PauseMenu.Mode.HANGAR))
		h.menu_requested.emit()
