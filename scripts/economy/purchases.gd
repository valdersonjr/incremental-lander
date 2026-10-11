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
static func buy(resources: Dictionary, levels: Dictionary, upgrade_id: String) -> bool:
	var lv := int(levels.get(upgrade_id, 0))
	if not EconMath.upgrade_available(upgrade_id, lv, levels):
		return false
	var cost := EconMath.upgrade_cost(upgrade_id, lv)
	if not can_afford(resources, cost):
		return false
	for res: String in cost:
		resources[res] = float(resources.get(res, 0.0)) - float(cost[res])
	levels[upgrade_id] = lv + 1
	return true


## Compra o maximo de niveis possivel (ate `limit`). Retorna quantos comprou.
static func buy_max(resources: Dictionary, levels: Dictionary, upgrade_id: String, limit: int = 1000) -> int:
	var n := 0
	while n < limit and buy(resources, levels, upgrade_id):
		n += 1
	return n


## Melhorias que ainda vao liberar (mostradas apagadas, com cadeado, para o jogador saber o que vem pela frente):
## as da oficina que pedem outra melhoria antes (ex.: Piloto automatico pede 1 drone). As ajudas de voo tem aba
## propria. Cada item: {id, name, requires: id da melhoria exigida}.
static func locked_upgrades(levels: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for u: Dictionary in EconMath.spec["upgrades"]:
		var id: String = u["id"]
		var lv := int(levels.get(id, 0))
		if u.has("assist") or lv >= int(u.get("max_level", 1000000000)):
			continue
		if EconMath.upgrade_available(id, lv, levels):
			continue
		var req: Dictionary = u.get("requires_upgrade", {})
		out.append({"id": id, "name": u.get("name", id), "requires": str(req.keys()[0]) if not req.is_empty() else ""})
	return out


## Linhas para a UI do hangar: upgrades disponiveis com nivel, custo, stat atual -> proximo e proximo marco.
static func upgrade_rows(resources: Dictionary, levels: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var now := EconMath.ship_stats(levels)
	for u: Dictionary in EconMath.spec["upgrades"]:
		var id: String = u["id"]
		var lv := int(levels.get(id, 0))
		if not EconMath.upgrade_available(id, lv, levels):
			continue
		var nxt_levels := levels.duplicate()
		var step := int(u["effect"].get("step", 0))               # degraus (v20): "next" = valor no proximo degrau
		nxt_levels[id] = mini((lv / step + 1) * step if step > 0 else lv + 1, int(u.get("max_level", lv + 1)))
		var nxt := EconMath.ship_stats(nxt_levels)
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


## A compra de before -> after niveis passou um marco (milestones da spec, a cada N niveis)?
## Usado para o jingle de marco no hangar.
static func milestone_crossed(upgrade_id: String, before: int, after: int) -> bool:
	if after <= before:
		return false
	var u := EconMath._find("upgrades", upgrade_id)
	for m: Dictionary in u.get("milestones", []):
		var every := int(m["every"])
		if every > 0 and after / every > before / every:
			return true
	return false


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
