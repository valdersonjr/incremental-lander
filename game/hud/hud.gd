## HUD do voo (arte: UiKit): gas (barra ciano -> ambar -> vermelho), velocidades com cor de seguranca,
## altitude, distancia ao alvo (seta aponta o lado), creditos e entregas; resultado do pouso em aviso central.
class_name Hud
extends Control

const TOAST_SECONDS := 2.5
const CONTROLS_HINT := "W/Espaço: propulsor   A/D: girar   R: reiniciar"

var flight: Flight = null
var run: RunState = null

var _status := ""
var _toast_left := 0.0

@onready var _gas: Label = %Gas
@onready var _gas_bar: ProgressBar = %GasBar
@onready var _vy: Label = %Vy
@onready var _vx: Label = %Vx
@onready var _alt: Label = %Alt
@onready var _dist: Label = %Dist
@onready var _msg: Label = %Message
@onready var _credits: Label = %Credits
@onready var _deliveries: Label = %Deliveries
@onready var _dist_icon: TextureRect = %DistIcon
@onready var _toast: Control = %Toast
@onready var _toast_title: Label = %ToastTitle
@onready var _toast_text: Label = %ToastText


func _ready() -> void:
	(%GasIcon as TextureRect).texture = UiKit.icon("gas")
	(%DistIcon as TextureRect).texture = UiKit.icon("distance")
	(%MoneyIcon as TextureRect).texture = UiKit.icon("credits")
	(%DeliveriesIcon as TextureRect).texture = UiKit.icon("expedition")


## Liga o HUD a uma cena de voo e ao run atual (referencias atribuidas pelo pai).
func bind(p_flight: Flight, p_run: RunState) -> void:
	flight = p_flight
	run = p_run
	flight.delivery_finished.connect(_on_delivery_finished)
	flight.lander.took_off.connect(func() -> void: _status = CONTROLS_HINT)   # resultado antigo nao fica no rodape
	_status = CONTROLS_HINT


func _process(delta: float) -> void:
	_tick_toast(delta)
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
		var dx := WorldConfig.px_to_m(float(pad["x"]) - l.global_position.x)
		_dist.text = "ALVO %d m" % int(absf(dx))
		_dist_icon.flip_h = dx < 0.0                           # a seta aponta para o lado da plataforma
	else:
		_dist.text = "escolha uma entrega"
		_dist_icon.flip_h = false
	_msg.text = _status
	_credits.text = EconMath.fmt(GameState.amount("credits"))
	_deliveries.text = "%d/%d" % [run.deliveries.size(), run.max_deliveries] if run != null else ""


func _set_speed(label: Label, value: float, limit: float) -> void:
	label.text = "%.1f m/s" % value
	label.theme_type_variation = &"GoodLabel" if value <= limit * 0.6 else (&"MoneyLabel" if value <= limit
			else &"BadLabel")


func _on_delivery_finished(result: Dictionary) -> void:
	if result["crashed"]:
		var why := UiKit.crash_text(str(result["reason"]))
		_status = "BATEU: %s  -  R para tentar de novo" % why
		_show_toast("BATEU!", why, &"BadLabel")
	else:
		_status = "ENTREGA! qualidade %d%%   gás usado %.1f" % [int(result["quality"] * 100.0), result["gas_used"]]
		_show_toast("ENTREGA!", "qualidade %d%%   gás usado %.1f" % [int(result["quality"] * 100.0),
				result["gas_used"]], &"GoodLabel")


## Aviso grande no centro (o momento mais importante do voo nao pode ficar so no rodape).
func _show_toast(title: String, text: String, variation: StringName) -> void:
	_toast_title.text = title
	_toast_title.add_theme_color_override(&"font_color", get_theme_color(&"font_color", variation))
	_toast_text.text = text
	_toast.modulate.a = 1.0
	_toast.visible = true
	_toast_left = TOAST_SECONDS


func _tick_toast(delta: float) -> void:
	if _toast_left <= 0.0:
		return
	_toast_left -= delta
	_toast.modulate.a = clampf(_toast_left / 0.5, 0.0, 1.0)  # some no ultimo meio segundo
	if _toast_left <= 0.0:
		_toast.visible = false
