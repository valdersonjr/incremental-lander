## Teste da sensacao do voo (auditoria do voo 2026-10-11) com a Flight real: raspao devagar fora da plataforma quica e
## o voo segue; o 3o raspao (ou um forte) explode; pouso um fio alem da tolerancia vale como pouso duro.
## Imprime FLIGHT_FEEL_TEST OK ou FALHOU.
extends Node

const FLIGHT_SCENE := preload("res://game/flight/flight.tscn")

var _log: Array[String] = []
var _ok := true
var _scrapes := 0
var _crash := ""
var _landed := {}


func _check(what: String, cond: bool) -> void:
	_log.append("%s=%s" % [what, cond])
	_ok = _ok and cond


func _ready() -> void:
	Telemetry.enabled = false
	await get_tree().process_frame
	var f := await _flight()
	var l: Lander = f.lander
	# 1) raspao devagar no chao entre as plataformas
	await _drop(f, _off_pad_x(f), Vector2(1.0, 5.0))
	_check("raspao_quica", _scrapes == 1 and _crash == "" and l.state == Lander.State.FLYING)
	_check("raspao_sobe", l.vel_m.y < 0.0)
	# 2) dois raspoes depois do primeiro: o 3o explode (per_hop = 2)
	await _drop(f, _off_pad_x(f), Vector2(0.0, 5.0))
	_check("segundo_raspao", _scrapes == 2 and _crash == "")
	await _drop(f, _off_pad_x(f), Vector2(0.0, 5.0))
	_check("terceiro_explode", _crash == "fora_da_plataforma")
	f.free()
	# 3) raspao forte explode na hora
	f = await _flight()
	await _drop(f, _off_pad_x(f), Vector2(0.0, 25.0))
	_check("forte_explode", _scrapes == 0 and _crash == "fora_da_plataforma")
	f.free()
	# 4) pouso duro na plataforma alvo: vy = 1,1 x tolerancia (a gravidade soma um pouco ate o toque)
	f = await _flight()
	var tol := LandingRules.tolerances(WorldConfig.load_config()["landing"], float(f.lander.params["gear"]))
	var pad: Dictionary = f.terrain.pads[f.target_pad_id]
	await _drop(f, float(pad["x"]), Vector2(0.0, float(tol["max_vy"]) * 1.1))
	_check("pouso_duro_vale", _crash == "" and bool(_landed.get("hard", false)))
	f.free()
	# 5) e 1,4 x tolerancia ainda bate
	f = await _flight()
	pad = f.terrain.pads[f.target_pad_id]
	await _drop(f, float(pad["x"]), Vector2(0.0, float(tol["max_vy"]) * 1.4))
	_check("muito_duro_bate", _crash == "vertical_rapido")
	f.free()
	print("FLIGHT_FEEL_TEST " + ("OK" if _ok else "FALHOU") + " " + " ".join(_log))
	get_tree().quit(0 if _ok else 1)


func _flight() -> Flight:
	_scrapes = 0
	_crash = ""
	_landed = {}
	var f: Flight = FLIGHT_SCENE.instantiate()
	add_child(f)
	f.start("luna", 7, EconMath.ship_stats({}), false)
	f.begin_mission(11, 700.0, "normal", 1, {"kind": "simple", "star": 1, "parts": [{"kind": "simple", "star": 1}]})
	for tw in get_tree().get_processed_tweens():               # pula a chegada (a nave descendo do ceu)
		tw.kill()
	f.lander.arriving = false
	await get_tree().physics_frame
	f.lander.ground_rest = false
	f.lander.scraped.connect(func(n: int, _at: Vector2) -> void: _scrapes = n)
	f.lander.crashed.connect(func(r: String, _i: Dictionary) -> void: _crash = r)
	f.lander.landed.connect(func(_p: Dictionary, _q: float, i: Dictionary) -> void: _landed = i)
	return f


## x no meio do caminho, longe das plataformas.
func _off_pad_x(f: Flight) -> float:
	var a: Dictionary = f.terrain.pads[f.current_pad_id]
	var b: Dictionary = f.terrain.pads[f.target_pad_id]
	return lerpf(float(a["x"]), float(b["x"]), 0.5)


## Solta a nave em voo, reta, 2 px acima do chao em x, com velocidade vel (m/s), e espera o toque. Antes espera a
## carencia do raspao anterior passar (contatos logo depois de um raspao so quicam, nao contam).
func _drop(f: Flight, x: float, vel: Vector2) -> void:
	var l: Lander = f.lander
	for i in 24:
		await get_tree().physics_frame
	var feet := WorldConfig.m_to_px(float(WorldConfig.load_config()["lander"]["feet_offset_m"]))
	l.state = Lander.State.FLYING
	l.arriving = false
	l.rotation = 0.0
	l.global_position = Vector2(x, TerrainGen.height_at(f.terrain.ridge, x) - feet - 2.0)
	l.vel_m = vel
	l.gas = 50.0
	var before := _scrapes
	for i in 30:
		await get_tree().physics_frame
		if _scrapes != before or _crash != "" or not _landed.is_empty():
			return
