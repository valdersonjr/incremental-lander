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
## shape (v15, relevo da missao; world.json missions.<tipo>.terrain) mexe so no trecho partida -> 1a entrega:
##   rise_m = o chao sobe ate o alvo (subida suave) · target_lift_m = alvo no alto de uma mesa/degrau ·
##   crest_scale = altura da crista (0 = sem) · basin_m = cratera no meio do caminho (basin_width_frac da distancia).
## shape["land"] (v15, paisagem sorteada por missao: TerrainGen.landscape; world.json terrain.landscapes) troca a
## receita: amplitude/frequencia/oitavas do ruido, ridged (picos), terrace_m (degraus), rise_m (desnivel, soma ao da
## missao), target_lift_m (alvo em mesa > 0 ou vale < 0, com side_slope proprio), crests (0-3 morros) x crest_frac
## (x crest_scale da missao), basins (crateras) x basin_m. Sem "land" = a receita de sempre (planeta).
static func generate(seed_value: int, planet_id: String, pad_distances_m: Array[float],
		pad_tiers: Array[String] = [], extend: Vector2 = Vector2.ZERO, shape: Dictionary = {}) -> Dictionary:
	var cfg: Dictionary = WorldConfig.load_config()["terrain"]
	var pcfg: Dictionary = cfg["planets"].get(planet_id, cfg["planets"]["luna"])
	var step := WorldConfig.m_to_px(cfg["step_m"])
	var margin := WorldConfig.m_to_px(cfg["margin_m"])
	var land: Dictionary = shape.get("land", {})
	var amp := WorldConfig.m_to_px(float(land.get("amplitude_m", pcfg["amplitude_m"])))
	var terrace := WorldConfig.m_to_px(float(land.get("terrace_m", 0.0)))
	var ridged := bool(land.get("ridged", false))
	var max_slope: float = float(cfg["max_slope"]) * (float(cfg.get("terrace_slope_mult", 2.5)) if terrace > 0.0 else 1.0)

	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = float(land.get("frequency", pcfg["frequency"])) / WorldConfig.m_to_px(1.0)
	noise.fractal_octaves = int(land.get("octaves", pcfg["octaves"]))

	var pad_xs: Array[float] = [0.0]
	var tiers: Array[String] = ["normal"]
	for i in pad_distances_m.size():
		pad_xs.append(WorldConfig.m_to_px(pad_distances_m[i]))
		tiers.append(pad_tiers[i] if i < pad_tiers.size() else "normal")
	var k_min := floori((minf(pad_xs.min(), 0.0) - margin - extend.x) / step)
	var k_max := ceili((pad_xs.max() + margin + extend.y) / step)
	var x_min := k_min * step
	var x_max := k_max * step

	# relevo de base: de 0 para a direita e de 0 para a esquerda, limitando a inclinacao a partir da ancora
	# v21 (pista "Mais longe"): rough_px > 0 = o relevo cresce com a distancia (amplitude x track_rough, ate rough_cap)
	var rough_px := float(shape.get("rough_px", 0.0))
	var rough_cap := float(shape.get("rough_cap", 4.0))
	var right := PackedVector2Array()
	var prev_y := _base_y(noise, 0.0, amp, ridged)
	for k in range(0, k_max + 1):
		var a_k := amp * (minf(1.0 + k * step / rough_px, rough_cap) if rough_px > 0.0 else 1.0)
		var y := clampf(_base_y(noise, k * step, a_k, ridged), prev_y - max_slope * step, prev_y + max_slope * step)
		right.append(Vector2(k * step, y))
		prev_y = y
	var left := PackedVector2Array()
	prev_y = right[0].y
	for k in range(-1, k_min - 1, -1):
		var y := clampf(_base_y(noise, k * step, amp, ridged), prev_y - max_slope * step, prev_y + max_slope * step)
		left.append(Vector2(k * step, y))
		prev_y = y
	left.reverse()
	var ridge := left + right
	var rise_m := float(shape.get("rise_m", 0.0)) + float(land.get("rise_m", 0.0))
	if pad_xs.size() > 1 and rise_m != 0.0:                 # desnivel ate o alvo (smoothstep; depois fica): > 0 sobe
		var rise := WorldConfig.m_to_px(rise_m)
		for j in ridge.size():
			var t := clampf(ridge[j].x / pad_xs[1], 0.0, 1.0)
			ridge[j].y -= rise * t * t * (3.0 - 2.0 * t)
	if terrace > 0.0:                                          # degraus: altura em patamares (depois do desnivel)
		_terrace(ridge, terrace, max_slope * step)

	# plataformas: largura e elevacao do tipo; altura decidida no relevo de base (antes das cristas)
	var side_slope: float = cfg["pad_side_slope"]
	var pads: Array[Dictionary] = []
	for i in pad_xs.size():
		var tc: Dictionary = cfg["pad_tiers"].get(tiers[i], cfg["pad_tiers"]["normal"])
		var half := WorldConfig.m_to_px(float(tc["width_m"])) * 0.5
		var lift := WorldConfig.m_to_px(float(tc["lift_m"]))
		var pad_side := side_slope
		if i == 1:                                             # alvo da missao numa mesa/degrau (ou vale da paisagem)
			lift += WorldConfig.m_to_px(float(shape.get("target_lift_m", 0.0)) + float(land.get("target_lift_m", 0.0)))
			pad_side = float(land.get("side_slope", side_slope))
		# pico/vale precisa de espaco ate a plataforma ANTERIOR (so ela: uma plataforma nunca muda quando outra e
		# criada depois — o lander pode estar pousado nela); perto demais -> plataforma no nivel do relevo
		var reach := half + absf(lift) / pad_side + WorldConfig.m_to_px(10.0)
		if i > 0:
			var prev: Dictionary = pads[i - 1]
			var prev_reach := float(prev["half_width"]) + absf(float(prev["lift"])) / float(prev["side"])
			if absf(pad_xs[i] - pad_xs[i - 1]) < reach + prev_reach:
				lift = 0.0
		pads.append({"id": i, "x": pad_xs[i], "half_width": half, "y": _height_at(ridge, pad_xs[i]) - lift,
				"tier": tiers[i], "lift": lift, "side": pad_side})
	for i in pads.size() - 1:
		var crest: Dictionary = cfg["crest"]
		if rough_px > 0.0:                                     # pista: morro entre TODAS as plataformas, mais alto longe
			crest = crest.duplicate()
			var mid_x := (float(pads[i]["x"]) + float(pads[i + 1]["x"])) * 0.5
			crest["min_distance_m"] = 0.0
			crest["frac"] = float(shape.get("crest_frac", crest["frac"])) * minf(1.0 + mid_x / rough_px, rough_cap)
			_add_crest(ridge, pads[i], pads[i + 1], crest, pcfg, pads, 0.5, -1.0, ridged)
			continue
		var n := 1
		if i == 0 and (shape.has("crest_scale") or land.has("crests")):
			n = int(land.get("crests", 1))
			var scale := float(shape.get("crest_scale", 1.0))
			if scale <= 0.0 or n <= 0:
				continue
			crest = crest.duplicate()
			crest["frac"] = float(land.get("crest_frac", crest["frac"])) * scale
		if n == 1:
			_add_crest(ridge, pads[i], pads[i + 1], crest, pcfg, pads, 0.5, -1.0, ridged)
		else:                                                  # varios morros espalhados no trecho (mais baixos)
			crest["frac"] = float(crest["frac"]) * 0.85
			for c in n:
				_add_crest(ridge, pads[i], pads[i + 1], crest, pcfg, pads, 0.25 + 0.5 * c / float(n - 1), 0.14, ridged)
	if pads.size() > 1 and float(shape.get("basin_m", 0.0)) > 0.0:
		_add_basin(ridge, pads[0], pads[1], shape)
	if pads.size() > 1 and int(land.get("basins", 0)) > 0:    # crateras da paisagem, espalhadas no trecho
		var nb := int(land["basins"])
		var bs := {"basin_m": float(land.get("basin_m", 50.0)), "basin_width_frac": float(land.get("basin_width_frac", 0.08))}
		for b in nb:
			_add_basin(ridge, pads[0], pads[1], bs, 0.2 + 0.6 * (b + 0.5) / float(nb))
	var y_range := _y_range(ridge)
	for p in pads:
		y_range = _shape_pad(ridge, p, float(p["side"]), y_range)
	for k in range(pads.size() - 1, -1, -1):                   # topo plano garantido; a mais antiga ganha
		var p: Dictionary = pads[k]
		var half_p := float(p["half_width"]) + 0.001
		for j in range(_first_at_or_after(ridge, float(p["x"]) - half_p), ridge.size()):
			if ridge[j].x > float(p["x"]) + half_p:
				break
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
## Funciona para os dois lados (pedido a esquerda: b antes de a). Sem crista se outra plataforma fica entre as duas
## (voltar por cima de plataformas antigas: a lombada as afundaria num buraco).
## t = posicao do morro no trecho (0..1, a -> b), wfrac = meia-largura / distancia (< 0 = crest.half_width_frac),
## ridged = topo pontudo (Serra).
static func _add_crest(ridge: PackedVector2Array, a: Dictionary, b: Dictionary, crest: Dictionary,
		pcfg: Dictionary, pads: Array[Dictionary] = [], t: float = 0.5, wfrac: float = -1.0, ridged: bool = false) -> void:
	var d := absf(float(b["x"]) - float(a["x"]))
	if d < WorldConfig.m_to_px(float(crest["min_distance_m"])):
		return
	var lo := minf(float(a["x"]), float(b["x"]))
	var hi := maxf(float(a["x"]), float(b["x"]))
	for p in pads:
		if p["id"] != a["id"] and p["id"] != b["id"] and float(p["x"]) > lo and float(p["x"]) < hi:
			return
	var h := minf(float(crest["frac"]) * d, WorldConfig.m_to_px(float(pcfg["crest_max_m"])))
	var w := (float(crest["half_width_frac"]) if wfrac < 0.0 else wfrac) * d
	var mid := lerpf(float(a["x"]), float(b["x"]), t)
	var peak_y := minf(float(a["y"]), float(b["y"])) - h        # y cresce para baixo
	var extra := minf(_height_at(ridge, mid) - peak_y, float(crest["max_bump_slope"]) * w / (PI * 0.5))
	if extra <= 0.0:
		return
	for j in range(_first_at_or_after(ridge, mid - w), ridge.size()):
		var dx := ridge[j].x - mid
		if dx >= w:
			break
		if absf(dx) < w:
			var k := 0.5 + 0.5 * cos(PI * dx / w)
			ridge[j].y -= extra * (pow(k, 1.6) if ridged else k)


## Altura do relevo de base no x (px): ruido x amplitude; ridged = vales largos e picos pontudos (1 - |n|).
static func _base_y(noise: FastNoiseLite, x: float, amp: float, ridged: bool) -> float:
	var v := noise.get_noise_1d(x)
	if ridged:
		v = (1.0 - absf(v)) * 1.6 - 0.8
	return -v * amp


## Degraus: arredonda a altura para patamares de 'size' px e limita a rampa entre eles (ida e volta).
static func _terrace(ridge: PackedVector2Array, size: float, max_dy: float) -> void:
	for j in ridge.size():
		ridge[j].y = roundf(ridge[j].y / size) * size
	for j in range(1, ridge.size()):
		ridge[j].y = clampf(ridge[j].y, ridge[j - 1].y - max_dy, ridge[j - 1].y + max_dy)
	for j in range(ridge.size() - 2, -1, -1):
		ridge[j].y = clampf(ridge[j].y, ridge[j + 1].y - max_dy, ridge[j + 1].y + max_dy)


## Paisagem resolvida para uma missao (world.json terrain.landscapes.<id>): cada faixa [min, max] vira um valor
## sorteado pela seed (contagens crests/basins arredondadas). Mesma seed = mesma paisagem. id desconhecido = {}.
static func landscape(land_id: String, seed_value: int) -> Dictionary:
	var spec: Dictionary = (WorldConfig.load_config()["terrain"].get("landscapes", {}) as Dictionary).get(land_id, {})
	if spec.is_empty():
		return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 7 + 3
	var out := {"id": land_id}
	for k: String in spec:
		var v: Variant = spec[k]
		if v is Array and (v as Array).size() == 2:
			var x := lerpf(float(v[0]), float(v[1]), rng.randf())
			out[k] = roundi(x) if k in ["crests", "basins"] else x
		elif k != "name" and k != "desc":
			out[k] = v
	return out


## Paisagem da missao: uma das liberadas, sorteada pela seed do mapa (mesma seed = mesma).
static func pick_landscape(unlocked: Array, seed_value: int) -> String:
	if unlocked.is_empty():
		return ""
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 31 + 11
	return str(unlocked[rng.randi() % unlocked.size()])


## Relevo pensado para a regra da missao (world.json missions.<tipo>.terrain; taxi = "taxi"; Dupla junta as partes
## ficando com o maior de cada campo).
static func mission_shape(p_mission: Dictionary, stage: int = 0) -> Dictionary:
	var cfg: Dictionary = WorldConfig.load_config()["missions"]
	var parts: Array = p_mission.get("parts", [])
	if parts.is_empty():
		parts = [{"kind": p_mission.get("kind", "simple")}]
	var out := {}
	for p: Dictionary in parts:
		var key := str(p["kind"])
		if key == "passenger" and stage > 0:
			key = "taxi"
		var t: Dictionary = (cfg.get(key, {}) as Dictionary).get("terrain", {})
		for k: String in t:
			if k == "crest_scale":                             # crista: a menor vence (Rapida/Cabo pedem trecho limpo)
				out[k] = minf(float(out.get(k, INF)), float(t[k]))
			else:
				out[k] = maxf(float(out.get(k, 0.0)), float(t[k]))
	return out


## Cratera no meio do trecho a -> b (relevo da missao): cosseno de largura basin_width_frac x distancia, funda
## basin_m (no maximo 15% da distancia, para a encosta continuar suave).
static func _add_basin(ridge: PackedVector2Array, a: Dictionary, b: Dictionary, shape: Dictionary,
		t: float = 0.5) -> void:
	var d := absf(float(b["x"]) - float(a["x"]))
	var w := float(shape.get("basin_width_frac", 0.3)) * d
	var depth := minf(WorldConfig.m_to_px(float(shape["basin_m"])), 0.15 * d)
	var mid := lerpf(float(a["x"]), float(b["x"]), t)
	for j in range(_first_at_or_after(ridge, mid - w), ridge.size()):
		var dx := ridge[j].x - mid
		if dx >= w:
			break
		if absf(dx) < w:
			ridge[j].y += depth * (0.5 + 0.5 * cos(PI * dx / w))
	var floor_m := float(shape.get("basin_floor_m", 0.0))
	if floor_m <= 0.0:
		return
	# fundo minimo (Bolhas: o mar precisa de vale): no meio a cratera chega a floor_m abaixo da ponta mais alta
	var floor_y := maxf(height_at(ridge, float(a["x"])), height_at(ridge, float(b["x"]))) + WorldConfig.m_to_px(floor_m)
	for j in range(_first_at_or_after(ridge, mid - w), ridge.size()):
		var dx := ridge[j].x - mid
		if dx >= w:
			break
		if absf(dx) < w:
			ridge[j].y = maxf(ridge[j].y, lerpf(ridge[j].y, floor_y, 0.5 + 0.5 * cos(PI * dx / w)))


## Pico (lift > 0) ou vale (lift < 0) em volta da plataforma: topo plano + encostas com side_slope. No nivel (lift 0):
## o chao em volta fica dentro de +-side_slope a partir das bordas (sem buraco nem parede colada no deck).
## y_range = (menor y, maior y) do contorno: limita a faixa que a encosta pode alcancar (o resto nao muda).
## Devolve o y_range atualizado (um vale pode descer o contorno abaixo do maior y anterior).
static func _shape_pad(ridge: PackedVector2Array, p: Dictionary, side_slope: float, y_range: Vector2) -> Vector2:
	var lift := float(p["lift"])
	var cx := float(p["x"])
	var half := float(p["half_width"])
	var py := float(p["y"])
	var reach := half + maxf(y_range.y - y_range.x, 0.0) / side_slope + 1.0   # no nivel: encosta para os 2 lados
	if lift > 0.0:
		reach = half + maxf(y_range.y - py, 0.0) / side_slope + 1.0
	elif lift < 0.0:
		reach = half + maxf(py - y_range.x, 0.0) / side_slope + 1.0
	for j in range(_first_at_or_after(ridge, cx - reach), ridge.size()):
		if ridge[j].x > cx + reach:
			break
		var dx := absf(ridge[j].x - cx)
		if dx <= half + 0.001:
			ridge[j].y = py
		elif lift > 0.0:
			ridge[j].y = minf(ridge[j].y, py + (dx - half) * side_slope)
		elif lift < 0.0:
			ridge[j].y = maxf(ridge[j].y, py - (dx - half) * side_slope)
		else:                                                  # no nivel: sem parede colada na borda (relevo alto)
			ridge[j].y = clampf(ridge[j].y, py - (dx - half) * side_slope, py + (dx - half) * side_slope)
		y_range = Vector2(minf(y_range.x, ridge[j].y), maxf(y_range.y, ridge[j].y))
	return y_range


## Altura media do relevo em volta de x (5 amostras de x - span a x + span) — o fundo do voo acompanha o chao.
static func mean_height(ridge: PackedVector2Array, x: float, span: float) -> float:
	var total := 0.0
	for i in 5:
		total += height_at(ridge, x + span * (i / 2.0 - 1.0))
	return total / 5.0


## Ponto mais alto do relevo (menor y) entre x_a e x_b — usado pelo piloto automatico para nao raspar cristas.
static func highest_between(ridge: PackedVector2Array, x_a: float, x_b: float) -> float:
	var lo := minf(x_a, x_b)
	var hi := maxf(x_a, x_b)
	var best := minf(_height_at(ridge, lo), _height_at(ridge, hi))
	for pt in ridge:
		if pt.x >= hi:
			break
		if pt.x > lo:
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


## Menor e maior y do contorno.
static func _y_range(ridge: PackedVector2Array) -> Vector2:
	var r := Vector2(INF, -INF)
	for pt in ridge:
		r.x = minf(r.x, pt.y)
		r.y = maxf(r.y, pt.y)
	return r


## Indice do primeiro ponto com x >= x0 (contorno crescente em x; ridge.size() se nenhum).
static func _first_at_or_after(ridge: PackedVector2Array, x0: float) -> int:
	var lo := 0
	var hi := ridge.size()
	while lo < hi:
		var mid := (lo + hi) >> 1
		if ridge[mid].x < x0:
			lo = mid + 1
		else:
			hi = mid
	return lo


## Busca binaria (o contorno e crescente em x): mapas de centenas de km tem dezenas de milhares de pontos e isto roda
## para cada pedra e varias vezes por quadro — a busca linear travava o jogo por segundos no fim do jogo.
static func _height_at(ridge: PackedVector2Array, x: float) -> float:
	var n := ridge.size()
	if x <= ridge[0].x:
		return ridge[0].y
	if x > ridge[n - 1].x:
		return ridge[n - 1].y
	var lo := 1
	var hi := n - 1
	while lo < hi:                                             # primeiro i com ridge[i].x >= x
		var mid := (lo + hi) >> 1
		if ridge[mid].x >= x:
			hi = mid
		else:
			lo = mid + 1
	var a := ridge[lo - 1]
	var b := ridge[lo]
	var t := (x - a.x) / maxf(b.x - a.x, 0.0001)
	return lerpf(a.y, b.y, t)


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
