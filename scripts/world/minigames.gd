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


## Nuvens: x (px) das N figuras espalhadas entre as plataformas (faixas iguais, sem as pontas).
static func spread_x(a: Dictionary, b: Dictionary, n: int) -> Array[float]:
	var out: Array[float] = []
	for i in n:
		out.append(lerpf(float(a["x"]), float(b["x"]), float(i + 1) / float(n + 1)))
	return out


## Nuvens (Snake): posicao do i-esimo da fila no historico de posicoes da nave (mais recente primeiro).
static func follow_point(history: PackedVector2Array, i: int, step: int) -> Vector2:
	if history.is_empty():
		return Vector2.ZERO
	return history[mini(history.size() - 1, (i + 1) * step)]


## Corrente de ar: a nave (px) esta dentro de alguma coluna {x, half} (ate height px acima do chao local)?
static func in_updraft(pos_px: Vector2, columns: Array, ground_y: float, height_px: float) -> bool:
	if pos_px.y < ground_y - height_px:
		return false
	for c: Dictionary in columns:
		if absf(pos_px.x - float(c["x"])) <= float(c["half"]):
			return true
	return false


## Cogumelos: a nave caindo (vy_mps > 0) com os pes na altura do chapeu {x, y, half} quica? (px)
static func hits_cap(feet_px: Vector2, vy_mps: float, cap: Dictionary) -> bool:
	return vy_mps > 0.0 and absf(feet_px.x - float(cap["x"])) <= float(cap["half"]) \
			and feet_px.y >= float(cap["y"]) - 3.0 and feet_px.y <= float(cap["y"]) + 8.0


## Velocidade (m/s, para cima = negativa) depois de quicar: pelo menos bounce_mps, ou quase a mesma da queda.
static func bounce_vy(vy_mps: float, bounce_mps: float) -> float:
	return -maxf(vy_mps * 0.95, bounce_mps)


## Sorvete (curling): qualidade pela distancia (m) ate o centro do alvo; fora do anel = 0.
static func curling_quality(dist_m: float, ring_m: float) -> float:
	return clampf(1.0 - dist_m / maxf(ring_m, 0.001), 0.0, 1.0)


## Sorvete: velocidade (m/s) depois de dt (s do modelo) de atrito no gelo (para em 0, nunca troca de lado).
static func slide_step(v_mps: float, friction: float, dt_m: float) -> float:
	var nv := absf(v_mps) - friction * dt_m
	return signf(v_mps) * nv if nv > 0.0 else 0.0


## A nave (centro, px) encostou no queijinho?
static func touches(pos_px: Vector2, coin_px: Vector2, radius_px: float) -> bool:
	return pos_px.distance_to(coin_px) <= radius_px
