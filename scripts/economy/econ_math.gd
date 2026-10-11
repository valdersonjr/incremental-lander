## EconMath - espelho em GDScript das formulas de .claude/skills/economy-balance/scripts/econ.py.
## Le a MESMA spec (res://data/economy.json) que o simulador usa. Se mudar uma formula em um lado,
## mude no outro (a skill economy-balance exige isso).
## Uso: EconMath.load_spec(); var c := EconMath.upgrade_cost("tank", level)
class_name EconMath
extends RefCounted

const SPEC_PATH := "res://data/economy.json"
const SUFFIXES := ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]

static var spec: Dictionary = {}


static func load_spec(path: String = SPEC_PATH) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	assert(f != null, "economy.json nao encontrado em %s" % path)
	spec = JSON.parse_string(f.get_as_text())
	return spec


static func _find(list_key: String, id: String) -> Dictionary:
	for it in spec[list_key]:
		if it["id"] == id:
			return it
	push_error("%s: id '%s' nao encontrado" % [list_key, id])
	return {}


# ---------------------------------------------------------------- curvas
static func cost_at(c: Dictionary, level: int) -> float:
	var t: String = c.get("type", "exp")
	var b: float = c["base"]
	var g: float = c["growth"]
	match t:
		"exp":
			return b * pow(g, level)
		"poly":
			return b * pow(level + 1, g)
		"linear":
			return b + g * level
	push_error("tipo de custo desconhecido: %s" % t)
	return INF


static func bulk_cost(c: Dictionary, level: int, n: int) -> float:
	if c.get("type", "exp") == "exp" and c["growth"] != 1.0:
		var b: float = c["base"]
		var r: float = c["growth"]
		return b * pow(r, level) * (pow(r, n) - 1.0) / (r - 1.0)
	var total := 0.0
	for i in n:
		total += cost_at(c, level + i)
	return total


static func max_affordable(c: Dictionary, level: int, money: float) -> int:
	if c.get("type", "exp") == "exp" and c["growth"] != 1.0:
		var b: float = c["base"]
		var r: float = c["growth"]
		var x := money * (r - 1.0) / (b * pow(r, level)) + 1.0
		return maxi(0, int(floor(log(x) / log(r) + 1e-9)))
	var n := 0
	while bulk_cost(c, level, n + 1) <= money:
		n += 1
	return n


## step (opcional, ex.: 10): o efeito so muda ao completar o degrau (as bolinhas do meio sao parcelas).
static func effect_value(e: Dictionary, level: int) -> float:
	if int(e.get("step", 0)) > 0:
		level = (level / int(e["step"])) * int(e["step"])
	match e["op"]:
		"add":
			return e["value"] * level
		"mult":
			return pow(e["value"], level)
		"hyper":
			return e["max"] * level / (level + e["k"])
		"milestone":
			return pow(e["value"], level / int(e["every"]))
	push_error("op desconhecida: %s" % e["op"])
	return 0.0


# ---------------------------------------------------------------- upgrades / stats
## Custo do proximo nivel de um upgrade: { "credits": 123.0, "ore": 4.0 }
static func upgrade_cost(upgrade_id: String, level: int) -> Dictionary:
	var u := _find("upgrades", upgrade_id)
	var out := {}
	for res in u["cost"]:
		out[res] = cost_at(u["cost"][res], level)
	return out


## Stats finais: base -> + (add/hyper) -> x (mult/milestone). levels = {id_upgrade: nivel}.
static func ship_stats(levels: Dictionary) -> Dictionary:
	var s: Dictionary = spec["ship"]["base"].duplicate()
	var adds := {}
	var mults := {}
	var sources := []
	for u in spec["upgrades"]:
		sources.append([u, int(levels.get(u["id"], 0))])
	for pair in sources:
		var u: Dictionary = pair[0]
		var lv: int = pair[1]
		if lv == 0:
			continue
		var e: Dictionary = u["effect"]
		var v := effect_value(e, lv)
		if e["op"] in ["add", "hyper"]:
			adds[e["stat"]] = adds.get(e["stat"], 0.0) + v
		else:
			mults[e["stat"]] = mults.get(e["stat"], 1.0) * v
	# marcos: a cada `every` niveis de um upgrade, `stat` e multiplicado por `mult`
	for u in spec["upgrades"]:
		var lvm: int = levels.get(u["id"], 0)
		for m in u.get("milestones", []):
			if lvm >= int(m["every"]):
				mults[m["stat"]] = mults.get(m["stat"], 1.0) * pow(m["mult"], lvm / int(m["every"]))
	for k in adds:
		s[k] += adds[k]
	for k in mults:
		s[k] *= mults[k]
	return s


## requires_upgrade = {id: nivel_minimo} (ex.: Rota exige o Rastro)
static func requires_ok(x: Dictionary, levels: Dictionary) -> bool:
	var req: Dictionary = x.get("requires_upgrade", {})
	for k in req:
		if int(levels.get(k, 0)) < int(req[k]):
			return false
	return true


## Upgrade disponivel? (nivel maximo e upgrades exigidos)
static func upgrade_available(upgrade_id: String, level: int, levels: Dictionary = {}) -> bool:
	var u := _find("upgrades", upgrade_id)
	if level >= int(u.get("max_level", 1000000000)):
		return false
	return requires_ok(u, levels)


## Renda da frota por segundo: cada drone repete as rotas do jogador com eficiencia `autopilot`.
## avg_player_income_per_s = media movel da renda do proprio jogador (ex.: ultimos 5 runs).
static func fleet_income_per_s(avg_player_income_per_s: float, stats: Dictionary) -> float:
	return avg_player_income_per_s * stats.get("drones", 0.0) * stats.get("autopilot", 0.0)


# ---------------------------------------------------------------- contratos
static func contract_pay(planet_id: String, distance: float, stats: Dictionary, quality: float) -> float:
	var c: Dictionary = spec["contracts"]
	var pl := _find("planets", planet_id)
	# v19: pay_fixed = taxa fixa por entrega (valor das entregas curtas); 0 = so a parte da distancia
	var pay: float = c["pay_base"] * (c.get("pay_fixed", 0.0) + pow(distance / c.get("distance_unit", 100.0), c["distance_exp"]))
	pay *= pl.get("pay_mult", 1.0) * stats.get("pay_mult", 1.0)
	var q := clampf(quality, 0.0, 1.0)
	return pay * (1.0 + c.get("quality_bonus", 0.5) * pow(q, c.get("quality_exp", 1.0)))


## Tipo de plataforma (contracts.pad_tiers): {id, name, mult, weight, q_drop, crash_mult}. Sem tipos -> normal x1.
static func pad_tier(tier_id: String) -> Dictionary:
	for t: Dictionary in spec["contracts"].get("pad_tiers", []):
		if t["id"] == tier_id:
			return t
	return {"id": "normal", "name": "normal", "mult": 1.0, "weight": 1.0, "q_drop": 0.0, "crash_mult": 1.0}


## Sorteia o tipo de plataforma de uma oferta pelos pesos da spec.
static func draw_pad_tier(rng: RandomNumberGenerator) -> String:
	var tiers: Array = spec["contracts"].get("pad_tiers", [])
	if tiers.is_empty():
		return "normal"
	var total := 0.0
	for t: Dictionary in tiers:
		total += float(t["weight"])
	var r := rng.randf() * total
	for t: Dictionary in tiers:
		r -= float(t["weight"])
		if r <= 0.0:
			return t["id"]
	return tiers[tiers.size() - 1]["id"]


## Reputacao por ratinho (v14, contracts.reputation): pontos permanentes por tipo de missao; levels[i].points ->
## +bonus nos pedidos DAQUELE ratinho. Espelho de econ.reputation_level / reputation_mult / reputation_points.
static func reputation_levels() -> Array:
	return spec["contracts"].get("reputation", {}).get("levels", [])


## Nivel (0..3) de um ratinho com points pontos.
static func reputation_level(points: int) -> int:
	var n := 0
	for lv: Dictionary in reputation_levels():
		if points >= int(lv["points"]):
			n += 1
	return n


## Multiplicador do pagamento no nivel level (0 = x1).
static func reputation_mult(level: int) -> float:
	var lvs := reputation_levels()
	if level <= 0 or lvs.is_empty():
		return 1.0
	return 1.0 + float(lvs[mini(level, lvs.size()) - 1]["bonus"])


## Pontos de uma entrega: regra cumprida (ok) da points_ok; com pouso perfeito, points_perfect; falhou/bateu = 0.
static func reputation_points(ok: bool, perfect: bool) -> int:
	var r: Dictionary = spec["contracts"].get("reputation", {})
	if not ok:
		return 0
	return int(r.get("points_perfect", 2)) if perfect else int(r.get("points_ok", 1))


## Pagamento de uma entrega concluida: base x qualidade x plataforma x reputacao x carga (mesma conta do simulador;
## mission_m = mission_mult(missao, falhas)).
static func delivery_pay(planet_id: String, distance: float, stats: Dictionary, quality: float,
		tier_id: String = "normal", rep: int = 0, mission_m: float = 1.0) -> float:
	return contract_pay(planet_id, distance, stats, quality) * float(pad_tier(tier_id)["mult"]) \
			* reputation_mult(rep) * mission_m


## Estrada das Estrelas (v13, progression.road): paradas em ordem {id, type, stars}; type = start | mission (no da
## arvore de missoes) | grant (habilidade/ajuda que vem pronta) | unlock (Frota/Piloto passam a ser compraveis) |
## final. stars = total ACUMULADO de estrelas para chegar (nao se gastam). Espelho de econ.road_spec.
## v17: uma Estrada por mundo (progression.roads.<planeta>); planet "" = todas as paradas juntas (busca por id).
static func road(planet: String = "") -> Array:
	var pr: Dictionary = spec.get("progression", {})
	if pr.has("roads"):
		if planet != "":
			return (pr["roads"] as Dictionary).get(planet, [])
		var all: Array = []
		for k: String in pr["roads"]:
			all.append_array(pr["roads"][k])
		return all
	return pr.get("road", [])


## Mundo seguinte na ordem da spec (o que a parada 'complete' libera); "" no ultimo.
static func next_world(planet: String) -> String:
	var ids: Array = spec["planets"].map(func(p: Dictionary) -> String: return p["id"])
	var i := ids.find(planet)
	return str(ids[i + 1]) if i >= 0 and i < ids.size() - 1 else ""


## Paradas que stars_total alcanca e ainda nao estao em reached (na ordem da estrada; v17: a Estrada do planeta).
static func road_reached_now(stars_total: int, reached: Array, planet: String = "") -> Array:
	var out: Array = []
	for s: Dictionary in road(planet):
		if not reached.has(s["id"]) and stars_total >= int(s["stars"]):
			out.append(s)
	return out


## Com estrada: 'grant' nunca se compra (vem pronto); 'unlock' so depois da parada; o resto, sempre.
static func road_can_buy(upgrade_id: String, reached: Array) -> bool:
	for s: Dictionary in road():
		if s["id"] == upgrade_id:
			return s["type"] == "unlock" and reached.has(upgrade_id)
	return true


## Parada da estrada pelo id ({} se nao existe).
## v16 (mundos paralelos, padrao Hill Climb Racing 2): bonus em moedas por bater o recorde de dinheiro do run NUM
## MUNDO. Primeira visita (sem recorde) = first_frac x dinheiro do run; bater a marca = frac x dinheiro do run.
static func record_bonus(run_money: float, old_record: float) -> float:
	var b: Dictionary = spec["contracts"].get("record_bonus", {})
	if b.is_empty() or run_money <= 0.0:
		return 0.0
	if old_record <= 0.0:
		return float(b.get("first_frac", 0.0)) * run_money
	return float(b.get("frac", 0.0)) * run_money if run_money > old_record else 0.0


## Mundo liberado por uma parada "world" da Estrada (id world_<planeta>); "" se a parada nao e de mundo.
static func world_of_stop(stop: Dictionary) -> String:
	return str(stop["id"]).substr(6) if str(stop.get("type", "")) == "world" else ""


static func road_stop(stop_id: String) -> Dictionary:
	for s: Dictionary in road():
		if s["id"] == stop_id:
			return s
	return {}


## Presentes no alto do morro (v10): tipos do planeta (contracts.gifts.kinds); [] se o planeta nao tem.
static func gift_kinds(planet_id: String) -> Array:
	var g: Dictionary = spec["contracts"].get("gifts", {})
	if g.is_empty() or (g.has("planets") and not (planet_id in g["planets"])):
		return []
	return g["kinds"]


static func gift_kind(kind_id: String) -> Dictionary:
	for k: Dictionary in spec["contracts"].get("gifts", {}).get("kinds", []):
		if k["id"] == kind_id:
			return k
	return {}


## Creditos de um presente pego no salto de distancia d: pay_frac x pagamento-base da entrega.
static func gift_value(planet_id: String, distance: float, stats: Dictionary, kind_id: String) -> float:
	return float(gift_kind(kind_id).get("pay_frac", 0.0)) * contract_pay(planet_id, distance, stats, 0.0)


## Gas devolvido por um presente: gas_frac x tanque (quem chama nao deixa passar do tanque cheio).
static func gift_gas(stats: Dictionary, kind_id: String) -> float:
	return float(gift_kind(kind_id).get("gas_frac", 0.0)) * float(stats["tank"])


## v15: multiplicador do gas do salto depois de n entregas no run (contracts.run_fatigue ^ n; 1 = sem cansaco).
## O run nao tem teto de entregas: o gas que cresce a cada entrega garante que ele acaba (galao devolve gas / esse fator).
static func run_fatigue_mult(n: int) -> float:
	return pow(float(spec["contracts"].get("run_fatigue", 1.0)), n)


# ---------------------------------------------------------------- v21: pista "Mais longe"
## Pista so para a frente (contracts.track; padrao Hill Climb Racing): plataformas em sequencia, pouso paga pela
## distancia DO COMECO (v22: acumulado por metro avancado x nota), relevo sobe com a distancia, galoes de gas, moedas no ar,
## marcos na 1a vez por mundo, estrelas = nota do pouso. Espelho de econ.py track_*.
static func is_track() -> bool:
	return not spec["contracts"].get("track", {}).is_empty()


## Regras da pista com o override do mundo (planets[].track).
static func track_spec(planet_id: String) -> Dictionary:
	var t: Dictionary = spec["contracts"].get("track", {}).duplicate(true)
	t.merge(_find("planets", planet_id).get("track", {}), true)
	return t


## Vao ate a proxima plataforma saindo de x (u em [0,1)).
static func track_gap(planet_id: String, x: float, u: float) -> float:
	var t := track_spec(planet_id)
	var g: Array = t["gap"]
	return (float(g[0]) + (float(g[1]) - float(g[0])) * u) * (1.0 + x / float(t.get("gap_scale", 1e12)))


## Pagamento-base da pista em x (sem qualidade): pay_base x (pay_fixed + (x/pay_unit)^distance_exp) x mundo x nave.
static func track_base(planet_id: String, x: float, stats: Dictionary) -> float:
	var c: Dictionary = spec["contracts"]
	var u := float(track_spec(planet_id).get("pay_unit", c.get("distance_unit", 100.0)))
	return float(c["pay_base"]) * (float(c.get("pay_fixed", 0.0)) + pow(x / u, float(c["distance_exp"]))) \
			* float(_find("planets", planet_id).get("pay_mult", 1.0)) * float(stats.get("pay_mult", 1.0))


## Relevo: o salto que passa por x custa x (1 + x/rough_scale) de delta-v (o terreno usa para a altura dos morros).
static func track_rough(planet_id: String, x: float) -> float:
	return 1.0 + x / float(track_spec(planet_id).get("rough_scale", 1e12))


## Posicoes dos galoes ate x_max: can_first, depois a cada can_every x (1 + x/can_scale).
static func track_cans(planet_id: String, x_max: float) -> Array[float]:
	var t := track_spec(planet_id)
	var out: Array[float] = []
	var c := float(t.get("can_first", 0.0))
	while c > 0.0 and c <= x_max:
		out.append(c)
		c += float(t["can_every"]) * (1.0 + c / float(t.get("can_scale", 1e12)))
	return out


## Gas de um galao (fracao do tanque; quem chama nao deixa passar do tanque cheio).
static func track_can_gas(stats: Dictionary) -> float:
	return float(spec["contracts"]["track"].get("can_frac", 0.0)) * float(stats["tank"])


## v22: ouro ACUMULADO voando para a frente de x0 ate x1 (placar "a receber"; nunca cai): integral de
## track_base(x)/per_m_ref dx. Espelho de econ.track_accum.
static func track_accum(planet_id: String, x0: float, x1: float, stats: Dictionary) -> float:
	if x1 <= x0:
		return 0.0
	var c: Dictionary = spec["contracts"]
	var t := track_spec(planet_id)
	var u := float(t.get("pay_unit", c.get("distance_unit", 100.0)))
	var e := float(c["distance_exp"])
	var f := float(c.get("pay_fixed", 0.0))
	var m := float(c["pay_base"]) * float(_find("planets", planet_id).get("pay_mult", 1.0)) * float(stats.get("pay_mult", 1.0))
	var integral := f * (x1 - x0) + u / (e + 1.0) * (pow(x1 / u, e + 1.0) - pow(maxf(x0, 0.0) / u, e + 1.0))
	return m * integral / float(t.get("per_m_ref", 175.0))


## Multiplicador do pouso sobre o acumulado: qualidade (1 + bonus q^exp) x tamanho da plataforma.
static func track_land_mult(quality: float, tier_id: String = "normal") -> float:
	var c: Dictionary = spec["contracts"]
	var q := clampf(quality, 0.0, 1.0)
	return (1.0 + float(c.get("quality_bonus", 0.5)) * pow(q, float(c.get("quality_exp", 1.0)))) * float(pad_tier(tier_id)["mult"])


## Pouso a x1 depois de decolar (ou pousar por ultimo) em x0: acumulado x multiplicador do pouso.
static func track_pay(planet_id: String, x0: float, x1: float, stats: Dictionary, quality: float,
		tier_id: String = "normal") -> float:
	return track_accum(planet_id, x0, x1, stats) * track_land_mult(quality, tier_id)


## Moedas no ar de um salto que termina em x, coletando a fracao frac.
static func track_coins(planet_id: String, x: float, stats: Dictionary, frac: float) -> float:
	return float(track_spec(planet_id).get("coin_frac", 0.0)) * track_base(planet_id, x, stats) * clampf(frac, 0.0, 1.0)


## Marcos (m) com x0 < m <= x1.
static func track_markers(planet_id: String, x0: float, x1: float) -> Array[float]:
	var ev := float(track_spec(planet_id).get("marker_every", 0.0))
	var out: Array[float] = []
	if ev <= 0.0 or x1 <= x0:
		return out
	for k in range(int(floor(x0 / ev)) + 1, int(floor(x1 / ev)) + 1):
		out.append(k * ev)
	return out


## Bonus do marco m na 1a vez naquele mundo.
static func track_marker_bonus(planet_id: String, m: float, stats: Dictionary) -> float:
	return float(track_spec(planet_id).get("marker_mult", 0.0)) * track_base(planet_id, m, stats)


## Estrelas de um pouso: 1 + (q >= good) + (q >= perfect).
static func landing_stars(quality: float) -> int:
	var s: Dictionary = spec["contracts"]["track"].get("stars", {})
	return 1 + int(quality >= float(s.get("good", 0.6))) + int(quality >= float(s.get("perfect", 0.85)))


## v17: bonus do minijogo do mundo (planets[].mission_bonus x pagamento-base) pela fracao cumprida (0..1).
static func minigame_pay(planet_id: String, distance: float, stats: Dictionary, frac: float, star: int = 1) -> float:
	return mission_bonus_at(planet_id, star) * contract_pay(planet_id, distance, stats, 0.0) * clampf(frac, 0.0, 1.0)


## v18: bonus do minijogo do mundo na estrela (planets[].mission_bonus: numero ou lista por estrela).
static func mission_bonus_at(planet_id: String, star: int = 1) -> float:
	var b: Variant = _find("planets", planet_id).get("mission_bonus", 0.0)
	if b is Array:
		return float(b[clampi(star, 1, (b as Array).size()) - 1])
	return float(b)


## v18: folga minima de empuxo do pedido-assinatura do mundo (planets[].takeoff_twr); outros pedidos: 1,05.
static func takeoff_twr(planet_id: String, kind_id: String, star: int) -> float:
	var p := _find("planets", planet_id)
	var t: Variant = p.get("takeoff_twr", null)
	if t == null or kind_id != str(p.get("mission", "")):
		return 1.05
	if t is Array:
		return float(t[clampi(star, 1, (t as Array).size()) - 1])
	return float(t)


## v18: fator de pagamento de uma regra que falhou com credito parcial (fail_mult + (1 - fail_mult) x parte 0..1).
static func fail_pay(level: Dictionary, partial: float = 0.0) -> float:
	var fm := float(level.get("fail_mult", 1.0))
	return fm + (1.0 - fm) * clampf(partial, 0.0, 1.0)


## Sorteia o presente do salto: "" (sem presente; chance da spec) ou o id do tipo (pelos pesos).
static func draw_gift(planet_id: String, rng: RandomNumberGenerator) -> String:
	var kinds := gift_kinds(planet_id)
	if kinds.is_empty() or rng.randf() >= float(spec["contracts"]["gifts"]["chance"]):
		return ""
	var tw := 0.0
	for k: Dictionary in kinds:
		tw += float(k["weight"])
	var r := rng.randf() * tw
	for k: Dictionary in kinds:
		r -= float(k["weight"])
		if r <= 0.0:
			return str(k["id"])
	return str(kinds[-1]["id"])


# ---------------------------------------------------------------- missoes (v12)
## Missao = REGRA com estrelas 1..3 (contracts.missions): {"kind", "star", "parts": [{"kind", "star"}...]}.
## Simples: parts vazio. Dupla: 2 partes. Cumpriu -> mult da estrela; falhou -> x fail_mult (nunca acaba o run).
## Liberacao: estrelas (1 por entrega) compram nos da arvore (nodes). Espelho de econ.py (mission_*).
static func mission_spec() -> Dictionary:
	return spec["contracts"].get("missions", {})


## Tipos de missao do planeta ([] se o planeta nao tem missoes: so Simples).
static func mission_kinds(planet_id: String) -> Array:
	var ms := mission_spec()
	if ms.is_empty() or not (ms.get("planets", []) as Array).has(planet_id):
		return []
	var sig := str(_find("planets", planet_id).get("mission", ""))
	if sig != "":                                              # v17: so o morador/pedido-assinatura do mundo
		return (ms["kinds"] as Array).filter(func(k: Dictionary) -> bool: return k["id"] == sig)
	return ms["kinds"]


static func mission_kind(kind_id: String) -> Dictionary:
	for k: Dictionary in mission_spec().get("kinds", []):
		if k["id"] == kind_id:
			return k
	return {"id": "simple", "name": "Simples", "weight": 1.0, "levels": [{"mult": 1.0}]}


## Parametros da estrela (mult, fail_mult, thrust_div, dv_mult, leg2...).
static func mission_level(kind_id: String, star: int) -> Dictionary:
	var lv: Array = mission_kind(kind_id)["levels"]
	return lv[clampi(star, 1, lv.size()) - 1]


## Missao Simples (sem regra).
static func simple_mission() -> Dictionary:
	return {"kind": "simple", "star": 1, "parts": []}


## Multiplicador de pagamento. failed = kinds das partes cuja regra falhou.
static func mission_mult(mission: Dictionary, failed: Array = [], partial: Dictionary = {}) -> float:
	var parts: Array = mission.get("parts", [])
	if parts.is_empty():
		return 1.0
	var fail := 1.0
	for p: Dictionary in parts:
		if failed.has(p["kind"]):
			fail *= fail_pay(mission_level(p["kind"], int(p["star"])), float(partial.get(p["kind"], 0.0)))
	var m := 1.0
	if mission["kind"] == "double":
		var mx := float(mission_spec().get("double", {}).get("max_mult", 3.0))
		for p: Dictionary in parts:
			m += float(mission_level(p["kind"], int(p["star"]))["mult"]) - 1.0
		m = minf(mx, m)
	else:
		m = float(mission_level(parts[0]["kind"], int(parts[0]["star"]))["mult"])
	return m * fail


## Pesada: o motor rende thrust / thrust_div.
static func mission_thrust_div(mission: Dictionary) -> float:
	var d := 1.0
	for p: Dictionary in mission.get("parts", []):
		d *= float(mission_level(p["kind"], int(p["star"])).get("thrust_div", 1.0))
	return d


## Cabo: o pendulo custa um pouco mais de delta-v.
static func mission_dv_mult(mission: Dictionary) -> float:
	var m := 1.0
	for p: Dictionary in mission.get("parts", []):
		m *= float(mission_level(p["kind"], int(p["star"])).get("dv_mult", 1.0))
	return m


## Taxi (Passageiro 2-3): o 2o trecho tem leg2 x a distancia da oferta (0 = sem 2o trecho).
static func mission_leg2(mission: Dictionary) -> float:
	if mission.get("kind", "") != "passenger":
		return 0.0
	return float(mission_level("passenger", int(mission["parts"][0]["star"])).get("leg2", 0.0))


## A missao tem a regra kind (sozinha ou numa Dupla)? Devolve a estrela (0 = nao tem).
static func mission_has(mission: Dictionary, kind_id: String) -> int:
	for p: Dictionary in mission.get("parts", []):
		if p["kind"] == kind_id:
			return int(p["star"])
	return 0


## O no da arvore pode ser liberado? (requires = todos; requires_any = {n, of}). owned = ids ja liberados.
static func mission_node_ok(node: Dictionary, owned: Array) -> bool:
	if owned.has(node["id"]):
		return false
	for r: String in node.get("requires", []):
		if not owned.has(r):
			return false
	var ra: Dictionary = node.get("requires_any", {})
	if ra.is_empty():
		return true
	var n := 0
	for r: String in ra["of"]:
		if owned.has(r):
			n += 1
	return n >= int(ra["n"])


## {kind: maior estrela liberada}; a Simples sempre vem.
static func missions_unlocked(owned: Array) -> Dictionary:
	var out := {"simple": 1}
	for n: Dictionary in mission_spec().get("nodes", []):
		if owned.has(n["id"]):
			out[n["kind"]] = maxi(int(out.get(n["kind"], 0)), int(n["star"]))
	return out


## Estrelas para liberar um no (no.cost ou stars.unlock_cost).
static func mission_node_cost(node: Dictionary) -> int:
	return int(node.get("cost", mission_spec().get("stars", {}).get("unlock_cost", 3)))


## Sorteia a missao de uma oferta entre as liberadas (unlocked = {kind: estrela}); boost = {kind: runs} recem-liberados
## pesam x new_boost.weight_mult. Estrela uniforme entre 1 e a liberada. Pesada que nao decola com estes stats fica
## de fora (stats/planet_id). Dupla: 2 regras diferentes de double.parts_from (Passageiro so ate a estrela 1).
static func draw_mission(planet_id: String, unlocked: Dictionary, boost: Dictionary, stats: Dictionary,
		rng: RandomNumberGenerator) -> Dictionary:
	var kinds := mission_kinds(planet_id)
	if kinds.is_empty():
		return simple_mission()
	var ms := mission_spec()
	var bm := float(ms.get("new_boost", {}).get("weight_mult", 1.0))
	var pool: Array[Dictionary] = []
	var weights: Array[float] = []
	for k: Dictionary in kinds:
		var top := int(unlocked.get(k["id"], 0))
		if top <= 0 or (k["id"] == "double" and _double_parts(planet_id, unlocked, stats).size() < 2):
			continue
		pool.append(k)
		weights.append(float(k.get("weight", 1.0)) * (bm if int(boost.get(k["id"], 0)) > 0 else 1.0))
	var kind: Dictionary = pool[_pick(weights, rng)]
	var kid: String = kind["id"]
	if kid == "simple":
		return simple_mission()
	if kid == "double":
		var opts := _double_parts(planet_id, unlocked, stats)
		var a: Dictionary = opts[rng.randi_range(0, opts.size() - 1)]
		var rest := opts.filter(func(o: Dictionary) -> bool: return o["kind"] != a["kind"])
		var b: Dictionary = rest[rng.randi_range(0, rest.size() - 1)]
		return {"kind": "double", "star": 1, "parts": [a, b]}
	var stars: Array[int] = []
	for s in range(1, int(unlocked[kid]) + 1):
		if _flies(planet_id, stats, kid, s):
			stars.append(s)
	if stars.is_empty():
		return simple_mission()
	var star: int = stars[rng.randi_range(0, stars.size() - 1)]
	return {"kind": kid, "star": star, "parts": [{"kind": kid, "star": star}]}


## Espacos de pedido do run (v12.1): a Simples tem simple_offers faixas de distancia (perto -> longe) e cada outro tipo
## liberado tem 1 pedido (um por ratinho). Entregou -> o mesmo espaco ganha um pedido novo.
static func mission_slots(unlocked: Dictionary, planet_id: String = "") -> Array[String]:
	var ms := mission_spec()
	var out: Array[String] = []
	var sig := str(_find("planets", planet_id).get("mission", "")) if planet_id != "" else ""
	if sig != "":                                              # v17: so o pedido-assinatura do mundo, em faixas
		for i in int(ms.get("simple_offers", 3)):
			out.append("%s%d" % [sig, i])
		return out
	for i in int(ms.get("simple_offers", 3)):
		out.append("simple%d" % i)
	for k: Dictionary in ms.get("kinds", []):
		if k["id"] != "simple" and int(unlocked.get(k["id"], 0)) > 0:
			out.append(k["id"])
	return out


## Distancia de um espaco a partir de u em [0,1): Simples i = faixa i (em log); outros = faixa toda do planeta.
static func slot_distance(planet_id: String, slot: String, u: float) -> float:
	var r: Array = _find("planets", planet_id)["distance"]
	var lo := log(float(r[0]))
	var hi := log(float(r[1]))
	if slot.right(1).is_valid_int():
		var n := float(mission_spec().get("simple_offers", 3))
		return exp(lo + (hi - lo) * (float(slot.substr(slot_kind(slot).length()).to_int()) + u) / n)
	return exp(lo + (hi - lo) * u)


## Tipo de missao de um espaco ("simple0" -> "simple").
static func slot_kind(slot: String) -> String:
	var k := slot
	while k.length() > 0 and k.right(1).is_valid_int():
		k = k.left(k.length() - 1)
	return k


## Estrelas que o jogador pode escolher para o tipo (liberadas e em que a nave decola; Simples/Dupla: so a 1).
static func mission_stars(kind_id: String, unlocked: Dictionary, planet_id: String, stats: Dictionary) -> Array[int]:
	var out: Array[int] = []
	if kind_id == "double":
		out.append(1)
		return out
	if kind_id == "simple":                                    # v17: a Simples tambem tem estrelas (trilha da Lua)
		for s in range(1, maxi(1, int(unlocked.get("simple", 1))) + 1):
			out.append(s)
		return out
	for s in range(1, int(unlocked.get(kind_id, 0)) + 1):
		if _flies(planet_id, stats, kind_id, s):
			out.append(s)
	return out


## Missao de um tipo na estrela escolhida (Dupla: sorteia 2 regras diferentes de double.parts_from).
static func mission_of(kind_id: String, star: int, unlocked: Dictionary, planet_id: String, stats: Dictionary,
		rng: RandomNumberGenerator) -> Dictionary:
	if kind_id == "simple":
		return simple_mission() if star <= 1 else {"kind": "simple", "star": star, "parts": [{"kind": "simple", "star": star}]}
	if kind_id == "double":
		var opts := _double_parts(planet_id, unlocked, stats)
		if opts.size() < 2:
			return simple_mission()
		var a: Dictionary = opts[rng.randi_range(0, opts.size() - 1)]
		var rest := opts.filter(func(o: Dictionary) -> bool: return o["kind"] != a["kind"])
		var b: Dictionary = rest[rng.randi_range(0, rest.size() - 1)]
		return {"kind": "double", "star": 1, "parts": [a, b]}
	return {"kind": kind_id, "star": star, "parts": [{"kind": kind_id, "star": star}]}


## Partes possiveis de uma Dupla: [{kind, star}] (uma por regra, a maior estrela que voa; Passageiro ate passenger_max_star).
static func _double_parts(planet_id: String, unlocked: Dictionary, stats: Dictionary) -> Array:
	var dbl: Dictionary = mission_spec().get("double", {})
	var out := []
	for kid: String in dbl.get("parts_from", []):
		var top := int(unlocked.get(kid, 0))
		if kid == "passenger":
			top = mini(top, int(dbl.get("passenger_max_star", 1)))
		for s in range(top, 0, -1):
			if _flies(planet_id, stats, kid, s):
				out.append({"kind": kid, "star": s})
				break
	return out


## A nave decola com a regra (Pesada divide o motor)?
static func _flies(planet_id: String, stats: Dictionary, kind_id: String, star: int) -> bool:
	var div := float(mission_level(kind_id, star).get("thrust_div", 1.0))
	return float(stats["thrust"]) / div > float(_find("planets", planet_id)["gravity"]) * takeoff_twr(planet_id, kind_id, star)


static func _pick(weights: Array[float], rng: RandomNumberGenerator) -> int:
	var total := 0.0
	for w in weights:
		total += w
	var r := rng.randf() * total
	for i in weights.size():
		r -= weights[i]
		if r <= 0.0:
			return i
	return weights.size() - 1


## Empuxo SENTIDO no voo (physics.feel, v20): a aceleracao liquida a - g passa por um teto suave (ate knee igual;
## depois se aproxima de max) — motor forte continua controlavel. Regras de decolagem usam o empuxo cru.
static func felt_thrust(a: float, g: float) -> float:
	var f: Dictionary = spec.get("physics", {}).get("feel", {})
	var net := a - g
	if f.is_empty() or net <= float(f["knee"]):
		return a
	var span := float(f["max"]) - float(f["knee"])
	return g + float(f["knee"]) + span * (1.0 - exp(-(net - float(f["knee"])) / span))


## Estimativa de delta-v de um salto (a mesma do simulador, sem desperdicio do piloto).
## Util para a UI mostrar "alcance estimado" e para validar a fisica real contra o modelo.
static func estimated_hop_dv(planet_id: String, distance: float, stats: Dictionary) -> float:
	var pl := _find("planets", planet_id)
	var g: float = pl["gravity"]
	var a: float = stats["thrust"]
	if a <= g * 1.05:
		return INF
	a = felt_thrust(a, g)
	var v0 := sqrt(g * distance)
	return 2.0 * v0 * (1.0 + 0.707 * g / a) * (1.0 + pl.get("drag", 0.0))


# ---------------------------------------------------------------- formatacao
static func fmt(x: float, style: String = "suffix", digits: int = 3) -> String:
	if is_nan(x):
		return "NaN"
	if is_inf(x):
		return "inf"
	var neg := x < 0.0
	x = absf(x)
	var s := ""
	if x < 1000.0:
		s = ("%.1f" % x).replace(".", ",") if (x < 10.0 and x != floor(x)) else str(int(x))
		return ("-" if neg else "") + s
	var e3 := _exp10(x) / 3                                    # mesmo que floor(log10(x) / 3) do Python
	if style == "sci":
		var e := _exp10(x)
		s = ("%." + str(digits - 1) + "f") % (x / pow(10.0, e)) + "e" + str(e)
	else:
		var m := x / pow(10.0, 3 * e3)
		var dec := maxi(0, digits - str(int(m)).length())
		var suf := ""
		if style == "eng":
			suf = "e" + str(3 * e3)
		elif e3 < SUFFIXES.size():
			suf = SUFFIXES[e3]
		else:
			var k := e3 - SUFFIXES.size()
			suf = char(97 + (k / 26) % 26) + char(97 + k % 26)
		s = ("%." + str(dec) + "f") % m + suf
	return ("-" if neg else "") + s.replace(".", ",")         # pt-BR: virgula decimal (igual ao econ.py)


## floor(log10(x)) exato nas potencias de 10 (log(x)/log(10) da 5.9999.. em 1e6 e virava "1000K").
static func _exp10(x: float) -> int:
	var e := int(floor(log(x) / log(10.0)))
	if pow(10.0, e + 1) <= x:
		e += 1
	elif pow(10.0, e) > x:
		e -= 1
	return e
