## Menu inicial (tela de titulo): fica por cima da cena do mundo atual (nave parada na plataforma, fundo animado).
## Continuar / Novo jogo (2 cliques se ha progresso) / Opcoes (volumes) / Sair. So emite sinais; a Main decide o fluxo.
class_name TitleScreen
extends Control

## Jogar a partir do progresso salvo (ou comecar, se nao ha progresso).
signal play_requested
## Apagar o progresso e comecar do zero (ja confirmado).
signal new_game_requested
signal quit_requested

var _confirm_new_game := false
var _options_open := false

@onready var _info: HBoxContainer = %Info
@onready var _menu: VBoxContainer = %Menu
@onready var _options: VBoxContainer = %Options


func _ready() -> void:
	%Play.pressed.connect(func() -> void:
		Sound.ui("click")
		play_requested.emit())
	%NewGame.pressed.connect(_on_new_game)
	%OptionsButton.pressed.connect(func() -> void: _set_options(true))
	%Quit.pressed.connect(func() -> void:
		Sound.ui("click")
		quit_requested.emit())


## Mostra o menu atualizado (texto de Continuar/Jogar e resumo do progresso salvo).
func open() -> void:
	theme = UiKit.theme_for(GameState.current_planet)
	_confirm_new_game = false
	visible = true
	_set_options(false)


static func has_progress() -> bool:
	return GameState.runs_done > 0


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		if _options_open:
			_set_options(false)
		elif _confirm_new_game:
			_confirm_new_game = false
			_refresh_menu()


func _set_options(open_options: bool) -> void:
	var was_open := _options_open
	_options_open = open_options
	_confirm_new_game = false
	_menu.visible = not open_options
	_options.visible = open_options
	if open_options:
		Sound.ui("click")
		_fill_options()
		%Hint.text = "setas: escolher  ·  Enter: -/+  ·  Esc: voltar"
	else:
		_refresh_menu()
		(%OptionsButton if was_open else %Play).grab_focus()   # voltar das opcoes devolve o cursor a elas


func _refresh_menu() -> void:
	var progress := has_progress()
	%Play.text = "Continuar" if progress else "Jogar"
	%NewGame.visible = progress
	_info.visible = progress
	%NewGame.text = "Apagar tudo? Clique de novo" if _confirm_new_game else "Novo jogo"
	%NewGame.theme_type_variation = &"DangerButton" if _confirm_new_game else &""
	%Hint.text = "Esc: cancelar" if _confirm_new_game else "setas: escolher  ·  Enter: confirmar"
	for c in _info.get_children():
		_info.remove_child(c)
		c.queue_free()
	if progress:                                               # resumo do jogo salvo, com os icones do jogo
		_info.add_child(UiKit.icon_label("planet", _planet_name(GameState.current_planet), &"DimLabel"))
		_info.add_child(UiKit.icon_label("expedition", "%d runs" % GameState.runs_done, &"DimLabel"))
		_info.add_child(UiKit.icon_label("credits", EconMath.fmt(GameState.amount("credits")), &"MoneyLabel"))


func _on_new_game() -> void:
	if _confirm_new_game:
		_confirm_new_game = false
		Sound.ui("click")
		new_game_requested.emit()
		return
	Sound.ui("click")
	_confirm_new_game = true
	_refresh_menu()


## Volumes por bus (- e +), a mesma linha das opcoes do hangar (UiKit.volume_row).
func _fill_options() -> void:
	for c in _options.get_children():
		if c.name != &"OptionsTitle":
			_options.remove_child(c)
			c.queue_free()
	var first: Button = null
	for bus: String in GameState.BUSES:
		var row := UiKit.volume_row(bus)
		_options.add_child(row)
		if first == null:
			first = row.get_child(1) as Button
	var back := Button.new()
	back.text = "Voltar [Esc]"
	back.pressed.connect(func() -> void: _set_options(false))
	_options.add_child(back)
	first.grab_focus()


func _planet_name(id: String) -> String:
	for p: Dictionary in EconMath.spec["planets"]:
		if p["id"] == id:
			return str(p["name"]).get_slice(" (", 0)   # "Docelândia (planeta dos doces)" -> "Docelândia"
	return id
