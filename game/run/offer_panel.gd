## Painel de ofertas de entrega (teclas 1..8 da fileira de cima ou do teclado numerico, ou clique, escolhem;
## E encerra o run). Se o jogador tenta pilotar antes de escolher, o aviso pisca. Placeholder de texto.
class_name OfferPanel
extends PanelContainer

signal offer_chosen(index: int)
signal end_requested

const COLOR_OK := Color("#c7dcd0")      # mist
const COLOR_BAD := Color("#e83b3b")     # red
const COLOR_TITLE := Color("#fbb954")   # honey
const COLOR_HINT := Color("#9babb2")    # steel
const COLOR_HOVER := Color("#30e1b9")   # aqua
const HINT := "Escolha: teclas 1-%d ou clique  >  depois W/Espaco decola"

## Segundos restantes do aviso piscando (tentou pilotar antes de escolher). Exposto para o teste de controles.
var hint_flash := 0.0
var _hint: Label
var _count := 0

@onready var _list: VBoxContainer = %List


## Mostra as ofertas do run com o gas que resta.
func show_offers(run: RunState, gas_left: float) -> void:
	for c in _list.get_children():
		c.queue_free()
	_count = run.offers.size()
	_add_line("ENTREGAS  [1-%d] escolher   [E] encerrar run" % _count, COLOR_TITLE)
	for i in _count:
		var info := run.offer_info(i, gas_left)
		var l := _add_line("%d  %5s m   min ~%s gas   +%s cr" % [i + 1, EconMath.fmt(info["distance"]),
				EconMath.fmt(info["gas_est"]), EconMath.fmt(info["pay_typical"])],
				COLOR_OK if info["reachable"] else COLOR_BAD)
		_make_clickable(l, i, COLOR_OK if info["reachable"] else COLOR_BAD)
	_hint = _add_line(HINT % _count, COLOR_HINT)
	hint_flash = 0.0
	visible = true


## Centro (tela) da linha da oferta i — usado pelo teste de controles para simular o clique.
func offer_line_center(i: int) -> Vector2:
	var l := _list.get_child(i + 1) as Control
	return l.get_global_rect().get_center()


func _process(delta: float) -> void:
	if _hint == null or not is_instance_valid(_hint):
		return
	if hint_flash > 0.0:
		hint_flash -= delta
		_hint.text = "ESCOLHA UMA ENTREGA PRIMEIRO: tecla 1-%d ou clique" % _count
		_hint.add_theme_color_override(&"font_color", COLOR_BAD if fmod(hint_flash, 0.4) > 0.2 else COLOR_TITLE)
	else:
		_hint.text = HINT % _count
		_hint.add_theme_color_override(&"font_color", COLOR_HINT)


func _make_clickable(l: Label, index: int, base: Color) -> void:
	l.mouse_filter = Control.MOUSE_FILTER_STOP
	l.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	l.mouse_entered.connect(func() -> void: l.add_theme_color_override(&"font_color", COLOR_HOVER))
	l.mouse_exited.connect(func() -> void: l.add_theme_color_override(&"font_color", base))
	l.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and visible:
			accept_event()
			offer_chosen.emit(index))


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"end_run"):
		get_viewport().set_input_as_handled()
		end_requested.emit()
	elif event.is_action_pressed(&"thrust") or event.is_action_pressed(&"rotate_left") \
			or event.is_action_pressed(&"rotate_right"):
		hint_flash = 2.0                                       # tentou pilotar antes de escolher: avisa
	elif event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		var n := -1
		if k >= KEY_1 and k <= KEY_9:
			n = k - KEY_1
		elif k >= KEY_KP_1 and k <= KEY_KP_9:
			n = k - KEY_KP_1                                   # teclado numerico tambem vale
		if n >= 0 and n < _count:
			get_viewport().set_input_as_handled()
			offer_chosen.emit(n)


func _add_line(text: String, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override(&"font_size", 10)
	l.add_theme_color_override(&"font_color", color)
	_list.add_child(l)
	return l
