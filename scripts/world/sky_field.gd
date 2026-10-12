## Obstaculos do ceu (world.json > sky_obstacles): regra pura, testavel. Grade fixa de celulas no mundo; cada celula
## sorteia (pela seed) se tem um satelite, com chance que cresce com a altura acima do relevo. Mesma pista e mesma
## seed = os mesmos satelites nos mesmos lugares (da para aprender o caminho).
class_name SkyField
extends RefCounted


## Chance de uma celula ter obstaculo a alt_m metros acima do relevo: 0 ate free_m, sobe ate max_p em full_m.
static func chance(alt_m: float, cfg: Dictionary) -> float:
	var free := float(cfg["free_m"])
	var full := float(cfg["full_m"])
	if alt_m <= free:
		return 0.0
	var t := clampf((alt_m - free) / maxf(full - free, 1.0), 0.0, 1.0)
	return float(cfg["max_p"]) * pow(t, float(cfg["exp"]))


## Obstaculo da celula (i, j) ou {} se vazia. ref_y = y (px) do ponto mais alto do relevo perto da coluna i.
## Devolve {"kind": nome, "pos": Vector2 (px, centro), "phase": float 0..1 (animacao)}.
static func cell(i: int, j: int, seed_value: int, ref_y: float, cfg: Dictionary) -> Dictionary:
	var size := WorldConfig.m_to_px(float(cfg["cell_m"]))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([i, j, seed_value])
	var jit := float(cfg["jitter"])
	var pos := Vector2((i + 0.5 + rng.randf_range(-jit, jit)) * size, (j + 0.5 + rng.randf_range(-jit, jit)) * size)
	var alt := WorldConfig.px_to_m(ref_y - pos.y)
	if rng.randf() >= chance(alt, cfg):
		return {}
	var kinds: Array = cfg["kinds"]
	var total := 0.0
	for k: Dictionary in kinds:
		total += float(k["weight"])
	var pick := rng.randf() * total
	var kind: Dictionary = kinds[-1]
	for k: Dictionary in kinds:
		pick -= float(k["weight"])
		if pick <= 0.0:
			kind = k
			break
	return {"kind": str(kind["name"]), "pos": pos, "phase": rng.randf()}


## Normal (saindo do obstaculo, unitaria) se a nave (centro p, raio r px) encosta numa area de batida; ZERO se nao.
static func hit_normal(p: Vector2, r: float, obstacle_pos: Vector2, circles: Array) -> Vector2:
	for c: Array in circles:
		var center := obstacle_pos + Vector2(float(c[0]), float(c[1]))
		var d := p - center
		if d.length() < r + float(c[2]):
			return d.normalized() if d.length() > 0.001 else Vector2.UP
	return Vector2.ZERO
