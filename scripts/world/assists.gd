## Geometria das ajudas de voo (Painel de bordo) — logica pura, testavel.
## arc(): arco ideal de 45 graus entre duas plataformas (o de menor gasto de gas), usado pelo Rastro e pela Rota.
## fall(): queda prevista sem motor a partir do estado atual (Onde vou cair), com a mesma fisica do Lander.
## arrow_tier()/verdict(): cor da Setinha e veredito do ponto de queda.
## Parametros em data/world.json > assists. Quem tem cada ajuda: GameState.assist_on(id).
class_name Assists
extends RefCounted


## Pontos (px do mundo, centro do lander) do arco da plataforma a ate b, das pontas inclusive.
static func arc(a: Dictionary, b: Dictionary, count: int) -> Array[Vector2]:
	var cfg: Dictionary = WorldConfig.load_config()
	var k := float(cfg["assists"]["arc_k"])
	var feet := WorldConfig.m_to_px(float(cfg["lander"]["feet_offset_m"]))
	var d := float(b["x"]) - float(a["x"])
	var out: Array[Vector2] = []
	for i in count + 1:
		var u := float(i) / float(count)
		var y := lerpf(float(a["y"]), float(b["y"]), u) - absf(d) * u * (1.0 - u) * k - feet
		out.append(Vector2(float(a["x"]) + d * u, y))
	return out


## Trajetoria sem motor (px do mundo) a partir de pos_px com velocidade vel_m (m/s do modelo), ate os pes tocarem o
## relevo (ultimo ponto = onde toca) ou acabar o tempo. params = Lander.params (gravity, planet_drag).
## Devolve {"points": Array[Vector2], "hit": bool, "vel": Vector2 (m/s no toque)}.
static func fall(pos_px: Vector2, vel_m: Vector2, params: Dictionary, ridge: PackedVector2Array) -> Dictionary:
	var cfg: Dictionary = WorldConfig.load_config()
	var ac: Dictionary = cfg["assists"]
	var dt := float(ac["predict_dt_m"])
	var ppm := float(cfg["px_per_m"])
	var feet := WorldConfig.m_to_px(float(cfg["lander"]["feet_offset_m"]))
	var p := {"gravity": params["gravity"], "thrust": 0.0, "efficiency": 1.0, "drag": 0.0}
	var pos := pos_px
	var vel := vel_m
	var pts: Array[Vector2] = [pos]
	for i in int(float(ac["predict_max_s"]) / dt):
		var ground := TerrainGen.height_at(ridge, pos.x)
		p["drag"] = LanderPhysics.drag_at(float(params.get("planet_drag", 0.0)), (ground - pos.y - feet) / ppm, cfg)
		vel = LanderPhysics.step(vel, 0.0, false, 0.0, p, dt)["velocity"]
		var nxt := pos + vel * ppm * dt
		var g2 := TerrainGen.height_at(ridge, nxt.x)
		if nxt.y + feet >= g2:
			# corta o passo onde os pes encostam no chao (interpolacao linear da folga)
			var gap0 := ground - (pos.y + feet)
			var gap1 := g2 - (nxt.y + feet)
			var t := clampf(gap0 / maxf(gap0 - gap1, 0.001), 0.0, 1.0)
			pts.append(pos.lerp(nxt, t))
			return {"points": pts, "hit": true, "vel": vel}
		pos = nxt
		pts.append(pos)
	return {"points": pts, "hit": false, "vel": vel}


## Cor da Setinha colorida pela fracao do salto que ainda falta: "far" | "mid" | "near".
static func arrow_tier(frac_left: float) -> String:
	var ac: Dictionary = WorldConfig.load_config()["assists"]
	if frac_left <= float(ac["near_frac"]):
		return "near"
	return "mid" if frac_left <= float(ac["mid_frac"]) else "far"


## Veredito da queda prevista (resultado de fall): "good" (cai na plataforma alvo dentro dos limites de velocidade),
## "hard" (cai na plataforma alvo, mas rapido demais), "miss" (fora dela) ou "" (nao toca o chao no tempo previsto).
static func verdict(f: Dictionary, target: Dictionary, half_lander_px: float, tol: Dictionary) -> String:
	if not f["hit"]:
		return ""
	var x: float = (f["points"] as Array[Vector2])[-1].x
	if target.is_empty() or absf(x - float(target["x"])) > float(target["half_width"]) - half_lander_px * 0.5:
		return "miss"
	var v: Vector2 = f["vel"]
	return "good" if v.y <= float(tol["max_vy"]) and absf(v.x) <= float(tol["max_vx"]) else "hard"


## "Da pra chegar?": gas que deve sobrar ao chegar se o salto for feito pelo arco ideal (marquinha na barra de gas).
## gas_start = gas na decolagem (ou o gas de agora, ainda pousado). Negativo = nao chega.
static func gas_left_at_arrival(planet_id: String, distance_m: float, stats: Dictionary, gas_start: float) -> float:
	return gas_start - EconMath.estimated_hop_dv(planet_id, distance_m, stats) / float(stats["efficiency"])
