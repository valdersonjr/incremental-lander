## PROGRESSAO entre runs (v13, antes "Oficina"; padrao Trophy Road — docs/DECISIONS.md 2026-10-07). No alto a
## ESTRADA DA LUA (RoadView): todas as paradas visiveis desde o comeco; estrelas acumuladas (1 por entrega) andam com a
## navezinha e cada parada libera sozinha (GameState._check_road). Abas: NAVE (nave grande com as pecas que crescem +
## 4 cartoes de peca em degraus de 10, compradas com moedas; habilidades e recordes no meio), AJUDAS (ligar/desligar;
## as que faltam mostram o lugar na estrada), FROTA (cadeado ate a parada; drones e Piloto automatico).
## Esc (sem botao na tela) pede o menu do jogo (menu_requested: a Main esconde e abre o PauseMenu no modo HANGAR).
## Q/E trocam de aba, Enter decola (ou ativa o botao com foco). Ao abrir depois de um voo, a navezinha anda ate as
## estrelas novas e cada parada nova faz festa (ratinho ★1 = telinha "Novo amiguinho!"). Numeros: GameState/EconMath.
class_name Hangar
extends Control

signal launch_requested
## Voltar ao menu inicial (contrato mantido; hoje o pedido sai do menu do jogo, PauseMenu.title_requested).
signal title_requested
## Esc: abrir o menu do jogo fora da tela.
signal menu_requested

enum Tab { SHIP, ASSISTS, FLEET }

const MISSION_INTRO := preload("res://game/run/mission_intro.tscn")
const TAB_INFO := [[Tab.SHIP, "NAVE", "thrust"], [Tab.ASSISTS, "AJUDAS", "distance"], [Tab.FLEET, "FROTA", "fleet"]]
const CARD_W := 184
const BULK := [[1, "×1"], [10, "×10"], [0, "MÁX"]]          # 0 = maximo possivel
const TOAST_S := 1.6
const CONFETTI := ["gold", "aqua", "coral", "violet", "ice", "white"]

var _tab := Tab.SHIP
var _bulk := 1
## Ultima interacao foi teclado/controle: refresh() devolve o foco ao mesmo botao (senao, ao DECOLAR).
var _keyboard_nav := false
var _flash_row := ""
var _flash_money := false
var _seen_stars := -1                  # estrelas da ultima vez que a estrada foi mostrada (a navezinha anda dai)
var _news: Array = []                  # paradas novas esperando a festa
var _ship_view: ShipView = null
var _intro: MissionIntro = null
var _toast_tween: Tween = null

@onready var _planet: Label = %Planet
@onready var _tabs: HBoxContainer = %Tabs
@onready var _bulk_box: HBoxContainer = %Bulk
@onready var _resources: HBoxContainer = %Resources
@onready var _road: RoadView = %Road
@onready var _body: MarginContainer = %Body
@onready var _launch: Button = %Launch
@onready var _balloon: PanelContainer = %Balloon
@onready var _toast: PanelContainer = %Toast


func _ready() -> void:
	_launch.pressed.connect(func() -> void: launch_requested.emit())
	launch_requested.connect(func() -> void: Sound.ui("click"))
	_intro = MISSION_INTRO.instantiate()
	add_child(_intro)
	_intro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_intro.closed.connect(func() -> void:
		_show_next_news()
		if not _launch.disabled:
			_launch.grab_focus())
	_road.stop_pressed.connect(_toggle_balloon)
	Events.road_reached.connect(func(id: String) -> void:
		if visible and not _news.has(id):                      # alcancou com a tela aberta (ex.: estrelas de dev)
			_news.append(id))


## Mostra a PROGRESSAO atualizada na aba NAVE; a navezinha anda ate as estrelas de agora e as paradas novas festejam.
func open() -> void:
	_tab = Tab.SHIP
	visible = true
	_balloon.visible = false
	_road.selected = ""
	refresh()
	var from := _seen_stars if _seen_stars >= 0 and _seen_stars < GameState.stars else -1
	_road.rebuild(from, true)
	_seen_stars = GameState.stars
	_news = GameState.road_news()
	if not _news.is_empty():
		get_tree().create_timer(0.6 if from >= 0 else 0.1).timeout.connect(_show_next_news)
	if not _launch.disabled:
		_launch.grab_focus()


func refresh() -> void:
	var focus_key := _focused_key()
	var planet := GameState.current_planet
	theme = UiKit.theme_for(planet)                            # a cor da tela acompanha o mundo atual
	_planet.text = _planet_name(planet) + ("  ·  SANDBOX" if Sandbox.active() else "")
	_fill_tabs()
	_fill_bulk()
	_fill_resources()
	var launchable := Purchases.can_launch(planet, GameState.ship_stats())
	_launch.disabled = not launchable
	_launch.text = "DECOLAR!  [Enter]" if launchable else "nave fraca: melhore Motor e Gasolina"
	_clear(_body)
	_ship_view = null
	match _tab:
		Tab.SHIP:
			_add_ship()
		Tab.ASSISTS:
			_add_assists()
		Tab.FLEET:
			_add_fleet()
	_after_rebuild(focus_key)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey or event is InputEventJoypadButton:
		_keyboard_nav = true
	elif event is InputEventMouseButton:
		_keyboard_nav = false
		if event.pressed and _balloon.visible and not _balloon.get_global_rect().has_point(event.global_position) \
				and not _road.get_global_rect().has_point(event.global_position):
			_close_balloon()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _intro.visible:
		return
	if event.is_action_pressed(&"confirm"):
		get_viewport().set_input_as_handled()
		if not _launch.disabled:
			launch_requested.emit()
	elif event.is_action_pressed(&"ui_cancel"):                # balao aberto: fecha; senao, menu do jogo
		get_viewport().set_input_as_handled()
		if _balloon.visible:
			_close_balloon()
		else:
			menu_requested.emit()
	elif (event.is_action_pressed(&"tab_prev") or event.is_action_pressed(&"tab_next")) and not event.is_echo():
		get_viewport().set_input_as_handled()                  # Q/E ou LB/RB
		_cycle_tab(-1 if event.is_action_pressed(&"tab_prev") else 1)


# --- cabecalho ---------------------------------------------------------------------------------------------------

func _fill_resources() -> void:
	_clear(_resources)
	var money := UiKit.icon_label("credits", EconMath.fmt(GameState.amount("credits")), &"MoneyLabel")
	(money.get_child(1) as Label).add_theme_font_size_override(&"font_size", UiKit.TITLE_SIZE)
	(money.get_child(0) as TextureRect).custom_minimum_size = Vector2(12, 22)
	money.tooltip_text = "moedas: compram as peças da nave"
	money.mouse_filter = Control.MOUSE_FILTER_PASS
	_resources.add_child(money)
	var stars := HBoxContainer.new()
	stars.add_theme_constant_override(&"separation", 2)
	stars.tooltip_text = "estrelas: cada entrega dá 1 e elas andam na estrada"
	stars.mouse_filter = Control.MOUSE_FILTER_PASS
	stars.add_child(_kid_rect("star_on", 18))
	var n := Label.new()
	n.text = str(GameState.stars)
	n.theme_type_variation = &"MoneyLabel"
	n.add_theme_font_size_override(&"font_size", UiKit.TITLE_SIZE)
	stars.add_child(n)
	_resources.add_child(stars)
	if _flash_money:
		_flash_money = false
		UiKit.pulse(_resources, 1.5)


func _fill_tabs() -> void:
	_clear(_tabs)
	for info: Array in TAB_INFO:
		var t: Tab = info[0]
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 15)
		var locked := t == Tab.FLEET and not GameState.road_reached.has("fleet")
		b.icon = UiKit.kid("lock") if locked else UiKit.icon(info[2])
		b.add_theme_constant_override(&"icon_max_width", 12)
		var news := t != _tab and _tab_has_news(t)
		b.text = str(info[1]) + (" !" if news else "")
		if t == _tab:
			b.theme_type_variation = &"PrimaryButton"
		elif news:
			for c: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color"]:
				b.add_theme_color_override(c, UiKit.color("gold"))
		if locked:
			b.modulate = Color(0.75, 0.75, 0.82)
		b.pressed.connect(func() -> void: _set_tab(t))
		_tabs.add_child(b)


## ×1 / ×10 / MAX: quantos niveis cada botao de peca compra (×10 = ate o fim do degrau).
func _fill_bulk() -> void:
	_clear(_bulk_box)
	_bulk_box.visible = _tab == Tab.SHIP
	for info: Array in BULK:
		var b := Button.new()
		b.text = str(info[1])
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(22, 13)
		b.tooltip_text = {1: "comprar 1 nível", 10: "comprar até o próximo degrau", 0: "comprar o máximo possível"}[info[0]]
		if int(info[0]) == _bulk:
			b.theme_type_variation = &"PrimaryButton"
		var v := int(info[0])
		b.pressed.connect(func() -> void:
			_bulk = v
			Sound.ui("click")
			refresh())
		_bulk_box.add_child(b)


func _set_tab(t: Tab) -> void:
	if t == _tab:
		return
	Sound.ui("click")
	_tab = t
	_close_balloon()
	refresh()


func _cycle_tab(step: int) -> void:
	var order: Array[Tab] = [Tab.SHIP, Tab.ASSISTS, Tab.FLEET]
	var i := order.find(_tab)
	_set_tab(order[posmod((0 if i < 0 else i) + step, order.size())])


func _tab_has_news(t: Tab) -> bool:
	match t:
		Tab.SHIP:
			return RoadText.PARTS.any(func(id: String) -> bool: return _plan(id)["ok"])
		Tab.ASSISTS:
			return GameState.road_news().any(func(id: String) -> bool: return RoadText.ASSIST_TIP.has(id))
		Tab.FLEET:
			return GameState.road_reached.has("fleet") and (_can_afford("fleet") or _can_afford("autopilot"))
	return false


# --- aba NAVE ----------------------------------------------------------------------------------------------------

## Nave grande no meio (pecas que crescem) + 2 cartoes de peca de cada lado; habilidades em cima e recordes embaixo.
func _add_ship() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 4)
	_body.add_child(row)
	var left := VBoxContainer.new()
	var right := VBoxContainer.new()
	for col: VBoxContainer in [left, right]:
		col.custom_minimum_size = Vector2(CARD_W, 0)
		col.add_theme_constant_override(&"separation", 3)
		col.alignment = BoxContainer.ALIGNMENT_CENTER
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_theme_constant_override(&"separation", 2)
	row.add_child(left)
	row.add_child(mid)
	row.add_child(right)
	left.add_child(_part_card("thrust"))
	left.add_child(_part_card("tank"))
	right.add_child(_part_card("efficiency"))
	right.add_child(_part_card("gear"))
	mid.add_child(_ability_row())
	_ship_view = ShipView.new()
	_ship_view.levels = GameState.levels
	_ship_view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mid.add_child(_ship_view)
	var rec := _records_row()
	if rec != null:
		mid.add_child(rec)
	if _flash_row.begins_with("up:"):
		_ship_view.bounce.call_deferred()


## Quantos niveis o botao da peca compra agora (pelo ×1/×10/MAX) e quanto custa. ok = da para pagar.
func _plan(id: String) -> Dictionary:
	var u := EconMath._find("upgrades", id)
	var lv := int(GameState.levels.get(id, 0))
	var mx := int(u.get("max_level", 1))
	if lv >= mx:
		return {"n": 0, "cost": 0.0, "ok": false, "max": true}
	var c: Dictionary = u["cost"]["credits"]
	var limit := mx - lv
	if _bulk == 1:
		limit = 1
	elif _bulk == 10:
		limit = mini(limit, RoadText.STAGE - lv % RoadText.STAGE)
	var n := mini(EconMath.max_affordable(c, lv, GameState.amount("credits")), limit)
	if n <= 0:
		return {"n": 1, "cost": EconMath.bulk_cost(c, lv, 1), "ok": false, "max": false}
	return {"n": n, "cost": EconMath.bulk_cost(c, lv, n), "ok": GameState.can_buy(id), "max": false}


func _can_afford(id: String) -> bool:
	var u := EconMath._find("upgrades", id)
	var lv := int(GameState.levels.get(id, 0))
	return GameState.can_buy(id) and lv < int(u.get("max_level", 1)) \
			and EconMath.upgrade_available(id, lv, GameState.levels) \
			and GameState.amount("credits") >= EconMath.bulk_cost(u["cost"]["credits"], lv, 1)


## Cartao de peca: figura + nome e degrau (I, II...) + o que melhora | 10 bolinhas do degrau | botao de preco |
## "faltam N: Motor III". Passar o mouse faz a peca brilhar na nave.
func _part_card(id: String) -> PanelContainer:
	var u := EconMath._find("upgrades", id)
	var lv := int(GameState.levels.get(id, 0))
	var mx := int(u.get("max_level", 1))
	var st := RoadText.stage_of(lv, mx)
	var stages := ceili(float(mx) / RoadText.STAGE)
	var maxed := lv >= mx
	var in_st := RoadText.STAGE if maxed else lv % RoadText.STAGE
	var card := PanelContainer.new()
	card.theme_type_variation = &"SlimPanel"
	card.set_meta(&"row_key", "up:" + id)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var s := GameState.ship_stats()
	card.tooltip_text = "%s nível %d de %d" % [u["name"], lv, mx]
	var stat := str(u.get("effect", {}).get("stat", ""))
	if s.has(stat):
		card.tooltip_text += "\nagora: %s" % _num(float(s[stat]))
	card.mouse_entered.connect(func() -> void:
		if _ship_view != null:
			_ship_view.highlight(id))
	card.mouse_exited.connect(func() -> void:
		if _ship_view != null:
			_ship_view.highlight(""))
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 1)
	card.add_child(box)
	var top := HBoxContainer.new()
	top.add_theme_constant_override(&"separation", 4)
	box.add_child(top)
	var ic := TextureRect.new()
	ic.texture = UiKit.icon(RoadText.PART_ICON[id])
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.custom_minimum_size = Vector2(24, 24)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(ic)
	var names := VBoxContainer.new()
	names.add_theme_constant_override(&"separation", 0)
	top.add_child(names)
	var title := Label.new()
	title.text = "%s %s" % [u["name"], RoadText.ROMAN[mini(st, RoadText.ROMAN.size() - 1)]]
	names.add_child(title)
	var does := Label.new()
	does.text = RoadText.PART_DOES[id]
	does.theme_type_variation = &"MoneyLabel"
	names.add_child(does)
	var pips := HBoxContainer.new()
	pips.add_theme_constant_override(&"separation", 2)
	box.add_child(pips)
	for i in RoadText.STAGE:
		pips.add_child(_pip(i < in_st, i == in_st and not maxed))
	var p := _plan(id)
	var buy := Button.new()
	buy.custom_minimum_size = Vector2(0, 16)
	buy.set_meta(&"focus_key", "buy:" + id)
	if maxed:
		buy.text = "COMPLETA!"
		buy.disabled = true
		buy.add_theme_color_override(&"font_disabled_color", UiKit.color("gold"))
	else:
		buy.icon = UiKit.icon("credits")
		buy.text = EconMath.fmt(float(p["cost"])) + ("  (+%d)" % int(p["n"]) if int(p["n"]) > 1 else "")
		buy.disabled = not p["ok"]
		buy.tooltip_text = "comprar %d nível(is)" % int(p["n"]) + _missing_text(float(p["cost"]))
		if p["ok"]:
			buy.theme_type_variation = &"PrimaryButton"
			var tw := buy.create_tween().set_loops()
			tw.tween_property(buy, "modulate", Color(1.25, 1.25, 1.25), 0.45).set_trans(Tween.TRANS_SINE)
			tw.tween_property(buy, "modulate", Color.WHITE, 0.45).set_trans(Tween.TRANS_SINE)
		buy.pressed.connect(func() -> void: _buy_part(id, int(p["n"])))
	box.add_child(buy)
	var nxt := Label.new()
	nxt.theme_type_variation = &"DimLabel"
	nxt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if maxed:
		nxt.text = "peça completa!"
	elif st + 1 < stages:
		nxt.text = "faltam %d: %s %s" % [RoadText.STAGE - in_st, u["name"], RoadText.ROMAN[st + 1]]
	else:
		nxt.text = "faltam %d para completar" % (mx - lv)
	box.add_child(nxt)
	return card


func _pip(full: bool, current: bool) -> Panel:
	var pip := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.anti_aliasing = false
	sb.set_border_width_all(1)
	sb.bg_color = UiKit.color("aqua") if full else UiKit.color("ink")
	sb.border_color = UiKit.color("ice") if full else UiKit.color("slate")
	pip.add_theme_stylebox_override(&"panel", sb)
	pip.custom_minimum_size = Vector2(0, 6)
	pip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if current:
		var tw := pip.create_tween().set_loops()
		tw.tween_property(pip, "modulate", Color(1.6, 1.6, 1.6), 0.5)
		tw.tween_property(pip, "modulate", Color.WHITE, 0.5)
	return pip


## Compra n niveis (um por vez: GameState valida cada um). Degrau novo = festa e a peca cresce.
func _buy_part(id: String, n: int) -> void:
	var before := int(GameState.levels.get(id, 0))
	var bought := 0
	for i in n:
		if not GameState.buy_upgrade(id):
			break
		bought += 1
	var after := int(GameState.levels.get(id, 0))
	Sound.ui("buy" if bought > 0 else "denied")
	if bought == 0:
		return
	_flash_row = "up:" + id
	_flash_money = true
	var mx := int(EconMath._find("upgrades", id).get("max_level", 1))
	var stage_up := after / RoadText.STAGE > before / RoadText.STAGE or after >= mx
	if stage_up or Purchases.milestone_crossed(id, before, after):
		Sound.jingle("milestone")
	refresh()
	if stage_up:
		var name := str(EconMath._find("upgrades", id)["name"])
		_show_toast(UiKit.icon(RoadText.PART_ICON[id]), "degrau novo!", "%s completa!" % name if after >= mx
				else "%s %s!" % [name, RoadText.ROMAN[mini(after / RoadText.STAGE, RoadText.ROMAN.size() - 1)]])


## Habilidades (Estabilizador, Turbo): vem prontas pela estrada. Tem: a tecla que usa. Nao tem: cadeado + estrelas.
func _ability_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 4)
	for id: String in ["stabilizer", "turbo"]:
		var u := EconMath._find("upgrades", id)
		if u.is_empty():
			continue
		var b := Button.new()
		b.icon = CargoArt.tex(id)
		b.custom_minimum_size = Vector2(0, 18)
		b.focus_mode = Control.FOCUS_NONE
		b.tooltip_text = "%s: %s" % [u["name"], RoadText.ABILITY_TIP.get(id, "")]
		if int(GameState.levels.get(id, 0)) >= 1:
			var keys := WorldConfig.current_keys(id if id != "stabilizer" else "stabilize")
			var key_txt := WorldConfig.key_label(keys[0]) if not keys.is_empty() else ""
			b.text = "%s [%s]" % [u["name"], key_txt]
			b.tooltip_text += "\nsegure %s no voo" % key_txt
		else:
			var stop := EconMath.road_stop(id)
			b.text = "%s  %d" % [u["name"], int(stop.get("stars", 0))]
			b.modulate = Color(0.7, 0.7, 0.78)
			b.tooltip_text += "\nvem na estrada com %d estrelas" % int(stop.get("stars", 0))
			b.pressed.connect(func() -> void: _toggle_balloon(id))
		row.add_child(b)
	return row


## Recordes pessoais numa linha (icone + valor; nome no tooltip). null se ainda nao ha recorde.
func _records_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 6)
	for key: String in GameState.RECORDS:
		var v := float(GameState.records.get(key, 0.0))
		if v <= 0.0:
			continue
		var info: Array = GameState.RECORDS[key]
		var item := UiKit.icon_label(str(info[1]), "%d" % int(v) if key == "best_perfect" else EconMath.fmt(v),
				&"MoneyLabel" if key in ["best_delivery", "best_run"] else &"ValueLabel")
		item.tooltip_text = "recorde: " + str(info[0])
		item.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(item)
	return row if row.get_child_count() > 0 else null


# --- aba AJUDAS --------------------------------------------------------------------------------------------------

## Ajudas de voo (vem pela estrada): figura do que desenham no voo + LIGADA/DESLIGADA; as que faltam, o lugar na estrada.
func _add_assists() -> void:
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override(&"h_separation", 3)
	grid.add_theme_constant_override(&"v_separation", 3)
	_body.add_child(grid)
	var ids: Array[String] = [GameState.ASSIST_FREE]
	for u: Dictionary in EconMath.spec["upgrades"]:
		if u.has("assist"):
			ids.append(str(u["id"]))
	for id in ids:
		grid.add_child(_assist_card(id))


func _assist_card(id: String) -> PanelContainer:
	var free := id == GameState.ASSIST_FREE
	var owned := free or int(GameState.levels.get(id, 0)) >= 1
	var on := GameState.assist_on(id)
	var card := PanelContainer.new()
	card.theme_type_variation = &"SlimPanel"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.set_meta(&"row_key", "up:" + id)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.tooltip_text = str(RoadText.ASSIST_TIP.get(id, ""))
	if not owned:
		card.modulate = Color(0.62, 0.62, 0.7)
	elif not on:
		card.modulate = Color(0.8, 0.8, 0.85)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 1)
	card.add_child(box)
	var title := Label.new()
	title.text = "Setinha" if free else str(EconMath._find("upgrades", id)["name"])
	title.theme_type_variation = &"GoodLabel" if owned and on else &"DimLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var pic := AssistIcon.new(id)
	pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(pic)
	var tip := Label.new()
	tip.text = str(RoadText.ASSIST_SHORT.get(id, ""))
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.custom_minimum_size = Vector2(0, 26)
	tip.theme_type_variation = &"DimLabel"
	box.add_child(tip)
	if owned:
		var btn := Button.new()
		btn.text = "LIGADA" if on else "DESLIGADA"
		btn.tooltip_text = "clique para %s" % ("desligar (mais desafio)" if on else "ligar")
		btn.set_meta(&"focus_key", "assist:" + id)
		btn.custom_minimum_size = Vector2(0, 15)
		if on:
			btn.theme_type_variation = &"PrimaryButton"
		btn.pressed.connect(func() -> void:
			GameState.set_assist(id, not on)
			Sound.ui("click")
			refresh())
		box.add_child(btn)
	else:
		var stop := EconMath.road_stop(id)
		var lock := HBoxContainer.new()
		lock.alignment = BoxContainer.ALIGNMENT_CENTER
		lock.add_theme_constant_override(&"separation", 2)
		lock.add_child(_kid_rect("lock", 12))
		var l := Label.new()
		l.text = "na estrada: %d" % int(stop.get("stars", 0))
		l.theme_type_variation = &"MoneyLabel"
		lock.add_child(l)
		lock.add_child(_kid_rect("star_on", 10))
		box.add_child(lock)
		card.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_toggle_balloon(id))
	return card


# --- aba FROTA ---------------------------------------------------------------------------------------------------

## Pista com 10 vagas (um drone por vaga) + cartoes Drone e Piloto automatico. Antes da parada: cadeado e o lugar
## na estrada.
func _add_fleet() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", 6)
	_body.add_child(col)
	var open := GameState.road_reached.has("fleet")
	var n := int(GameState.levels.get("fleet", 0))
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override(&"separation", 16)
	top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(top)
	if open:
		top.add_child(_fleet_card("fleet", "drone", "Drone %d/10" % n, "faz entregas sozinho e traz moedas"))
		var ap := _fleet_card("autopilot", "drone_coin", "Piloto automático", "os drones trazem mais moedas")
		if not (GameState.road_reached.has("autopilot") and n > 0):
			ap.modulate = Color(0.62, 0.62, 0.7)
		top.add_child(ap)
	else:
		var msg := VBoxContainer.new()
		msg.alignment = BoxContainer.ALIGNMENT_CENTER
		var lock := _kid_rect("lock", 24)
		lock.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		msg.add_child(lock)
		var l := Label.new()
		l.text = "A Frota abre na estrada com %d estrelas.\nDrones fazem entregas sozinhos\ne trazem moedas." \
				% int(EconMath.road_stop("fleet").get("stars", 0))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		msg.add_child(l)
		top.add_child(msg)
	var pads := HBoxContainer.new()                            # pista: uma vaga por drone
	pads.alignment = BoxContainer.ALIGNMENT_CENTER
	pads.add_theme_constant_override(&"separation", 12)
	col.add_child(pads)
	for i in 10:
		var slot := VBoxContainer.new()
		slot.add_theme_constant_override(&"separation", 0)
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(36, 26)
		var d := _kid_rect("drone", 24)
		d.position = Vector2(6, 2)
		d.size = Vector2(24, 24)
		holder.add_child(d)
		if i >= n:
			d.modulate = Color(0, 0, 0, 0.35)
		else:
			var tw := d.create_tween().set_loops()
			tw.tween_property(d, "position:y", -2.0, 0.7 + 0.05 * i).set_trans(Tween.TRANS_SINE)
			tw.tween_property(d, "position:y", 2.0, 0.7 + 0.05 * i).set_trans(Tween.TRANS_SINE)
		slot.add_child(holder)
		var pad := ColorRect.new()
		pad.color = UiKit.color("steel") if i < n else UiKit.color("slate")
		pad.custom_minimum_size = Vector2(36, 4)
		slot.add_child(pad)
		pads.add_child(slot)


func _fleet_card(id: String, pic: String, title: String, does: String) -> PanelContainer:
	var u := EconMath._find("upgrades", id)
	var lv := int(GameState.levels.get(id, 0))
	var mx := int(u.get("max_level", 1))
	var card := PanelContainer.new()
	card.theme_type_variation = &"SlimPanel"
	card.custom_minimum_size = Vector2(220, 0)
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.set_meta(&"row_key", "up:" + id)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 2)
	card.add_child(box)
	var top := HBoxContainer.new()
	top.add_theme_constant_override(&"separation", 4)
	top.add_child(_kid_rect(pic, 24))
	var names := VBoxContainer.new()
	names.add_theme_constant_override(&"separation", 0)
	var t := Label.new()
	t.text = title
	names.add_child(t)
	var d := Label.new()
	d.text = does
	d.theme_type_variation = &"MoneyLabel"
	names.add_child(d)
	top.add_child(names)
	box.add_child(top)
	if id == "autopilot":
		var pips := HBoxContainer.new()
		pips.add_theme_constant_override(&"separation", 2)
		for i in mx:
			pips.add_child(_pip(i < lv, i == lv))
		box.add_child(pips)
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 16)
	b.set_meta(&"focus_key", "buy:" + id)
	var reachable := GameState.can_buy(id) and EconMath.upgrade_available(id, lv, GameState.levels)
	if lv >= mx:
		b.text = "COMPLETO!"
		b.disabled = true
	elif not reachable:
		var stop := EconMath.road_stop(id)
		b.icon = UiKit.kid("lock")
		b.add_theme_constant_override(&"icon_max_width", 12)
		b.text = "compre 1 drone" if GameState.road_reached.has(id) else "na estrada: %d estrelas" % int(stop.get("stars", 0))
		b.disabled = true
	else:
		var cost := EconMath.bulk_cost(u["cost"]["credits"], lv, 1)
		b.icon = UiKit.icon("credits")
		b.text = EconMath.fmt(cost)
		b.disabled = GameState.amount("credits") < cost
		b.tooltip_text = "comprar" + _missing_text(cost)
		if not b.disabled:
			b.theme_type_variation = &"PrimaryButton"
		b.pressed.connect(func() -> void:
			var ok := GameState.buy_upgrade(id)
			Sound.ui("buy" if ok else "denied")
			if ok:
				_flash_row = "up:" + id
				_flash_money = true
				if id == "fleet" and int(GameState.levels.get("fleet", 0)) == 1:
					Sound.jingle("unlock")
			refresh())
	box.add_child(b)
	return card


# --- balao, festa ------------------------------------------------------------------------------------------------

## Balao de uma parada (clique na estrada): figura, nome, o que traz e quanto falta. Clicar de novo fecha.
func _toggle_balloon(stop_id: String) -> void:
	if _balloon.visible and _road.selected == stop_id:
		_close_balloon()
		return
	var stop := EconMath.road_stop(stop_id)
	if stop.is_empty():
		return
	Sound.ui("click")
	_road.selected = stop_id
	_road.rebuild()
	if not _road.is_visible_stop(stop_id):
		_road.center_on(RoadView.X0 + EconMath.road().find(stop) * RoadView.SPACING)
	_clear(_balloon)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)
	_balloon.add_child(row)
	var pic := TextureRect.new()
	pic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if str(stop["type"]) == "mission":                         # o ratinho de corpo inteiro
		var kind := str(RoadText._node(stop_id)["kind"])
		var frames: SpriteFrames = load("res://assets/sprites/talk_mouse_%s_frames.tres" % kind)
		pic.texture = frames.get_frame_texture(&"idle", 0)
	else:
		pic.texture = RoadText.stop_icon(stop)
		pic.custom_minimum_size = Vector2(36, 36)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(pic)
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", 2)
	col.custom_minimum_size = Vector2(170, 0)
	row.add_child(col)
	var name := Label.new()
	name.text = RoadText.stop_name(stop) + (" (%d estrelas de dificuldade)" % RoadText.stop_star(stop)
			if RoadText.stop_star(stop) > 1 else "")
	name.theme_type_variation = &"BalloonLabel"
	col.add_child(name)
	var desc := Label.new()
	desc.text = RoadText.stop_desc(stop)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.theme_type_variation = &"BalloonLabel"
	desc.custom_minimum_size = Vector2(170, 0)
	col.add_child(desc)
	var status := Label.new()
	status.theme_type_variation = &"BalloonLabel"
	status.autowrap_mode = TextServer.AUTOWRAP_WORD
	status.custom_minimum_size = Vector2(170, 0)
	var need := int(stop["stars"])
	if GameState.road_reached.has(stop_id):
		status.text = "Você já tem!"
	else:
		status.text = "Faltam %d estrelas (você tem %d). Cada entrega dá 1." % [need - GameState.stars, GameState.stars]
	col.add_child(status)
	if not GameState.road_reached.has(stop_id):
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.theme_type_variation = &"XpBar"
		bar.custom_minimum_size = Vector2(170, 6)
		bar.max_value = maxi(1, need)
		bar.value = GameState.stars
		col.add_child(bar)
	_balloon.visible = true
	_balloon.reset_size()
	_balloon.size = _balloon.get_combined_minimum_size()
	var a := _road.stop_anchor(stop_id) + _road.get_global_position() - get_global_position()
	_balloon.position = Vector2(clampf(a.x - _balloon.size.x * 0.5, 4.0, size.x - _balloon.size.x - 4.0), a.y + 30.0)


func _close_balloon() -> void:
	if not _balloon.visible:
		return
	_balloon.visible = false
	_road.selected = ""
	_road.rebuild()


## Proxima parada nova: ratinho ★1 = "Novo amiguinho!" (fecha e chama a proxima); o resto = aviso com festa.
func _show_next_news() -> void:
	if _news.is_empty() or not visible:
		return
	var id := str(_news.pop_front())
	GameState.mark_road_seen(id)
	var stop := EconMath.road_stop(id)
	if stop.is_empty():
		_show_next_news()
		return
	_road.center_on(RoadView.X0 + EconMath.road().find(stop) * RoadView.SPACING)
	_road.celebrate(id)
	_confetti()
	Sound.jingle("unlock")
	refresh()
	if str(stop["type"]) == "mission" and RoadText.stop_star(stop) == 1:
		_intro.show_kind(str(RoadText._node(id)["kind"]))
		return
	var head := "Lua completa!" if str(stop["type"]) == "final" else "Na estrada!"
	_show_toast(RoadText.stop_icon(stop), head, RoadText.stop_name(stop) + (" ★%d" % RoadText.stop_star(stop)
			if RoadText.stop_star(stop) > 1 else ""))
	get_tree().create_timer(TOAST_S + 0.2).timeout.connect(_show_next_news)


## Aviso no meio da tela: figura + titulo pequeno + texto grande; some sozinho.
func _show_toast(icon: Texture2D, small: String, big: String) -> void:
	_clear(_toast)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)
	_toast.add_child(row)
	var pic := TextureRect.new()
	pic.texture = icon
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.custom_minimum_size = Vector2(24, 24)
	row.add_child(pic)
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", 0)
	row.add_child(col)
	var a := Label.new()
	a.text = small
	a.theme_type_variation = &"DimLabel"
	col.add_child(a)
	var b := Label.new()
	b.text = big
	b.theme_type_variation = &"MoneyLabel"
	b.add_theme_font_size_override(&"font_size", UiKit.TITLE_SIZE)
	col.add_child(b)
	_toast.reset_size()
	_toast.size = _toast.get_combined_minimum_size()
	_toast.position = Vector2(roundf((size.x - _toast.size.x) * 0.5), 150)
	_toast.pivot_offset = _toast.size * 0.5
	_toast.visible = true
	_toast.modulate.a = 1.0
	_toast.scale = Vector2(0.3, 0.3)
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_toast_tween.tween_interval(TOAST_S)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.25)
	_toast_tween.tween_callback(func() -> void: _toast.visible = false)


## Chuva de papeizinhos coloridos (quadradinhos da paleta) do meio da tela.
func _confetti() -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = 48
	p.lifetime = 1.4
	p.explosiveness = 1.0
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 190.0
	p.gravity = Vector2(0, 260)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 3.0
	var g := Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	g.offsets = PackedFloat32Array()
	g.colors = PackedColorArray()
	for i in CONFETTI.size():
		g.add_point(float(i) / CONFETTI.size(), UiKit.color(CONFETTI[i]))
	p.color_initial_ramp = g
	p.position = Vector2(size.x * 0.5, 120)
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


# --- utilitarios -------------------------------------------------------------------------------------------------

func _kid_rect(name: String, px: int = 24) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = UiKit.kid(name)
	tr.custom_minimum_size = Vector2(px, px)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


## "\nfaltam X" para o tooltip de um custo que ainda nao da para pagar.
func _missing_text(cost: float) -> String:
	var miss := cost - GameState.amount("credits")
	return "" if miss <= 0.0 else "\nfaltam %s moedas" % EconMath.fmt(miss)


func _focused_key() -> String:
	var f := get_viewport().gui_get_focus_owner()
	if f != null and is_ancestor_of(f) and f.has_meta(&"focus_key"):
		return str(f.get_meta(&"focus_key"))
	return ""


## Depois de refazer: brilho da compra e foco (mesmo botao se o jogador usa teclado; senao DECOLAR).
func _after_rebuild(focus_key: String) -> void:
	for n: Node in _body.find_children("*", "Control", true, false):
		if _flash_row != "" and n.get_meta(&"row_key", "") == _flash_row:
			UiKit.pulse(n as CanvasItem)
	_flash_row = ""
	if _keyboard_nav and focus_key != "":
		for b: Node in find_children("*", "Button", true, false):
			if b.get_meta(&"focus_key", "") == focus_key and not b.is_queued_for_deletion():
				(b as Button).grab_focus.call_deferred()
				return
	if not _launch.disabled and visible:
		_launch.grab_focus.call_deferred()


func _clear(box: Node) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func _planet_name(id: String) -> String:
	for p: Dictionary in EconMath.spec["planets"]:
		if p["id"] == id:
			return str(p["name"]).to_upper()
	return id.to_upper()


## Valor de stat: 2 casas abaixo de 10, 1 casa ate 1000, depois K/M/B.
func _num(v: float) -> String:
	if v >= 1000.0:
		return EconMath.fmt(v)
	if v < 10.0:
		return "%.2f" % v
	return str(int(v)) if is_equal_approx(v, roundf(v)) else "%.1f" % v
