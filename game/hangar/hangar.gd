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

@onready var _header: Label = %Header
@onready var _ship: Label = %Ship
@onready var _rows: VBoxContainer = %Rows
@onready var _launch: Button = %Launch


func _ready() -> void:
	_launch.pressed.connect(func() -> void: launch_requested.emit())


## Mostra o hangar atualizado.
func open() -> void:
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
	for r: Dictionary in GameState.upgrade_rows():
		_rows.add_child(_make_row(r))


func _make_row(r: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	var buy := Button.new()
	buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var cost_txt := []
	for res: String in r["cost"]:
		cost_txt.append("%s %s" % [EconMath.fmt(float(r["cost"][res])), "cr" if res == "credits" else res])
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
