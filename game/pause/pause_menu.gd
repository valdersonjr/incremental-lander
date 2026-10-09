## Menu do jogo (arte: UiKit), janela modal sobre o mundo escurecido. Dois modos:
## FLIGHT (Esc no voo): "PAUSA", congela a arvore (SceneTree.paused), volumes + controles + Menu inicial (o run acaba;
## as entregas feitas ja foram pagas) + CONTINUAR.
## HANGAR (Esc/Opções no hangar; a Main esconde o hangar): "MENU", volumes + controles + Menu inicial + Novo jogo
## (2 cliques, Esc cancela) + VOLTAR AO HANGAR. Nos dois modos, Salvar abre a lista dos jogos salvos (SaveSlots SAVE)
## para gravar o jogo num dos espacos (por cima de outro com 2 cliques). No sandbox: "Sair do modo livre" no lugar do menu inicial e sem Novo jogo. So apresentacao/navegacao: emite sinais, a Main decide o fluxo.
## Roda com PROCESS_MODE_ALWAYS.
class_name PauseMenu
extends Control

signal closed
## Voltar ao menu inicial (a Main salva e mostra o titulo; no voo, o run em andamento acaba).
signal title_requested
## Modo HANGAR: apagar o jogo em uso e comecar do zero (confirmado com 2 cliques).
signal new_game_requested

enum Mode { FLIGHT, HANGAR }

## Acoes remapeaveis (world.json > remappable) com o texto do menu; as fixas vem em CONTROLS_FIXED.
const KEY_TITLES := {
	"thrust": "motor (subir)",
	"rotate_left": "girar à esquerda",
	"rotate_right": "girar à direita",
	"restart": "recomeçar a viagem (2 vezes)",
	"end_run": "terminar a viagem (2 vezes)",
	"stabilize": "estabilizador",
	"turbo": "turbo",
}
const CONTROLS_FIXED := [
	["números 1 a 9 ou clique", "escolher entrega"],
	["controle de videogame", "também funciona"],
]
## Abas do menu (uma secao por vez: menos coisa na tela de uma vez so).
enum Tab { SOUND, CONTROLS, GAME }
const TAB_NAMES := {Tab.SOUND: "SOM E IMAGEM", Tab.CONTROLS: "CONTROLES", Tab.GAME: "JOGO"}

var mode := Mode.FLIGHT
var _confirm_new_game := false
## Lista dos espacos para Salvar (aberta no lugar das colunas).
var _slots: SaveSlots = null
var _tab := Tab.SOUND
var _tab_buttons: Dictionary = {}           # Tab -> Button


func _ready() -> void:
	visible = false
	%Continue.pressed.connect(close)
	%MenuButton.pressed.connect(func() -> void:
		Sound.ui("click")
		visible = false
		get_tree().paused = false
		title_requested.emit())
	%NewGame.pressed.connect(_on_new_game)
	%SaveButton.pressed.connect(_open_saves)
	%SavesBack.pressed.connect(_close_saves)
	_slots = SaveSlots.new()
	_slots.mode = SaveSlots.Mode.SAVE
	_slots.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_slots.slot_saved.connect(func(n: int) -> void:
		%SavesTitle.text = "Salvo no Jogo %d!" % n
		%SavesTitle.theme_type_variation = &"GoodLabel"
		_show_new_game())
	%SavesView.add_child(_slots)
	%SavesView.move_child(_slots, 1)
	_build_tabs()
	%RestoreKeys.pressed.connect(func() -> void:
		Sound.ui("click")
		GameState.reset_keys()
		SaveManager.request_save()
		_fill_keys())
	for c: Array in CONTROLS_FIXED:
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 4)
		var key := Label.new()
		key.text = c[0]
		key.theme_type_variation = &"ValueLabel"
		key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(key)
		var what := Label.new()
		what.text = c[1]
		what.theme_type_variation = &"DimLabel"
		what.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(what)
		%Controls.add_child(row)


## Abre o menu. FLIGHT pausa o jogo; HANGAR nao pausa (nada corre no hangar) e mostra as acoes do jogo salvo.
func open(p_mode: Mode = Mode.FLIGHT) -> void:
	mode = p_mode
	_confirm_new_game = false
	theme = UiKit.theme_for(GameState.current_planet)
	for c in %Volumes.get_children():
		%Volumes.remove_child(c)
		c.queue_free()
	for bus: String in GameState.BUSES:
		%Volumes.add_child(UiKit.volume_row(bus))
	%Volumes.add_child(UiKit.crt_row())
	%Volumes.add_child(UiKit.shake_row())
	%Volumes.add_child(UiKit.fullscreen_row())
	_fill_keys()
	var hangar := mode == Mode.HANGAR
	%Title.text = "MENU" if hangar else "PAUSA"
	%Continue.text = "VOLTAR AO MAPA" if hangar else "CONTINUAR"
	var sandbox := Sandbox.active()                            # no sandbox: sair dele; nunca apagar o jogo salvo
	if sandbox:
		%MenuLabel.text = "Voltar ao menu inicial (seu jogo salvo volta intacto)"
	else:
		%MenuLabel.text = "Voltar ao menu inicial (salva)" if hangar else "Ao menu inicial (entregas feitas ficam)"
	%MenuButton.text = "Sair do modo livre" if sandbox else "Menu inicial"
	%NewGameRow.visible = hangar and not sandbox                # apagar o jogo so com calma, no hangar
	%SaveRow.visible = not sandbox                              # o sandbox nunca grava
	%SaveLabel.text = "Gravar o jogo (agora no Jogo %d)" % SaveManager.slot
	_close_saves(false)
	_show_new_game()
	_set_tab(Tab.SOUND, false)
	visible = true
	if not hangar:
		get_tree().paused = true
	Sound.ui("click")
	%Continue.grab_focus()
	UiKit.pulse(%Panel, 1.3, 0.25)


## Linhas das teclas remapeaveis (refeitas ao abrir e ao restaurar o padrao), antes das linhas fixas.
func _fill_keys() -> void:
	for c in %Keys.get_children():
		%Keys.remove_child(c)
		c.queue_free()
	for action: String in WorldConfig.remappable():
		%Keys.add_child(UiKit.key_row(action, KEY_TITLES.get(action, action)))


func close() -> void:
	if not visible:
		return
	Sound.ui("click")
	visible = false
	get_tree().paused = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		if %SavesView.visible:                                 # na lista de espacos: desiste de gravar por cima / volta
			if not _slots.cancel_confirm():
				_close_saves()
		elif _confirm_new_game:                                # Esc primeiro desiste da confirmacao
			_confirm_new_game = false
			Sound.ui("click")
			_show_new_game()
		else:
			close()
	elif event.is_action_pressed(&"confirm") and not %SavesView.visible:
		get_viewport().set_input_as_handled()
		close()


## Troca as colunas pela lista dos espacos (o jogo em uso com o foco).
func _open_saves() -> void:
	Sound.ui("click")
	%SavesTitle.text = "SALVAR EM QUAL ESPAÇO?"
	%SavesTitle.theme_type_variation = &"SectionLabel"
	%Columns.visible = false
	%Continue.visible = false
	(_tab_buttons[Tab.SOUND] as Button).get_parent().visible = false
	%SavesView.visible = true
	_slots.fill()


func _close_saves(sound: bool = true) -> void:
	if sound:
		Sound.ui("click")
	%SavesView.visible = false
	%Columns.visible = true
	%Continue.visible = true
	if _tab_buttons.size() > 0:
		(_tab_buttons[Tab.SOUND] as Button).get_parent().visible = true
	%SaveLabel.text = "Gravar o jogo (agora no Jogo %d)" % SaveManager.slot
	if sound:
		%SaveButton.grab_focus()


func _on_new_game() -> void:
	Sound.ui("click")
	if not _confirm_new_game:
		_confirm_new_game = true
		_show_new_game()
		return
	_confirm_new_game = false
	visible = false
	new_game_requested.emit()


func _show_new_game() -> void:
	%NewGameLabel.text = "Recomeçar o Jogo %d do zero" % SaveManager.slot
	%NewGame.text = "Apagar? Clique de novo" if _confirm_new_game else "Novo jogo"


## Barra de abas sob o titulo (SOM E IMAGEM / CONTROLES / JOGO); os titulos de secao viram as abas.
func _build_tabs() -> void:
	var bar := HBoxContainer.new()
	bar.name = "Tabs"
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override(&"separation", 4)
	for t: Tab in TAB_NAMES:
		var b := Button.new()
		b.text = TAB_NAMES[t]
		b.custom_minimum_size = Vector2(96, 0)
		b.pressed.connect(func() -> void: _set_tab(t))
		bar.add_child(b)
		_tab_buttons[t] = b
	%Title.get_parent().add_child(bar)
	%Title.get_parent().move_child(bar, %Title.get_index() + 1)
	for n: String in ["VolumeTitle", "ControlsTitle", "GameTitle"]:
		(%Columns.find_child(n) as Control).visible = false


## Mostra so a secao da aba (a outra coluna some; a janela encolhe).
func _set_tab(t: Tab, sound: bool = true) -> void:
	if sound:
		Sound.ui("click")
	_tab = t
	for k: Tab in _tab_buttons:
		(_tab_buttons[k] as Button).theme_type_variation = &"PrimaryButton" if k == t else &""
	var left := %Columns.get_node("Left") as Control
	left.visible = t != Tab.CONTROLS
	%Volumes.visible = t == Tab.SOUND
	%Game.visible = t == Tab.GAME
	(%Columns.get_node("Right") as Control).visible = t == Tab.CONTROLS
	if sound:
		(_tab_buttons[t] as Button).grab_focus()
