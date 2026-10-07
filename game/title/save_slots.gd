## Lista compacta dos jogos salvos (SaveManager.SLOTS cartoes, um embaixo do outro), usada pelo menu inicial (PLAY) e
## pelo menu do jogo (SAVE). Cada cartao e um botao com a faixa do mapa do jogo no fundo (assets/ui/save_bg_<mundo>.png)
## e "Jogo N" + tempo jogado, creditos e estrelas. Nao ha apagar: um jogo some quando outro e gravado por cima.
## PLAY: com jogo -> slot_play_requested; vazio -> new_game_requested; ilegivel -> desabilitado.
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


func _init() -> void:
	add_theme_constant_override(&"separation", 3)


## Refaz os cartoes (le o resumo de cada espaco) e poe o foco no jogo em uso (ou no cartao que ja tinha o foco).
func fill() -> void:
	var focus_slot := _focused_slot()
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var first: Button = null
	for n in range(1, SaveManager.SLOTS + 1):
		var card := _card(n, SaveManager.slot_summary(n))
		add_child(card)
		if first == null or (n == SaveManager.slot and not card.disabled):
			first = card
	var target: Button = first
	if focus_slot > 0 and not (get_child(focus_slot - 1) as Button).disabled:
		target = get_child(focus_slot - 1)
	(func() -> void:                                           # adiado; a lista pode ser refeita antes
		if is_instance_valid(target) and target.is_inside_tree():
			target.grab_focus()).call_deferred()


## Desiste de gravar por cima (Esc). true se havia uma confirmacao pendente.
func cancel_confirm() -> bool:
	if _confirm == 0:
		return false
	_confirm = 0
	Sound.ui("click")
	fill()
	return true


func _card(n: int, s: Dictionary) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(CARD_W, CARD_H)
	card.set_meta(&"slot", n)
	var current: bool = s["current"] and s["ok"]
	if s["ok"] and _confirm != n:                              # pedindo confirmacao: cartao liso (o aviso le melhor)
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


func _focused_slot() -> int:
	var f := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	return int(f.get_meta(&"slot", 0)) if f != null and is_ancestor_of(f) else 0


static func _fmt_time(sec: float) -> String:
	var t := int(sec)
	return "%dh%02dm" % [t / 3600, (t % 3600) / 60] if t >= 3600 else "%dm%02ds" % [t / 60, t % 60]
