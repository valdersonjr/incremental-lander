## Pedidos no mundo (2026-10-05, interface "para criancas"; arte: UiKit.kid). Cada oferta de entrega e um pino com o
## rostinho de quem pediu: se o lugar da entrega cabe na tela, o pino fica fincado no chao onde a plataforma vai
## nascer (a crianca ve para onde vai voar); se fica alem da tela, vai para a coluna da borda do lado dele (direita ou,
## na Lua, esquerda) com uma setinha (mais em cima = mais perto). Pino cinza = o gas nao chega (continua escolhivel).
## Na Lua o pino mostra o RATINHO do tipo de missao (cada tipo tem o seu: mineiro, ratao, confeiteira, sorveteiro,
## taxista, ratinha do cabo, campeao). Um mini-cartao embaixo mostra o pedido selecionado com figuras: ratinho + figura
## da regra, quanto do gas gasta, estrelas de dificuldade (da missao; Simples =
## as da plataforma) e o premio.
## Teclas 1..9 (ou teclado numerico) escolhem direto; setas andam entre os pinos e Enter escolhe; clique no pino ou
## em VAMOS! escolhe. E encerra o run (2 toques). Se o jogador tenta pilotar antes de escolher, os pinos pulam.
class_name OfferPanel
extends Control

signal offer_chosen(index: int)
signal end_requested

## Geometria (px da arte): pino 24x24; no mundo, o pino fica POLE px acima do chao e pinos vizinhos que se
## encostam sobem um degrau (STEP); na borda, coluna de EDGE_TOP ate EDGE_BOTTOM, encostada em EDGE_RIGHT.
const PIN := 24
const POLE := 22
const STEP := 38
const MIN_GAP := 48
const EDGE_RIGHT := 624.0
const EDGE_LEFT := 16.0
const EDGE_TOP_LEFT := 112.0                                    # coluna da esquerda abaixo do painel do HUD
const EDGE_TOP := 58.0
const EDGE_BOTTOM := 296.0
const EDGE_ROW := 30.0
const EDGE_LABEL := 46.0
## Pino no mundo so entre estes x (fora disso fica a coluna da borda daquele lado).
const WORLD_MAX_X := EDGE_RIGHT - PIN - EDGE_LABEL - 8.0
const WORLD_MIN_X := EDGE_LEFT + PIN + EDGE_LABEL + 8.0
## Rostinhos dos clientes (atlas kids) por mundo; o pedido sorteia um pelo hash da distancia.
## Lua (2026-10-05): so ratinhos (usuario: "tira todos coelhos e alienigena").
const CUSTOMERS := {"luna": ["rat"]}
## Dica de cada regra (tooltip; a figura ja diz o principal).
const MISSION_TIP := {"simple": "entrega simples", "heavy": "pesada: a nave sobe mais devagar e gasta mais gás",
		"soft": "pouso suave: pouse bem devagar!", "fast": "rápida: chegue antes do relógio acabar!",
		"tow": "cabo: não deixe a carga bater no chão!", "passenger": "passageiro: passe devagar pertinho dele!",
		"taxi": "táxi: pouse para buscar o ratinho e leve de volta"}
## Tamanhos de plataforma escolhiveis no cartao (v12.1), do mais facil ao mais dificil.
const TIERS := ["normal", "narrow", "tight"]
## Ultima escolha do jogador por tipo de missao ({kind: [plataforma, estrela]}): pedidos novos ja vem assim.
static var last_choice: Dictionary = {}

## Onde fica na tela o chao de um pedido: Callable(distance_m: float, dir: int) -> Vector2 (Flight.offer_ground_screen).
## Sem ele, todos os pinos vao para a coluna da borda.
var ground_at := Callable()
## Segundos restantes do aviso (tentou pilotar antes de escolher). Exposto para o teste de controles.
var hint_flash := 0.0
## Segundos restantes para o 2o toque de E confirmar o fim do run (um toque sem querer nao encerra).
var end_armed := 0.0
var _count := 0
var _infos: Array[Dictionary] = []
var _pins: Array[Button] = []
var _prizes: Array[Label] = []
var _ground: Array[Vector2] = []      # chao de cada pino no mundo (tela); INF = pino na borda
var _edge_left: Array[bool] = []      # pino na borda esquerda (pedido a esquerda alem da tela)
var _sel := -1
var _gas_left := 0.0
var _planet := "luna"
var _run: RunState = null
var _diff_row: HBoxContainer = null

@onready var _layer: Control = %Pins
@onready var _hint: Label = %Hint
@onready var _face: TextureRect = %Face
@onready var _cargo: TextureRect = %Cargo
@onready var _gas_bar: ProgressBar = %GasBar
@onready var _stars: HBoxContainer = %Stars
@onready var _prize: Label = %Prize
@onready var _go: Button = %Go


func _ready() -> void:
	_layer.draw.connect(_draw_marks)
	(%Coins as TextureRect).texture = UiKit.kid("coins")
	(%GasIcon as TextureRect).texture = UiKit.kid("drop_s")       # sem palavras: gota = gas, plataforma = pouso
	(%PadIcon as TextureRect).texture = UiKit.kid("pad_s")
	_go.icon = UiKit.kid("ship")
	_diff_row = HBoxContainer.new()                             # dificuldade (estrela) da missao, ao lado da plataforma
	_diff_row.add_theme_constant_override(&"separation", 2)
	_stars.get_parent().add_child(_diff_row)                   # mesma linha da plataforma (cartao baixo: nao cobre a nave)
	(%Card as Control).offset_left = -185.0
	(%Card as Control).offset_right = 185.0
	_go.pressed.connect(func() -> void:
		if _sel >= 0:
			offer_chosen.emit(_sel))


## Mostra os pedidos do run com o gas que resta.
func show_offers(run: RunState, gas_left: float) -> void:
	for c in _layer.get_children():
		_layer.remove_child(c)
		c.queue_free()
	_pins.clear()
	_prizes.clear()
	_infos.clear()
	_gas_left = gas_left
	_planet = run.planet_id
	_run = run
	_count = run.offers.size()
	for i in _count:                                           # pedido novo ja vem com a ultima escolha do tipo
		var lc: Array = last_choice.get(str(run.offer_mission[i]["kind"]), [])
		if not lc.is_empty():
			run.set_choice(i, str(lc[0]), int(lc[1]))
		_infos.append(run.offer_info(i, gas_left))
		_add_pin(i)
	for i in _count:                                           # setas andam na ordem dos pedidos (perto -> longe)
		var p := _pins[i]
		var prev := _pins[maxi(i - 1, 0)].get_path()
		var next := _pins[mini(i + 1, _count - 1)].get_path()
		p.focus_neighbor_left = prev
		p.focus_neighbor_top = p.get_path()                    # cima/baixo escolhem a plataforma (_input)
		p.focus_neighbor_right = next
		p.focus_neighbor_bottom = p.get_path()
		p.focus_previous = prev
		p.focus_next = next
	hint_flash = 0.0
	end_armed = 0.0
	visible = true
	_layout()
	# foco no 1o pedido alcancavel: setas/direcional + Enter/A escolhem (controle e teclado sem numeros)
	var first := 0
	for i in _count:
		if _infos[i]["reachable"]:
			first = i
			break
	_sel = -1
	if _count > 0:
		_select(first)
		_pins[first].grab_focus.call_deferred()


## Centro (tela) do pino da oferta i — usado pelo teste de controles para simular o clique.
func offer_line_center(i: int) -> Vector2:
	return _pins[i].get_global_rect().get_center()


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
	_layout()                                                  # a camera ainda se ajeita nos 1os quadros


func _set_hint(text: String, variation: StringName) -> void:
	_hint.text = text
	_hint.visible = text != ""
	_hint.theme_type_variation = variation


# --- pinos ----------------------------------------------------------------------------------------------------------

## Posiciona os pinos: no chao do pedido quando cabe na tela (vizinhos encostados sobem um degrau), senao na coluna
## da borda direita. Os pinos pulam enquanto o aviso pisca.
func _layout() -> void:
	_ground.clear()
	_edge_left.clear()
	var level_x: Array[float] = []                             # x do ultimo pino em cada degrau
	var edge: Array[int] = []
	var edge_l: Array[int] = []
	for i in _count:
		var g := Vector2.INF
		var left := int(_infos[i].get("dir", 1)) < 0
		if ground_at.is_valid():
			g = ground_at.call(float(_infos[i]["distance"]), int(_infos[i].get("dir", 1)))
			if g.x > WORLD_MAX_X or g.x < WORLD_MIN_X:
				g = Vector2.INF
		_ground.append(g)
		_edge_left.append(left and g == Vector2.INF)
		if g == Vector2.INF:
			(edge_l if left else edge).append(i)
			continue
		var lv := 0
		while lv < level_x.size() and g.x - level_x[lv] < MIN_GAP:
			lv += 1
		if lv == level_x.size():
			level_x.append(g.x)
		level_x[lv] = g.x
		_place(i, Vector2(g.x - PIN * 0.5, g.y - POLE - PIN - lv * STEP), true)
	var row := minf(EDGE_ROW, (EDGE_BOTTOM - EDGE_TOP) / maxf(edge.size(), 1))
	for k in edge.size():
		_place(edge[k], Vector2(EDGE_RIGHT - PIN, EDGE_TOP + k * row), false)
	row = minf(EDGE_ROW, (EDGE_BOTTOM - EDGE_TOP_LEFT) / maxf(edge_l.size(), 1))
	for k in edge_l.size():
		_place(edge_l[k], Vector2(EDGE_LEFT, EDGE_TOP_LEFT + k * row), false, true)
	_layer.queue_redraw()


func _place(i: int, pos: Vector2, in_world: bool, left_edge: bool = false) -> void:
	if hint_flash > 0.0 and fmod(hint_flash + pos.x * 0.01, 0.4) > 0.2:
		pos.y -= 3.0
	_pins[i].position = pos.round()
	var lab := _prizes[i]
	var w := lab.get_combined_minimum_size().x
	lab.size = Vector2(w, 10)
	if in_world:                                               # premio em cima do pino
		lab.position = Vector2(roundf((PIN - w) * 0.5), -11)
	elif left_edge:                                            # borda esquerda: premio a direita do pino
		lab.position = Vector2(PIN + 3, 6)
	else:                                                      # premio a esquerda do pino
		lab.position = Vector2(-w - 3, 6)


func _add_pin(i: int) -> void:
	var info := _infos[i]
	var ok: bool = info["reachable"]
	var pin := Button.new()
	pin.flat = true
	pin.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())   # selecao = pino dourado (pin_sel)
	pin.custom_minimum_size = Vector2(PIN, PIN)
	pin.size = Vector2(PIN, PIN)
	pin.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pin.tooltip_text = _tooltip(info)
	for part: String in ["bg", "face"]:
		var tr := TextureRect.new()
		tr.name = part.capitalize()
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.texture = UiKit.kid(_customer(info) if part == "face" else ("pin" if ok else "pin_off"))
		if part == "face" and not ok:
			tr.modulate = Color(0.7, 0.7, 0.75)
		pin.add_child(tr)
	var prize := Label.new()
	prize.text = "+" + EconMath.fmt(info["pay_typical"])
	prize.theme_type_variation = &"MoneyLabel" if ok else &"DimLabel"
	prize.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pin.add_child(prize)
	pin.focus_entered.connect(_select.bind(i))
	pin.mouse_entered.connect(func() -> void: pin.grab_focus())
	pin.pressed.connect(func() -> void: offer_chosen.emit(i))
	_layer.add_child(pin)
	_pins.append(pin)
	_prizes.append(prize)


func _has_missions() -> bool:
	return not EconMath.mission_kinds(_planet).is_empty()


## Rostinho de quem pediu: com missoes, o ratinho do tipo (rat_<tipo>, atlas kids); senao um do mundo pelo hash.
func _customer(info: Dictionary) -> String:
	if _has_missions():
		return "rat_" + str(info["mission"]["kind"])
	var faces: Array = CUSTOMERS.get(_planet, CUSTOMERS["luna"])
	return faces[absi(hash(int(float(info["distance"])))) % faces.size()]


func _tooltip(info: Dictionary) -> String:
	var t := "distância %s m  ·  gás estimado %s  ·  pagamento típico +%s" % [EconMath.fmt(info["distance"]),
			EconMath.fmt(info["gas_est"]), EconMath.fmt(info["pay_typical"])]
	if info["tier"] != "normal":
		t += "\nplataforma %s: paga %s, mas é mais difícil de pousar" % [EconMath.pad_tier(info["tier"])["name"],
				UiKit.mult_text(info["mult"])]
	if _has_missions():
		t += "\n" + _mission_tip(info["mission"])
	if not info["reachable"]:
		t += "\narriscado: precisa de mais gás do que resta"
	return t


## Dica da missao (Dupla: as duas regras; taxi tem frase propria).
func _mission_tip(m: Dictionary) -> String:
	var tips: Array[String] = []
	for p: Dictionary in m.get("parts", []):
		var k: String = p["kind"]
		tips.append(MISSION_TIP["taxi"] if k == "passenger" and EconMath.mission_leg2(m) > 0.0 else MISSION_TIP.get(k, ""))
	return MISSION_TIP["simple"] if tips.is_empty() else "\n".join(tips)


## Etiqueta escura atras de cada premio (legivel sobre o ceu e o chao). Pino no mundo: haste tracejada ate o chao e
## um X no lugar da plataforma. Pino na borda: setinha para a direita.
func _draw_marks() -> void:
	var tag := UiKit.color("ink")
	tag.a = 0.8
	for i in _count:
		var sel := i == _sel
		var col := UiKit.color("gold" if sel else ("mist" if _infos[i]["reachable"] else "slate"))
		var p := _pins[i].position
		var lab := _prizes[i]
		_layer.draw_rect(Rect2(p + lab.position + Vector2(-2, 0), lab.size + Vector2(4, 1)), tag)
		var g := _ground[i]
		if g == Vector2.INF:
			var ay := p.y + PIN * 0.5
			if _edge_left[i]:
				for k in 4:                                    # triangulo de 4 px apontando para a esquerda
					_layer.draw_rect(Rect2(p.x - 3 - k, ay - 3 + k, 1, 7 - 2 * k), col)
			else:
				var ax := p.x + PIN + 2
				for k in 4:                                    # triangulo de 4 px apontando para a direita
					_layer.draw_rect(Rect2(ax + k, ay - 3 + k, 1, 7 - 2 * k), col)
			continue
		var cx := roundf(p.x + PIN * 0.5)
		for y in range(int(p.y + PIN + 1), int(g.y) - 3, 3):
			_layer.draw_rect(Rect2(cx - (1 if sel else 0), y, 2 if sel else 1, 2), col)
		for k in 3:                                            # X no chao
			_layer.draw_rect(Rect2(cx - 2 + k * 2 - 1, g.y - 4 + k * 2 - 1, 2, 2), col)
			_layer.draw_rect(Rect2(cx + 2 - k * 2 - 1, g.y - 4 + k * 2 - 1, 2, 2), col)


# --- mini-cartao do pedido selecionado ------------------------------------------------------------------------------

func _select(i: int) -> void:
	if i == _sel or i < 0 or i >= _count:
		return
	if _sel >= 0 and _sel < _pins.size():
		(_pins[_sel].get_node("Bg") as TextureRect).texture = UiKit.kid("pin" if _infos[_sel]["reachable"] else "pin_off")
	_sel = i
	var info := _infos[i]
	var ok: bool = info["reachable"]
	(_pins[i].get_node("Bg") as TextureRect).texture = UiKit.kid("pin_sel")
	UiKit.pulse(_pins[i], 1.4, 0.2)
	_face.texture = UiKit.kid(_customer(info))
	_cargo.visible = _has_missions()
	if _cargo.visible:
		_cargo.texture = CargoArt.icon(str(info["mission"]["kind"]))
	var r: float = info["gas_est"] / maxf(_gas_left, 0.001)
	_gas_bar.value = minf(r, 1.0) * 100.0
	_gas_bar.theme_type_variation = &"GasBar" if r <= 0.55 else (&"WarnBar" if r <= 1.0 else &"DangerBar")
	_fill_choices(i)
	_prize.text = "+" + EconMath.fmt(info["pay_typical"])
	_prize.theme_type_variation = &"MoneyLabel" if ok else &"BadLabel"
	_go.tooltip_text = _tooltip(info)
	_layer.queue_redraw()


## Seletores do cartao: tamanho da plataforma (x1 / x1,5 / x2,2) e dificuldade da missao (estrelas liberadas).
## Clique, ou setas cima/baixo (plataforma) e Shift + cima/baixo (estrela).
func _fill_choices(i: int) -> void:
	for c in _stars.get_children():
		c.queue_free()
	for c in _diff_row.get_children():
		c.queue_free()
	var info := _infos[i]
	for t: String in TIERS:
		var b := _choice_button(UiKit.mult_text(float(EconMath.pad_tier(t)["mult"])), t == info["tier"])
		b.tooltip_text = "plataforma %s: paga %s (cima/baixo troca)" % [EconMath.pad_tier(t)["name"],
				UiKit.mult_text(float(EconMath.pad_tier(t)["mult"]))]
		b.pressed.connect(_choose.bind(i, t, int(info["mission"]["star"])))
		_stars.add_child(b)
	var stars: Array[int] = _run.stars_for(i) if _run != null else []
	_diff_row.visible = stars.size() > 1 or (stars.size() == 1 and info["mission"]["kind"] != "simple")
	var star_icon := TextureRect.new()
	star_icon.texture = UiKit.kid("star_on")
	star_icon.custom_minimum_size = Vector2(14, 14)
	star_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_diff_row.add_child(star_icon)
	for st: int in stars:
		var b := _choice_button("%d" % st, st == int(info["mission"]["star"]))
		var lv := EconMath.mission_level(str(info["mission"]["kind"]), st)
		b.tooltip_text = "dificuldade %d: paga %s (Shift + cima/baixo troca)" % [st, UiKit.mult_text(float(lv["mult"]))]
		b.pressed.connect(_choose.bind(i, str(info["tier"]), st))
		_diff_row.add_child(b)


func _choice_button(text: String, on: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE                          # setas continuam andando entre os pinos
	b.custom_minimum_size = Vector2(26, 12)
	if on:
		b.theme_type_variation = &"PrimaryButton"
	return b


## Aplica a escolha (plataforma, estrela) no pedido i, guarda como ultima do tipo e atualiza pino + cartao.
func _choose(i: int, tier: String, star: int) -> void:
	if _run == null or i < 0 or i >= _count:
		return
	_run.set_choice(i, tier, star)
	last_choice[str(_run.offer_mission[i]["kind"])] = [tier, int(_run.offer_mission[i]["star"])]
	_infos[i] = _run.offer_info(i, _gas_left)
	_prizes[i].text = "+" + EconMath.fmt(_infos[i]["pay_typical"])
	(_pins[i].get_node("Bg") as TextureRect).texture = UiKit.kid("pin_sel")
	Sound.ui("click")
	var keep := _sel
	_sel = -1
	_select(keep)


## Cima/baixo: plataforma; Shift + cima/baixo: estrela (antes do foco dos pinos e do aviso de pilotar).
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
