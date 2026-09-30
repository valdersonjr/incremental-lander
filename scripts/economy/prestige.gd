## Prestigio e loja da Poeira Estelar (logica pura, testavel). Regras da spec via EconMath:
## ganho = prestige_gain(creditos do ciclo), exige planeta e ganho minimo; reset via prestige_reset_state.
## O estado e um Dictionary com as chaves do GameState (resources, levels, shop, unlocked, current_planet,
## prestige_points, cycle_earned) para poder ser testado sem autoloads.
class_name Prestige
extends RefCounted


## Poeira que o jogador ganharia recomecando agora.
static func gain(state: Dictionary) -> float:
	var p: Dictionary = EconMath.spec["prestige"]
	var based_on: String = p.get("based_on", "credits")
	return EconMath.prestige_gain(float(state["cycle_earned"].get(based_on, 0.0)))


## Pode recomecar? (planeta exigido liberado e ganho >= minimo)
static func can_prestige(state: Dictionary) -> bool:
	var p: Dictionary = EconMath.spec["prestige"]
	var req: String = p.get("requires_planet", "")
	if req != "" and not req in state["unlocked"]:
		return false
	return gain(state) >= float(p.get("min_gain", 1.0))


## Passo 1 do recomeco: coleta a Poeira (nivel e moeda) e zera o ciclo. Retorna o ganho (0 se nao pode).
## Depois o jogador gasta na loja e so entao chama reset() — igual ao simulador da economy-balance.
static func collect(state: Dictionary) -> float:
	if not can_prestige(state):
		return 0.0
	var res_id: String = EconMath.spec["prestige"]["resource"]
	var g := gain(state)
	state["resources"][res_id] = float(state["resources"].get(res_id, 0.0)) + g
	state["prestige_points"] = float(state["prestige_points"]) + g
	state["cycle_earned"] = {}
	return g


## Passo 2 do recomeco: reseta recursos/niveis/planetas aplicando a loja (capital, ficha, cartas...).
## Mantem a Poeira e os upgrades persistentes (etapas da Expedicao).
static func reset(state: Dictionary) -> void:
	var p: Dictionary = EconMath.spec["prestige"]
	var res_id: String = p["resource"]
	var dust := float(state["resources"].get(res_id, 0.0))
	var r := EconMath.prestige_reset_state(state["shop"])
	var keep: Array = r["keep"]
	var new_levels: Dictionary = r["levels"].duplicate()
	for uid: String in r["keep_upgrades"]:
		if state["levels"].has(uid):
			new_levels[uid] = state["levels"][uid]
	if not "upgrades" in keep:
		state["levels"] = new_levels
	if not "money" in keep:
		state["resources"] = r["resources"].duplicate()
	state["resources"][res_id] = dust
	if not "planets" in keep:
		state["unlocked"] = ["luna"]
		state["current_planet"] = "luna"
	state["cycle_earned"] = {}


## Atalho: coleta + reset (sem passar pela loja).
static func apply(state: Dictionary) -> float:
	var g := collect(state)
	if g > 0.0:
		reset(state)
	return g


## Itens da loja com nivel, custo, se pode comprar.
static func shop_rows(state: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var res_id: String = EconMath.spec["prestige"]["resource"]
	for it: Dictionary in EconMath.shop_items():
		var id: String = it["id"]
		var lv := int(state["shop"].get(id, 0))
		var maxed := lv >= int(it.get("max_level", 1))
		var cost := EconMath.shop_cost(id, lv)
		rows.append({"id": id, "name": it.get("name", id), "level": lv, "max_level": int(it.get("max_level", 1)),
				"maxed": maxed, "cost": cost, "effect": it["effect"],
				"affordable": not maxed and float(state["resources"].get(res_id, 0.0)) >= cost})
	return rows


## Compra 1 nivel de um item da loja com Poeira. Retorna true se comprou.
static func buy_shop(state: Dictionary, item_id: String) -> bool:
	var res_id: String = EconMath.spec["prestige"]["resource"]
	for r: Dictionary in shop_rows(state):
		if r["id"] == item_id and r["affordable"]:
			state["resources"][res_id] = float(state["resources"][res_id]) - float(r["cost"])
			state["shop"][item_id] = int(r["level"]) + 1
			return true
	return false
