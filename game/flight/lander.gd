## Lander: fisica propria (LanderPhysics) em unidades do modelo, pouso/batida por LandingRules.
## Controlado pelo teclado ou por um Autopilot (modo --demo). Placeholder desenhado com _draw().
class_name Lander
extends CharacterBody2D

signal took_off
signal landed(pad: Dictionary, quality: float, info: Dictionary)
signal crashed(reason: String, info: Dictionary)

enum State {LANDED, FLYING, CRASHED}

const COLOR_HULL := Color("#9babb2")    # steel
const COLOR_DARK := Color("#2e222f")    # ink
const COLOR_GLASS := Color("#4d9be6")   # sky
const COLOR_LEGS := Color("#625565")    # slate
const COLOR_FLAME := Color("#f79617")   # amber
const COLOR_CORE := Color("#f9c22b")    # gold

var state: State = State.LANDED
var vel_m := Vector2.ZERO               # velocidade em m/s do modelo
var gas := 0.0
var params: Dictionary = {}             # gravity, thrust, efficiency, drag, tank, gear
var pads: Array[Dictionary] = []
var autopilot: Autopilot = null
var thrusting := false
var flight_time_m := 0.0                # segundos do modelo desde a decolagem
var gas_at_takeoff := 0.0


## Configura a nave (stats do EconMath + planeta da spec) e as plataformas do terreno.
func setup(stats: Dictionary, planet: Dictionary, terrain_pads: Array[Dictionary]) -> void:
	params = {
		"gravity": float(planet["gravity"]),
		"drag": float(planet.get("drag", 0.0)) * 0.02,
		"thrust": float(stats["thrust"]),
		"efficiency": float(stats["efficiency"]),
		"tank": float(stats["tank"]),
		"gear": float(stats.get("gear", 1.0)),
	}
	gas = params["tank"]
	pads = terrain_pads
	state = State.LANDED
	vel_m = Vector2.ZERO
	rotation = 0.0


func _physics_process(delta: float) -> void:
	if state == State.CRASHED:
		return
	var cfg: Dictionary = WorldConfig.load_config()
	var controls := _read_controls()
	if state == State.LANDED:
		if controls["thrust"] and gas > 0.0:
			state = State.FLYING
			flight_time_m = 0.0
			gas_at_takeoff = gas
			took_off.emit()
		else:
			thrusting = false
			queue_redraw()
			return
	rotation += float(controls["rotate"]) * float(cfg["rotate_speed"]) * delta
	var dt_m := delta * float(cfg["time_scale"])
	var r := LanderPhysics.step(vel_m, rotation, controls["thrust"], gas, params, dt_m)
	vel_m = r["velocity"]
	gas = r["gas"]
	thrusting = float(r["gas_used"]) > 0.0
	flight_time_m += dt_m
	# recovery_as_collision=true: encostado e descendo devagar tambem conta como toque (senao o pouso lento nunca e detectado)
	var col := move_and_collide(vel_m * float(cfg["px_per_m"]) * dt_m, false, 0.08, true)
	if col:
		_on_touch()
	queue_redraw()


func _draw() -> void:
	var w := WorldConfig.m_to_px(float(WorldConfig.load_config()["lander"]["half_width_m"]))
	var feet := WorldConfig.m_to_px(float(WorldConfig.load_config()["lander"]["feet_offset_m"]))
	if thrusting:
		var flicker := 3.0 + float(Engine.get_physics_frames() % 3)
		draw_colored_polygon(PackedVector2Array([Vector2(-3, 4), Vector2(3, 4), Vector2(0, 8 + flicker * 2.0)]), COLOR_FLAME)
		draw_colored_polygon(PackedVector2Array([Vector2(-1.5, 4), Vector2(1.5, 4), Vector2(0, 6 + flicker)]), COLOR_CORE)
	draw_line(Vector2(-w + 2, 2), Vector2(-w, feet), COLOR_LEGS, 1.0)
	draw_line(Vector2(w - 2, 2), Vector2(w, feet), COLOR_LEGS, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-5, 4), Vector2(-6, -2), Vector2(-3, -7), Vector2(3, -7),
			Vector2(6, -2), Vector2(5, 4)]), COLOR_HULL)
	draw_rect(Rect2(-2, -5, 4, 3), COLOR_GLASS)
	if state == State.CRASHED:
		draw_circle(Vector2.ZERO, 9.0, Color("#e83b3b"))


## Estado do voo atual (m/s do modelo, rad, gas gasto desde a decolagem, tempo do modelo).
func info() -> Dictionary:
	return {"vx": vel_m.x, "vy": vel_m.y, "tilt": wrapf(rotation, -PI, PI),
			"gas_used": gas_at_takeoff - gas, "flight_time_m": flight_time_m}


func _read_controls() -> Dictionary:
	if autopilot != null:
		return autopilot.control(global_position, vel_m, rotation, params)
	return {
		"rotate": Input.get_axis(&"rotate_left", &"rotate_right"),
		"thrust": Input.is_action_pressed(&"thrust"),
	}


func _on_touch() -> void:
	var cfg: Dictionary = WorldConfig.load_config()
	var half := WorldConfig.m_to_px(float(cfg["lander"]["half_width_m"]))
	var pad := TerrainGen.pad_at(pads, global_position.x)
	var on_pad := not pad.is_empty() and absf(global_position.x - float(pad["x"])) <= float(pad["half_width"]) - half * 0.5
	var tol := LandingRules.tolerances(cfg["landing"], float(params["gear"]))
	var inf := info()
	var reason := LandingRules.crash_reason(inf["vy"], inf["vx"], inf["tilt"], on_pad, tol)
	if reason == "":
		var offset := (global_position.x - float(pad["x"])) / float(pad["half_width"])
		var q := LandingRules.quality(inf["vy"], inf["vx"], inf["tilt"], offset, tol, cfg["landing"]["weights"])
		state = State.LANDED
		vel_m = Vector2.ZERO
		thrusting = false
		landed.emit(pad, q, inf)
	else:
		state = State.CRASHED
		thrusting = false
		crashed.emit(reason, inf)
