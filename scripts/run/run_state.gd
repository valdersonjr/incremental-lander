## Estado de um run (logica pura, testavel): ofertas de entrega, entregas feitas, ganhos e fim do run.
## Regras da economy-balance (run-model.md): ofertas log-uniformes na faixa do planeta, oferta cumprida e
## substituida (regenerate), teto de entregas (max_per_run), pagamento via EconMath.delivery_pay (qualidade x
## tipo de plataforma x combo) + cristais coletados (EconMath.pickup_value).
class_name RunState
extends RefCounted

var planet_id := ""
var stats: Dictionary = {}
var offers: Array[float] = []             # distancias (m do modelo) das ofertas atuais
var offer_tiers: Array[String] = []       # tipo de plataforma de cada oferta (mesma ordem): normal/narrow/tight
var streak := 0                           # pousos bons seguidos neste run (combo; EconMath.combo_mult)
var taken_tier := "normal"                # tipo da plataforma da entrega em andamento
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
		run.offer_tiers.append(EconMath.draw_pad_tier(run._rng))
	run._sort_offers()
	return run


## Dados de uma oferta para a UI/piloto: distancia, tipo de plataforma e multiplicador, pagamento (perfeito e
## tipico, ja com o combo atual), gas estimado, alcancavel.
func offer_info(index: int, gas_left: float) -> Dictionary:
	var d: float = offers[index]
	var tier: String = offer_tiers[index]
	var gas_est := EconMath.estimated_hop_dv(planet_id, d, stats) / float(stats["efficiency"])
	return {
		"distance": d,
		"tier": tier,
		"mult": float(EconMath.pad_tier(tier)["mult"]),
		"pay_best": EconMath.delivery_pay(planet_id, d, stats, 1.0, tier, streak),
		"pay_typical": EconMath.delivery_pay(planet_id, d, stats, 0.7, tier, streak),
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


## Aceita uma oferta: remove da lista e (se a spec manda) sorteia uma nova. Retorna a distancia;
## o tipo da plataforma fica em taken_tier.
func take_offer(index: int) -> float:
	var d: float = offers[index]
	taken_tier = offer_tiers[index]
	offers.remove_at(index)
	offer_tiers.remove_at(index)
	if EconMath.spec["contracts"].get("regenerate", false):
		offers.append(_draw_distance())
		offer_tiers.append(EconMath.draw_pad_tier(_rng))
		_sort_offers()
	return d


## Registra uma entrega concluida (na plataforma taken_tier, com o combo atual e os cristais coletados no salto)
## e devolve as recompensas {recurso: qtd}. Depois atualiza o combo: pouso bom soma, pouso ruim zera.
## Detalhes da conta ficam em deliveries[-1] (base, mult, combo, cristais) para o HUD mostrar.
func complete_delivery(distance: float, quality: float, gas_used: float, crystals: int = 0) -> Dictionary:
	var combo := EconMath.combo_mult(streak)
	var mult := float(EconMath.pad_tier(taken_tier)["mult"])
	var crystal_pay := crystals * EconMath.pickup_value(planet_id, distance, stats)
	var pay := EconMath.delivery_pay(planet_id, distance, stats, quality, taken_tier, streak) + crystal_pay
	var rewards := {}
	var weights: Dictionary = _planet.get("rewards", {"credits": 1.0})
	for res: String in weights:
		rewards[res] = pay * float(weights[res])
		earned[res] = float(earned.get(res, 0.0)) + rewards[res]
	var good := EconMath.combo_counts(quality)
	deliveries.append({"distance": distance, "quality": quality, "gas_used": gas_used, "rewards": rewards,
			"tier": taken_tier, "mult": mult, "combo": combo, "crystals": crystals, "crystal_pay": crystal_pay,
			"good": good})
	streak = streak + 1 if good else 0
	taken_tier = "normal"
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


## Ordena as ofertas por distancia levando o tipo de plataforma junto.
func _sort_offers() -> void:
	var idx := range(offers.size())
	idx.sort_custom(func(a: int, b: int) -> bool: return offers[a] < offers[b])
	var d: Array[float] = []
	var t: Array[String] = []
	for i: int in idx:
		d.append(offers[i])
		t.append(offer_tiers[i])
	offers = d
	offer_tiers = t


func _draw_distance() -> float:
	var r: Array = _planet["distance"]
	return exp(_rng.randf_range(log(float(r[0])), log(float(r[1]))))
