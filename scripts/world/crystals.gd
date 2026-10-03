## Cristais do salto (Fase 11.4) — logica pura, testavel. Ficam sobre o arco ideal de 45 graus entre as plataformas
## (o de menor gasto de gas): mostram o caminho eficiente; quem sai dele decide se vale o gas de desviar para buscar.
## Quantidade = economy.json contracts.pickups.per_hop; posicao/raio = world.json crystals.
class_name Crystals
extends RefCounted


## Posicoes (px do mundo) dos cristais do salto da plataforma a ate b (centro do lander, nao os pes).
static func place(a: Dictionary, b: Dictionary, count: int) -> Array[Vector2]:
	var cfg: Dictionary = WorldConfig.load_config()
	var k := float(cfg["crystals"]["arc_k"])
	var feet := WorldConfig.m_to_px(float(cfg["lander"]["feet_offset_m"]))
	var d := float(b["x"]) - float(a["x"])
	var out: Array[Vector2] = []
	for i in count:
		var u := float(i + 1) / float(count + 1)
		var y := lerpf(float(a["y"]), float(b["y"]), u) - absf(d) * u * (1.0 - u) * k - feet
		out.append(Vector2(float(a["x"]) + d * u, y))
	return out


## Indices dos cristais ainda nao pegos (taken[i] == false) que o lander em pos (px) alcanca.
static func hits(positions: Array[Vector2], taken: Array[bool], pos: Vector2) -> Array[int]:
	var r := WorldConfig.m_to_px(float(WorldConfig.load_config()["crystals"]["radius_m"]))
	var out: Array[int] = []
	for i in positions.size():
		if not taken[i] and positions[i].distance_to(pos) <= r:
			out.append(i)
	return out
