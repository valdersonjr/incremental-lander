## Mapa das estrelas = TELA PRINCIPAL do jogo (v17, hub aprovado em art/previews/hub/hub.html): os mundos num caminho
## pontilhado, a navezinha no mundo escolhido e, embaixo, o CARTAO DO MUNDO (nome, recorde ou "NOVO! +40%", a Estrada
## daquele mundo e os botoes VOAR / NAVE). Mundo completo = anel dourado + bandeirinha; fechado = cinza + cadeado
## ("complete o anterior"). open(travel_from) faz a viagem: a navezinha anda do mundo completo ate o novo.
## Setas/clique escolhem; Enter/VOAR voa (fly_requested); NAVE abre a PROGRESSAO (ship_requested); Esc = menu.
class_name WorldMap
extends Control

signal fly_requested(planet_id: String)
signal ship_requested
signal menu_requested

const BADGE := 30                                   # meia celula do planetinha (assets/ui/map_planets.png, 60 px em 1x)
const STARS := 46

var _ids: Array[String] = []
var _nodes: Dictionary = {}                          # id -> {"box": VBoxContainer, "badge": TextureRect, "name": Label}
var _sel := ""
var _lander: TextureRect
var _fly: Button
var _ship: Button
var _stars_label: Label
var _card_name: Label
var _card_info: Label
var _road: RoadView
var _toast: Label
var _bob := 0.0
var _traveling := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var title := Label.new()
	title.text = "MUNDOS"
	title.theme_type_variation = &"TitleLabel"
	title.position = Vector2(12, 6)
	add_child(title)
	var stars_row := HBoxContainer.new()
	stars_row.add_theme_constant_override(&"separation", 2)
	stars_row.position = Vector2(580, 8)
	stars_row.add_child(_star_icon(16))
	_stars_label = Label.new()
	_stars_label.theme_type_variation = &"MoneyLabel"
	stars_row.add_child(_stars_label)
	add_child(stars_row)
	_build_card()
	_toast = Label.new()
	_toast.theme_type_variation = &"MoneyLabel"
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.position = Vector2(0, 30)
	_toast.size = Vector2(640, 14)
	_toast.visible = false
	add_child(_toast)
	_lander = TextureRect.new()
	var at := AtlasTexture.new()
	at.atlas = load("res://assets/sprites/lander.png")
	at.region = Rect2(0, 0, 32, 32)
	_lander.texture = at
	_lander.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lander)


## Cartao do mundo (embaixo): nome + recorde/NOVO, a Estrada do mundo e os botoes VOAR / NAVE.
func _build_card() -> void:
	var card := PanelContainer.new()
	card.position = Vector2(6, 226)
	card.size = Vector2(628, 128)
	card.custom_minimum_size = Vector2(628, 128)
	add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)
	card.add_child(row)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override(&"separation", 0)
	row.add_child(left)
	var head := HBoxContainer.new()
	head.add_theme_constant_override(&"separation", 6)
	_card_name = Label.new()
	_card_name.theme_type_variation = &"MoneyLabel"
	head.add_child(_card_name)
	_card_info = Label.new()
	_card_info.theme_type_variation = &"DimLabel"
	head.add_child(_card_info)
	left.add_child(head)
	_road = RoadView.new()
	_road.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(_road)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(120, 0)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override(&"separation", 6)
	row.add_child(right)
	_fly = Button.new()
	_fly.theme_type_variation = &"PrimaryButton"
	_fly.text = "VOAR!  [Enter]"
	_fly.custom_minimum_size = Vector2(120, 30)
	_fly.pressed.connect(func() -> void: _go())
	right.add_child(_fly)
	_ship = Button.new()
	_ship.text = "NAVE"
	_ship.custom_minimum_size = Vector2(120, 20)
	_ship.pressed.connect(func() -> void:
		Sound.ui("click")
		visible = false
		ship_requested.emit())
	right.add_child(_ship)


## Abre o mapa com o mundo atual escolhido. travel_from = mundo que acabou de ficar completo: a navezinha viaja dele
## ate o mundo novo (ja escolhido) e o aviso "X completo! Y abriu!" aparece.
func open(travel_from: String = "") -> void:
	_build()
	visible = true
	_stars_label.text = "%d" % GameState.stars
	var cur := GameState.current_planet if GameState.current_planet in GameState.worlds() else "luna"
	if travel_from != "" and _nodes.has(travel_from):
		_travel(travel_from, cur)
	else:
		_select(cur, false)
	_celebrate_news()
	_fly.grab_focus()


## Viagem (mundo completo): a navezinha sai do mundo completo e voa pelo pontilhado ate o novo.
func _travel(from_id: String, to_id: String) -> void:
	_traveling = true
	_select(to_id, false)
	var a: Vector2 = (_nodes[from_id]["box"] as Control).position + Vector2(64, -18)
	var b: Vector2 = (_nodes[to_id]["box"] as Control).position + Vector2(64, -18)
	_lander.position = a
	_toast.text = "%s completo! %s abriu!" % [_planet_name(from_id), _planet_name(to_id)]
	_toast.visible = true
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_property(_lander, "position", b, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void:
		_traveling = false
		UiKit.pulse(_nodes[to_id]["badge"], 1.8, 0.5)
		Sound.jingle("goal"))
	tw.tween_interval(2.5)
	tw.tween_callback(func() -> void: _toast.visible = false)


## Paradas novas da Estrada do mundo aparecem com festa no cartao (e ficam vistas).
func _celebrate_news() -> void:
	var news: Array = GameState.road_news().filter(func(id: String) -> bool:
		return EconMath.road(GameState.current_planet).any(func(st: Dictionary) -> bool: return st["id"] == id))
	for id: String in news:
		GameState.mark_road_seen(id)
	if news.is_empty():
		return
	_road.rebuild(-1, true)
	_road.celebrate(str(news[-1]))
	Sound.jingle("unlock")


func _planet_name(id: String) -> String:
	return str(EconMath._find("planets", id).get("name", id))


## Posicoes dos mundos no caminho (zigue-zague da esquerda-baixo para a direita-alto), em px da tela 640x360.
static func node_positions(n: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for i in n:
		var t := float(i) / maxf(1.0, n - 1)
		out.append(Vector2(70.0 + t * 500.0, 150.0 - t * 80.0 + (-26.0 if i % 2 == 1 else 10.0)))
	return out


func _build() -> void:
	for c: Variant in _nodes.values():
		(c["box"] as Control).queue_free()
	_nodes.clear()
	_ids.clear()
	for p: Dictionary in EconMath.spec["planets"]:
		_ids.append(str(p["id"]))
	var open_ids := GameState.worlds()
	var pos := node_positions(_ids.size())
	for i in _ids.size():
		var id := _ids[i]
		var is_open := id in open_ids
		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override(&"separation", 0)
		box.custom_minimum_size = Vector2(96, 0)
		box.mouse_filter = Control.MOUSE_FILTER_STOP
		var badge := TextureRect.new()
		badge.texture = planet_texture(id, not is_open, GameState.world_done(id))
		badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge.custom_minimum_size = Vector2(BADGE * 2, BADGE * 2)
		badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		badge.pivot_offset = Vector2(BADGE, BADGE)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(badge)
		var name := Label.new()
		name.text = str(EconMath._find("planets", id).get("name", id))
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name.theme_type_variation = &"ValueLabel" if is_open else &"DimLabel"
		box.add_child(name)
		box.add_child(_info_row(id, is_open))
		add_child(box)
		box.position = pos[i] - Vector2(48, BADGE)
		box.gui_input.connect(_on_node_input.bind(id))
		_nodes[id] = {"box": box, "badge": badge, "name": name}
	move_child(_lander, -1)
	queue_redraw()


## Linha de baixo do mundo: trofeu + recorde | "NOVO! +40%" | cadeado + estrelas que a parada pede.
func _info_row(id: String, is_open: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 2)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic := TextureRect.new()
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	ic.custom_minimum_size = Vector2(12, 12)
	var l := Label.new()
	if not is_open:
		var lock := TextureRect.new()
		lock.texture = UiKit.kid("lock")
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.custom_minimum_size = Vector2(12, 12)
		row.add_child(lock)
		l.text = "complete o anterior"
		l.theme_type_variation = &"DimLabel"
		row.add_child(l)
		return row
	if GameState.world_done(id):
		l.text = "completo!"
		l.theme_type_variation = &"MoneyLabel"
		row.add_child(l)
		return row
	var rec := float(GameState.world_records(id).get("run_money", 0.0))
	if rec > 0.0:
		ic.texture = UiKit.icon("trophy")
		row.add_child(ic)
		l.text = EconMath.fmt(rec)
		l.theme_type_variation = &"MoneyLabel"
	else:
		var first := float((EconMath.spec["contracts"].get("record_bonus", {}) as Dictionary).get("first_frac", 0.0))
		l.text = "NOVO! +%d%%" % roundi(first * 100.0)
		l.theme_type_variation = &"GoodLabel"
	row.add_child(l)
	return row


## Planetinha 24x24 em pixel (ceu em cima, chao ondulado embaixo, pintinhas, contorno ink) nas cores
## world.json > terrain.planets.<id>.map; cinza quando fechado. (Placeholder ate a arte da 18.5.)
static func planet_texture(id: String, locked: bool, done: bool = false) -> Texture2D:
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/map_planets.json"))
	var names: Array = meta["names"]
	var tag := "locked" if locked else ("done" if done else "open")
	var i := names.find("%s_%s" % [id, tag])
	if i < 0:
		i = names.find("luna_" + tag)
	var cell := int(meta["cell"])
	var at := AtlasTexture.new()
	at.atlas = load("res://assets/ui/map_planets.png")
	at.region = Rect2(i * cell, 0, cell, cell)
	return at


static func _star_icon(px: int) -> TextureRect:
	var st := TextureRect.new()
	st.texture = UiKit.kid("star_on")
	st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	st.custom_minimum_size = Vector2(px, px)
	st.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	st.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return st


func _select(id: String, click: bool = true) -> void:
	_sel = id
	GameState.select_world(id)
	_card_name.text = _planet_name(id)
	var rec := float(GameState.world_records(id).get("run_money", 0.0))
	var road := EconMath.road(id)
	var total := int(road[-1]["stars"]) if not road.is_empty() else 0
	_card_info.text = ("recorde %s · " % EconMath.fmt(rec) if rec > 0.0 else "NOVO! · ") + \
			("completo!" if GameState.world_done(id) else "%d/%d estrelas" % [mini(GameState.stars_in(id), total), total])
	_road.rebuild(-1, true)
	for k: String in _nodes:
		var n: Dictionary = _nodes[k]
		(n["badge"] as Control).scale = Vector2.ONE * (1.15 if k == id else 1.0)
		if k in GameState.worlds():
			(n["name"] as Label).theme_type_variation = &"MoneyLabel" if k == id else &"ValueLabel"
	if click:
		Sound.ui("click")


func _on_node_input(event: InputEvent, id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not id in GameState.worlds():
			UiKit.pulse(_nodes[id]["badge"], 1.5, 0.3)
			return
		if id == _sel:
			_go()
		else:
			_select(id)


func _go() -> void:
	if not visible:
		return
	visible = false
	fly_requested.emit(_sel)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		visible = false
		menu_requested.emit()
	elif event.is_action_pressed(&"confirm") or event.is_action_pressed(&"ui_accept"):
		get_viewport().set_input_as_handled()
		_go()
	elif event.is_action_pressed(&"ui_left") or event.is_action_pressed(&"ui_right"):
		get_viewport().set_input_as_handled()
		var open_ids := GameState.worlds()
		var i := open_ids.find(_sel)
		i = clampi(i + (1 if event.is_action_pressed(&"ui_right") else -1), 0, open_ids.size() - 1)
		_select(open_ids[i])


func _process(delta: float) -> void:
	if not visible or not _nodes.has(_sel) or _traveling:
		return
	_bob += delta
	var box: Control = _nodes[_sel]["box"]
	_lander.position = box.position + Vector2(64, -18 + roundf(sin(_bob * 2.5) * 2.0))


func _draw() -> void:
	# ceu do mapa: faixas da Resurrect 64 (anil -> marinho -> ameixa -> ink) com transicao pontilhada (xadrez) de 8 px
	var bands := [Color("#484a77"), Color("#323353"), Color("#45293f"), Color("#2e222f")]
	var h := 360.0 / bands.size()
	for i in bands.size():
		draw_rect(Rect2(0, i * h, 640, h), bands[i])
		if i > 0:
			for y in range(int(i * h) - 8, int(i * h)):
				for x in range(posmod(y, 2), 640, 2 if y >= int(i * h) - 4 else 4):
					draw_rect(Rect2(x, y, 1, 1), bands[i])
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in STARS:
		var p := Vector2(rng.randi_range(0, 639), rng.randi_range(0, 359))
		draw_rect(Rect2(p, Vector2.ONE * (2 if i % 7 == 0 else 1)), Color("#eaaded") if i % 3 else Color("#ffffff"))
	var pos := node_positions(_ids.size())
	for i in range(1, pos.size()):                           # caminho pontilhado entre os mundos
		var a: Vector2 = pos[i - 1]
		var b: Vector2 = pos[i]
		var n := int(a.distance_to(b) / 8.0)
		for k in n:
			if k % 2 == 0:
				draw_rect(Rect2(a.lerp(b, float(k) / n).round(), Vector2(2, 2)), Color("#7f708a"))
