## Geracao do relevo em poligono (deterministica por seed) — logica pura, testavel.
## Coordenadas em pixels do mundo; y cresce para baixo; plataforma de partida em x = 0.
class_name TerrainGen
extends RefCounted


## Gera {"ridge": PackedVector2Array, "pads": Array[Dictionary], "polygon": PackedVector2Array}.
## pad_distances_m: distancias (m do modelo) das plataformas a partir da partida (a partida e sempre criada).
## pad_tiers: tipo de cada plataforma de entrega (mesma ordem; faltando = "normal") -> largura e elevacao
## (world.json terrain.pad_tiers: plataforma estreita num vale, apertada no alto de um pico).
## Entre plataformas seguidas ergue uma CRISTA (terrain.crest): um arco bom passa por cima, voar rente nao.
## extend = px extras alem da margem (x: a esquerda, y: a direita) — o Flight estende quando a nave chega perto da
## borda. O relevo e ancorado em x = 0 (grade e limite de inclinacao correm de 0 para cada lado): estender ou criar
## plataformas novas NUNCA muda os pontos que ja existiam.
static func generate(seed_value: int, planet_id: String, pad_distances_m: Array[float],
		pad_tiers: Array[String] = [], extend: Vector2 = Vector2.ZERO) -> Dictionary:
	var cfg: Dictionary = WorldConfig.load_config()["terrain"]
	var pcfg: Dictionary = cfg["planets"].get(planet_id, cfg["planets"]["luna"])
	var step := WorldConfig.m_to_px(cfg["step_m"])
	var margin := WorldConfig.m_to_px(cfg["margin_m"])
	var amp := WorldConfig.m_to_px(pcfg["amplitude_m"])
	var max_slope: float = cfg["max_slope"]

	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = float(pcfg["frequency"]) / WorldConfig.m_to_px(1.0)
	noise.fractal_octaves = int(pcfg["octaves"])

	var pad_xs: Array[float] = [0.0]
	var tiers: Array[String] = ["normal"]
	for i in pad_distances_m.size():
		pad_xs.append(WorldConfig.m_to_px(pad_distances_m[i]))
		tiers.append(pad_tiers[i] if i < pad_tiers.size() else "normal")
	var k_min := floori((-margin - extend.x) / step)
	var k_max := ceili((pad_xs.max() + margin + extend.y) / step)
	var x_min := k_min * step
	var x_max := k_max * step

	# relevo de base: de 0 para a direita e de 0 para a esquerda, limitando a inclinacao a partir da ancora
	var right := PackedVector2Array()
	var prev_y := -noise.get_noise_1d(0.0) * amp
	for k in range(0, k_max + 1):
		var y := clampf(-noise.get_noise_1d(k * step) * amp, prev_y - max_slope * step, prev_y + max_slope * step)
		right.append(Vector2(k * step, y))
		prev_y = y
	var left := PackedVector2Array()
	prev_y = right[0].y
	for k in range(-1, k_min - 1, -1):
		var y := clampf(-noise.get_noise_1d(k * step) * amp, prev_y - max_slope * step, prev_y + max_slope * step)
		left.append(Vector2(k * step, y))
		prev_y = y
	left.reverse()
	var ridge := left + right

	# plataformas: largura e elevacao do tipo; altura decidida no relevo de base (antes das cristas)
	var side_slope: float = cfg["pad_side_slope"]
	var pads: Array[Dictionary] = []
	for i in pad_xs.size():
		var tc: Dictionary = cfg["pad_tiers"].get(tiers[i], cfg["pad_tiers"]["normal"])
		var half := WorldConfig.m_to_px(float(tc["width_m"])) * 0.5
		var lift := WorldConfig.m_to_px(float(tc["lift_m"]))
		# pico/vale precisa de espaco ate a plataforma ANTERIOR (so ela: uma plataforma nunca muda quando outra e
		# criada depois — o lander pode estar pousado nela); perto demais -> plataforma no nivel do relevo
		var reach := half + absf(lift) / side_slope + WorldConfig.m_to_px(10.0)
		if i > 0:
			var prev: Dictionary = pads[i - 1]
			var prev_reach := float(prev["half_width"]) + absf(float(prev["lift"])) / side_slope
			if pad_xs[i] - pad_xs[i - 1] < reach + prev_reach:
				lift = 0.0
		pads.append({"id": i, "x": pad_xs[i], "half_width": half, "y": _height_at(ridge, pad_xs[i]) - lift,
				"tier": tiers[i], "lift": lift})
	for i in pads.size() - 1:
		_add_crest(ridge, pads[i], pads[i + 1], cfg["crest"], pcfg)
	for p in pads:
		_shape_pad(ridge, p, side_slope)
	for k in range(pads.size() - 1, -1, -1):                   # topo plano garantido; a mais antiga ganha
		var p: Dictionary = pads[k]
		for j in ridge.size():
			if absf(ridge[j].x - float(p["x"])) <= float(p["half_width"]) + 0.001:
				ridge[j] = Vector2(ridge[j].x, float(p["y"]))
	# garante as bordas exatas das plataformas no contorno
	for p in pads:
		ridge = _insert_point(ridge, Vector2(p["x"] - p["half_width"], p["y"]))
		ridge = _insert_point(ridge, Vector2(p["x"] + p["half_width"], p["y"]))

	var bottom := WorldConfig.m_to_px(cfg["bottom_m"])
	var lowest := 0.0
	for pt in ridge:
		lowest = maxf(lowest, pt.y)
	var polygon := PackedVector2Array(ridge)
	polygon.append(Vector2(x_max, lowest + bottom))
	polygon.append(Vector2(x_min, lowest + bottom))
	return {"ridge": ridge, "pads": pads, "polygon": polygon}


## Crista entre duas plataformas seguidas: lombada em cosseno no meio do trecho, com o pico pelo menos
## frac x distancia acima da plataforma mais alta (o arco de 45 graus sobe 1/4 da distancia: passa com folga).
## A inclinacao da lombada e limitada (max_bump_slope) para a arte e o pouso continuarem legiveis.
static func _add_crest(ridge: PackedVector2Array, a: Dictionary, b: Dictionary, crest: Dictionary,
		pcfg: Dictionary) -> void:
	var d := float(b["x"]) - float(a["x"])
	if d < WorldConfig.m_to_px(float(crest["min_distance_m"])):
		return
	var h := minf(float(crest["frac"]) * d, WorldConfig.m_to_px(float(pcfg["crest_max_m"])))
	var w := float(crest["half_width_frac"]) * d
	var mid := (float(a["x"]) + float(b["x"])) * 0.5
	var peak_y := minf(float(a["y"]), float(b["y"])) - h        # y cresce para baixo
	var extra := minf(_height_at(ridge, mid) - peak_y, float(crest["max_bump_slope"]) * w / (PI * 0.5))
	if extra <= 0.0:
		return
	for j in ridge.size():
		var dx := ridge[j].x - mid
		if absf(dx) < w:
			ridge[j].y -= extra * (0.5 + 0.5 * cos(PI * dx / w))


## Pico (lift > 0) ou vale (lift < 0) em volta da plataforma: topo plano + encostas com side_slope.
static func _shape_pad(ridge: PackedVector2Array, p: Dictionary, side_slope: float) -> void:
	var lift := float(p["lift"])
	var cx := float(p["x"])
	var half := float(p["half_width"])
	var py := float(p["y"])
	for j in ridge.size():
		var dx := absf(ridge[j].x - cx)
		if dx <= half + 0.001:
			ridge[j].y = py
		elif lift > 0.0:
			ridge[j].y = minf(ridge[j].y, py + (dx - half) * side_slope)
		elif lift < 0.0:
			ridge[j].y = maxf(ridge[j].y, py - (dx - half) * side_slope)


## Ponto mais alto do relevo (menor y) entre x_a e x_b — usado pelo piloto automatico para nao raspar cristas.
static func highest_between(ridge: PackedVector2Array, x_a: float, x_b: float) -> float:
	var lo := minf(x_a, x_b)
	var hi := maxf(x_a, x_b)
	var best := minf(_height_at(ridge, lo), _height_at(ridge, hi))
	for pt in ridge:
		if pt.x > lo and pt.x < hi:
			best = minf(best, pt.y)
	return best


## Altura do relevo (y) na posicao x, interpolando o contorno.
static func height_at(ridge: PackedVector2Array, x: float) -> float:
	return _height_at(ridge, x)


## Plataforma que contem x (ou {} se nenhuma).
static func pad_at(pads: Array[Dictionary], x: float) -> Dictionary:
	for p in pads:
		if absf(x - float(p["x"])) <= float(p["half_width"]):
			return p
	return {}


static func _height_at(ridge: PackedVector2Array, x: float) -> float:
	if x <= ridge[0].x:
		return ridge[0].y
	for i in range(1, ridge.size()):
		if ridge[i].x >= x:
			var a := ridge[i - 1]
			var b := ridge[i]
			var t := (x - a.x) / maxf(b.x - a.x, 0.0001)
			return lerpf(a.y, b.y, t)
	return ridge[ridge.size() - 1].y


static func _insert_point(ridge: PackedVector2Array, p: Vector2) -> PackedVector2Array:
	for i in ridge.size():
		if absf(ridge[i].x - p.x) < 0.001:
			ridge[i] = p
			return ridge
		if ridge[i].x > p.x:
			ridge.insert(i, p)
			return ridge
	ridge.append(p)
	return ridge
