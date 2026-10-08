## Teste de viabilidade dos minijogos (auditoria 2026-10-07): monta a Flight real de cada mundo em varias seeds,
## distancias e estrelas e confere a GEOMETRIA gerada (o minigame_flow teleporta a nave; este garante que da para
## jogar de verdade). Imprime MINIGAME_GEOMETRY_TEST OK ou FALHOU com o primeiro caso de cada regra.
extends Node

const FLIGHT_SCENE := preload("res://game/flight/flight.tscn")
const KIND := {"luna": "simple", "nuvens": "passenger", "cogumelos": "soft", "sorvete": "fast", "jardim": "heavy",
		"bolhas": "tow"}
const SEEDS := 6
const DISTANCES: Array[float] = [250.0, 700.0, 2000.0]

var _fails: Dictionary = {}                                 # regra -> primeiro caso que falhou


func _check(rule: String, cond: bool, where: String) -> void:
	if not cond and not _fails.has(rule):
		_fails[rule] = where


func _ready() -> void:
	await get_tree().process_frame
	var stats := EconMath.ship_stats({"thrust": 30, "tank": 20, "efficiency": 10})
	for w: String in KIND:
		for star in [1, 2, 3]:
			for dist: float in DISTANCES:
				for s in SEEDS:
					var f: Flight = FLIGHT_SCENE.instantiate()
					add_child(f)
					f.start(w, 7, stats, false)
					var k: String = KIND[w]
					f.begin_mission(100 + s * 17, dist, "normal", 1 if s % 2 == 0 else -1,
							{"kind": k, "star": star, "parts": [{"kind": k, "star": star}]})
					call("_check_" + w, f, star, "%s ★%d d=%d seed=%d" % [w, star, int(dist), s])
					f.free()
	_check_sorvete_rules()
	var ok := _fails.is_empty()
	var msg: Array[String] = []
	for r: String in _fails:
		msg.append("%s (%s)" % [r, _fails[r]])
	print("MINIGAME_GEOMETRY_TEST " + ("OK" if ok else "FALHOU " + "; ".join(msg)))
	get_tree().quit(0 if ok else 1)


func dist_m(f: Flight) -> float:
	return f.target_distance_m


func _ground(f: Flight, x: float) -> float:
	return TerrainGen.height_at(f.terrain.ridge, x)


## Lua: queijinhos acima do chao com folga e no maximo max_extra_lift_m acima do arco ideal (cabe na tela).
func _check_luna(f: Flight, star: int, where: String) -> void:
	var cfg := Minigames.spec("luna")
	var a: Dictionary = f.terrain.pads[f.current_pad_id]
	var b: Dictionary = f.terrain.pads[f.target_pad_id]
	var ideal := Minigames.trail_points(a, b, f._trail.size(), 1.0)
	for i in f._trail.size():
		var p: Vector2 = f._trail[i]["pos"]
		_check("lua_queijinho_acima_do_chao", _ground(f, p.x) - p.y >= 18.0, where)
		_check("lua_trilha_cabe_na_tela", ideal[i].y - p.y <= WorldConfig.m_to_px(float(cfg.get("max_extra_lift_m", 1e9))) + 1.0,
				where)


## Nuvens: so os carneirinhos marcados ficam dentro de uma corrente; os outros ficam longe dela.
func _check_nuvens(f: Flight, star: int, where: String) -> void:
	var cfg := Minigames.spec("nuvens")
	var want := int(Minigames.by_star(cfg.get("updraft_sheep", [0]), star))
	var clear := WorldConfig.m_to_px(float(cfg.get("updraft_clear_m", 0.0)))
	var inside := 0
	for c: Dictionary in f._sheep:
		var p: Vector2 = c["pos"]
		var near := 1e9
		var half := 0.0
		for u: Dictionary in f._updrafts:
			if absf(p.x - float(u["x"])) < near:
				near = absf(p.x - float(u["x"]))
				half = float(u["half"])
		if near <= half:
			inside += 1
		elif dist_m(f) >= 600.0:                               # salto curto: basta ficar fora da corrente
			_check("nuvens_carneirinho_longe_da_corrente", near >= half + clear - 1.0, where)
		_check("nuvens_carneirinho_acima_do_chao", _ground(f, p.x) - p.y >= 20.0, where)
	_check("nuvens_carneirinhos_na_corrente_pela_estrela", inside == mini(want, f._sheep.size()), where)


## Cogumelos: escada que leva ao alvo (ultimo chapeu acima da plataforma alvo) e chapeus acima do chao.
func _check_cogumelos(f: Flight, _star: int, where: String) -> void:
	var b: Dictionary = f.terrain.pads[f.target_pad_id]
	var last: Dictionary = f._caps[-1]
	_check("cogumelos_ultimo_chapeu_acima_do_alvo", float(b["y"]) - float(last["y"]) >= 15.0, where)
	for c: Dictionary in f._caps:
		_check("cogumelos_chapeu_acima_do_chao", _ground(f, float(c["x"])) - float(c["y"]) >= 20.0, where)


## Jardim: o vao de cada caule tem o tamanho da estrela inteiro (o chao nao corta) e fica acima do chao.
func _check_jardim(f: Flight, star: int, where: String) -> void:
	var gap := WorldConfig.m_to_px(float(Minigames.by_star(Minigames.spec("jardim")["gap_m"], star)))
	for st: Dictionary in f._stems:
		_check("jardim_vao_inteiro", float(st["gap_bot"]) - float(st["gap_top"]) >= gap - 1.0, where)
		_check("jardim_vao_acima_do_chao", _ground(f, float(st["x"])) - float(st["gap_bot"]) >= 9.0, where)


## Bolhas: bau sempre debaixo d'agua e alcancavel com folga entre a nave e o mar (garra pendurada reta).
func _check_bolhas(f: Flight, _star: int, where: String) -> void:
	var cfg := Minigames.spec("bolhas")
	var wy := float(f._water["y"])
	var feet := WorldConfig.m_to_px(float(WorldConfig.load_config()["lander"]["feet_offset_m"]))
	var depth := f._chest_pos.y - wy
	_check("bolhas_bau_na_agua", depth >= WorldConfig.m_to_px(5.0), where + " depth=%.1f wy=%.1f pads=%.1f/%.1f gy=%.1f" % [depth, wy,
			float(f.terrain.pads[f.current_pad_id]["y"]), float(f.terrain.pads[f.target_pad_id]["y"]), _ground(f, f._chest_pos.x)])
	var ship_y := f._chest_pos.y - f._tow.rope_px - feet - WorldConfig.m_to_px(float(cfg.get("grab_m", 10.0)))
	_check("bolhas_folga_nave_mar", wy - ship_y >= WorldConfig.m_to_px(20.0), where)


## Sorvete: pista de gelo do tamanho certo.
func _check_sorvete(f: Flight, _star: int, where: String) -> void:
	var b: Dictionary = f.terrain.pads[f.target_pad_id]
	_check("sorvete_pista_larga", WorldConfig.px_to_m(float(b["half_width"])) >= 100.0, where)


## Sorvete: o deslize minimo cabe no anel mais apertado (pousar no centro devagar ainda pontua).
func _check_sorvete_rules() -> void:
	var cfg := Minigames.spec("sorvete")
	var v := float(cfg["min_slide_mps"])
	var slide := v * v / (2.0 * float(cfg["friction_mps2"]))
	_check("sorvete_deslize_minimo_cabe_no_anel_apertado", slide < float(cfg["ring_m"]["tight"]), "%.1f m" % slide)
