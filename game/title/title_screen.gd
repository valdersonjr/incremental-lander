## Menu inicial (tela de titulo): fica por cima da cena do mundo atual (nave parada na plataforma, fundo animado).
## Continuar (jogo em uso) / Jogos salvos (SaveManager.SLOTS espacos: jogar, novo jogo, apagar com 2 cliques) /
## Sandbox (testar tudo sem progressao: mundo + nave, nada e salvo) / Opcoes (volumes, CRT) / Sair. Emite sinais; a Main
## decide o fluxo (carregar, decolar, hangar).
class_name TitleScreen
extends Control

## Jogar a partir do jogo em uso (ou comecar, se ele nao tem progresso).
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
## Confirmacao pendente na lista de jogos ("" ou "del:N").
var _confirm := ""
## Escolhas da tela do sandbox.
var _sb_planet := "luna"
var _sb_strong := true

@onready var _info: HBoxContainer = %Info
@onready var _menu: VBoxContainer = %Menu
@onready var _saves: VBoxContainer = %Saves
@onready var _options: VBoxContainer = %Options
@onready var _sandbox: VBoxContainer = %Sandbox


func _ready() -> void:
	%Play.pressed.connect(func() -> void:
		Sound.ui("click")
		play_requested.emit())
	%SavesButton.pressed.connect(func() -> void: _set_screen(Screen.SAVES))
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
	_saves.visible = s == Screen.SAVES
	_options.visible = s == Screen.OPTIONS
	_sandbox.visible = s == Screen.SANDBOX
	%Hint.text = HINTS[s]
	match s:
		Screen.MENU:
			_refresh_menu()
			# voltar de uma subtela devolve o cursor ao botao dela
			var focus: Button = {Screen.SAVES: %SavesButton, Screen.OPTIONS: %OptionsButton,
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
	var progress := has_progress()
	%Play.text = "Continuar" if progress else "Jogar"
	_clear(_info)
	_info.visible = progress
	if progress:                                               # resumo do jogo em uso, com os icones do jogo
		var slot := Label.new()
		slot.text = "Jogo %d" % SaveManager.slot
		slot.theme_type_variation = &"DimLabel"
		_info.add_child(slot)
		_info.add_child(UiKit.icon_label("planet", _planet_name(GameState.current_planet), &"DimLabel"))
		_info.add_child(UiKit.icon_label("expedition", "%d runs" % GameState.runs_done, &"DimLabel"))
		_info.add_child(UiKit.icon_label("credits", EconMath.fmt(GameState.amount("credits")), &"MoneyLabel"))


# --- jogos salvos ------------------------------------------------------------------------------------------------

## Uma linha por espaco: nome | resumo (mundo, runs, creditos, tempo) | Jogar ou Novo jogo | Apagar (2 cliques).
func _fill_saves() -> void:
	var focus_key := _focused_key()
	for c in _saves.get_children():
		if c.name != &"SavesTitle":
			_saves.remove_child(c)
			c.queue_free()
	var first: Button = null
	for n in range(1, SaveManager.SLOTS + 1):
		var s := SaveManager.slot_summary(n)
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 6)
		row.custom_minimum_size = Vector2(0, 15)
		var name := Label.new()
		name.text = "Jogo %d" % n
		name.custom_minimum_size = Vector2(40, 0)
		name.theme_type_variation = &"GoodLabel" if s["current"] and s["ok"] else &"ValueLabel"
		if s["current"] and s["ok"]:
			name.tooltip_text = "jogo em uso"
			name.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(name)
		row.add_child(_slot_info(s))
		var act := Button.new()
		act.custom_minimum_size = Vector2(70, 15)
		var del := Button.new()
		del.custom_minimum_size = Vector2(92, 15)
		del.theme_type_variation = &"DangerButton"
		del.set_meta(&"focus_key", "del:%d" % n)
		if s["ok"]:
			act.text = "Jogar"
			act.theme_type_variation = &"PrimaryButton" if s["current"] else &""
			act.set_meta(&"focus_key", "play:%d" % n)
			act.pressed.connect(func() -> void:
				Sound.ui("click")
				slot_play_requested.emit(n))
		elif s["exists"]:                                      # arquivo ilegivel: so da para apagar
			act.text = "-"
			act.disabled = true
		else:
			act.text = "Novo jogo"
			act.set_meta(&"focus_key", "new:%d" % n)
			act.pressed.connect(func() -> void:
				Sound.ui("click")
				new_game_requested.emit(n))
		del.disabled = not s["exists"]
		del.text = "Sim, apagar" if _confirm == "del:%d" % n else "Apagar"
		del.tooltip_text = "apaga este jogo para sempre (Esc cancela)"
		del.pressed.connect(func() -> void: _on_delete(n))
		row.add_child(act)
		row.add_child(del)
		_saves.add_child(row)
		if first == null or (s["current"] and not act.disabled):
			first = act if not act.disabled else del
	var back := Button.new()
	back.text = "Voltar [Esc]"
	back.set_meta(&"focus_key", "back")
	back.pressed.connect(func() -> void: _set_screen(Screen.MENU))
	_saves.add_child(back)
	var target: Button = _find_focus(focus_key)
	var btn: Button = target if target != null else first
	(func() -> void:                                           # adiado; a lista pode ser refeita antes
		if is_instance_valid(btn) and btn.is_inside_tree():
			btn.grab_focus()).call_deferred()


## Resumo de um espaco: icones como no menu; vazio/corrompido em texto.
func _slot_info(s: Dictionary) -> HBoxContainer:
	var info := HBoxContainer.new()
	info.add_theme_constant_override(&"separation", 8)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.custom_minimum_size = Vector2(230, 0)
	if s["ok"]:
		info.add_child(UiKit.icon_label("planet", _planet_name(s["planet"]), &"ValueLabel"))
		info.add_child(UiKit.icon_label("expedition", "%d runs" % int(s["runs"]), &"DimLabel"))
		info.add_child(UiKit.icon_label("credits", EconMath.fmt(float(s["credits"])), &"MoneyLabel"))
		var t := Label.new()
		t.text = _fmt_time(float(s["play_seconds"]))
		t.theme_type_variation = &"DimLabel"
		info.add_child(t)
	else:
		var l := Label.new()
		l.text = "save ilegível" if s["exists"] else "vazio"
		l.theme_type_variation = &"BadLabel" if s["exists"] else &"DimLabel"
		info.add_child(l)
	return info


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
	back.text = "Voltar [Esc]"
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
	back.text = "Voltar [Esc]"
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

func _clear(box: Node) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func _fmt_time(s: float) -> String:
	var t := int(s)
	return "%dh%02dm" % [t / 3600, (t % 3600) / 60] if t >= 3600 else "%dm%02ds" % [t / 60, t % 60]


func _planet_name(id: String) -> String:
	for p: Dictionary in EconMath.spec["planets"]:
		if p["id"] == id:
			return str(p["name"]).get_slice(" (", 0)   # "Docelândia (planeta dos doces)" -> "Docelândia"
	return id
