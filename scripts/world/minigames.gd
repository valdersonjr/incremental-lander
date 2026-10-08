## Minijogos do voo (v17, um por mundo; regras em data/world.json > minigames) — logica pura, testavel.
## Lua: trilha de queijinhos (padrao Subway Surfers) no arco ideal entre as plataformas; cada queijinho pego paga
## uma parte do bonus do minijogo (economy.json planets[].mission_bonus x pagamento-base x pegos/total).
class_name Minigames
extends RefCounted


## Config do minijogo do mundo ({} se o mundo nao tem).
static func spec(planet_id: String) -> Dictionary:
	return (WorldConfig.load_config().get("minigames", {}) as Dictionary).get(planet_id, {})


## Valor da estrela (1..3) numa lista da config (a ultima vale para estrelas maiores).
static func by_star(values: Array, star: int) -> Variant:
	return values[clampi(star, 1, values.size()) - 1]


## Pontos dos queijinhos (px do mundo): n pontos ao longo do arco ideal de a ate b, sem as pontas; arc_mult > 1
## levanta o arco (estrela mais alta = trilha mais alta e com mais curva).
static func trail_points(a: Dictionary, b: Dictionary, n: int, arc_mult: float) -> Array[Vector2]:
	var arc := Assists.arc(a, b, n + 1)
	var out: Array[Vector2] = []
	for i in range(1, n + 1):
		var base_y := lerpf(float(a["y"]), float(b["y"]), float(i) / float(n + 1))
		var lift := base_y - arc[i].y                         # quanto o arco sobe neste ponto
		out.append(Vector2(arc[i].x, base_y - lift * arc_mult))
	return out


## A nave (centro, px) encostou no queijinho?
static func touches(pos_px: Vector2, coin_px: Vector2, radius_px: float) -> bool:
	return pos_px.distance_to(coin_px) <= radius_px
