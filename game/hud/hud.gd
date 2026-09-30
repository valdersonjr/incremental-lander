## HUD do voo (placeholder de texto): gas, velocidades com cor de seguranca, altitude, distancia ao alvo.
class_name Hud
extends Control

const COLOR_OK := Color("#1ebc73")      # emerald
const COLOR_WARN := Color("#f9c22b")    # gold
const COLOR_BAD := Color("#e83b3b")     # red
const COLOR_TEXT := Color("#c7dcd0")    # mist

var flight: Flight = null
var _status := ""

@onready var _gas: Label = %Gas
@onready var _vy: Label = %Vy
@onready var _vx: Label = %Vx
@onready var _alt: Label = %Alt
@onready var _dist: Label = %Dist
@onready var _msg: Label = %Message


## Liga o HUD a uma cena de voo (referencia atribuida pelo pai).
func bind(p_flight: Flight) -> void:
	flight = p_flight
	flight.delivery_finished.connect(_on_delivery_finished)
	_status = "W/Espaco: propulsor  A/D: girar  R: reiniciar"


func _process(_delta: float) -> void:
	if flight == null:
		return
	var l := flight.lander
	var cfg: Dictionary = WorldConfig.load_config()
	var tol := LandingRules.tolerances(cfg["landing"], float(l.params.get("gear", 1.0)))
	_gas.text = "GAS %s / %s" % [EconMath.fmt(l.gas), EconMath.fmt(float(l.params.get("tank", 0.0)))]
	_set_speed(_vy, "V.VERT", l.vel_m.y, tol["max_vy"])
	_set_speed(_vx, "V.HOR ", absf(l.vel_m.x), tol["max_vx"])
	var ground := TerrainGen.height_at(flight.terrain.ridge, l.global_position.x)
	_alt.text = "ALT %d m" % int(WorldConfig.px_to_m(ground - l.global_position.y))
	var pad := flight.target_pad()
	_dist.text = "ALVO %d m" % int(WorldConfig.px_to_m(float(pad["x"]) - l.global_position.x))
	_msg.text = _status


func _set_speed(label: Label, title: String, value: float, limit: float) -> void:
	label.text = "%s %.1f m/s" % [title, value]
	var c := COLOR_OK if value <= limit * 0.6 else (COLOR_WARN if value <= limit else COLOR_BAD)
	label.add_theme_color_override(&"font_color", c)


func _on_delivery_finished(result: Dictionary) -> void:
	if result["crashed"]:
		_status = "BATEU (%s) - R para tentar de novo" % result["reason"]
	else:
		_status = "ENTREGA! qualidade %d%% - gas usado %.1f" % [int(result["quality"] * 100.0), result["gas_used"]]
