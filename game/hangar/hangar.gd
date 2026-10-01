## Hangar entre runs (arte: UiKit, cor de destaque do mundo atual): comprar upgrades (COMPRAR / MAX), planetas,
## prestigio + loja da Poeira, Expedicao, opcoes e decolar. Tudo que e numero vem de GameState/EconMath.
class_name Hangar
extends PanelContainer

signal launch_requested

const UNITS := {"thrust": "m/s2", "tank": "gás", "efficiency": "m/s/gás", "pay_mult": "×", "gear": "×",
		"drones": "", "autopilot": "×"}
const ICONS := {"thrust": "thrust", "tank": "tank", "efficiency": "efficiency", "contracts": "reputation",
		"gear": "gear", "refinery": "refinery", "fleet": "fleet", "autopilot": "autopilot"}
const RES := {"credits": ["credits", "MoneyLabel"], "ore": ["ore", "ValueLabel"], "stardust": ["stardust", "DustLabel"]}

var _confirm_prestige := false
var _confirm_new_game := false

@onready var _planet: Label = %Planet
@onready var _resources: HBoxContainer = %Resources
@onready var _ship: HBoxContainer = %Ship
@onready var _rows: VBoxContainer = %Rows
@onready var _launch: Button = %Launch


func _ready() -> void:
	_launch.pressed.connect(func() -> void: launch_requested.emit())


## Mostra o hangar atualizado.
func open() -> void:
	_confirm_prestige = false
	_confirm_new_game = false
	visible = true
	refresh()
	_launch.grab_focus()


func refresh() -> void:
	var planet := GameState.current_planet
	theme = UiKit.theme_for(planet)                            # a cor do hangar acompanha o mundo atual
	_planet.text = _planet_name(planet)
	_clear(_resources)
	_resources.add_child(UiKit.icon_label("credits", EconMath.fmt(GameState.amount("credits")), &"MoneyLabel"))
	if GameState.amount("ore") > 0.0:
		_resources.add_child(UiKit.icon_label("ore", EconMath.fmt(GameState.amount("ore")), &"ValueLabel"))
	var dust_id: String = EconMath.spec["prestige"]["resource"]
	if GameState.amount(dust_id) > 0.0:
		_resources.add_child(UiKit.icon_label("stardust", EconMath.fmt(GameState.amount(dust_id)), &"DustLabel"))
	var s := GameState.ship_stats()
	var reach := Purchases.max_reach_m(planet, s, float(s["tank"]))
	_clear(_ship)
	_ship.add_child(UiKit.icon_label("thrust", "motor %.1f m/s2" % float(s["thrust"])))
	_ship.add_child(UiKit.icon_label("tank", "tanque %s gás" % EconMath.fmt(float(s["tank"]))))
	_ship.add_child(UiKit.icon_label("efficiency", "bocais %.2f m/s/gás" % float(s["efficiency"])))
	_ship.add_child(UiKit.icon_label("distance", "alcance máx ~%s m" % EconMath.fmt(reach)))
	_clear(_rows)
	if GameState.prestige_pending:
		_add_pending_prestige()
		return
	_launch.disabled = false
	_rows.add_child(_section("PLANETAS"))
	for p: Dictionary in GameState.planet_rows():
		if p["unlocked"] or p["available"]:
			_rows.add_child(_make_planet_row(p))
	_add_prestige_section()
	var rows := GameState.upgrade_rows()
	var stages := rows.filter(func(r: Dictionary) -> bool: return _is_stage(str(r["id"])))
	if not stages.is_empty() or _stages_done() > 0:
		_add_expedition(stages)
	_rows.add_child(_section("UPGRADES"))
	for r: Dictionary in rows:
		if not _is_stage(str(r["id"])):
			_rows.add_child(_make_row(r))
	_add_options()


func _clear(box: Node) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func _planet_name(id: String) -> String:
	for p: Dictionary in EconMath.spec["planets"]:
		if p["id"] == id:
			return str(p["name"]).to_upper()
	return id.to_upper()


## Opcoes: volume por bus (clique alterna 100/75/50/25/0%) e novo jogo (2 cliques).
func _add_options() -> void:
	_rows.add_child(_section("OPÇÕES"))
	var line := HBoxContainer.new()
	line.add_theme_constant_override(&"separation", 3)
	var names := {"Music": "Música", "Ambience": "Ambiente", "SFX": "Efeitos", "UI": "Interface"}
	for bus: String in GameState.BUSES:
		var b := Button.new()
		b.icon = UiKit.icon("options") if bus == "Music" else null
		b.text = "%s %d%%" % [names[bus], int(round(GameState.volume(bus) * 100.0))]
		b.pressed.connect(func() -> void:
			var v := GameState.volume(bus) - 0.25
			GameState.set_volume(bus, 1.0 if v < -0.01 else v)
			SaveManager.request_save()
			refresh())
		line.add_child(b)
	var ng := Button.new()
	ng.text = "CONFIRMA? apagar todo o progresso" if _confirm_new_game else "Novo jogo"
	ng.pressed.connect(func() -> void:
		if _confirm_new_game:
			_confirm_new_game = false
			SaveManager.new_game()
		else:
			_confirm_new_game = true
		refresh())
	line.add_child(ng)
	_rows.add_child(line)


func _is_stage(id: String) -> bool:
	for u: Dictionary in EconMath.spec["upgrades"]:
		if u["id"] == id:
			return bool(u.get("progress", false))
	return false


func _stages_done() -> int:
	var n := 0
	for u: Dictionary in EconMath.spec["upgrades"]:
		if u.get("progress", false) and int(GameState.levels.get(u["id"], 0)) > 0:
			n += 1
	return n


## Expedicao ao Quarto: barra de progresso (gradiente de meta) + proxima etapa.
func _add_expedition(stages: Array) -> void:
	var total := 0
	for u: Dictionary in EconMath.spec["upgrades"]:
		if u.get("progress", false):
			total += 1
	var done := _stages_done()
	var head := HBoxContainer.new()
	head.add_theme_constant_override(&"separation", 6)
	head.add_child(_section("EXPEDIÇÃO AO QUARTO"))
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(120, 8)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.max_value = total
	bar.value = done
	head.add_child(bar)
	var n := Label.new()
	n.text = "%d/%d" % [done, total]
	n.theme_type_variation = &"ValueLabel"
	head.add_child(n)
	_rows.add_child(head)
	for r: Dictionary in stages:
		_rows.add_child(_make_row(r))


## Secao de prestigio + loja da Poeira (aparece depois do 2o mundo ou quando ja houve prestigio).
func _add_prestige_section() -> void:
	var dust_id: String = EconMath.spec["prestige"]["resource"]
	var req: String = EconMath.spec["prestige"].get("requires_planet", "")
	if GameState.prestige_points <= 0.0 and not req in GameState.unlocked_planets:
		return
	var bonus := 0.0
	for b: Dictionary in EconMath.spec["prestige"]["bonuses"]:
		if b["stat"] == "pay_mult":
			bonus = float(b["per_point"]) * GameState.prestige_points * 100.0
	var head := UiKit.icon_label("prestige", "PRESTÍGIO   Poeira Estelar %s   nível %s (+%d%% pagamento)" % [
			EconMath.fmt(GameState.amount(dust_id)), EconMath.fmt(GameState.prestige_points), int(bonus)], &"DustLabel")
	_rows.add_child(head)
	var st := GameState.prestige_state()
	var g := Prestige.gain(st)
	var b := Button.new()
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.icon = UiKit.icon("stardust")
	if Prestige.can_prestige(st):
		b.text = ("CONFIRMA? recomeçar do zero por +%s Poeira (clique de novo)" if _confirm_prestige
				else "Recomeçar (prestígio): +%s Poeira Estelar") % EconMath.fmt(g)
		b.pressed.connect(func() -> void:
			if _confirm_prestige:
				_confirm_prestige = false
				GameState.begin_prestige()
			else:
				_confirm_prestige = true
			refresh())
	else:
		b.text = "Recomeçar: +%s Poeira agora (mínimo %s) - ganhe mais créditos neste ciclo" % [
				EconMath.fmt(g), EconMath.fmt(float(EconMath.spec["prestige"].get("min_gain", 1)))]
		b.disabled = true
	_rows.add_child(b)
	if GameState.prestige_points <= 0.0:
		return
	_add_shop(st)


## Recomeco em andamento: so a loja + concluir (o reset usa o que foi comprado).
func _add_pending_prestige() -> void:
	_launch.disabled = true
	var head := Label.new()
	head.text = "RECOMEÇO: gaste sua Poeira Estelar na loja e conclua. O progresso comum será zerado."
	head.theme_type_variation = &"DustLabel"
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rows.add_child(head)
	_add_shop(GameState.prestige_state())
	var done := Button.new()
	done.text = "CONCLUIR RECOMEÇO"
	done.theme_type_variation = &"PrimaryButton"
	done.pressed.connect(func() -> void:
		GameState.finish_prestige()
		refresh())
	_rows.add_child(done)


func _add_shop(st: Dictionary) -> void:
	var dust_id: String = EconMath.spec["prestige"]["resource"]
	_rows.add_child(UiKit.icon_label("stardust", "LOJA DA POEIRA   (%s disponível)" % EconMath.fmt(
			GameState.amount(dust_id)), &"DustLabel"))
	for r: Dictionary in Prestige.shop_rows(st):
		var sb := Button.new()
		sb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		sb.icon = UiKit.icon("prestige")
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
	l.theme_type_variation = &"SectionLabel"
	return l


func _make_planet_row(p: Dictionary) -> Button:
	var b := Button.new()
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.icon = UiKit.icon("planet")
	var id: String = p["id"]
	var info := "gravidade %.2f   pagamento ×%s" % [float(p["gravity"]), EconMath.fmt(float(p["pay_mult"]))]
	if id == GameState.current_planet:
		b.text = "%s (atual)   %s" % [p["name"], info]
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


## Linha de upgrade: icone | nome (+ marco) | nivel | atual > proximo | COMPRAR (custo) | MAX
func _make_row(r: Dictionary) -> HBoxContainer:
	var id: String = r["id"]
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 4)
	var ic := TextureRect.new()
	ic.texture = UiKit.icon("expedition" if _is_stage(id) else ICONS.get(id, "options"))
	ic.custom_minimum_size = Vector2(12, 12)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	row.add_child(ic)
	var name := Label.new()
	name.text = str(r["name"])
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.clip_text = true
	if not (r["milestone"] as Dictionary).is_empty():
		name.tooltip_text = "marco no nível %d: pagamento ×%s" % [int(r["milestone"]["level"]), str(r["milestone"]["mult"])]
		name.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(name)
	var lv := Label.new()
	lv.text = "nv %d" % int(r["level"])
	lv.theme_type_variation = &"DimLabel"
	lv.custom_minimum_size = Vector2(34, 0)
	row.add_child(lv)
	var eff := Label.new()
	var unit: String = UNITS.get(r["stat"], "")
	eff.text = "%s > %s %s" % [_num(r["current"]), _num(r["next"]), unit]
	eff.theme_type_variation = &"ValueLabel"
	eff.custom_minimum_size = Vector2(118, 0)
	row.add_child(eff)
	var buy := Button.new()
	var cost_txt := []
	for res: String in r["cost"]:
		cost_txt.append(EconMath.fmt(float(r["cost"][res])) + ("" if res == "credits" else " " + _res_label(res)))
	buy.text = " + ".join(cost_txt)
	buy.icon = UiKit.icon(RES.get(r["cost"].keys()[0], ["credits"])[0]) if not (r["cost"] as Dictionary).is_empty() else null
	buy.custom_minimum_size = Vector2(78, 15)
	buy.alignment = HORIZONTAL_ALIGNMENT_LEFT
	buy.disabled = not r["affordable"]
	buy.pressed.connect(func() -> void:
		GameState.buy_upgrade(id)
		refresh())
	row.add_child(buy)
	var mx := Button.new()
	mx.text = "MAX"
	mx.custom_minimum_size = Vector2(30, 15)
	mx.disabled = not r["affordable"]
	mx.pressed.connect(func() -> void:
		GameState.buy_upgrade_max(id)
		refresh())
	row.add_child(mx)
	return row


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"confirm"):
		get_viewport().set_input_as_handled()
		launch_requested.emit()


func _num(v: float) -> String:
	return EconMath.fmt(v) if v >= 1000.0 else ("%.2f" % v if v < 10.0 else "%.1f" % v)


func _res_label(res: String) -> String:
	return {"credits": "cr", "ore": "minério", "stardust": "poeira"}.get(res, res)
