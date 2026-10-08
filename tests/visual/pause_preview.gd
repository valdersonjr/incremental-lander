## Previa do menu do jogo (PauseMenu no modo HANGAR). gdtool.py capture res://tests/visual/pause_preview.tscn [-- --saves [--overwrite]]
## --saves: tela Salvar com os jogos de previa (pasta user://preview_saves, nunca o save real; jogo 1 em uso).
## --overwrite: com --saves, clica uma vez no jogo 3 (pede o 2o clique para gravar por cima).
## --tab=controls|game: abre nessa aba (padrao: SOM E IMAGEM).
extends Node

const PAUSE_SCENE := preload("res://game/pause/pause_menu.tscn")
const TitlePreview := preload("res://tests/visual/title_preview.gd")


func _ready() -> void:
	WorldConfig.register_input()
	var args := OS.get_cmdline_user_args()
	var layer := CanvasLayer.new()
	add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color("#6b3e75")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	if "--saves" in args:
		TitlePreview.fake_saves()
	var p: PauseMenu = PAUSE_SCENE.instantiate()
	layer.add_child(p)
	p.open(PauseMenu.Mode.HANGAR)
	for a: String in args:
		if a.begins_with("--tab="):
			p._set_tab({"controls": PauseMenu.Tab.CONTROLS, "game": PauseMenu.Tab.GAME}.get(a.get_slice("=", 1), PauseMenu.Tab.SOUND), false)
	if "--saves" in args:
		p._open_saves()
		if "--overwrite" in args:
			p._slots._on_save(3, true)
