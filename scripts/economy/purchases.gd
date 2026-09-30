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
