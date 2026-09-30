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


## Quantidade de um recurso.
func amount(resource_id: String) -> float:
	return float(resources.get(resource_id, 0.0))


## Soma recompensas {recurso: qtd} e avisa pelo Events.
func add_rewards(rewards: Dictionary) -> void:
	for res: String in rewards:
		resources[res] = amount(res) + float(rewards[res])
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
