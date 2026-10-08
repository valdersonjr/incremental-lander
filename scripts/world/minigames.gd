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


## Nuvens: x (px) dos carneirinhos: os want primeiros do meio ficam DENTRO de uma corrente (no centro da mais
## perto); os outros ficam a pelo menos half + clear dela (empurrados para o lado mais perto, sem sair de a..b).
static func sheep_xs(xs: Array[float], columns: Array, clear: float, want: int, xa: float, xb: float) -> Array[float]:
	var out: Array[float] = xs.duplicate()
	var lo := minf(xa, xb)
	var hi := maxf(xa, xb)
	var order: Array[int] = []                                 # do meio para as pontas
	for i in out.size():
		order.append(i)
	var mid := (out.size() - 1) * 0.5
	order.sort_custom(func(i: int, j: int) -> bool: return absf(i - mid) < absf(j - mid))
	var used: Array[int] = []
	for i: int in order:
		if columns.is_empty():
			break
		var ci := _nearest_column(out[i], columns, used if used.size() < columns.size() else [])
		var c: Dictionary = columns[ci]
		if used.size() < want:
			out[i] = float(c["x"])
			used.append(ci)
			continue
		var fx := free_x(out[i], columns, clear, lo, hi)
		out[i] = fx if not is_nan(fx) else free_x(out[i], columns, 0.0, lo, hi)
		if is_nan(out[i]):
			out[i] = xs[i]
	return out


## Ponto de lo..hi mais perto de x que fica a pelo menos half + clear de toda corrente (NAN se nao houver).
static func free_x(x: float, columns: Array, clear: float, lo: float, hi: float) -> float:
	var blocked: Array[Vector2] = []
	for c: Dictionary in columns:
		var need := float(c["half"]) + clear + 0.5
		blocked.append(Vector2(float(c["x"]) - need, float(c["x"]) + need))
	blocked.sort_custom(func(u: Vector2, v: Vector2) -> bool: return u.x < v.x)
	var best := NAN
	var cur := lo
	for seg: Vector2 in blocked + [Vector2(hi, hi)]:
		var e := minf(seg.x, hi)
		if e >= cur:                                           # trecho livre cur..e
			var cand := clampf(x, cur, e)
			if is_nan(best) or absf(cand - x) < absf(best - x):
				best = cand
		cur = maxf(cur, seg.y)
	return best


static func _nearest_column(x: float, columns: Array, skip: Array) -> int:
	var best := 0
	var bd := INF
	for k in columns.size():
		if k in skip:
			continue
		var d := absf(x - float(columns[k]["x"]))
		if d < bd:
			bd = d
			best = k
	return best


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


## Cogumelos: y (px) do chapeu i de n numa escada que sobe da partida (ya) ate above px acima do alvo (yb) no ultimo;
## nunca a menos de clear px do chao local gy.
static func cap_y(ya: float, yb: float, i: int, n: int, above: float, gy: float, clear: float) -> float:
	return minf(lerpf(ya, yb, float(i + 1) / float(n)) - above, gy - clear)


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


## Sorvete: x (px) onde a nave para se tocar o gelo agora: anda vx ate tocar (h m de altura caindo a vy, minimo
## 1 m/s) e depois desliza max(|vx|, min_slide)^2 / (2 x atrito) no sentido de vx (vx 0 = dir). 1 m = 1 px.
static func slide_stop_x(x: float, vel_mps: Vector2, h_m: float, min_slide: float, friction: float, dir: float) -> float:
	var t := maxf(h_m, 0.0) / maxf(vel_mps.y, 1.0)
	var vx := vel_mps.x
	var v := maxf(absf(vx), min_slide)
	var sgn := signf(vx) if vx != 0.0 else signf(dir)
	return x + WorldConfig.m_to_px(vx * t + sgn * v * v / (2.0 * maxf(friction, 0.001)))


## Jardim (Flappy Bird): a nave (px) bate no caule {x, half, gap_top, gap_bot}? (dentro da faixa do caule e fora do vao)
static func hits_stem(pos_px: Vector2, stem: Dictionary) -> bool:
	return absf(pos_px.x - float(stem["x"])) <= float(stem["half"]) \
			and (pos_px.y < float(stem["gap_top"]) or pos_px.y > float(stem["gap_bot"]))


## Jardim: vento lateral (m/s2) no tempo t (s): vai e volta, forca da estrela.
static func wind_at(t: float, strength: float, period_s: float) -> float:
	return strength * sin(TAU * t / maxf(period_s, 0.1))


## Bolhas: x (px) do ponto mais fundo do relevo entre x0 e x1 (passo de 4 px; empate = o mais perto do meio).
static func deepest_x(ridge: PackedVector2Array, x0: float, x1: float) -> float:
	var best := (x0 + x1) * 0.5
	var best_y := TerrainGen.height_at(ridge, best)
	var x := x0
	while x <= x1:
		var y := TerrainGen.height_at(ridge, x)
		if y > best_y + 0.5:
			best = x
			best_y = y
		x += 4.0
	return best


## A nave (centro, px) encostou no queijinho?
static func touches(pos_px: Vector2, coin_px: Vector2, radius_px: float) -> bool:
	return pos_px.distance_to(coin_px) <= radius_px
