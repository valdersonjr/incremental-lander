## Painel de ofertas de entrega (teclas 1..8 escolhem; E encerra o run). Placeholder de texto.
class_name OfferPanel
extends PanelContainer

signal offer_chosen(index: int)
signal end_requested

const COLOR_OK := Color("#c7dcd0")      # mist
const COLOR_BAD := Color("#e83b3b")     # red
const COLOR_TITLE := Color("#fbb954")   # honey

@onready var _list: VBoxContainer = %List


## Mostra as ofertas do run com o gas que resta.
func show_offers(run: RunState, gas_left: float) -> void:
	for c in _list.get_children():
		c.queue_free()
	_add_line("ENTREGAS  [1-%d] escolher   [E] encerrar run" % run.offers.size(), COLOR_TITLE)
	for i in run.offers.size():
		var info := run.offer_info(i, gas_left)
		_add_line("%d  %5s m   min ~%s gas   +%s cr" % [i + 1, EconMath.fmt(info["distance"]),
				EconMath.fmt(info["gas_est"]), EconMath.fmt(info["pay_typical"])],
				COLOR_OK if info["reachable"] else COLOR_BAD)
	visible = true


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"end_run"):
		get_viewport().set_input_as_handled()
		end_requested.emit()
	elif event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		if k >= KEY_1 and k <= KEY_9 and k - KEY_1 < _list.get_child_count() - 1:
			get_viewport().set_input_as_handled()
			offer_chosen.emit(k - KEY_1)


func _add_line(text: String, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override(&"font_size", 10)
	l.add_theme_color_override(&"font_color", color)
	_list.add_child(l)
