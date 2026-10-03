## Perigos por mundo (Fase 11.5) — logica pura, testavel. Zonas de um salto geradas por seed (world.json hazards):
##  gust   (Silvania)  faixa do ceu na altura do arco; rajada lateral liga/desliga em ciclo (aviso antes);
##  geyser (Doces)     coluna de calda que nasce do chao em ciclo: freia e empurra para cima (pega quem voa baixo);
##  fan    (Quarto)    coluna de ar do ventilador: empurra para cima o tempo todo (ajuda quem sabe usar);
##  toy    (Quarto)    brinquedo cai numa coluna em ciclo (aviso antes); encostar destroi a nave.
## Coordenadas em px do mundo; tempo em SEGUNDOS REAIS (avisos que o jogador consegue ler); forcas em m/s2 do modelo.
## Lua: nenhum perigo.
class_name Hazards
extends RefCounted


## Zonas do salto da plataforma a ate b. ridge = contorno do terreno (px).
static func generate(seed_value: int, planet_id: String, a: Dictionary, b: Dictionary,
		ridge: PackedVector2Array) -> Array[Dictionary]:
	var all: Dictionary = WorldConfig.load_config()["hazards"]
	var out: Array[Dictionary] = []
	if not all.has(planet_id):
		return out
	var specs: Array = all[planet_id] if all[planet_id] is Array else [all[planet_id]]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, int(a["x"]), int(b["x"]), planet_id])
	var d := float(b["x"]) - float(a["x"])
	if absf(d) < WorldConfig.m_to_px(250.0):
		return out                                             # salto curto: so pousar ja e o desafio
	for s: Dictionary in specs:
		var n := rng.randi_range(int(s["count"][0]), int(s["count"][1]))
		for i in n:
			var u := lerpf(0.25, 0.75, (i + rng.randf_range(0.2, 0.8)) / float(n))
			var x := float(a["x"]) + d * u
			var ground := TerrainGen.height_at(ridge, x)
			var arc_y := lerpf(float(a["y"]), float(b["y"]), u) - absf(d) * u * (1.0 - u)
			var z := {"type": s["type"], "phase": rng.randf_range(0.0, float(s.get("period_s", 1.0)))}
			match str(s["type"]):
				"gust":
					var w := WorldConfig.m_to_px(rng.randf_range(s["width_m"][0], s["width_m"][1]))
					var h := WorldConfig.m_to_px(rng.randf_range(s["height_m"][0], s["height_m"][1]))
					z["rect"] = Rect2(x - w * 0.5, arc_y - h * 0.5, w, h)
					z["accel"] = Vector2(float(s["accel"]) * (1.0 if rng.randf() < 0.5 else -1.0), 0.0)
				"geyser":
					var hm := clampf(absf(WorldConfig.px_to_m(d)) * float(s["height_frac"]), s["height_m"][0], s["height_m"][1])
					var w := WorldConfig.m_to_px(float(s["width_m"]))
					var h := WorldConfig.m_to_px(hm)
					z["rect"] = Rect2(x - w * 0.5, ground - h, w, h)
					z["drag"] = float(s["drag"])
					z["accel"] = Vector2(0.0, -float(s["lift"]))
				"fan":
					var w := WorldConfig.m_to_px(float(s["width_m"]))
					var h := WorldConfig.m_to_px(rng.randf_range(s["height_m"][0], s["height_m"][1]))
					z["rect"] = Rect2(x - w * 0.5, ground - h, w, h)
					z["accel"] = Vector2(0.0, -float(s["accel"]))
				"toy":
					z["x"] = x
					z["top"] = arc_y - WorldConfig.m_to_px(float(s["drop_m"]))
					z["ground"] = ground
					z["radius"] = WorldConfig.m_to_px(float(s["radius_m"]))
					z["speed"] = (ground - float(z["top"])) / float(s["fall_s"])   # px por segundo real
			for k in ["period_s", "on_s", "warn_s"]:
				if s.has(k):
					z[k] = float(s[k])
			out.append(z)
	return out


## Fase do ciclo: "off", "warn" (aviso, ainda sem efeito) ou "on". Zonas sem ciclo (fan) estao sempre "on".
static func cycle(z: Dictionary, t: float) -> String:
	if not z.has("period_s"):
		return "on"
	var p := fposmod(t + float(z["phase"]), float(z["period_s"]))
	if z["type"] == "toy":
		var fall := (float(z["ground"]) - float(z["top"])) / float(z["speed"])
		if p < float(z["warn_s"]):
			return "warn"
		return "on" if p < float(z["warn_s"]) + fall else "off"
	var on := float(z["on_s"])
	if p < on:
		return "on"
	return "warn" if p > float(z["period_s"]) - float(z["warn_s"]) else "off"


## Posicao do brinquedo caindo (px) no instante t, ou Vector2.INF se nao esta caindo.
static func toy_pos(z: Dictionary, t: float) -> Vector2:
	if cycle(z, t) != "on":
		return Vector2.INF
	var p := fposmod(t + float(z["phase"]), float(z["period_s"])) - float(z["warn_s"])
	return Vector2(float(z["x"]), float(z["top"]) + p * float(z["speed"]))


## Efeito das zonas no lander em pos (px) no instante t: {"accel": Vector2 m/s2, "drag": 1/s, "lethal": motivo|""}.
static func effect_at(zones: Array[Dictionary], pos: Vector2, t: float) -> Dictionary:
	var accel := Vector2.ZERO
	var drag := 0.0
	var lethal := ""
	for z in zones:
		if cycle(z, t) != "on":
			continue
		if z["type"] == "toy":
			if toy_pos(z, t).distance_to(pos) <= float(z["radius"]):
				lethal = "atingido"
		elif (z["rect"] as Rect2).has_point(pos):
			accel += z["accel"]
			drag += float(z.get("drag", 0.0))
	return {"accel": accel, "drag": drag, "lethal": lethal}
