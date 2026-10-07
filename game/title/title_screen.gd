## Menu inicial (tela de titulo) com cena PROPRIA (TitleBackdrop: gatinho heroi no morro de queijo, nada do mapa de
## voo). Logo + frase da proposta + coluna de botoes a esquerda; as subtelas abrem no painel do meio.
## Jogar -> cartoes dos jogos salvos (SaveManager.SLOTS espacos com a progressao; jogar, novo jogo, apagar com 2 cliques) /
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

const SLOT_CARD_W := 104

const HINTS := {
	Screen.MENU: "setas: escolher  ·  Enter: confirmar",
	Screen.SAVES: "setas: escolher  ·  Enter: confirmar  ·  Esc: voltar",
	Screen.OPTIONS: "setas: escolher  ·  Enter: -/+  ·  Esc: voltar",
	Screen.SANDBOX: "setas: escolher  ·  Enter: confirmar  ·  Esc: voltar",
}

var _screen := Screen.MENU
## Confirmacao pendente na lista de jogos ("" ou "del:N").
var _confirm := ""
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
		if _confirm != "":                                     # Esc primeiro desiste da confirmacao
			_confirm = ""
			Sound.ui("click")
			_fill_saves()
		elif _screen != Screen.MENU:
			_set_screen(Screen.MENU)


func _set_screen(s: Screen) -> void:
	var back_from := _screen
	_screen = s
	_confirm = ""
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

## Um cartao por espaco (SaveManager.SLOTS, lado a lado): o cartao inteiro e o botao (com jogo: Jogar; vazio:
## Novo jogo; ilegivel: desabilitado) e mostra a progressao (missoes liberadas na arvore, creditos, runs, tempo).
## Embaixo de cada um, Apagar com 2 cliques.
func _fill_saves() -> void:
	var focus_key := _focused_key()
	for c in _saves.get_children():
		if c.name != &"SavesTitle":
			_saves.remove_child(c)
			c.queue_free()
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override(&"separation", 6)
	_saves.add_child(cards)
	var first: Button = null
	for n in range(1, SaveManager.SLOTS + 1):
		var s := SaveManager.slot_summary(n)
		var col := VBoxContainer.new()
		col.add_theme_constant_override(&"separation", 3)
		cards.add_child(col)
		var card := _slot_card(n, s)
		col.add_child(card)
		var del := Button.new()
		del.custom_minimum_size = Vector2(0, 15)
		del.theme_type_variation = &"DangerButton"
		del.set_meta(&"focus_key", "del:%d" % n)
		del.disabled = not s["exists"]
		del.text = "Sim, apagar" if _confirm == "del:%d" % n else "Apagar"
		del.tooltip_text = "apaga este jogo para sempre (Esc cancela)"
		del.pressed.connect(func() -> void: _on_delete(n))
		col.add_child(del)
		if first == null or (s["current"] and not card.disabled):
			first = card if not card.disabled else del
	var back := Button.new()
	back.text = "Voltar"
	back.set_meta(&"focus_key", "back")
	back.pressed.connect(func() -> void: _set_screen(Screen.MENU))
	_saves.add_child(back)
	var target: Button = _find_focus(focus_key)
	var btn: Button = target if target != null else first
	(func() -> void:                                           # adiado; a lista pode ser refeita antes
		if is_instance_valid(btn) and btn.is_inside_tree():
			btn.grab_focus()).call_deferred()


## Cartao-botao de um espaco: nome no topo; com jogo, a barra de missoes liberadas (estrela + N/total), creditos,
## runs e tempo; vazio, um "+" e "Novo jogo".
func _slot_card(n: int, s: Dictionary) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(SLOT_CARD_W, 104)
	card.set_meta(&"focus_key", "slot:%d" % n)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
	box.add_theme_constant_override(&"separation", 3)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	var current: bool = s["current"] and s["ok"]
	var title := _card_label("Jogo %d" % n, &"GoodLabel" if current else &"ValueLabel")
	box.add_child(title)
	if s["ok"]:
		if current:                                            # jogo em uso: moldura dourada (como a escolha atual)
			card.tooltip_text = "jogo em uso"
			var frame := Panel.new()
			frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
			frame.add_theme_stylebox_override(&"panel", UiKit.gold_frame())
			card.add_child(frame)
		card.pressed.connect(func() -> void:
			Sound.ui("click")
			slot_play_requested.emit(n))
		var total: int = maxi((EconMath.mission_spec().get("nodes", []) as Array).size(), 1)
		var done := mini(int(s["nodes"]), total)
		var star_row := HBoxContainer.new()
		star_row.alignment = BoxContainer.ALIGNMENT_CENTER
		star_row.add_theme_constant_override(&"separation", 2)
		star_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var star := TextureRect.new()
		star.texture = UiKit.kid("star_on")
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.custom_minimum_size = Vector2(14, 14)
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		star_row.add_child(star)
		star_row.add_child(_card_label("%d/%d" % [done, total], &"MoneyLabel"))
		box.add_child(star_row)
		var bar := ProgressBar.new()                           # progressao: missoes liberadas na arvore
		bar.show_percentage = false
		bar.theme_type_variation = &"XpBar"
		bar.custom_minimum_size = Vector2(SLOT_CARD_W - 20, 6)
		bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		bar.max_value = total
		bar.value = done
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(bar)
		for line: HBoxContainer in [UiKit.icon_label("credits", EconMath.fmt(float(s["credits"])), &"MoneyLabel"),
				UiKit.icon_label("expedition", "%d runs" % int(s["runs"]), &"DimLabel")]:
			line.alignment = BoxContainer.ALIGNMENT_CENTER
			for c: Control in line.get_children():
				c.mouse_filter = Control.MOUSE_FILTER_IGNORE
			line.mouse_filter = Control.MOUSE_FILTER_IGNORE
			box.add_child(line)
		box.add_child(_card_label(_fmt_time(float(s["play_seconds"])), &"DimLabel"))
	elif s["exists"]:                                          # arquivo ilegivel: so da para apagar
		card.disabled = true
		box.add_child(_card_label("save ilegível", &"BadLabel"))
	else:
		card.pressed.connect(func() -> void:
			Sound.ui("click")
			new_game_requested.emit(n))
		var plus := _card_label("+", &"DimLabel")
		plus.add_theme_font_size_override(&"font_size", UiKit.TITLE_SIZE)
		box.add_child(plus)
		box.add_child(_card_label("Novo jogo", &"DimLabel"))
	return card


func _card_label(text: String, variation: StringName) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = variation
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _on_delete(n: int) -> void:
	Sound.ui("click")
	var key := "del:%d" % n
	if _confirm != key:
		_confirm = key
		_fill_saves()
		return
	_confirm = ""
	var was_current := n == SaveManager.slot
	SaveManager.delete_slot(n)
	if was_current:
		theme = UiKit.theme_for(GameState.current_planet)
		current_slot_changed.emit()
	_fill_saves()


func _focused_key() -> String:
	var f := get_viewport().gui_get_focus_owner()
	if f != null and _saves.is_ancestor_of(f) and f.has_meta(&"focus_key"):
		return str(f.get_meta(&"focus_key"))
	return ""


func _find_focus(key: String) -> Button:
	if key == "":
		return null
	for b: Node in _saves.find_children("*", "Button", true, false):
		if b.get_meta(&"focus_key", "") == key and not b.is_queued_for_deletion() and not (b as Button).disabled:
			return b
	return null


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

func _fmt_time(s: float) -> String:
	var t := int(s)
	return "%dh%02dm" % [t / 3600, (t % 3600) / 60] if t >= 3600 else "%dm%02ds" % [t / 60, t % 60]


func _planet_name(id: String) -> String:
	for p: Dictionary in EconMath.spec["planets"]:
		if p["id"] == id:
			return str(p["name"]).get_slice(" (", 0)   # "Docelândia (planeta dos doces)" -> "Docelândia"
	return id
