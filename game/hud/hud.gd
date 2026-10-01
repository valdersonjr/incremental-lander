## HUD do voo (arte: UiKit): gas (barra ciano -> ambar -> vermelho), velocidades com cor de seguranca,
## altitude, distancia ao alvo, creditos e entregas.
class_name Hud
extends Control

var flight: Flight = null
var run: RunState = null
var _status := ""

@onready var _gas: Label = %Gas
@onready var _gas_bar: ProgressBar = %GasBar
@onready var _vy: Label = %Vy
@onready var _vx: Label = %Vx
@onready var _alt: Label = %Alt
@onready var _dist: Label = %Dist
@onready var _msg: Label = %Message
@onready var _credits: Label = %Credits
@onready var _deliveries: Label = %Deliveries


func _ready() -> void:
	(%GasIcon as TextureRect).texture = UiKit.icon("gas")
	(%DistIcon as TextureRect).texture = UiKit.icon("distance")
	(%MoneyIcon as TextureRect).texture = UiKit.icon("credits")


## Liga o HUD a uma cena de voo e ao run atual (referencias atribuidas pelo pai).
func bind(p_flight: Flight, p_run: RunState) -> void:
	flight = p_flight
	run = p_run
	flight.delivery_finished.connect(_on_delivery_finished)
	_status = "W/Espaço: propulsor   A/D: girar   R: reiniciar"


func _process(_delta: float) -> void:
	if flight == null:
		return
	var l := flight.lander
	var cfg: Dictionary = WorldConfig.load_config()
	var tol := LandingRules.tolerances(cfg["landing"], float(l.params.get("gear", 1.0)))
	var tank := float(l.params.get("tank", 0.0))
	var frac := l.gas / tank if tank > 0.0 else 0.0
	_gas.text = EconMath.fmt(l.gas)
	_gas_bar.value = frac * 100.0
	_gas_bar.theme_type_variation = &"GasBar" if frac > 0.35 else (&"WarnBar" if frac > 0.15 else &"DangerBar")
	_set_speed(_vy, l.vel_m.y, tol["max_vy"])
	_set_speed(_vx, absf(l.vel_m.x), tol["max_vx"])
	var ground := TerrainGen.height_at(flight.terrain.ridge, l.global_position.x)
	_alt.text = "%d m" % int(WorldConfig.px_to_m(ground - l.global_position.y))
	if flight.target_pad_id >= 0:
		var pad := flight.target_pad()
		_dist.text = "ALVO %d m" % int(WorldConfig.px_to_m(float(pad["x"]) - l.global_position.x))
	else:
		_dist.text = "escolha uma entrega"
	_msg.text = _status
	_credits.text = EconMath.fmt(GameState.amount("credits"))
	_deliveries.text = "%d/%d" % [run.deliveries.size(), run.max_deliveries] if run != null else ""


func _set_speed(label: Label, value: float, limit: float) -> void:
	label.text = "%.1f m/s" % value
	label.theme_type_variation = &"GoodLabel" if value <= limit * 0.6 else (&"MoneyLabel" if value <= limit
			else &"BadLabel")


func _on_delivery_finished(result: Dictionary) -> void:
	if result["crashed"]:
		_status = "BATEU (%s) - R para tentar de novo" % result["reason"]
	else:
		_status = "ENTREGA! qualidade %d%%   gás usado %.1f" % [int(result["quality"] * 100.0), result["gas_used"]]
