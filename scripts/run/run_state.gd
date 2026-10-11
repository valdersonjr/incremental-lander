## Estado de um run (logica pura, testavel): ofertas de entrega, entregas feitas, ganhos e fim do run.
## Regras da economy-balance (run-model.md): ofertas log-uniformes na faixa do planeta, oferta cumprida e
## substituida (regenerate), sem teto de entregas (v15: o gas de cada salto cresce com fatigue(); o run acaba pelo gas
## ou na batida), pagamento via EconMath.delivery_pay (qualidade x
## tipo de plataforma x reputacao do ratinho x missao).
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
var rep_points: Dictionary = {}           # Reputacao por ratinho (v14): tipo -> pontos (vem do GameState no inicio do
                                          # run; complete_delivery soma; o Main devolve ao GameState a cada entrega)
var perfect_streak := 0                   # pousos perfeitos seguidos neste run (som do pouso perfeito)
var perfect_count := 0                    # pousos perfeitos neste run (recorde run_perfect)
var distance_flown := 0.0                 # metros entregues neste run (taxi soma os 2 trechos; recorde run_distance)
var best_delivery := 0.0                  # maior pagamento de uma entrega neste run (recorde best_delivery)
var offer_dirs: Array[int] = []          # lado de cada oferta: 1 = direita, -1 = esquerda
var offer_mission: Array[Dictionary] = [] # missao de cada oferta ({kind, star, parts})
var offer_slot: Array[String] = []        # espaco de cada oferta (simple0..2 ou o tipo do ratinho)
var taken_tier := "normal"                # tipo da plataforma da entrega em andamento
var taken_dir := 1                        # lado da entrega em andamento
var taken_mission: Dictionary = {}        # missao da entrega em andamento
var stars := 0                            # estrelas ganhas neste run (contracts.missions.stars.per_delivery)
var minigames_played := 0                 # entregas com minijogo neste run (auditoria T4: selo no resumo)
var minigames_full := 0                   # ... e quantas com o minijogo feito por inteiro
var unlocked: Dictionary = {"simple": 1}  # missoes liberadas pelo jogador ({kind: estrela})
var boost: Dictionary = {}                # missoes recem-liberadas ({kind: runs}) aparecem mais
var deliveries: Array[Dictionary] = []
var earned: Dictionary = {}               # recurso -> quantidade ganha neste run
var over := false
var end_reason := ""

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
		run.unlocked = p_unlocked.duplicate()
	var sig := str(EconMath._find("planets", p_planet_id).get("mission", ""))
	if sig != "":                                              # v17: o pedido do mundo vem sempre (pelo menos a 1)
		run.unlocked[sig] = maxi(1, int(run.unlocked.get(sig, 0)))
	run.boost = p_boost
	run._rng.seed = seed_value
	run._rng_extra.seed = seed_value * 7919 + 17
	run._left_chance = float(WorldConfig.load_config().get("routes", {}).get(p_planet_id, {}).get("left_chance", 0.0))
	for p: Dictionary in EconMath.spec["planets"]:
		if p["id"] == p_planet_id:
			run._planet = p
	var c: Dictionary = EconMath.spec["contracts"]
	if not EconMath.mission_kinds(p_planet_id).is_empty():
		for slot in EconMath.mission_slots(run.unlocked, p_planet_id):
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
	if m["kind"] == "double":
		return
	if star in stars_for(index):
		offer_mission[index] = EconMath.mission_of(str(m["kind"]), star, unlocked, planet_id, stats, _rng_extra)


## Estrelas que o jogador pode escolher no pedido index.
func stars_for(index: int) -> Array[int]:
	return EconMath.mission_stars(str(offer_mission[index]["kind"]), unlocked, planet_id, stats)


## Dados de uma oferta para a UI/piloto: distancia, tipo de plataforma e multiplicador, missao, pagamento (perfeito e
## tipico, ja com a reputacao atual; taxi soma os 2 trechos), gas estimado (Pesada: motor mais fraco; Cabo: dv_mult;
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
		"pay_best": _pay(d, d2, 1.0, tier, mm, str(m.get("kind", "simple"))) + _mg_pay(d, m, 1.0),
		"pay_typical": _pay(d, d2, 0.7, tier, mm, str(m.get("kind", "simple"))) + _mg_pay(d, m, 0.7),
		"gas_est": gas_est,
		"reachable": gas_est <= gas_left,
	}


## Pagamento tipico do pedido index se o jogador escolher a plataforma tier (os 3 botoes do cartao).
func pay_for_tier(index: int, tier: String) -> float:
	var d: float = offers[index]
	var m: Dictionary = offer_mission[index]
	return _pay(d, leg2_m(m, d), 0.7, tier, EconMath.mission_mult(m), str(m.get("kind", "simple"))) + _mg_pay(d, m, 0.7)


## v18: bonus do minijogo do mundo que o pedido pode render (frac = parte cumprida estimada; Lua: queijinhos da
## estrela, Cogumelos: quiques) — o cartao mostra o que a estrela maior vale.
func _mg_pay(d: float, m: Dictionary, frac: float) -> float:
	return EconMath.minigame_pay(planet_id, d, stats, frac, maxi(1, int(m.get("star", 1))))


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
	return dv * EconMath.mission_dv_mult(m) / float(stats["efficiency"]) * fatigue()


## Cansaco do run (v15): multiplicador do gas da proxima missao (EconMath.run_fatigue_mult das entregas feitas).
func fatigue() -> float:
	return EconMath.run_fatigue_mult(deliveries.size())


## Distancia do 2o trecho do taxi (0 = sem): leg2 x d, nunca menor que a entrega mais curta do mundo.
func leg2_m(m: Dictionary, d: float) -> float:
	var f := EconMath.mission_leg2(m)
	return maxf(d * f, float(_planet["distance"][0])) if f > 0.0 else 0.0


## Nivel de reputacao (0..3) do ratinho do tipo kind.
func rep_level(kind: String) -> int:
	return EconMath.reputation_level(int(rep_points.get(kind, 0)))


func _pay(d: float, d2: float, quality: float, tier: String, mm: float, kind: String) -> float:
	var lv := rep_level(kind)
	var pay := EconMath.delivery_pay(planet_id, d, stats, quality, tier, lv, mm)
	if d2 > 0.0:
		pay += EconMath.delivery_pay(planet_id, d2, stats, quality, tier, lv, mm)
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


## Registra uma entrega concluida (na plataforma taken_tier, com a reputacao atual)
## e devolve as recompensas {recurso: qtd}. Depois a Reputacao do ratinho: regra cumprida soma pontos (pouso perfeito
## soma mais); falhou = 0.
## gift_pay = creditos do presente pego no alto do morro (EconMath.gift_value; v10), somados ao pagamento.
## failed = kinds das regras da missao taken_mission que falharam (paga mult x fail_mult; nunca acaba o run);
## partial = {kind: parte cumprida} do minijogo (v18: credito parcial, EconMath.fail_pay).
## Taxi: distance = 1o trecho; o 2o (leg2 x distance) tambem paga. Ganha estrelas (stars.per_delivery).
## Detalhes da conta ficam em deliveries[-1] (base, mult, rep, missao) para o HUD mostrar.
func complete_delivery(distance: float, quality: float, gas_used: float, failed: Array = [],
		gift_pay: float = 0.0, perfect: bool = false, partial: Dictionary = {}, minigame: Array = [0, 0]) -> Dictionary:
	var kind := str(taken_mission.get("kind", "simple"))
	var rep := EconMath.reputation_mult(rep_level(kind))
	var mult := float(EconMath.pad_tier(taken_tier)["mult"])
	var mm := EconMath.mission_mult(taken_mission, failed, partial)
	var pay := _pay(distance, leg2_m(taken_mission, distance), quality, taken_tier, mm, kind) + gift_pay
	var rewards := {}
	var weights: Dictionary = _planet.get("rewards", {"credits": 1.0})
	for res: String in weights:
		rewards[res] = pay * float(weights[res])
		earned[res] = float(earned.get(res, 0.0)) + rewards[res]
	deliveries.append({"distance": distance, "quality": quality, "gas_used": gas_used, "rewards": rewards,
			"tier": taken_tier, "mult": mult, "rep": rep,
			"perfect": perfect, "mission": taken_mission, "failed": failed.duplicate(), "mission_mult": mm,
			"gift_pay": gift_pay, "minigame": minigame.duplicate()})
	if int(minigame[1]) > 0:                                   # selo do resumo: minijogos feitos por inteiro
		minigames_played += 1
		minigames_full += 1 if int(minigame[0]) >= int(minigame[1]) else 0
	var pts := EconMath.reputation_points(failed.is_empty(), perfect)   # regra cumprida; pouso perfeito vale mais
	rep_points[kind] = int(rep_points.get(kind, 0)) + pts
	deliveries[-1]["rep_kind"] = kind
	deliveries[-1]["rep_pts"] = pts
	perfect_streak = perfect_streak + 1 if perfect else 0
	perfect_count += 1 if perfect else 0
	distance_flown += distance + leg2_m(taken_mission, distance)
	best_delivery = maxf(best_delivery, float(rewards.get("credits", 0.0)))
	stars += int(EconMath.mission_spec().get("stars", {}).get("per_delivery", 1))
	taken_tier = "normal"
	taken_dir = 1
	taken_mission = EconMath.simple_mission()
	return rewards


## v21 (pista "Mais longe"): pouso na plataforma a x_m metros do comeco, pulando `skipped` plataformas. Paga
## EconMath.track_pay (distancia do comeco x qualidade x plataforma x pulo) e da as estrelas da nota do pouso.
## distance_flown = o mais longe que a nave chegou (recorde do mundo).
func complete_track_landing(x_m: float, skipped: int, quality: float, tier: String, gas_used: float,
		perfect: bool) -> Dictionary:
	var pay := EconMath.track_pay(planet_id, x_m, stats, quality, tier, skipped)
	var rewards := _add_earned(pay)
	var st := EconMath.landing_stars(quality)
	deliveries.append({"distance": x_m, "quality": quality, "gas_used": gas_used, "rewards": rewards, "tier": tier,
			"mult": float(EconMath.pad_tier(tier)["mult"]), "skipped": skipped, "perfect": perfect, "stars": st,
			"mission": EconMath.simple_mission(), "failed": [], "rep": 1.0})
	perfect_streak = perfect_streak + 1 if perfect else 0
	perfect_count += 1 if perfect else 0
	distance_flown = maxf(distance_flown, x_m)
	best_delivery = maxf(best_delivery, float(rewards.get("credits", 0.0)))
	stars += st
	return rewards


## Moedas soltas na pista (moeda no ar, marco): entram no ganho do run sem contar como pouso.
func add_bonus(amount: float) -> Dictionary:
	return _add_earned(amount)


## Distancia alcancada em voo (m do comeco): o recorde conta ate onde a nave foi, nao so o ultimo pouso.
func note_distance(x_m: float) -> void:
	distance_flown = maxf(distance_flown, x_m)


func _add_earned(amount: float) -> Dictionary:
	var rewards := {}
	var weights: Dictionary = _planet.get("rewards", {"credits": 1.0})
	for res: String in weights:
		rewards[res] = amount * float(weights[res])
		earned[res] = float(earned.get(res, 0.0)) + rewards[res]
	return rewards


## Numeros do run para os recordes pessoais (GameState.RECORDS): o dinheiro e so o das entregas (+ presentes).
func record_values() -> Dictionary:
	return {"run_money": float(earned.get("credits", 0.0)), "run_deliveries": float(deliveries.size()),
			"run_distance": distance_flown, "run_perfect": float(perfect_count), "best_delivery": best_delivery}


## Batida: a entrega em andamento e perdida e o run acaba (o que ja foi ganho fica; nao ganha reputacao).
func crash(reason: String) -> void:
	perfect_streak = 0
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
		"minigames": [minigames_full, minigames_played],
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
