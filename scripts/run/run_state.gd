## Estado de um run (logica pura, testavel): ofertas de entrega, entregas feitas, ganhos e fim do run.
## Regras da economy-balance (run-model.md): ofertas log-uniformes na faixa do planeta, oferta cumprida e
## substituida (regenerate), teto de entregas (max_per_run), pagamento via EconMath.contract_pay (com q).
class_name RunState
extends RefCounted

var planet_id := ""
var stats: Dictionary = {}
var offers: Array[float] = []             # distancias (m do modelo) das ofertas atuais
var deliveries: Array[Dictionary] = []
var earned: Dictionary = {}               # recurso -> quantidade ganha neste run
var over := false
var end_reason := ""
var max_deliveries := 6

var _rng := RandomNumberGenerator.new()
var _planet: Dictionary = {}


## Cria um run no planeta com os stats da nave. Mesmo seed => mesmas ofertas.
static func create(p_planet_id: String, p_stats: Dictionary, seed_value: int) -> RunState:
	var run := RunState.new()
	run.planet_id = p_planet_id
	run.stats = p_stats
	run._rng.seed = seed_value
	for p: Dictionary in EconMath.spec["planets"]:
		if p["id"] == p_planet_id:
			run._planet = p
	var c: Dictionary = EconMath.spec["contracts"]
	run.max_deliveries = int(c.get("max_per_run", 6))
	var n := int(run._planet.get("contracts_per_run", c.get("per_run", 8)))
	for i in n:
		run.offers.append(run._draw_distance())
	run.offers.sort()
	return run


## Dados de uma oferta para a UI/piloto: distancia, pagamento (perfeito e tipico), gas estimado, alcancavel.
func offer_info(index: int, gas_left: float) -> Dictionary:
	var d: float = offers[index]
	var gas_est := EconMath.estimated_hop_dv(planet_id, d, stats) / float(stats["efficiency"])
	return {
		"distance": d,
		"pay_best": EconMath.contract_pay(planet_id, d, stats, 1.0),
		"pay_typical": EconMath.contract_pay(planet_id, d, stats, 0.7),
		"gas_est": gas_est,
		"reachable": gas_est <= gas_left,
	}


## Indice da melhor oferta alcancavel (pagamento por gas estimado, com folga), ou -1. Usado pelo --demo.
func best_offer(gas_left: float, margin: float = 2.2) -> int:
	var best := -1
	var best_score := 0.0
	for i in offers.size():
		var info := offer_info(i, gas_left)
		if info["gas_est"] * margin > gas_left:
			continue
		var score: float = info["pay_typical"] / maxf(info["gas_est"], 0.001)
		if score > best_score:
			best = i
			best_score = score
	return best


## Aceita uma oferta: remove da lista e (se a spec manda) sorteia uma nova. Retorna a distancia.
func take_offer(index: int) -> float:
	var d: float = offers[index]
	offers.remove_at(index)
	if EconMath.spec["contracts"].get("regenerate", false):
		offers.append(_draw_distance())
		offers.sort()
	return d


## Registra uma entrega concluida e devolve as recompensas {recurso: qtd}.
func complete_delivery(distance: float, quality: float, gas_used: float) -> Dictionary:
	var pay := EconMath.contract_pay(planet_id, distance, stats, quality)
	var rewards := {}
	var weights: Dictionary = _planet.get("rewards", {"credits": 1.0})
	for res: String in weights:
		rewards[res] = pay * float(weights[res])
		earned[res] = float(earned.get(res, 0.0)) + rewards[res]
	deliveries.append({"distance": distance, "quality": quality, "gas_used": gas_used, "rewards": rewards})
	if deliveries.size() >= max_deliveries:
		finish("limite_de_entregas")
	return rewards


## Batida: a entrega em andamento e perdida e o run acaba (o que ja foi ganho fica).
func crash(reason: String) -> void:
	finish("batida:" + reason)


## O jogador ainda consegue fazer alguma entrega com o gas que resta?
func can_continue(gas_left: float) -> bool:
	if over:
		return false
	for i in offers.size():
		if offer_info(i, gas_left)["reachable"]:
			return true
	return false


func finish(reason: String) -> void:
	if not over:
		over = true
		end_reason = reason


## Resumo para a tela de fim de run.
func summary() -> Dictionary:
	var q_total := 0.0
	for d in deliveries:
		q_total += float(d["quality"])
	return {
		"planet": planet_id,
		"deliveries": deliveries.size(),
		"avg_quality": q_total / maxf(1.0, deliveries.size()),
		"earned": earned,
		"reason": end_reason,
	}


func _draw_distance() -> float:
	var r: Array = _planet["distance"]
	return exp(_rng.randf_range(log(float(r[0])), log(float(r[1]))))
