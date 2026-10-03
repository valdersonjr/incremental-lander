## Compras de upgrades (logica pura, testavel). Custos/efeitos vem da spec via EconMath — nada de numeros aqui.
## Opera sobre dicionarios de estado (resources, levels) para poder ser testada sem autoloads.
class_name Purchases
extends RefCounted


## Tem recursos para pagar o custo {recurso: qtd}?
static func can_afford(resources: Dictionary, cost: Dictionary) -> bool:
	for res: String in cost:
		if float(resources.get(res, 0.0)) < float(cost[res]):
			return false
	return true


## Compra 1 nivel. Muta resources/levels. Retorna true se comprou.
static func buy(resources: Dictionary, levels: Dictionary, upgrade_id: String, unlocked: Array,
		shop: Dictionary) -> bool:
	var lv := int(levels.get(upgrade_id, 0))
	if not EconMath.upgrade_available(upgrade_id, lv, unlocked, shop, levels):
		return false
	var cost := EconMath.upgrade_cost(upgrade_id, lv)
	if not can_afford(resources, cost):
		return false
	for res: String in cost:
		resources[res] = float(resources.get(res, 0.0)) - float(cost[res])
	levels[upgrade_id] = lv + 1
	return true


## Compra o maximo de niveis possivel (ate `limit`). Retorna quantos comprou.
static func buy_max(resources: Dictionary, levels: Dictionary, upgrade_id: String, unlocked: Array,
		shop: Dictionary, limit: int = 1000) -> int:
	var n := 0
	while n < limit and buy(resources, levels, upgrade_id, unlocked, shop):
		n += 1
	return n


## Linhas para a UI do hangar: upgrades disponiveis com nivel, custo, stat atual -> proximo e proximo marco.
static func upgrade_rows(resources: Dictionary, levels: Dictionary, unlocked: Array, shop: Dictionary,
		prestige_points: float) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var now := EconMath.ship_stats(levels, prestige_points, shop)
	for u: Dictionary in EconMath.spec["upgrades"]:
		var id: String = u["id"]
		var lv := int(levels.get(id, 0))
		if not EconMath.upgrade_available(id, lv, unlocked, shop, levels):
			continue
		var nxt_levels := levels.duplicate()
		nxt_levels[id] = lv + 1
		var nxt := EconMath.ship_stats(nxt_levels, prestige_points, shop)
		var stat: String = u["effect"]["stat"]
		var cost := EconMath.upgrade_cost(id, lv)
		var milestone := {}
		for m: Dictionary in u.get("milestones", []):
			var every := int(m["every"])
			milestone = {"level": (lv / every + 1) * every, "stat": m["stat"], "mult": m["mult"]}
		rows.append({
			"id": id, "name": u.get("name", id), "level": lv, "stat": stat,
			"current": float(now.get(stat, 0.0)), "next": float(nxt.get(stat, 0.0)),
			"cost": cost, "affordable": can_afford(resources, cost), "milestone": milestone,
		})
	return rows


## Maior distancia (m) alcancavel com `gas`, pelo delta-v ideal (sem desperdicio). Busca binaria.
static func max_reach_m(planet_id: String, stats: Dictionary, gas: float) -> float:
	var eff := float(stats["efficiency"])
	var lo := 0.0
	var hi := 1.0e6
	if EconMath.estimated_hop_dv(planet_id, 1.0, stats) / eff > gas:
		return 0.0
	for i in 60:
		var mid := (lo + hi) * 0.5
		if EconMath.estimated_hop_dv(planet_id, mid, stats) / eff <= gas:
			lo = mid
		else:
			hi = mid
	return lo


## A nave consegue voar no planeta? (motor vence a gravidade — mesma regra do modelo: delta-v finito)
static func can_fly(planet_id: String, stats: Dictionary) -> bool:
	return EconMath.estimated_hop_dv(planet_id, 1.0, stats) < INF


## Da para decolar neste mundo? O motor vence a gravidade E o tanque cheio alcanca a entrega mais curta possivel
## do mundo (senao o run acabaria na hora, sem nenhuma entrega).
static func can_launch(planet_id: String, stats: Dictionary) -> bool:
	if not can_fly(planet_id, stats):
		return false
	var d_min := float(EconMath._find("planets", planet_id)["distance"][0])
	return EconMath.estimated_hop_dv(planet_id, d_min, stats) / float(stats["efficiency"]) <= float(stats["tank"])


## Melhor mundo liberado onde a nave decola (o ultimo na ordem da spec); "luna" se nenhum.
static func best_launchable(unlocked: Array, stats: Dictionary) -> String:
	var best := "luna"
	for p: Dictionary in EconMath.spec["planets"]:
		if p["id"] in unlocked and can_launch(p["id"], stats):
			best = p["id"]
	return best


## Libera um planeta (custo e requisitos da spec). Muta resources/unlocked. Retorna true se liberou.
static func unlock_planet(resources: Dictionary, unlocked: Array, planet_id: String, shop: Dictionary,
		levels: Dictionary) -> bool:
	if planet_id in unlocked or not EconMath.planet_available(planet_id, unlocked, shop, levels):
		return false
	var cost: Dictionary = EconMath._find("planets", planet_id).get("unlock", {})
	if not can_afford(resources, cost):
		return false
	for res: String in cost:
		resources[res] = float(resources.get(res, 0.0)) - float(cost[res])
	unlocked.append(planet_id)
	return true


## Linhas de planetas para o hangar: liberado?, disponivel para liberar?, custo, pode voar com a nave atual.
static func planet_rows(resources: Dictionary, unlocked: Array, shop: Dictionary, levels: Dictionary,
		stats: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for p: Dictionary in EconMath.spec["planets"]:
		var id: String = p["id"]
		var cost: Dictionary = p.get("unlock", {})
		rows.append({
			"id": id, "name": p.get("name", id), "unlocked": id in unlocked,
			"available": EconMath.planet_available(id, unlocked, shop, levels),
			"cost": cost, "affordable": can_afford(resources, cost), "can_fly": can_fly(id, stats),
			"can_launch": can_launch(id, stats),
			"gravity": float(p["gravity"]), "pay_mult": float(p.get("pay_mult", 1.0)),
		})
	return rows
