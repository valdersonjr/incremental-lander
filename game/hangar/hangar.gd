## Hangar entre runs: comprar upgrades (clique/Enter no botao; "max" compra o maximo) e decolar.
## Tudo que e numero vem de GameState/EconMath. Placeholder de UI (sem arte ainda).
class_name Hangar
extends PanelContainer

signal launch_requested

const UNITS := {"thrust": "m/s2", "tank": "gas", "efficiency": "m/s/gas", "pay_mult": "x", "gear": "x",
		"drones": "", "autopilot": "x"}
const COLOR_TITLE := Color("#fbb954")    # honey
const COLOR_TEXT := Color("#c7dcd0")     # mist
const COLOR_DIM := Color("#7f708a")      # lilac_grey
const COLOR_DUST := Color("#a884f3")     # violet (Poeira Estelar)

var _confirm_prestige := false

@onready var _header: Label = %Header
@onready var _ship: Label = %Ship
@onready var _rows: VBoxContainer = %Rows
@onready var _launch: Button = %Launch


func _ready() -> void:
	_launch.pressed.connect(func() -> void: launch_requested.emit())


## Mostra o hangar atualizado.
func open() -> void:
	_confirm_prestige = false
	visible = true
	refresh()
	_launch.grab_focus()


func refresh() -> void:
	var planet := GameState.current_planet
	var res := "%s cr" % EconMath.fmt(GameState.amount("credits"))
	if GameState.amount("ore") > 0.0:
		res += "   %s minerio" % EconMath.fmt(GameState.amount("ore"))
	_header.text = "HANGAR  -  %s        %s" % [planet.to_upper(), res]
	var s := GameState.ship_stats()
	var reach := Purchases.max_reach_m(planet, s, float(s["tank"]))
	_ship.text = "motor %.1f m/s2   tanque %s gas   bocais %.2f m/s/gas   alcance max ~%s m (ideal)" % [
			float(s["thrust"]), EconMath.fmt(float(s["tank"])), float(s["efficiency"]), EconMath.fmt(reach)]
	for c in _rows.get_children():
		c.queue_free()
	if GameState.prestige_pending:
		_add_pending_prestige()
		return
	_launch.disabled = false
	_rows.add_child(_section("PLANETAS"))
	for p: Dictionary in GameState.planet_rows():
		if p["unlocked"] or p["available"]:
			_rows.add_child(_make_planet_row(p))
	_add_prestige_section()
	_rows.add_child(_section("UPGRADES"))
	for r: Dictionary in GameState.upgrade_rows():
		_rows.add_child(_make_row(r))


## Secao de prestigio + loja da Poeira (aparece depois de Ares ou quando ja houve prestigio).
func _add_prestige_section() -> void:
	var dust_id: String = EconMath.spec["prestige"]["resource"]
	var req: String = EconMath.spec["prestige"].get("requires_planet", "")
	if GameState.prestige_points <= 0.0 and not req in GameState.unlocked_planets:
		return
	var bonus := 0.0
	for b: Dictionary in EconMath.spec["prestige"]["bonuses"]:
		if b["stat"] == "pay_mult":
			bonus = float(b["per_point"]) * GameState.prestige_points * 100.0
	var head := _section("PRESTIGIO   Poeira Estelar: %s   nivel %s (+%d%% pagamento)" % [
			EconMath.fmt(GameState.amount(dust_id)), EconMath.fmt(GameState.prestige_points), int(bonus)])
	head.add_theme_color_override(&"font_color", COLOR_DUST)
	_rows.add_child(head)
	var st := GameState.prestige_state()
	var g := Prestige.gain(st)
	var b := Button.new()
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override(&"font_size", 10)
	if Prestige.can_prestige(st):
		b.text = ("CONFIRMA? recomecar do zero por +%s Poeira (clique de novo)" if _confirm_prestige
				else "Recomecar (prestigio): +%s Poeira Estelar") % EconMath.fmt(g)
		b.pressed.connect(func() -> void:
			if _confirm_prestige:
				_confirm_prestige = false
				GameState.begin_prestige()
			else:
				_confirm_prestige = true
			refresh())
	else:
		b.text = "Recomecar: +%s Poeira agora (minimo %s) - ganhe mais creditos neste ciclo" % [
				EconMath.fmt(g), EconMath.fmt(float(EconMath.spec["prestige"].get("min_gain", 1)))]
		b.disabled = true
	_rows.add_child(b)
	if GameState.prestige_points <= 0.0:
		return
	_add_shop(st)


## Recomeco em andamento: so a loja + concluir (o reset usa o que foi comprado).
func _add_pending_prestige() -> void:
	_launch.disabled = true
	var head := _section("RECOMECO: gaste sua Poeira Estelar na loja e conclua. O progresso comum sera zerado.")
	head.add_theme_color_override(&"font_color", COLOR_DUST)
	_rows.add_child(head)
	_add_shop(GameState.prestige_state())
	var done := Button.new()
	done.text = "CONCLUIR RECOMECO"
	done.add_theme_font_size_override(&"font_size", 12)
	done.pressed.connect(func() -> void:
		GameState.finish_prestige()
		refresh())
	_rows.add_child(done)


func _add_shop(st: Dictionary) -> void:
	var dust_id: String = EconMath.spec["prestige"]["resource"]
	var shop_head := _section("LOJA DA POEIRA   (%s disponivel)" % EconMath.fmt(GameState.amount(dust_id)))
	shop_head.add_theme_color_override(&"font_color", COLOR_DUST)
	_rows.add_child(shop_head)
	for r: Dictionary in Prestige.shop_rows(st):
		var sb := Button.new()
		sb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		sb.add_theme_font_size_override(&"font_size", 10)
		var lvl := "MAX" if r["maxed"] else "nv %d/%d" % [int(r["level"]), int(r["max_level"])]
		sb.text = "%s  %s   %s" % [r["name"], lvl, "" if r["maxed"] else "%s poeira" % EconMath.fmt(float(r["cost"]))]
		sb.disabled = not r["affordable"]
		var id: String = r["id"]
		sb.pressed.connect(func() -> void:
			GameState.buy_shop_item(id)
			refresh())
		_rows.add_child(sb)


func _section(title: String) -> Label:
	var l := Label.new()
	l.text = title
	l.add_theme_font_size_override(&"font_size", 10)
	l.add_theme_color_override(&"font_color", COLOR_TITLE)
	return l


func _make_planet_row(p: Dictionary) -> Button:
	var b := Button.new()
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override(&"font_size", 10)
	var id: String = p["id"]
	var info := "gravidade %.2f   pagamento x%s" % [float(p["gravity"]), EconMath.fmt(float(p["pay_mult"]))]
	if id == GameState.current_planet:
		b.text = "> %s (atual)   %s" % [p["name"], info]
		b.disabled = true
	elif p["unlocked"]:
		if p["can_fly"]:
			b.text = "Voar em %s   %s" % [p["name"], info]
			b.pressed.connect(func() -> void:
				GameState.current_planet = id
				refresh())
		else:
			b.text = "%s: motor fraco para esta gravidade (compre Motor)   %s" % [p["name"], info]
			b.disabled = true
	else:
		var cost_txt := []
		for res: String in p["cost"]:
			cost_txt.append("%s %s" % [EconMath.fmt(float(p["cost"][res])), _res_label(res)])
		b.text = "Liberar %s   %s   %s" % [p["name"], " + ".join(cost_txt), info]
		b.disabled = not p["affordable"]
		b.pressed.connect(func() -> void:
			GameState.unlock_planet(id)
			refresh())
	return b


func _make_row(r: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	var buy := Button.new()
	buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var cost_txt := []
	for res: String in r["cost"]:
		cost_txt.append("%s %s" % [EconMath.fmt(float(r["cost"][res])), _res_label(res)])
	var unit: String = UNITS.get(r["stat"], "")
	var ms := ""
	if not (r["milestone"] as Dictionary).is_empty():
		ms = "  (marco nv %d: pag x%s)" % [int(r["milestone"]["level"]), str(r["milestone"]["mult"])]
	buy.text = "%s  nv %d   %s -> %s %s   %s%s" % [r["name"], int(r["level"]), _num(r["current"]),
			_num(r["next"]), unit, " + ".join(cost_txt), ms]
	buy.disabled = not r["affordable"]
	buy.add_theme_font_size_override(&"font_size", 10)
	var id: String = r["id"]
	buy.pressed.connect(func() -> void:
		GameState.buy_upgrade(id)
		refresh())
	var mx := Button.new()
	mx.text = "max"
	mx.disabled = not r["affordable"]
	mx.add_theme_font_size_override(&"font_size", 10)
	mx.pressed.connect(func() -> void:
		GameState.buy_upgrade_max(id)
		refresh())
	row.add_child(buy)
	row.add_child(mx)
	return row


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"confirm"):
		get_viewport().set_input_as_handled()
		launch_requested.emit()


func _num(v: float) -> String:
	return EconMath.fmt(v) if v >= 1000.0 else ("%.2f" % v if v < 10.0 else "%.1f" % v)


func _res_label(res: String) -> String:
	return {"credits": "cr", "ore": "minerio", "stardust": "poeira"}.get(res, res)
