## Escolha do pedido (2026-10-06, versao D aprovada em art/previews/offer_card/; arte: UiKit.kid + balao).
## No alto, a FILA de rostinhos: um chip por pedido (ratinho do tipo, premio; o mineiro mostra perto/medio/longe).
## Cinza = o gas nao chega (continua escolhivel). Embaixo, o CARTAO do chip escolhido: ratinho + carga, balao de fala
## com a regra (MissionText.balloon), as 3 PLATAFORMAS como botoes de partir (cada uma com o premio) e, se houver, as
## estrelas de dificuldade. Sem gas e sem botao "vamos": clicar na plataforma ja parte.
## Mouse: passar no chip mostra o cartao dele; clicar no chip parte com a plataforma marcada; passar numa plataforma
## marca, clicar parte. Teclado: setas esquerda/direita andam na fila, cima/baixo trocam a plataforma, Shift + cima/baixo
## a estrela, Enter parte; 1..9 (ou teclado numerico) partem direto. E encerra o run (2 toques). Se o jogador tenta
## pilotar antes de escolher, a fila pula.
class_name OfferPanel
extends Control

signal offer_chosen(index: int)
signal end_requested

## Tamanhos de plataforma escolhiveis no cartao (v12.1), do mais facil ao mais dificil, com a figura de cada um.
const TIERS := ["normal", "narrow", "tight"]
const PAD_ICON := {"normal": "pad_normal", "narrow": "pad_narrow", "tight": "pad_tight"}
## Botao de plataforma e chip da fila (px da arte).
const PAD_BUTTON := Vector2(64, 32)
const CHIP := Vector2(35, 50)
## Recortes das celulas 24x24 do atlas kids (so o desenho, sem a sobra transparente).
const CUT_COIN := Rect2(6, 9, 12, 12)
const CUT_STAR := Rect2(6, 6, 12, 12)
const CUT_DIST := Rect2(0, 5, 24, 15)
const CUT_PAD := Rect2(0, 11, 24, 9)
## Ultima escolha do jogador por tipo de missao ({kind: [plataforma, estrela]}): pedidos novos ja vem assim.
static var last_choice: Dictionary = {}

## Segundos restantes do aviso (tentou pilotar antes de escolher). Exposto para o teste de controles.
var hint_flash := 0.0
## Segundos restantes para o 2o toque de E confirmar o fim do run (um toque sem querer nao encerra).
var end_armed := 0.0
var _count := 0
var _infos: Array[Dictionary] = []
var _chips: Array[Button] = []
var _pad_buttons: Dictionary = {}     # tier -> Button do cartao atual
var _sel := -1
var _gas_left := 0.0
var _run: RunState = null
var _board_y := 0.0

@onready var _board: Control = %Board
@onready var _chip_row: HBoxContainer = %Chips
@onready var _hint: Label = %Hint
@onready var _face: TextureRect = %Face
@onready var _cargo: TextureRect = %Cargo
@onready var _balloon: PanelContainer = %Balloon
@onready var _say: Label = %Say
@onready var _pads: HBoxContainer = %Pads
@onready var _stars: HBoxContainer = %Stars


func _ready() -> void:
	_board_y = _board.position.y
	var tail := load("res://assets/ui/balloon_tail.png") as Texture2D
	_balloon.draw.connect(func() -> void:                      # rabinho por cima da borda esquerda, para o ratinho
		_balloon.draw_texture(tail, Vector2(-5.0, roundf(_balloon.size.y * 0.5) - 4.0)))


## Mostra os pedidos do run com o gas que resta.
func show_offers(run: RunState, gas_left: float) -> void:
	for c in _chip_row.get_children():
		_chip_row.remove_child(c)
		c.queue_free()
	_chips.clear()
	_infos.clear()
	_gas_left = gas_left
	_run = run
	_count = run.offers.size()
	for i in _count:                                           # pedido novo ja vem com a ultima escolha do tipo
		var lc: Array = last_choice.get(str(run.offer_mission[i]["kind"]), [])
		if not lc.is_empty():
			run.set_choice(i, str(lc[0]), int(lc[1]))
		_infos.append(run.offer_info(i, gas_left))
		_add_chip(i)
	for i in _count:                                           # setas andam na ordem dos pedidos (perto -> longe)
		var c := _chips[i]
		var prev := _chips[maxi(i - 1, 0)].get_path()
		var next := _chips[mini(i + 1, _count - 1)].get_path()
		c.focus_neighbor_left = prev
		c.focus_neighbor_right = next
		c.focus_neighbor_top = c.get_path()                    # cima/baixo escolhem a plataforma (_input)
		c.focus_neighbor_bottom = c.get_path()
		c.focus_previous = prev
		c.focus_next = next
	hint_flash = 0.0
	end_armed = 0.0
	visible = true
	# foco no 1o pedido alcancavel: setas/direcional + Enter/A escolhem (controle e teclado sem numeros)
	var first := 0
	for i in _count:
		if _infos[i]["reachable"]:
			first = i
			break
	_sel = -1
	if _count > 0:
		_select(first)
		_chips[first].grab_focus.call_deferred()


## Centro (tela) do chip do pedido i — usado pelo teste de controles para simular o clique.
func offer_line_center(i: int) -> Vector2:
	return _chips[i].get_global_rect().get_center()


## Centro (tela) do botao da plataforma tier no cartao do pedido escolhido (teste de controles).
func pad_button_center(tier: String) -> Vector2:
	return (_pad_buttons[tier] as Button).get_global_rect().get_center()


func _process(delta: float) -> void:
	if not visible:
		return
	if end_armed > 0.0:
		end_armed -= delta
		_set_hint("E de novo para encerrar o run (o que você ganhou fica)", &"MoneyLabel")
	elif hint_flash > 0.0:
		hint_flash -= delta
		_set_hint("ESCOLHA UM AMIGUINHO PRIMEIRO!", &"BadLabel" if fmod(hint_flash, 0.4) > 0.2 else &"MoneyLabel")
	else:
		_set_hint("", &"DimLabel")
	_board.position.y = _board_y - (3.0 if hint_flash > 0.0 and fmod(hint_flash, 0.4) > 0.2 else 0.0)


func _set_hint(text: String, variation: StringName) -> void:
	_hint.text = text
	_hint.visible = text != ""
	_hint.theme_type_variation = variation


# --- fila de chips ---------------------------------------------------------------------------------------------------

func _add_chip(i: int) -> void:
	var info := _infos[i]
	var ok: bool = info["reachable"]
	var chip := Button.new()
	chip.flat = true
	chip.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())   # escolha = pino dourado (pin_sel)
	chip.custom_minimum_size = CHIP
	chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	chip.tooltip_text = _tooltip(info)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override(&"separation", 0)
	chip.add_child(box)
	var pin := Control.new()
	pin.name = "Pin"
	pin.custom_minimum_size = Vector2(24, 24)
	pin.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(pin)
	for part: String in ["bg", "face"]:
		var tr := TextureRect.new()
		tr.name = part.capitalize()
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.texture = UiKit.kid(_face_name(info) if part == "face" else ("pin" if ok else "pin_off"))
		if part == "face" and not ok:
			tr.modulate = Color(0.7, 0.7, 0.75)
		pin.add_child(tr)
	var slot: String = _run.offer_slot[i] if i < _run.offer_slot.size() else ""
	var dist := TextureRect.new()                              # mineiro: perto/medio/longe (simple0..2)
	dist.custom_minimum_size = Vector2(24, 15)                 # mesma altura em todos (premios alinhados)
	dist.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dist.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if slot.begins_with("simple") and slot.length() > 6:
		dist.texture = _cut("dist_%d" % (int(slot.substr(6)) + 1), CUT_DIST)
		dist.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	box.add_child(dist)
	var prize := Label.new()
	prize.name = "Prize"
	prize.text = "+" + EconMath.fmt(info["pay_typical"])
	prize.theme_type_variation = &"MoneyLabel" if ok else &"DimLabel"
	prize.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prize.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(prize)
	chip.focus_entered.connect(_select.bind(i))
	chip.mouse_entered.connect(func() -> void: chip.grab_focus())
	chip.pressed.connect(func() -> void: offer_chosen.emit(i))
	_chip_row.add_child(chip)
	_chips.append(chip)


## Rostinho de quem pediu: o ratinho do tipo de missao (rat_<tipo>, atlas kids).
func _face_name(info: Dictionary) -> String:
	return "rat_" + str(info["mission"]["kind"])


## Parte r de uma celula do atlas kids (o desenho sem a sobra transparente, para alinhar nos containers).
func _cut(name: String, r: Rect2) -> AtlasTexture:
	var base := UiKit.kid(name) as AtlasTexture
	var at := AtlasTexture.new()
	at.atlas = base.atlas
	at.region = Rect2(base.region.position + r.position, r.size)
	return at


func _tooltip(info: Dictionary) -> String:
	var t := "%s · distância %s m · pagamento típico +%s" % [EconMath.mission_kind(str(info["mission"]["kind"]))["name"],
			EconMath.fmt(info["distance"]), EconMath.fmt(info["pay_typical"])]
	t += "\n" + MissionText.tip(info["mission"])
	if not info["reachable"]:
		t += "\narriscado: precisa de mais gás do que resta"
	return t


# --- cartao do pedido escolhido ---------------------------------------------------------------------------------------

func _select(i: int) -> void:
	if i == _sel or i < 0 or i >= _count:
		return
	if _sel >= 0 and _sel < _chips.size():
		(_chips[_sel].get_node("Box/Pin/Bg") as TextureRect).texture = \
				UiKit.kid("pin" if _infos[_sel]["reachable"] else "pin_off")
	_sel = i
	var info := _infos[i]
	(_chips[i].get_node("Box/Pin/Bg") as TextureRect).texture = UiKit.kid("pin_sel")
	UiKit.pulse(_chips[i], 1.4, 0.2)
	_face.texture = UiKit.kid(_face_name(info))
	_cargo.texture = CargoArt.icon(str(info["mission"]["kind"]))
	_say.text = MissionText.balloon(info["mission"])
	_fill_choices(i)


## Botoes do cartao: as 3 plataformas (figura + premio; clicar parte) e as estrelas liberadas da missao.
func _fill_choices(i: int) -> void:
	for c in _pads.get_children():
		_pads.remove_child(c)
		c.queue_free()
	for c in _stars.get_children():
		_stars.remove_child(c)
		c.queue_free()
	_pad_buttons.clear()
	var info := _infos[i]
	var star := int(info["mission"]["star"])
	for t: String in TIERS:
		var on: bool = t == info["tier"]
		var b := _choice_button(PAD_BUTTON, on)
		var box := VBoxContainer.new()
		box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override(&"separation", 2)
		b.add_child(box)
		var prize := HBoxContainer.new()
		prize.alignment = BoxContainer.ALIGNMENT_CENTER
		prize.mouse_filter = Control.MOUSE_FILTER_IGNORE
		prize.add_theme_constant_override(&"separation", 1)
		var coin := TextureRect.new()
		coin.texture = _cut("coin", CUT_COIN)
		coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		prize.add_child(coin)
		var lab := Label.new()
		lab.text = "+" + EconMath.fmt(_run.pay_for_tier(i, t))
		lab.theme_type_variation = &"BalloonLabel" if on else &"MoneyLabel"
		lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		prize.add_child(lab)
		box.add_child(prize)
		var pad := TextureRect.new()
		pad.texture = _cut(PAD_ICON[t], CUT_PAD)
		pad.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(pad)
		b.tooltip_text = "plataforma %s: paga %s" % [EconMath.pad_tier(t)["name"],
				UiKit.mult_text(float(EconMath.pad_tier(t)["mult"]))]
		b.mouse_entered.connect(func() -> void:
			if t != _infos[i]["tier"]:
				_choose(i, t, int(_infos[i]["mission"]["star"])))
		b.pressed.connect(func() -> void:                     # parte sem remontar o cartao (o botao some junto)
			_remember(i, t, int(_infos[i]["mission"]["star"]))
			offer_chosen.emit(i))
		_pads.add_child(b)
		_pad_buttons[t] = b
	var stars: Array[int] = _run.stars_for(i) if _run != null else []
	_stars.visible = stars.size() > 1
	for st: int in stars:
		var b := _choice_button(Vector2(36, 14), st == star)
		var row := HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override(&"separation", -4)      # estrelas encostadas (cabem 3 no botao)
		for k in st:
			var s := TextureRect.new()
			s.texture = _cut("star_on", CUT_STAR)
			s.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(s)
		b.add_child(row)
		var lv := EconMath.mission_level(str(info["mission"]["kind"]), st)
		b.tooltip_text = "dificuldade %d: paga %s (Shift + cima/baixo troca)" % [st, UiKit.mult_text(float(lv["mult"]))]
		b.pressed.connect(func() -> void: _choose(i, str(_infos[i]["tier"]), st))
		_stars.add_child(b)


## Botao do cartao: o escolhido fica no estilo principal com a moldura dourada (como o pino escolhido).
func _choice_button(size_px: Vector2, on: bool) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE                          # setas continuam andando na fila
	b.custom_minimum_size = size_px
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if on:
		b.theme_type_variation = &"PrimaryButton"
		var frame := Panel.new()
		frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_theme_stylebox_override(&"panel", UiKit.gold_frame())
		b.add_child(frame)
	return b


## Aplica a escolha (plataforma, estrela) no pedido i, guarda como ultima do tipo e atualiza chip + cartao.
func _choose(i: int, tier: String, star: int) -> void:
	if _run == null or i < 0 or i >= _count:
		return
	_remember(i, tier, star)
	(_chips[i].get_node("Box/Prize") as Label).text = "+" + EconMath.fmt(_infos[i]["pay_typical"])
	_chips[i].tooltip_text = _tooltip(_infos[i])
	Sound.ui("click")
	var keep := _sel
	_sel = -1
	_select(keep)


## Grava a escolha (plataforma, estrela) no pedido i e como ultima do tipo, sem mexer na tela.
func _remember(i: int, tier: String, star: int) -> void:
	_run.set_choice(i, tier, star)
	last_choice[str(_run.offer_mission[i]["kind"])] = [tier, int(_run.offer_mission[i]["star"])]
	_infos[i] = _run.offer_info(i, _gas_left)


## Cima/baixo: plataforma; Shift + cima/baixo: estrela (antes do foco dos chips e do aviso de pilotar).
func _input(event: InputEvent) -> void:
	if not visible or _sel < 0 or not (event is InputEventKey) or not event.pressed:
		return
	var k: int = (event as InputEventKey).keycode
	if k != KEY_UP and k != KEY_DOWN:
		return
	get_viewport().set_input_as_handled()
	var step := 1 if k == KEY_UP else -1
	var info := _infos[_sel]
	if (event as InputEventKey).shift_pressed:
		var stars: Array[int] = _run.stars_for(_sel)
		var j := stars.find(int(info["mission"]["star"]))
		if stars.size() > 1:
			_choose(_sel, str(info["tier"]), stars[clampi(j + step, 0, stars.size() - 1)])
	else:
		var t := TIERS.find(str(info["tier"]))
		_choose(_sel, TIERS[clampi(t + step, 0, TIERS.size() - 1)], int(info["mission"]["star"]))


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"end_run"):
		get_viewport().set_input_as_handled()
		if end_armed > 0.0:
			end_armed = 0.0
			end_requested.emit()
		else:
			end_armed = 2.0
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
