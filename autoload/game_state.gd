## Estado do progresso do jogador (recursos, niveis, loja, prestigio). Regras numericas via EconMath.
## Fase 2: recursos da sessao (save na Fase 7). Emite Events.resources_changed ao mudar.
extends Node

var resources: Dictionary = {}
var levels: Dictionary = {}
var shop: Dictionary = {}
var prestige_points := 0.0
var current_planet := "luna"
var unlocked_planets: Array = ["luna"]
var runs_done := 0
var cycle_earned: Dictionary = {}     # ganhos desde o ultimo prestigio (base do ganho de Poeira)
var prestige_pending := false         # Poeira coletada; falta gastar na loja e concluir o recomeco
var income_history: Array = []        # [{earned, seconds}] dos ultimos runs (base da renda da frota)
var reached_goal := false             # chegou ao planeta final (targets.goal)


func _ready() -> void:
	EconMath.load_spec()
	reset()


## Volta ao estado inicial da spec (recursos iniciais, sem upgrades).
func reset() -> void:
	resources.clear()
	for r: Dictionary in EconMath.spec["resources"]:
		resources[r["id"]] = float(r.get("start", 0.0))
	levels.clear()
	shop.clear()
	prestige_points = 0.0
	cycle_earned.clear()
	unlocked_planets = ["luna"]
	current_planet = "luna"


## Quantidade de um recurso.
func amount(resource_id: String) -> float:
	return float(resources.get(resource_id, 0.0))


## Soma recompensas {recurso: qtd} e avisa pelo Events.
func add_rewards(rewards: Dictionary) -> void:
	for res: String in rewards:
		resources[res] = amount(res) + float(rewards[res])
		cycle_earned[res] = float(cycle_earned.get(res, 0.0)) + float(rewards[res])
		Events.resources_changed.emit(res, resources[res])


## Stats atuais da nave (upgrades + prestigio + loja).
func ship_stats() -> Dictionary:
	return EconMath.ship_stats(levels, prestige_points, shop)


## Compra 1 nivel de um upgrade (regras em Purchases/EconMath). Retorna true se comprou.
func buy_upgrade(upgrade_id: String) -> bool:
	var before := resources.duplicate()
	if not Purchases.buy(resources, levels, upgrade_id, unlocked_planets, shop):
		return false
	_emit_changes(before)
	Events.upgrade_bought.emit(upgrade_id, int(levels[upgrade_id]))
	return true


## Compra o maximo de niveis possivel. Retorna quantos.
func buy_upgrade_max(upgrade_id: String) -> int:
	var before := resources.duplicate()
	var n := Purchases.buy_max(resources, levels, upgrade_id, unlocked_planets, shop)
	if n > 0:
		_emit_changes(before)
		Events.upgrade_bought.emit(upgrade_id, int(levels[upgrade_id]))
	return n


## Linhas de upgrades disponiveis para o hangar.
func upgrade_rows() -> Array[Dictionary]:
	return Purchases.upgrade_rows(resources, levels, unlocked_planets, shop, prestige_points)


func _emit_changes(before: Dictionary) -> void:
	for res: String in resources:
		if not is_equal_approx(float(before.get(res, 0.0)), float(resources[res])):
			Events.resources_changed.emit(res, resources[res])


## Libera um planeta (custo/requisitos da spec). Retorna true se liberou.
func unlock_planet(planet_id: String) -> bool:
	var before := resources.duplicate()
	if not Purchases.unlock_planet(resources, unlocked_planets, planet_id, shop, levels):
		return false
	_emit_changes(before)
	Events.planet_unlocked.emit(planet_id)
	check_goal(planet_id)
	return true


## Linhas de planetas para o hangar.
func planet_rows() -> Array[Dictionary]:
	return Purchases.planet_rows(resources, unlocked_planets, shop, levels, ship_stats())


## Estado no formato usado por Prestige (referencias aos mesmos dicionarios).
func prestige_state() -> Dictionary:
	return {"resources": resources, "levels": levels, "shop": shop, "unlocked": unlocked_planets,
			"current_planet": current_planet, "prestige_points": prestige_points, "cycle_earned": cycle_earned}


## Recomeco, passo 1: coleta a Poeira. Enquanto prestige_pending, o jogador so compra na loja.
func begin_prestige() -> float:
	var st := prestige_state()
	var g := Prestige.collect(st)
	if g <= 0.0:
		return 0.0
	_pull(st)
	prestige_pending = true
	Events.prestiged.emit(g, prestige_points)
	return g


## Recomeco, passo 2: aplica o reset com o que foi comprado na loja.
func finish_prestige() -> void:
	if not prestige_pending:
		return
	var st := prestige_state()
	Prestige.reset(st)
	_pull(st)
	prestige_pending = false
	for res: String in resources:
		Events.resources_changed.emit(res, resources[res])


func _pull(st: Dictionary) -> void:
	resources = st["resources"]
	levels = st["levels"]
	unlocked_planets = st["unlocked"]
	current_planet = st["current_planet"]
	prestige_points = st["prestige_points"]
	cycle_earned = st["cycle_earned"]


## Compra 1 nivel de item da loja da Poeira.
func buy_shop_item(item_id: String) -> bool:
	var st := prestige_state()
	if not Prestige.buy_shop(st, item_id):
		return false
	Events.resources_changed.emit(EconMath.spec["prestige"]["resource"], amount(EconMath.spec["prestige"]["resource"]))
	return true


## Fecha a contabilidade de um run: registra a renda (para a frota) e paga a frota pelo tempo do run.
## seconds = duracao do run em segundos do modelo. Retorna o que a frota rendeu.
func settle_run(earned: Dictionary, seconds: float) -> Dictionary:
	income_history.append({"earned": earned.duplicate(), "seconds": maxf(seconds, 1.0)})
	if income_history.size() > Fleet.HISTORY:
		income_history = income_history.slice(income_history.size() - Fleet.HISTORY)
	var fleet := Fleet.payout(ship_stats(), income_history, seconds)
	if not fleet.is_empty():
		add_rewards(fleet)
	return fleet


## Libera o planeta objetivo? Chamado apos unlock_planet para disparar o final.
func check_goal(planet_id: String) -> bool:
	var goal: String = EconMath.spec["targets"].get("goal", {}).get("planet", "")
	if planet_id == goal and not reached_goal:
		reached_goal = true
		Events.goal_reached.emit(planet_id)
		return true
	return false
