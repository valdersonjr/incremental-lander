## Menu inicial (tela de titulo): fica por cima da cena do mundo atual (nave parada na plataforma, fundo animado).
## Continuar (jogo em uso) / Jogos salvos (SaveManager.SLOTS espacos: jogar, novo jogo, apagar com 2 cliques) /
## Opcoes (volumes) / Sair. Emite sinais; a Main decide o fluxo (carregar, decolar, hangar).
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

enum Screen { MENU, SAVES, OPTIONS }

const HINTS := {
	Screen.MENU: "setas: escolher  ·  Enter: confirmar",
	Screen.SAVES: "setas: escolher  ·  Enter: confirmar  ·  Esc: voltar",
	Screen.OPTIONS: "setas: escolher  ·  Enter: -/+  ·  Esc: voltar",
}

var _screen := Screen.MENU
## Confirmacao pendente na lista de jogos ("" ou "del:N").
var _confirm := ""

@onready var _info: HBoxContainer = %Info
@onready var _menu: VBoxContainer = %Menu
@onready var _saves: VBoxContainer = %Saves
@onready var _options: VBoxContainer = %Options


func _ready() -> void:
	%Play.pressed.connect(func() -> void:
		Sound.ui("click")
		play_requested.emit())
	%SavesButton.pressed.connect(func() -> void: _set_screen(Screen.SAVES))
	%OptionsButton.pressed.connect(func() -> void: _set_screen(Screen.OPTIONS))
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
	%Hint.text = HINTS[s]
	match s:
		Screen.MENU:
			_refresh_menu()
			# voltar de uma subtela devolve o cursor ao botao dela
			var focus: Button = {Screen.SAVES: %SavesButton, Screen.OPTIONS: %OptionsButton}.get(back_from, %Play)
			focus.grab_focus()
		Screen.SAVES:
			Sound.ui("click")
			_fill_saves()
		Screen.OPTIONS:
			Sound.ui("click")
			_fill_options()


func _refresh_menu() -> void:
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
	back.pressed.connect(func() -> void: _set_screen(Screen.MENU))
	_options.add_child(back)
	first.grab_focus()


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
