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


static func effect_value(e: Dictionary, level: int) -> float:
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


static func prestige_gain(earned: float) -> float:
	var p: Dictionary = spec.get("prestige", {})
	if p.is_empty():
		return 0.0
	var x := maxf(0.0, earned / p["scale"])
	var v := 0.0
	match p.get("formula", "sqrt"):
		"sqrt":
			v = sqrt(x)
		"cbrt":
			v = pow(x, 1.0 / 3.0)
		"pow":
			v = pow(x, p["exponent"])
		"log10":
			v = log(x) / log(10.0) if x >= 1.0 else 0.0
	return floor(v * p.get("mult", 1.0))


# ---------------------------------------------------------------- upgrades / stats
## Custo do proximo nivel de um upgrade: { "credits": 123.0, "ore": 4.0 }
static func upgrade_cost(upgrade_id: String, level: int) -> Dictionary:
	var u := _find("upgrades", upgrade_id)
	var out := {}
	for res in u["cost"]:
		out[res] = cost_at(u["cost"][res], level)
	return out


static func shop_items() -> Array:
	return spec.get("prestige", {}).get("shop", [])


## Custo (em poeira estelar) do proximo nivel de um item da loja de prestigio.
static func shop_cost(item_id: String, level: int) -> float:
	for it in shop_items():
		if it["id"] == item_id:
			return cost_at(it["cost"], level)
	push_error("item da loja '%s' nao encontrado" % item_id)
	return INF


## Stats finais: base -> + (add/hyper) -> x (mult/milestone) -> x prestigio.
## levels = {id_upgrade: nivel}; shop = {id_item_loja: nivel} (itens com effect.type == "stat").
static func ship_stats(levels: Dictionary, prestige_points: float = 0.0, shop: Dictionary = {}) -> Dictionary:
	var s: Dictionary = spec["ship"]["base"].duplicate()
	var adds := {}
	var mults := {}
	var sources := []
	for u in spec["upgrades"]:
		sources.append([u, int(levels.get(u["id"], 0))])
	for it in shop_items():
		if it["effect"]["type"] == "stat":
			sources.append([it, int(shop.get(it["id"], 0))])
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
	var p: Dictionary = spec.get("prestige", {})
	if not p.is_empty() and prestige_points > 0.0:
		for b in p["bonuses"]:
			s[b["stat"]] *= 1.0 + b["per_point"] * prestige_points
	return s


## Estado inicial apos um prestigio, conforme a loja: { "levels": {...}, "resources": {...}, "keep": [...] }.
## O jogo aplica isso ao resetar (mesma logica do simulador em econ.py/simulate).
static func prestige_reset_state(shop: Dictionary) -> Dictionary:
	var p: Dictionary = spec.get("prestige", {})
	var keep: Array = p.get("keep", []).duplicate()
	var levels := {}
	var resources := {}
	for r in spec["resources"]:
		resources[r["id"]] = float(r.get("start", 0.0))
	for it in shop_items():
		var lv: int = shop.get(it["id"], 0)
		if lv == 0:
			continue
		var e: Dictionary = it["effect"]
		match e["type"]:
			"keep":
				keep.append(e["what"])
			"start_resources":
				for k in e["amounts"]:
					resources[k] += e["amounts"][k] * lv
			"start_levels":
				for k in e["levels"]:
					levels[k] = maxi(int(levels.get(k, 0)), int(e["levels"][k] * lv))
	# upgrades 'persistent' (etapas do megaprojeto) nao resetam: o jogo deve manter o nivel atual deles
	var keep_upgrades := []
	for u in spec["upgrades"]:
		if u.get("persistent", false):
			keep_upgrades.append(u["id"])
	return {"levels": levels, "resources": resources, "keep": keep, "keep_upgrades": keep_upgrades}


## Planeta pode ser desbloqueado? (requisito de planeta anterior e de item da loja)
static func planet_available(planet_id: String, unlocked: Array, shop: Dictionary,
		levels: Dictionary = {}) -> bool:
	var pl := _find("planets", planet_id)
	if not requires_ok(pl, levels):
		return false
	if pl.has("requires") and not (pl["requires"] in unlocked):
		return false
	if pl.has("requires_shop") and int(shop.get(pl["requires_shop"], 0)) == 0:
		return false
	return true


## Upgrade disponivel? (nivel maximo, planeta exigido, item da loja exigido)
## requires_upgrade = {id: nivel_minimo} (ex.: etapa 3 do megaprojeto exige a etapa 2)
static func requires_ok(x: Dictionary, levels: Dictionary) -> bool:
	var req: Dictionary = x.get("requires_upgrade", {})
	for k in req:
		if int(levels.get(k, 0)) < int(req[k]):
			return false
	return true


static func upgrade_available(upgrade_id: String, level: int, unlocked: Array, shop: Dictionary,
		levels: Dictionary = {}) -> bool:
	var u := _find("upgrades", upgrade_id)
	if level >= int(u.get("max_level", 1000000000)):
		return false
	if not requires_ok(u, levels):
		return false
	if u.has("requires_shop") and int(shop.get(u["requires_shop"], 0)) == 0:
		return false
	if u.has("requires_planet") and not (u["requires_planet"] in unlocked):
		return false
	return true


## Renda da frota por segundo: cada drone repete as rotas do jogador com eficiencia `autopilot`.
## avg_player_income_per_s = media movel da renda do proprio jogador (ex.: ultimos 5 runs).
static func fleet_income_per_s(avg_player_income_per_s: float, stats: Dictionary) -> float:
	return avg_player_income_per_s * stats.get("drones", 0.0) * stats.get("autopilot", 0.0)


# ---------------------------------------------------------------- contratos
static func contract_pay(planet_id: String, distance: float, stats: Dictionary, quality: float) -> float:
	var c: Dictionary = spec["contracts"]
	var pl := _find("planets", planet_id)
	var pay: float = c["pay_base"] * pow(distance / c.get("distance_unit", 100.0), c["distance_exp"])
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


## Multiplicador do combo: pousos bons seguidos no run antes desta entrega (contracts.combo).
static func combo_mult(streak: int) -> float:
	var c: Dictionary = spec["contracts"].get("combo", {})
	if c.is_empty():
		return 1.0
	return 1.0 + float(c["step"]) * mini(streak, int(c["max_steps"]))


## O pouso conta para o combo? (q >= combo.q_min)
static func combo_counts(quality: float) -> bool:
	var c: Dictionary = spec["contracts"].get("combo", {})
	return not c.is_empty() and quality >= float(c["q_min"])


## Pagamento de uma entrega concluida: base x qualidade x plataforma x combo x carga (mesma conta do simulador;
## cargo_m = cargo_mult(tipo, cumpriu)).
static func delivery_pay(planet_id: String, distance: float, stats: Dictionary, quality: float,
		tier_id: String = "normal", streak: int = 0, cargo_m: float = 1.0) -> float:
	return contract_pay(planet_id, distance, stats, quality) * float(pad_tier(tier_id)["mult"]) * combo_mult(streak) \
			* cargo_m


## Cargas do planeta (contracts.cargo, v8): [] se o planeta nao tem cargas especiais (so caixa).
static func cargo_kinds(planet_id: String) -> Array:
	var cg: Dictionary = spec["contracts"].get("cargo", {})
	if cg.is_empty() or not (cg.get("planets", []) as Array).has(planet_id):
		return []
	return cg["kinds"]


## Tipo de carga {id, name, mult, weight, fail_mult, fail_p, dv_mult}; desconhecido -> caixa x1.
static func cargo_kind(kind_id: String) -> Dictionary:
	for k: Dictionary in spec["contracts"].get("cargo", {}).get("kinds", []):
		if k["id"] == kind_id:
			return k
	return {"id": "box", "name": "caixa", "mult": 1.0, "weight": 1.0, "fail_mult": 1.0, "fail_p": 0.0, "dv_mult": 1.0}


## Multiplicador de pagamento da carga: cumpriu a regra (ok) -> mult; falhou -> mult x fail_mult.
static func cargo_mult(kind_id: String, ok: bool = true) -> float:
	var k := cargo_kind(kind_id)
	return float(k.get("mult", 1.0)) * (1.0 if ok else float(k.get("fail_mult", 1.0)))


## Sorteia a carga de uma oferta pelos pesos (planeta sem cargas -> "box").
static func draw_cargo(planet_id: String, rng: RandomNumberGenerator) -> String:
	var kinds := cargo_kinds(planet_id)
	if kinds.is_empty():
		return "box"
	var total := 0.0
	for k: Dictionary in kinds:
		total += float(k["weight"])
	var r := rng.randf() * total
	for k: Dictionary in kinds:
		r -= float(k["weight"])
		if r <= 0.0:
			return k["id"]
	return kinds[kinds.size() - 1]["id"]


## Estimativa de delta-v de um salto (a mesma do simulador, sem desperdicio do piloto).
## Util para a UI mostrar "alcance estimado" e para validar a fisica real contra o modelo.
static func estimated_hop_dv(planet_id: String, distance: float, stats: Dictionary) -> float:
	var pl := _find("planets", planet_id)
	var g: float = pl["gravity"]
	var a: float = stats["thrust"]
	if a <= g * 1.05:
		return INF
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
		s = ("%.1f" % x) if (x < 10.0 and x != floor(x)) else str(int(x))
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
	return ("-" if neg else "") + s


## floor(log10(x)) exato nas potencias de 10 (log(x)/log(10) da 5.9999.. em 1e6 e virava "1000K").
static func _exp10(x: float) -> int:
	var e := int(floor(log(x) / log(10.0)))
	if pow(10.0, e + 1) <= x:
		e += 1
	elif pow(10.0, e) > x:
		e -= 1
	return e
