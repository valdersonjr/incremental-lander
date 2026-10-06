## Presentes no alto do morro (v10, 2026-10-06) — logica pura, testavel. Metade dos saltos (economy.json
## contracts.gifts) tem um presente no ponto mais alto do relevo entre as plataformas: encostar devagar pega.
## Galao de gas (devolve gas na hora) ou presente (creditos pagos junto com a entrega). Posicao/toque: world.json gifts.
class_name Gifts
extends RefCounted


## Pes do presente (px do mundo): o ponto mais alto do relevo na faixa central do salto de a ate b.
static func place(a: Dictionary, b: Dictionary, ridge: PackedVector2Array) -> Vector2:
	var span: Array = WorldConfig.load_config()["gifts"]["span"]
	var xa := float(a["x"])
	var d := float(b["x"]) - xa
	var lo := minf(xa + d * float(span[0]), xa + d * float(span[1]))
	var hi := maxf(xa + d * float(span[0]), xa + d * float(span[1]))
	var best := Vector2(lo, TerrainGen.height_at(ridge, lo))
	for pt in ridge:
		if pt.x >= hi:
			break
		if pt.x > lo and pt.y < best.y:
			best = pt
	var r := TerrainGen.height_at(ridge, hi)
	if r < best.y:
		best = Vector2(hi, r)
	return best.round()


## A nave (centro pos_px, velocidade vel_m em m/s) pega o presente com pes em gift_px? Perto e devagar.
static func touches(pos_px: Vector2, vel_m: Vector2, gift_px: Vector2) -> bool:
	var g: Dictionary = WorldConfig.load_config()["gifts"]
	var center := gift_px + Vector2(0, -8)
	return pos_px.distance_to(center) <= WorldConfig.m_to_px(float(g["radius_m"])) \
			and vel_m.length() <= float(g["max_speed"])


## Sorteador proprio do presente do salto (nao muda distancias, lados nem cargas de um seed).
static func rng_for(seed: int, pad_id: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, pad_id, "gift"])
	return rng
