## Estrada das Estrelas (tela PROGRESSAO, v13; sem titulo nem barra de progresso, pedido do usuario): TODAS as paradas da spec (EconMath.road) lado a lado desde o comeco,
## padrao Trophy Road. Cada parada: estrelas que pede (em cima), bolinha com a figura, nome (embaixo); feita = verde
## com check, proxima = dourada pulsando com "faltam N", futura = apagada. A navezinha marca as estrelas do jogador
## entre as paradas; a linha se enche ate ela. Rola com as setas dos lados, a roda do mouse ou arrastando; clicar numa
## parada emite stop_pressed (a PROGRESSAO abre o balao). Tudo desenhado com nos + StyleBoxFlat (sem arte nova).
class_name RoadView
extends Control

signal stop_pressed(stop_id: String)

const SPACING := 76                    # distancia entre paradas (px)
const X0 := 40                         # centro da 1a parada
const BUBBLE := 30                     # diametro da bolinha
const TOP := 13                        # y da bolinha (abaixo da linha das estrelas)
const HEAD := 2                        # folga em cima (sem titulo nem barra: a estrada fala por si)
const ARROW_W := 12
const SCROLL_STEP := 228.0

var selected := ""                     # parada com o balao aberto (moldura branca)
var _scroll := 0.0
var _drag_x := -1.0
var _drag_scroll := 0.0
var _dragged := false
var _avatar_x := 0.0
var _clip: Control
var _track: Control
var _avatar: TextureRect
var _stop_nodes: Dictionary = {}       # id -> Control da parada
var _built := false
var _center_x := -1.0


func _ready() -> void:
	custom_minimum_size = Vector2(0, HEAD + 84)
	_clip = Control.new()
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_clip)
	_track = Control.new()
	_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_track.draw.connect(_draw_line)
	_clip.add_child(_track)
	for side in [-1, 1]:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.text = "<" if side < 0 else ">"
		b.custom_minimum_size = Vector2(ARROW_W, 22)
		b.tooltip_text = "ver o começo da estrada" if side < 0 else "ver o resto da estrada"
		b.pressed.connect(func() -> void: scroll_by(side * SCROLL_STEP))
		b.name = "Left" if side < 0 else "Right"
		add_child(b)
	resized.connect(_layout)
	_clip.gui_input.connect(_on_clip_input)


## Refaz as paradas com o estado atual. from_stars >= 0: a navezinha anda de from_stars ate as estrelas de agora.
## recenter: rola ate a navezinha (senao mantem a rolagem do jogador).
func rebuild(from_stars: int = -1, recenter: bool = false) -> void:
	for c in _track.get_children():
		_track.remove_child(c)
		c.queue_free()
	_stop_nodes.clear()
	var road := EconMath.road()
	var next_i := _next_index(road)
	for i in road.size():
		var stop: Dictionary = road[i]
		var reached := GameState.road_reached.has(stop["id"])
		var n := _make_stop(stop, reached, i == next_i and not reached)
		n.position = Vector2(X0 + i * SPACING - SPACING / 2.0, 0)
		_track.add_child(n)
		_stop_nodes[stop["id"]] = n
	_track.custom_minimum_size = Vector2(X0 * 2 + SPACING * maxi(0, road.size() - 1), 84)
	_track.size = _track.custom_minimum_size
	_avatar = TextureRect.new()
	var at := AtlasTexture.new()
	at.atlas = load("res://assets/sprites/lander.png")
	at.region = Rect2(0, 0, 32, 32)
	_avatar.texture = at
	_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_avatar.size = Vector2(32, 32)
	_track.add_child(_avatar)
	var target := _x_for(GameState.stars, road)
	_avatar_x = _x_for(from_stars, road) if from_stars >= 0 else target
	_place_avatar()
	if next_i >= 0 and not GameState.road_reached.has(road[next_i]["id"]):
		var need := Label.new()
		need.text = "faltam %d" % (int(road[next_i]["stars"]) - GameState.stars)
		need.theme_type_variation = &"MoneyLabel"
		var row := _with_star(need, 12)
		row.position = Vector2(X0 + next_i * SPACING - 34, 72)
		row.custom_minimum_size = Vector2(68, 0)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		_track.add_child(row)
	if from_stars >= 0 and not is_equal_approx(_avatar_x, target):
		var tw := create_tween()
		tw.tween_method(func(x: float) -> void:
			_avatar_x = x
			_place_avatar(), _avatar_x, target, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_layout()
	if recenter or not _built:
		_built = true
		center_on(_avatar_x)


## Rola para deixar o x da estrada visivel (a navezinha a 1/3 da largura). Antes do layout (largura 0) guarda o
## pedido e aplica no primeiro _layout.
func center_on(x: float) -> void:
	_center_x = x
	_scroll = x - _clip.size.x * 0.35
	if _clip.size.x > 0.0:
		_center_x = -1.0
	_apply_scroll()


func scroll_by(dx: float) -> void:
	_scroll += dx
	_apply_scroll()


## Posicao (no proprio RoadView) do centro da bolinha de uma parada — para o balao.
func stop_anchor(stop_id: String) -> Vector2:
	var n: Control = _stop_nodes.get(stop_id)
	if n == null:
		return Vector2.ZERO
	return _clip.position + _track.position + n.position + Vector2(SPACING / 2.0, TOP + BUBBLE)


## A parada aparece na janela da estrada?
func is_visible_stop(stop_id: String) -> bool:
	var a := stop_anchor(stop_id)
	return a.x >= _clip.position.x and a.x <= _clip.position.x + _clip.size.x


## Pulinho de festa numa parada (recem-alcancada).
func celebrate(stop_id: String) -> void:
	var n: Control = _stop_nodes.get(stop_id)
	if n != null:
		UiKit.pulse(n, 1.8, 0.5)


func _layout() -> void:
	_clip.position = Vector2(ARROW_W + 2, HEAD)
	_clip.size = Vector2(maxf(0.0, size.x - 2 * (ARROW_W + 2)), size.y - HEAD)
	var left: Button = get_node_or_null("Left")
	var right: Button = get_node_or_null("Right")
	if _center_x >= 0.0 and _clip.size.x > 0.0:
		_scroll = _center_x - _clip.size.x * 0.35
		_center_x = -1.0
	if left != null:
		left.position = Vector2(0, HEAD + TOP + BUBBLE / 2.0 - 11)
		right.position = Vector2(size.x - ARROW_W, HEAD + TOP + BUBBLE / 2.0 - 11)
	_apply_scroll()


func _apply_scroll() -> void:
	if _track == null or _clip == null:
		return
	_scroll = clampf(_scroll, 0.0, maxf(0.0, _track.size.x - _clip.size.x))
	_track.position.x = -roundf(_scroll)


func _place_avatar() -> void:
	if _avatar != null and is_instance_valid(_avatar):
		_avatar.position = Vector2(roundf(_avatar_x) - 16, TOP + BUBBLE / 2.0 - 30)
	_track.queue_redraw()


## Indice da proxima parada (a primeira ainda nao alcancada; -1 = estrada completa).
func _next_index(road: Array) -> int:
	for i in road.size():
		if not GameState.road_reached.has(road[i]["id"]):
			return i
	return -1


## x da navezinha para um total de estrelas: entre a ultima parada alcancada e a proxima, na proporcao das estrelas.
func _x_for(stars: int, road: Array) -> float:
	if road.is_empty():
		return X0
	for i in range(1, road.size()):
		var a := int(road[i - 1]["stars"])
		var b := int(road[i]["stars"])
		if stars < b:
			var f := clampf(float(stars - a) / maxf(1.0, b - a), 0.0, 1.0)
			return X0 + (i - 1 + f) * SPACING
	return X0 + (road.size() - 1) * SPACING


func _draw_line() -> void:
	var y := TOP + BUBBLE / 2.0 - 2
	var x1 := X0 + SPACING * maxi(0, EconMath.road().size() - 1)
	_track.draw_rect(Rect2(X0, y, x1 - X0, 5), UiKit.color("ink"))
	_track.draw_rect(Rect2(X0, y + 1, x1 - X0, 3), UiKit.color("slate"))
	_track.draw_rect(Rect2(X0, y + 1, clampf(_avatar_x - X0, 0.0, x1 - X0), 3), UiKit.color("aqua"))


func _make_stop(stop: Dictionary, reached: bool, is_next: bool) -> Control:
	var id := str(stop["id"])
	var box := Control.new()
	box.size = Vector2(SPACING, 84)
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	box.tooltip_text = "%s: %s" % [RoadText.stop_name(stop), RoadText.stop_desc(stop)]
	box.pivot_offset = Vector2(SPACING / 2.0, TOP + BUBBLE / 2.0)
	box.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed and not _dragged:
			stop_pressed.emit(id))
	if not reached and str(stop["type"]) != "start":            # estrelas que a parada pede
		var th := Label.new()
		th.text = "%d" % int(stop["stars"])
		th.theme_type_variation = &"MoneyLabel" if is_next else &"DimLabel"
		var row := _with_star(th, 10)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.size = Vector2(SPACING, 12)
		row.position = Vector2(0, 0)
		box.add_child(row)
	var d := BUBBLE + (6 if is_next else 0)
	var bubble := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.anti_aliasing = false
	sb.set_corner_radius_all(d / 2)
	sb.set_border_width_all(2)
	sb.bg_color = UiKit.color("deep", GameState.current_planet) if reached else UiKit.color("ink")
	sb.border_color = UiKit.color("aqua") if reached else (UiKit.color("gold") if is_next else UiKit.color("slate"))
	if selected == id:
		sb.border_color = UiKit.color("white")
	bubble.add_theme_stylebox_override(&"panel", sb)
	bubble.size = Vector2(d, d)
	bubble.position = Vector2((SPACING - d) / 2.0, TOP + (BUBBLE - d) / 2.0)
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(bubble)
	var pic := TextureRect.new()
	pic.texture = RoadText.stop_icon(stop)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	pic.size = Vector2(d, d)
	pic.position = bubble.position
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not reached and not is_next:
		pic.modulate = Color(0.7, 0.7, 0.78)
	box.add_child(pic)
	var star := RoadText.stop_star(stop)
	if star > 0:                                               # estrelinhas da dificuldade do ratinho
		var stars := HBoxContainer.new()
		stars.add_theme_constant_override(&"separation", -3)
		for s in star:
			var st := TextureRect.new()
			st.texture = UiKit.kid("star_on")
			st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			st.custom_minimum_size = Vector2(9, 9)
			st.mouse_filter = Control.MOUSE_FILTER_IGNORE
			stars.add_child(st)
		stars.position = Vector2(SPACING / 2.0 - 3 * star - 1, TOP + BUBBLE - 6 + (3 if is_next else 0))
		stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(stars)
	if reached:
		var ck := TextureRect.new()
		ck.texture = UiKit.kid("check")
		ck.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ck.size = Vector2(12, 12)
		ck.position = Vector2(SPACING / 2.0 + BUBBLE / 2.0 - 7, TOP + BUBBLE - 10)
		ck.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(ck)
	var name := Label.new()
	name.text = RoadText.stop_name(stop)
	name.autowrap_mode = TextServer.AUTOWRAP_WORD
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.theme_type_variation = &"MoneyLabel" if is_next else (&"Label" if reached else &"DimLabel")
	name.size = Vector2(SPACING - 2, 26)
	name.position = Vector2(1, TOP + BUBBLE + 4)
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name)
	if is_next:
		var tw := bubble.create_tween().set_loops()
		tw.tween_property(bubble, "modulate", Color(1.3, 1.3, 1.1), 0.5).set_trans(Tween.TRANS_SINE)
		tw.tween_property(bubble, "modulate", Color.WHITE, 0.5).set_trans(Tween.TRANS_SINE)
	return box


func _with_star(label: Label, px: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 1)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	var st := TextureRect.new()
	st.texture = UiKit.kid("star_on")
	st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	st.custom_minimum_size = Vector2(px, px)
	st.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	st.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(st)
	return row


## Roda do mouse e arrastar rolam a estrada (arrastar nao conta como clique na parada).
func _on_clip_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.pressed and mb.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT]:
			scroll_by(SPACING * 0.5)
			accept_event()
		elif mb.pressed and mb.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT]:
			scroll_by(-SPACING * 0.5)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_drag_x = mb.position.x
				_drag_scroll = _scroll
				_dragged = false
			else:
				_drag_x = -1.0
				_dragged = false
	elif ev is InputEventMouseMotion and _drag_x >= 0.0:
		var dx := (ev as InputEventMouseMotion).position.x - _drag_x
		if absf(dx) > 4.0:
			_dragged = true
		if _dragged:
			_scroll = _drag_scroll - dx
			_apply_scroll()
