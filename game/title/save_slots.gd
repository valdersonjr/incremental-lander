## Lista compacta dos jogos salvos (SaveManager.SLOTS cartoes, um embaixo do outro), usada pelo menu inicial (PLAY) e
## pelo menu do jogo (SAVE). Cada cartao e um botao com a faixa do mapa do jogo no fundo (assets/ui/save_bg_<mundo>.png)
## e "Jogo N" + tempo jogado, creditos e estrelas.
## PLAY: com jogo -> slot_play_requested; vazio -> new_game_requested; ilegivel -> desabilitado. Ao lado de cada jogo
## salvo, um botao X apaga (2o clique confirma; Esc ou clicar no cartao desiste).
## SAVE: grava o jogo em uso no espaco (SaveManager.save_to_slot); por cima de OUTRO jogo pede um 2o clique.
class_name SaveSlots
extends VBoxContainer

signal slot_play_requested(slot: int)
signal new_game_requested(slot: int)
## SAVE: o jogo foi gravado no espaco slot (que passa a ser o jogo em uso).
signal slot_saved(slot: int)

enum Mode { PLAY, SAVE }

const CARD_W := 250
const CARD_H := 28
## Borda do cartao que fica sem o fundo do mapa (o contorno/foco do botao continua a vista).
const INSET := 3

var mode := Mode.PLAY
## SAVE: espaco esperando o 2o clique para gravar por cima (0 = nenhum).
var _confirm := 0
## PLAY: espaco esperando o 2o clique no X para apagar (0 = nenhum).
var _confirm_delete := 0


func _init() -> void:
	add_theme_constant_override(&"separation", 3)


## Refaz os cartoes (le o resumo de cada espaco) e poe o foco no jogo em uso (ou no cartao que ja tinha o foco).
func fill() -> void:
	var focused := _focused_button()
	var focus_slot := int(focused.get_meta(&"slot", 0)) if focused != null else 0
	var focus_delete := focused != null and focused.has_meta(&"delete")
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var first: Button = null
	for n in range(1, SaveManager.SLOTS + 1):
		var s := SaveManager.slot_summary(n)
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 3)
		var card := _card(n, s)
		row.add_child(card)
		if mode == Mode.PLAY:
			row.add_child(_delete_button(n, s["exists"]))
		add_child(row)
		if first == null or (n == SaveManager.slot and not card.disabled):
			first = card
	var target: Button = first
	if focus_slot > 0:
		var del := delete_button(focus_slot)
		if focus_delete and del != null:
			target = del
		elif not card(focus_slot).disabled:
			target = card(focus_slot)
	(func() -> void:                                           # adiado; a lista pode ser refeita antes
		if is_instance_valid(target) and target.is_inside_tree():
			target.grab_focus()).call_deferred()


## Cartao do espaco n (1..SLOTS).
func card(n: int) -> Button:
	return get_child(n - 1).get_child(0) as Button


## Botao X (apagar) do espaco n; null se o espaco esta vazio ou no modo SAVE.
func delete_button(n: int) -> Button:
	var row := get_child(n - 1)
	return row.get_child(1) as Button if row.get_child_count() > 1 else null


## Desiste de gravar por cima ou de apagar (Esc). true se havia uma confirmacao pendente.
func cancel_confirm() -> bool:
	if _confirm == 0 and _confirm_delete == 0:
		return false
	_confirm = 0
	_confirm_delete = 0
	Sound.ui("click")
	fill()
	return true


func _card(n: int, s: Dictionary) -> Button:
	var card := Button.new()
	var w := CARD_W - CARD_H - 3 if mode == Mode.PLAY else CARD_W   # PLAY: o X ao lado cabe na mesma largura
	card.custom_minimum_size = Vector2(w, CARD_H)
	card.set_meta(&"slot", n)
	var current: bool = s["current"] and s["ok"]
	if s["ok"] and _confirm != n and _confirm_delete != n:                              # pedindo confirmacao: cartao liso (o aviso le melhor)
		_add_map(card, str(s["planet"]))
	if current:                                                # jogo em uso: moldura dourada (como a escolha atual)
		card.tooltip_text = "jogo em uso"
		var frame := Panel.new()
		frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_theme_stylebox_override(&"panel", UiKit.gold_frame())
		card.add_child(frame)
	var box := HBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 7)
	box.add_theme_constant_override(&"separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	box.add_child(_label("Jogo %d" % n, &"GoodLabel" if current else &"ValueLabel"))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(spacer)
	if _confirm == n:
		box.add_child(_label("Gravar por cima? Clique de novo", &"BadLabel"))
	elif _confirm_delete == n:
		box.add_child(_label("Apagar? Clique no X de novo", &"BadLabel"))
	elif s["ok"]:
		box.add_child(_stat("clock", _fmt_time(float(s["play_seconds"])), &"ValueLabel"))
		box.add_child(_stat("coin", EconMath.fmt(float(s["credits"])), &"MoneyLabel"))
		box.add_child(_stat("star_on", str(int(s["stars"])), &"MoneyLabel"))
	elif s["exists"]:
		box.add_child(_label("save ilegível", &"BadLabel"))
	else:
		box.add_child(_label("+ Novo jogo" if mode == Mode.PLAY else "vazio", &"DimLabel"))
	match mode:
		Mode.PLAY:
			card.disabled = s["exists"] and not s["ok"]          # ilegivel: so some gravando outro jogo por cima
			card.pressed.connect(func() -> void:
				if _confirm_delete != 0:                         # pedindo para apagar: clicar no cartao desiste
					cancel_confirm()
					return
				Sound.ui("click")
				if s["ok"]:
					slot_play_requested.emit(n)
				else:
					new_game_requested.emit(n))
		Mode.SAVE:
			card.pressed.connect(func() -> void: _on_save(n, s["exists"] and not current))
	return card


## Faixa do mapa do jogo no fundo, no tamanho do miolo do cartao (sem escalar: pixel nitido).
func _add_map(card: Button, planet: String) -> void:
	var path := "res://assets/ui/save_bg_%s.png" % planet
	if not ResourceLoader.exists(path):                        # mundo ainda sem faixa propria: a da Lua
		path = "res://assets/ui/save_bg_luna.png"
	if not ResourceLoader.exists(path):
		return
	var clip := Control.new()
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, INSET)
	var bg := TextureRect.new()
	bg.texture = load(path)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(bg)
	card.add_child(clip)


## X ao lado do cartao (so com jogo salvo, inclusive ilegivel); vazio ganha um espaco do mesmo tamanho.
func _delete_button(n: int, exists: bool) -> Control:
	if not exists:
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(CARD_H, CARD_H)
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return gap
	var b := Button.new()
	b.custom_minimum_size = Vector2(CARD_H, CARD_H)
	b.icon = UiKit.kid("cross")
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.tooltip_text = "apagar"
	b.set_meta(&"slot", n)
	b.set_meta(&"delete", true)
	b.pressed.connect(func() -> void: _on_delete(n))
	return b


func _on_delete(n: int) -> void:
	_confirm = 0
	if _confirm_delete != n:
		Sound.ui("click")
		_confirm_delete = n
		fill()
		return
	_confirm_delete = 0
	SaveManager.delete_slot(n)
	Sound.ui("click")
	fill()


func _on_save(n: int, overwrite: bool) -> void:
	if overwrite and _confirm != n:
		Sound.ui("click")
		_confirm = n
		fill()
		return
	_confirm = 0
	SaveManager.save_to_slot(n)
	Sound.ui("buy")
	fill()
	slot_saved.emit(n)


## Figura do atlas kids (12 px) + numero, com contorno escuro (legivel sobre o fundo do mapa).
func _stat(icon: String, text: String, variation: StringName) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 1)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pic := TextureRect.new()
	pic.texture = UiKit.kid(icon)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.custom_minimum_size = Vector2(12, 12)
	pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(pic)
	row.add_child(_label(text, variation))
	return row


func _label(text: String, variation: StringName) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = variation
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override(&"font_outline_color", UiKit.color("ink"))
	l.add_theme_constant_override(&"outline_size", 4)
	return l


func _focused_button() -> Control:
	var f := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	return f if f != null and is_ancestor_of(f) else null


static func _fmt_time(sec: float) -> String:
	var t := int(sec)
	return "%dh%02dm" % [t / 3600, (t % 3600) / 60] if t >= 3600 else "%dm%02ds" % [t / 60, t % 60]
