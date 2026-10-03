## Painel de ofertas de entrega (arte: UiKit). Teclas 1..9 (fileira de cima ou teclado numerico) ou clique na
## linha escolhem; E encerra o run. Se o jogador tenta pilotar antes de escolher, o aviso pisca.
class_name OfferPanel
extends PanelContainer

signal offer_chosen(index: int)
signal end_requested

const HINT := "teclas 1-%d ou clique  >  depois W/Espaço decola"
## Largura (px) das colunas distancia e gas (sem o icone de 12 px + 3 de espaco) e da coluna da plataforma.
const COL_W := [54, 28]
const TIER_W := 26

## Segundos restantes do aviso piscando (tentou pilotar antes de escolher). Exposto para o teste de controles.
var hint_flash := 0.0
var _count := 0

@onready var _list: VBoxContainer = %List
@onready var _hint: Label = %Hint


func _ready() -> void:
	# cabecalho das colunas (mesmas larguras das linhas de _make_row)
	for c: Array in [["", 16], ["distância", COL_W[0] + 15], ["gás", COL_W[1] + 15], ["plat.", TIER_W],
			["pagamento", 0]]:
		var l := Label.new()
		l.text = c[0]
		l.theme_type_variation = &"DimLabel"
		l.custom_minimum_size = Vector2(int(c[1]), 0)
		%Cols.add_child(l)


## Mostra as ofertas do run com o gas que resta.
func show_offers(run: RunState, gas_left: float) -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	_count = run.offers.size()
	for i in _count:
		var info := run.offer_info(i, gas_left)
		_list.add_child(_make_row(i, info))
	hint_flash = 0.0
	visible = true


## Centro (tela) da linha da oferta i — usado pelo teste de controles para simular o clique.
func offer_line_center(i: int) -> Vector2:
	return (_list.get_child(i) as Control).get_global_rect().get_center()


func _process(delta: float) -> void:
	if hint_flash > 0.0:
		hint_flash -= delta
		_hint.text = "ESCOLHA UMA ENTREGA PRIMEIRO: tecla 1-%d ou clique" % _count
		_hint.theme_type_variation = &"BadLabel" if fmod(hint_flash, 0.4) > 0.2 else &"MoneyLabel"
	else:
		_hint.text = HINT % _count
		_hint.theme_type_variation = &"DimLabel"


func _make_row(index: int, info: Dictionary) -> HBoxContainer:
	var ok: bool = info["reachable"]
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 3)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# entrega acima do gas estimado continua escolhivel (tecla ou clique): o botao fica em vermelho, nao desabilitado
	row.tooltip_text = "distância %s m  ·  gás estimado %s  ·  pagamento típico +%s" % [EconMath.fmt(info["distance"]),
			EconMath.fmt(info["gas_est"]), EconMath.fmt(info["pay_typical"])]
	if info["tier"] != "normal":
		row.tooltip_text += "\nplataforma %s: paga %s, mas é mais difícil de pousar" % [
				EconMath.pad_tier(info["tier"])["name"], UiKit.mult_text(info["mult"])]
	if not ok:
		row.tooltip_text += "\narriscada: precisa de mais gás do que resta"
	var key := Button.new()
	key.text = str(index + 1)
	key.custom_minimum_size = Vector2(16, 15)
	key.focus_mode = Control.FOCUS_NONE
	key.mouse_filter = Control.MOUSE_FILTER_PASS              # a dica da linha aparece sobre o botao tambem
	if not ok:
		key.theme_type_variation = &"DangerButton"
	key.pressed.connect(func() -> void: offer_chosen.emit(index))
	row.add_child(key)
	var cols := [["distance", "%s m" % EconMath.fmt(info["distance"]), COL_W[0]],
			["gas", EconMath.fmt(info["gas_est"]), COL_W[1]], ["credits", "+" + EconMath.fmt(info["pay_typical"]), 0]]
	for c: Array in cols:
		if c[0] == "credits":
			row.add_child(_tier_cell(info))
		var cell := UiKit.icon_label(c[0], c[1], &"BadLabel" if not ok else (&"MoneyLabel" if c[0] == "credits"
				else &"ValueLabel"))
		cell.custom_minimum_size = Vector2(int(c[2]) + 15, 0) if int(c[2]) > 0 else Vector2.ZERO
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for ch in cell.get_children():
			(ch as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(cell)
	# linha inteira clicavel; destaque no botao ao passar o mouse
	row.mouse_entered.connect(func() -> void:
		key.add_theme_stylebox_override(&"normal", key.get_theme_stylebox(&"hover")))
	row.mouse_exited.connect(func() -> void: key.remove_theme_stylebox_override(&"normal"))
	row.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and visible:
			accept_event()
			offer_chosen.emit(index))
	return row


## Coluna da plataforma: vazia na normal; "×1,5" ambar na estreita, "×2,2" vermelho na apertada (cor + numero).
func _tier_cell(info: Dictionary) -> Label:
	var l := Label.new()
	l.custom_minimum_size = Vector2(TIER_W, 0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if info["tier"] != "normal":
		l.text = UiKit.mult_text(info["mult"])
		l.theme_type_variation = &"BadLabel" if info["tier"] == "tight" else &"MoneyLabel"
	return l


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
