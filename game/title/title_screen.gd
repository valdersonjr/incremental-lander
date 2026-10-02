## Menu inicial (tela de titulo): fica por cima da cena do mundo atual (nave parada na plataforma, fundo animado).
## Continuar / Novo jogo (2 cliques se ha progresso) / Opcoes (volumes) / Sair. So emite sinais; a Main decide o fluxo.
class_name TitleScreen
extends Control

## Jogar a partir do progresso salvo (ou comecar, se nao ha progresso).
signal play_requested
## Apagar o progresso e comecar do zero (ja confirmado).
signal new_game_requested
signal quit_requested

const BUS_NAMES := {"Music": "Música", "Ambience": "Ambiente", "SFX": "Efeitos", "UI": "Interface"}

var _confirm_new_game := false
var _options_open := false

@onready var _info: Label = %Info
@onready var _menu: VBoxContainer = %Menu
@onready var _options: VBoxContainer = %Options


func _ready() -> void:
	%Play.pressed.connect(func() -> void:
		Sound.ui("click")
		play_requested.emit())
	%NewGame.pressed.connect(_on_new_game)
	%OptionsButton.pressed.connect(func() -> void: _set_options(true))
	%Quit.pressed.connect(func() -> void: quit_requested.emit())


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
	_options_open = open_options
	_menu.visible = not open_options
	_options.visible = open_options
	if open_options:
		Sound.ui("click")
		_fill_options()
	else:
		_refresh_menu()
		%Play.grab_focus()


func _refresh_menu() -> void:
	var progress := has_progress()
	%Play.text = "Continuar" if progress else "Jogar"
	%NewGame.visible = progress
	_info.visible = progress
	%NewGame.text = "CONFIRMA? (apaga tudo)" if _confirm_new_game else "Novo jogo"
	_info.text = "" if not progress else "%s  -  %d runs  -  %s cr" % [_planet_name(GameState.current_planet),
			GameState.runs_done, EconMath.fmt(GameState.amount("credits"))]


func _on_new_game() -> void:
	if _confirm_new_game:
		_confirm_new_game = false
		new_game_requested.emit()
		return
	Sound.ui("click")
	_confirm_new_game = true
	_refresh_menu()


## Volumes por bus (clique: -25%; de 0% volta a 100%), como nas opcoes do hangar.
func _fill_options() -> void:
	for c in _options.get_children():
		if c.name != &"OptionsTitle":
			c.queue_free()
	var first: Button = null
	for bus: String in GameState.BUSES:
		var b := Button.new()
		b.text = "%s: %d%%" % [BUS_NAMES[bus], int(round(GameState.volume(bus) * 100.0))]
		b.pressed.connect(func() -> void:
			var v := GameState.volume(bus) - 0.25
			GameState.set_volume(bus, 1.0 if v < -0.01 else v)
			SaveManager.request_save()
			Sound.ui("click")
			b.text = "%s: %d%%" % [BUS_NAMES[bus], int(round(GameState.volume(bus) * 100.0))])
		_options.add_child(b)
		if first == null:
			first = b
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
