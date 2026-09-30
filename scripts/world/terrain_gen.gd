## Geracao do relevo em poligono (deterministica por seed) — logica pura, testavel.
## Coordenadas em pixels do mundo; y cresce para baixo; plataforma de partida em x = 0.
class_name TerrainGen
extends RefCounted


## Gera {"ridge": PackedVector2Array, "pads": Array[Dictionary], "polygon": PackedVector2Array}.
## pad_distances_m: distancias (m do modelo) das plataformas a partir da partida (a partida e sempre criada).
static func generate(seed_value: int, planet_id: String, pad_distances_m: Array[float]) -> Dictionary:
	var cfg: Dictionary = WorldConfig.load_config()["terrain"]
	var pcfg: Dictionary = cfg["planets"].get(planet_id, cfg["planets"]["luna"])
	var step := WorldConfig.m_to_px(cfg["step_m"])
	var pad_half := WorldConfig.m_to_px(cfg["pad_width_m"]) * 0.5
	var margin := WorldConfig.m_to_px(cfg["margin_m"])
	var amp := WorldConfig.m_to_px(pcfg["amplitude_m"])
	var max_slope: float = cfg["max_slope"]

	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = float(pcfg["frequency"]) / WorldConfig.m_to_px(1.0)
	noise.fractal_octaves = int(pcfg["octaves"])

	var pad_xs: Array[float] = [0.0]
	for d in pad_distances_m:
		pad_xs.append(WorldConfig.m_to_px(d))
	var x_min := -margin
	var x_max: float = pad_xs.max() + margin

	var ridge := PackedVector2Array()
	var prev_y := 0.0
	var x := x_min
	while x <= x_max + 0.001:
		var y := -noise.get_noise_1d(x) * amp
		if not ridge.is_empty():
			y = clampf(y, prev_y - max_slope * step, prev_y + max_slope * step)
		ridge.append(Vector2(x, y))
		prev_y = y
		x += step

	# plataformas: trechos planos na altura do relevo no centro
	var pads: Array[Dictionary] = []
	for i in pad_xs.size():
		var cx: float = pad_xs[i]
		var py := _height_at(ridge, cx)
		for j in ridge.size():
			if absf(ridge[j].x - cx) <= pad_half + 0.001:
				ridge[j] = Vector2(ridge[j].x, py)
		pads.append({"id": i, "x": cx, "half_width": pad_half, "y": py})
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
