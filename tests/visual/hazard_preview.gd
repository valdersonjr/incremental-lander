## Previa dos perigos por mundo (Fase 11.5): voo real congelado com a camera num perigo, no aviso ou ligado.
## gdtool.py capture res://tests/visual/hazard_preview.tscn --frames 60 --every 20 -- --planet=ares|kronos|titan
##   [--zone=N] [--phase=on|warn]
extends Node

const FLIGHT := preload("res://game/flight/flight.tscn")


func _ready() -> void:
	WorldConfig.register_input()
	Telemetry.enabled = false
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var planet := str(args.get("planet", "ares"))
	var flight := FLIGHT.instantiate() as Flight
	add_child(flight)
	var stats := EconMath.ship_stats({"thrust": 40, "tank": 30})
	flight.start(planet, 7, stats, false)
	flight.set_target(3000.0, "normal")
	var zi := int(args.get("zone", "0"))
	var z: Dictionary = flight._zones[mini(zi, flight._zones.size() - 1)]
	# relogio no instante pedido (ligado ou aviso)
	var want := str(args.get("phase", "on"))
	var t := 0.0
	while Hazards.cycle(z, t) == want and t < 60.0:             # sai da fase atual para pegar o INICIO da pedida
		t += 0.05
	while Hazards.cycle(z, t) != want and t < 60.0:
		t += 0.05
	if want == "on" and z["type"] == "toy":
		t += 0.6                                              # brinquedo no meio da queda
	if want == "on" and z["type"] == "geyser":
		t += 0.5                                              # coluna ja crescida
	flight._hz_t = t
	var focus: Vector2 = (z["rect"] as Rect2).get_center() if z.has("rect") else Vector2(float(z["x"]), float(z["ground"]) - 120.0)
	if z["type"] == "toy" and want == "on":
		focus = Hazards.toy_pos(z, t) + Vector2(0, 60)        # enquadra o bloco caindo
	var l := flight.lander
	l.set_physics_process(false)
	l.state = Lander.State.FLYING
	l.global_position = focus + Vector2(-60, 0)
	flight.set_physics_process(false)
	flight.camera.global_position = l.global_position
	flight.set_camera_lift(0.0)
	flight._hazard_view.t = t
	var half := get_viewport().get_visible_rect().size * 0.5
	flight._hazard_view.view = Rect2(l.global_position - half, half * 2.0)
	flight._hazard_view.zones = flight._zones
	print("HAZARD_PREVIEW ", planet, " ", z["type"], " ", want, " t=", t)
