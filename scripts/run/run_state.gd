## Estado de um run (logica pura, testavel): ofertas de entrega, entregas feitas, ganhos e fim do run.
## Regras da economy-balance (run-model.md): ofertas log-uniformes na faixa do planeta, oferta cumprida e
## substituida (regenerate), teto de entregas (max_per_run), pagamento via EconMath.delivery_pay (qualidade x
## tipo de plataforma x combo x missao).
## Lua: cada oferta tambem tem LADO (world.json routes: pedidos a esquerda) e MISSAO (economy.json contracts.missions).
## v12.1: um pedido por ESPACO (EconMath.mission_slots: a Simples tem 3 faixas perto -> longe, cada ratinho liberado tem
## 1); o jogador escolhe no cartao o tamanho da plataforma e a estrela (set_choice). Entregou -> o mesmo espaco ganha
## pedido novo. Planeta sem missoes: ofertas sorteadas como antes (plataforma sorteada).
class_name RunState
extends RefCounted

var planet_id := ""
var stats: Dictionary = {}
var offers: Array[float] = []             # distancias (m do modelo) das ofertas atuais
var offer_tiers: Array[String] = []       # tipo de plataforma de cada oferta (mesma ordem): normal/narrow/tight
var streak := 0                           # pousos bons seguidos neste run (combo; EconMath.combo_mult)
var offer_dirs: Array[int] = []          # lado de cada oferta: 1 = direita, -1 = esquerda
var offer_mission: Array[Dictionary] = [] # missao de cada oferta ({kind, star, parts})
var offer_slot: Array[String] = []        # espaco de cada oferta (simple0..2 ou o tipo do ratinho)
var taken_tier := "normal"                # tipo da plataforma da entrega em andamento
var taken_dir := 1                        # lado da entrega em andamento
var taken_mission: Dictionary = {}        # missao da entrega em andamento
var stars := 0                            # estrelas ganhas neste run (contracts.missions.stars.per_delivery)
var unlocked: Dictionary = {"simple": 1}  # missoes liberadas pelo jogador ({kind: estrela})
var boost: Dictionary = {}                # missoes recem-liberadas ({kind: runs}) aparecem mais
var deliveries: Array[Dictionary] = []
var earned: Dictionary = {}               # recurso -> quantidade ganha neste run
var over := false
var end_reason := ""
var max_deliveries := 6

var _rng := RandomNumberGenerator.new()
var _rng_extra := RandomNumberGenerator.new()   # lado + missao (sequencia propria)
var _left_chance := 0.0
var _planet: Dictionary = {}


## Cria um run no planeta com os stats da nave. Mesmo seed => mesmas ofertas. p_unlocked = missoes liberadas
## ({kind: estrela}; vazio = so Simples), p_boost = recem-liberadas ({kind: runs}).
static func create(p_planet_id: String, p_stats: Dictionary, seed_value: int, p_unlocked: Dictionary = {},
		p_boost: Dictionary = {}) -> RunState:
	var run := RunState.new()
	run.planet_id = p_planet_id
	run.stats = p_stats
	run.taken_mission = EconMath.simple_mission()
	if not p_unlocked.is_empty():
		run.unlocked = p_unlocked
	run.boost = p_boost
	run._rng.seed = seed_value
	run._rng_extra.seed = seed_value * 7919 + 17
	run._left_chance = float(WorldConfig.load_config().get("routes", {}).get(p_planet_id, {}).get("left_chance", 0.0))
	for p: Dictionary in EconMath.spec["planets"]:
		if p["id"] == p_planet_id:
			run._planet = p
	var c: Dictionary = EconMath.spec["contracts"]
	run.max_deliveries = int(c.get("max_per_run", 6))
	if not EconMath.mission_kinds(p_planet_id).is_empty():
		for slot in EconMath.mission_slots(run.unlocked):
			run._add_slot_offer(slot)
		run._sort_offers()
		return run
	var n := int(run._planet.get("contracts_per_run", c.get("per_run", 8)))
	for i in n:
		run.offers.append(run._draw_distance())
		run.offer_tiers.append(EconMath.draw_pad_tier(run._rng))
		run.offer_slot.append("")
		run._draw_extra()
	run._sort_offers()
	return run


## Escolha do jogador no cartao: tamanho da plataforma e estrela da missao (so as de EconMath.mission_stars).
func set_choice(index: int, tier: String, star: int) -> void:
	offer_tiers[index] = tier
	var m: Dictionary = offer_mission[index]
	if m["kind"] == "simple" or m["kind"] == "double":
		return
	if star in stars_for(index):
		offer_mission[index] = {"kind": m["kind"], "star": star, "parts": [{"kind": m["kind"], "star": star}]}


## Estrelas que o jogador pode escolher no pedido index.
func stars_for(index: int) -> Array[int]:
	return EconMath.mission_stars(str(offer_mission[index]["kind"]), unlocked, planet_id, stats)


## Dados de uma oferta para a UI/piloto: distancia, tipo de plataforma e multiplicador, missao, pagamento (perfeito e
## tipico, ja com o combo atual; taxi soma os 2 trechos), gas estimado (Pesada: motor mais fraco; Cabo: dv_mult;
## taxi: os 2 trechos), alcancavel.
func offer_info(index: int, gas_left: float) -> Dictionary:
	var d: float = offers[index]
	var tier: String = offer_tiers[index]
	var m: Dictionary = offer_mission[index]
	var mm := EconMath.mission_mult(m)
	var d2 := leg2_m(m, d)
	var gas_est := mission_gas(m, d)
	return {
		"distance": d,
		"distance2": d2,
		"tier": tier,
		"dir": offer_dirs[index],
		"mission": m,
		"mission_mult": mm,
		"mult": float(EconMath.pad_tier(tier)["mult"]),
		"pay_best": _pay(d, d2, 1.0, tier, mm),
		"pay_typical": _pay(d, d2, 0.7, tier, mm),
		"gas_est": gas_est,
		"reachable": gas_est <= gas_left,
	}


## Gas estimado de uma missao de distancia d (os 2 trechos do taxi; Pesada divide o motor; Cabo x dv_mult).
func mission_gas(m: Dictionary, d: float) -> float:
	var st := stats
	var div := EconMath.mission_thrust_div(m)
	if div != 1.0:
		st = stats.duplicate()
		st["thrust"] = float(stats["thrust"]) / div
	var dv := EconMath.estimated_hop_dv(planet_id, d, st)
	var d2 := leg2_m(m, d)
	if d2 > 0.0:
		dv += EconMath.estimated_hop_dv(planet_id, d2, st)
	return dv * EconMath.mission_dv_mult(m) / float(stats["efficiency"])


## Distancia do 2o trecho do taxi (0 = sem): leg2 x d, nunca menor que a entrega mais curta do mundo.
func leg2_m(m: Dictionary, d: float) -> float:
	var f := EconMath.mission_leg2(m)
	return maxf(d * f, float(_planet["distance"][0])) if f > 0.0 else 0.0


func _pay(d: float, d2: float, quality: float, tier: String, mm: float) -> float:
	var pay := EconMath.delivery_pay(planet_id, d, stats, quality, tier, streak, mm)
	if d2 > 0.0:
		pay += EconMath.delivery_pay(planet_id, d2, stats, quality, tier, streak, mm)
	return pay


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
## o tipo da plataforma, o lado e a missao ficam em taken_tier/taken_dir/taken_mission.
func take_offer(index: int) -> float:
	var d: float = offers[index]
	taken_tier = offer_tiers[index]
	taken_dir = offer_dirs[index]
	taken_mission = offer_mission[index]
	var slot: String = offer_slot[index]
	offers.remove_at(index)
	offer_tiers.remove_at(index)
	offer_dirs.remove_at(index)
	offer_mission.remove_at(index)
	offer_slot.remove_at(index)
	if EconMath.spec["contracts"].get("regenerate", false):
		if slot != "":
			_add_slot_offer(slot)                              # o mesmo ratinho traz pedido novo
		else:
			offers.append(_draw_distance())
			offer_tiers.append(EconMath.draw_pad_tier(_rng))
			offer_slot.append("")
			_draw_extra()
		_sort_offers()
	return d


## Registra uma entrega concluida (na plataforma taken_tier, com o combo atual)
## e devolve as recompensas {recurso: qtd}. Depois atualiza o combo: pouso bom soma, pouso ruim zera.
## gift_pay = creditos do presente pego no alto do morro (EconMath.gift_value; v10), somados ao pagamento.
## failed = kinds das regras da missao taken_mission que falharam (paga mult x fail_mult; nunca acaba o run).
## Taxi: distance = 1o trecho; o 2o (leg2 x distance) tambem paga. Ganha estrelas (stars.per_delivery).
## Detalhes da conta ficam em deliveries[-1] (base, mult, combo, missao) para o HUD mostrar.
func complete_delivery(distance: float, quality: float, gas_used: float, failed: Array = [],
		gift_pay: float = 0.0) -> Dictionary:
	var combo := EconMath.combo_mult(streak)
	var mult := float(EconMath.pad_tier(taken_tier)["mult"])
	var mm := EconMath.mission_mult(taken_mission, failed)
	var pay := _pay(distance, leg2_m(taken_mission, distance), quality, taken_tier, mm) + gift_pay
	var rewards := {}
	var weights: Dictionary = _planet.get("rewards", {"credits": 1.0})
	for res: String in weights:
		rewards[res] = pay * float(weights[res])
		earned[res] = float(earned.get(res, 0.0)) + rewards[res]
	var good := EconMath.combo_counts(quality)
	deliveries.append({"distance": distance, "quality": quality, "gas_used": gas_used, "rewards": rewards,
			"tier": taken_tier, "mult": mult, "combo": combo,
			"good": good, "mission": taken_mission, "failed": failed.duplicate(), "mission_mult": mm,
			"gift_pay": gift_pay})
	streak = streak + 1 if good else 0
	stars += int(EconMath.mission_spec().get("stars", {}).get("per_delivery", 1))
	taken_tier = "normal"
	taken_dir = 1
	taken_mission = EconMath.simple_mission()
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
		"stars": stars,
		"reason": end_reason,
	}


## Ordena as ofertas por distancia levando tipo de plataforma, lado e missao juntos.
func _sort_offers() -> void:
	var idx := range(offers.size())
	idx.sort_custom(func(a: int, b: int) -> bool: return offers[a] < offers[b])
	var d: Array[float] = []
	var t: Array[String] = []
	var dirs: Array[int] = []
	var ms: Array[Dictionary] = []
	var sl: Array[String] = []
	for i: int in idx:
		d.append(offers[i])
		t.append(offer_tiers[i])
		dirs.append(offer_dirs[i])
		ms.append(offer_mission[i])
		sl.append(offer_slot[i])
	offers = d
	offer_tiers = t
	offer_dirs = dirs
	offer_mission = ms
	offer_slot = sl


## Pedido novo do espaco slot: distancia da faixa do espaco, plataforma normal e a estrela 1 (o jogador escolhe no
## cartao), lado e partes da Dupla pelo sorteador proprio.
func _add_slot_offer(slot: String) -> void:
	offers.append(EconMath.slot_distance(planet_id, slot, _rng.randf()))
	offer_tiers.append("normal")
	offer_slot.append(slot)
	offer_dirs.append(-1 if _rng_extra.randf() < _left_chance else 1)
	var kind := EconMath.slot_kind(slot)
	var st := EconMath.mission_stars(kind, unlocked, planet_id, stats)
	offer_mission.append(EconMath.mission_of(kind, st[0], unlocked, planet_id, stats, _rng_extra) if not st.is_empty()
			else EconMath.simple_mission())


## Lado e missao de uma oferta nova (sorteador proprio).
func _draw_extra() -> void:
	offer_dirs.append(-1 if _rng_extra.randf() < _left_chance else 1)
	offer_mission.append(EconMath.draw_mission(planet_id, unlocked, boost, stats, _rng_extra))


func _draw_distance() -> float:
	var r: Array = _planet["distance"]
	return exp(_rng.randf_range(log(float(r[0])), log(float(r[1]))))
