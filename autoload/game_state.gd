## Estado do progresso do jogador (recursos, niveis, loja, prestigio). Regras numericas via EconMath.
## Fase 2: recursos da sessao (save na Fase 7). Emite Events.resources_changed ao mudar.
extends Node

var resources: Dictionary = {}
var levels: Dictionary = {}
var shop: Dictionary = {}
var prestige_points := 0.0
var current_planet := "luna"
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
