## Menu inicial (tela de titulo) com cena PROPRIA (TitleBackdrop: gatinho heroi no morro de queijo, nada do mapa de
## voo). Logo + frase da proposta + coluna de botoes a esquerda; as subtelas abrem no painel do meio.
## Jogar -> lista dos jogos salvos (SaveSlots: jogar ou novo jogo; X ao lado apaga com 2 cliques) /
## Sandbox (testar tudo sem progressao: mundo + nave, nada e salvo) / Opcoes (volumes, CRT) / Sair. Emite sinais; a Main
## decide o fluxo (carregar, decolar, hangar).
class_name TitleScreen
extends Control

## Continuar o jogo em uso sem passar pelos cartoes (usado pelos testes de fluxo).
signal play_requested
## Jogar o jogo salvo do espaco slot (a Main carrega e segue como Continuar).
signal slot_play_requested(slot: int)
## Comecar do zero no espaco slot (vazio).
signal new_game_requested(slot: int)
## O jogo em uso mudou sem sair do menu (foi apagado): a Main refaz a cena de fundo.
signal current_slot_changed
signal quit_requested
## Comecar o sandbox no mundo planet_id; strong = nave forte (a Main chama Sandbox.begin e abre o hangar).
signal sandbox_requested(planet_id: String, strong: bool)

enum Screen { MENU, SAVES, OPTIONS, SANDBOX }

const HINTS := {
	Screen.MENU: "setas: escolher  ·  Enter: confirmar",
	Screen.SAVES: "setas: escolher  ·  Enter: confirmar  ·  Esc: voltar",
	Screen.OPTIONS: "setas: escolher  ·  Enter: -/+  ·  Esc: voltar",
	Screen.SANDBOX: "setas: escolher  ·  Enter: confirmar  ·  Esc: voltar",
}

var _screen := Screen.MENU
## Lista dos jogos salvos (criada ao abrir a tela pela 1a vez).
var _slots: SaveSlots = null
## Escolhas da tela do sandbox.
var _sb_planet := "luna"
var _sb_strong := true

@onready var _menu: VBoxContainer = %Menu
@onready var _saves: VBoxContainer = %Saves
@onready var _options: VBoxContainer = %Options
@onready var _sandbox: VBoxContainer = %Sandbox


func _ready() -> void:
	%Play.pressed.connect(func() -> void: _set_screen(Screen.SAVES))
	%OptionsButton.pressed.connect(func() -> void: _set_screen(Screen.OPTIONS))
	%SandboxButton.pressed.connect(func() -> void: _set_screen(Screen.SANDBOX))
	%Quit.pressed.connect(func() -> void:
		Sound.ui("click")
		quit_requested.emit())


## Mostra o menu atualizado (texto de Continuar/Jogar e resumo do jogo em uso).
func open() -> void:
	theme = UiKit.theme_for(GameState.current_planet)
	visible = true
	_screen = Screen.MENU
	_set_screen(Screen.MENU)


static func has_progress() -> bool:
	return GameState.runs_done > 0


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		if _screen == Screen.SAVES and _slots.cancel_confirm():   # Esc primeiro desiste de apagar
			return
		if _screen != Screen.MENU:
			_set_screen(Screen.MENU)


func _set_screen(s: Screen) -> void:
	var back_from := _screen
	_screen = s
	_menu.visible = s == Screen.MENU
	%Panel.visible = s != Screen.MENU                          # no menu, so a coluna da esquerda sobre a cena
	_saves.visible = s == Screen.SAVES
	_options.visible = s == Screen.OPTIONS
	_sandbox.visible = s == Screen.SANDBOX
	%Hint.text = HINTS[s]
	match s:
		Screen.MENU:
			_refresh_menu()
			# voltar de uma subtela devolve o cursor ao botao dela
			var focus: Button = {Screen.SAVES: %Play, Screen.OPTIONS: %OptionsButton,
					Screen.SANDBOX: %SandboxButton}.get(back_from, %Play)
			focus.grab_focus()
		Screen.SAVES:
			Sound.ui("click")
			_fill_saves()
		Screen.OPTIONS:
			Sound.ui("click")
			_fill_options()
		Screen.SANDBOX:
			Sound.ui("click")
			_fill_sandbox()


func _refresh_menu() -> void:
	%Warning.text = SaveManager.load_warning                   # save ilegivel: o jogador fica sabendo (e que foi guardado)
	%Warning.visible = SaveManager.load_warning != ""


# --- jogos salvos ------------------------------------------------------------------------------------------------

## Lista compacta de SaveSlots (com jogo: Jogar; vazio: Novo jogo) + Voltar.
func _fill_saves() -> void:
	if _slots == null:
		_slots = SaveSlots.new()
		_slots.slot_play_requested.connect(func(n: int) -> void: slot_play_requested.emit(n))
		_slots.new_game_requested.connect(func(n: int) -> void: new_game_requested.emit(n))
		_saves.add_child(_slots)
		var back := Button.new()
		back.text = "Voltar"
		back.pressed.connect(func() -> void: _set_screen(Screen.MENU))
		_saves.add_child(back)
	_slots.fill()


# --- opcoes ------------------------------------------------------------------------------------------------------

## Volumes por bus (- e +) e filtro CRT, as mesmas linhas do menu do jogo (UiKit.volume_row / crt_row).
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
	_options.add_child(UiKit.crt_row())
	_options.add_child(UiKit.shake_row())
	_options.add_child(UiKit.fullscreen_row())
	var back := Button.new()
	back.text = "Voltar"
	back.pressed.connect(func() -> void: _set_screen(Screen.MENU))
	_options.add_child(back)
	first.grab_focus()


# --- sandbox -----------------------------------------------------------------------------------------------------

## Escolha do mundo (os 4) e da nave; o selecionado e o botao cheio. COMECAR emite sandbox_requested.
func _fill_sandbox(focus_key: String = "sb:start") -> void:
	for c in _sandbox.get_children():
		if c.name != &"SandboxTitle":
			_sandbox.remove_child(c)
			c.queue_free()
	var about := Label.new()
	about.text = "Teste tudo sem a progressão: mundos liberados e recursos de sobra\n(repostos a cada volta ao hangar). Nada é salvo."
	about.theme_type_variation = &"DimLabel"
	about.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sandbox.add_child(about)
	var worlds := []
	for p: Dictionary in EconMath.spec["planets"]:
		worlds.append([str(p["id"]), _planet_name(str(p["id"]))])
	if worlds.size() > 1:                                       # so a Lua por enquanto: sem escolha de mundo
		_sandbox.add_child(_choice_row("Mundo", worlds, _sb_planet, func(v: String) -> void: _sb_planet = v))
	_sandbox.add_child(_choice_row("Nave", [["base", "Básica"], ["strong", "Forte"]], "strong" if _sb_strong else "base",
			func(v: String) -> void: _sb_strong = v == "strong"))
	var start := Button.new()
	start.text = "COMEÇAR SANDBOX"
	start.theme_type_variation = &"PrimaryButton"
	start.set_meta(&"focus_key", "sb:start")
	start.pressed.connect(func() -> void:
		Sound.ui("click")
		sandbox_requested.emit(_sb_planet, _sb_strong))
	_sandbox.add_child(start)
	var back := Button.new()
	back.text = "Voltar"
	back.set_meta(&"focus_key", "sb:back")
	back.pressed.connect(func() -> void: _set_screen(Screen.MENU))
	_sandbox.add_child(back)
	for b: Node in _sandbox.find_children("*", "Button", true, false):
		if b.get_meta(&"focus_key", "") == focus_key:
			(b as Button).grab_focus.call_deferred()


## Linha de escolha unica: rotulo | botoes (o atual em destaque cheio). Escolher refaz a tela mantendo o foco.
func _choice_row(title: String, options: Array, current: String, pick: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 4)
	var l := Label.new()
	l.text = title
	l.custom_minimum_size = Vector2(44, 0)
	row.add_child(l)
	for o: Array in options:
		var b := Button.new()
		b.text = str(o[1])
		b.custom_minimum_size = Vector2(66, 15)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.theme_type_variation = &"PrimaryButton" if o[0] == current else &""
		var key := "sb:%s:%s" % [title, o[0]]
		b.set_meta(&"focus_key", key)
		b.pressed.connect(func() -> void:
			Sound.ui("click")
			pick.call(str(o[0]))
			_fill_sandbox(key))
		row.add_child(b)
	return row


# --- utilitarios -------------------------------------------------------------------------------------------------

func _planet_name(id: String) -> String:
	for p: Dictionary in EconMath.spec["planets"]:
		if p["id"] == id:
			return str(p["name"]).get_slice(" (", 0)   # "Docelândia (planeta dos doces)" -> "Docelândia"
	return id
