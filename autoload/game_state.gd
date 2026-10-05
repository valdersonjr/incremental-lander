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
var play_seconds := 0.0               # tempo de jogo acumulado
var settings: Dictionary = {}         # opcoes (volumes por bus) — salvas junto
var records: Dictionary = {}          # recordes pessoais (pos-jogo): RECORDS -> maior valor ja feito

const BUSES := ["Music", "Ambience", "SFX", "UI"]
## Recordes pessoais (estatistica, nao economia): id -> [nome para o jogador, icone].
const RECORDS := {
	"best_delivery": ["maior entrega", "credits"],
	"longest_hop": ["salto mais longo (m)", "distance"],
	"best_combo": ["maior combo", "quality"],
	"best_run": ["run mais rico", "expedition"],
}

var _fullscreen_applied := false
var _bus_base_db: Dictionary = {}     # volume de cada bus no default_bus_layout (a opcao soma por cima)


func _ready() -> void:
	EconMath.load_spec()
	reset()
	apply_settings()


func _process(delta: float) -> void:
	play_seconds += delta


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
	prestige_pending = false
	income_history = []
	reached_goal = false
	runs_done = 0
	play_seconds = 0.0
	records = {}


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
func locked_upgrades() -> Array[Dictionary]:
	return Purchases.locked_upgrades(levels, unlocked_planets, shop)


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
	# planetas mantidos (Cartas de navegacao) mas a nave voltou ao inicio: nao deixar o jogador num mundo em que nao
	# decola (o run acabaria na hora, sem entregas)
	if not Purchases.can_launch(current_planet, ship_stats()):
		current_planet = Purchases.best_launchable(unlocked_planets, ship_stats())
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


## Registra um valor para um recorde. Retorna true se bateu o recorde anterior (e havia um: a primeira marca nao conta).
func note_record(key: String, value: float) -> bool:
	var old := float(records.get(key, 0.0))
	if value <= old:
		return false
	records[key] = value
	return old > 0.0


## Libera o planeta objetivo? Chamado apos unlock_planet para disparar o final.
func check_goal(planet_id: String) -> bool:
	var goal: String = EconMath.spec["targets"].get("goal", {}).get("planet", "")
	if planet_id == goal and not reached_goal:
		reached_goal = true
		Events.goal_reached.emit(planet_id)
		return true
	return false


## Estado para o save (SaveData.serialize).
func save_state() -> Dictionary:
	return {"resources": resources, "levels": levels, "shop": shop, "prestige_points": prestige_points,
			"prestige_pending": prestige_pending, "unlocked": unlocked_planets, "current_planet": current_planet,
			"cycle_earned": cycle_earned, "income_history": income_history, "reached_goal": reached_goal,
			"runs_done": runs_done, "play_seconds": play_seconds, "settings": settings, "records": records}


## Aplica um estado ja validado por SaveData.deserialize.
func apply_save_state(st: Dictionary) -> void:
	resources = st["resources"]
	levels = st["levels"]
	shop = st["shop"]
	prestige_points = st["prestige_points"]
	prestige_pending = st["prestige_pending"]
	unlocked_planets = st["unlocked"]
	current_planet = st["current_planet"]
	cycle_earned = st["cycle_earned"]
	income_history = st["income_history"]
	reached_goal = st["reached_goal"]
	runs_done = st["runs_done"]
	play_seconds = st["play_seconds"]
	settings = st["settings"]
	records = st.get("records", {})
	apply_settings()
	for res: String in resources:
		Events.resources_changed.emit(res, resources[res])


## Volume 0..1 de um bus (padrao 1).
func volume(bus: String) -> float:
	return float(settings.get("vol_" + bus, 1.0))


func set_volume(bus: String, value: float) -> void:
	settings["vol_" + bus] = clampf(value, 0.0, 1.0)
	apply_settings()


## Filtro CRT ligado (padrao: sim).
func crt_enabled() -> bool:
	return bool(settings.get("crt", true))


func set_crt(on: bool) -> void:
	settings["crt"] = on
	apply_settings()


## Tremor de tela na batida e em pousos duros (padrao: sim).
func shake_enabled() -> bool:
	return bool(settings.get("shake", true))


func set_shake(on: bool) -> void:
	settings["shake"] = on
	apply_settings()


## Tela cheia (padrao: nao). F11 / Alt+Enter alternam (Main).
func fullscreen() -> bool:
	return bool(settings.get("fullscreen", false))


func set_fullscreen(on: bool) -> void:
	settings["fullscreen"] = on
	apply_settings()


## Teclas de uma acao remapeavel (nomes): as escolhidas pelo jogador ou as padrao de world.json.
func keys_for(action: String) -> Array:
	var custom: Variant = settings.get("keys")
	if custom is Dictionary and (custom as Dictionary).get(action) is Array:
		return custom[action]
	return WorldConfig.default_keys(action)


## Remapeia a tecla principal de uma acao: key_name passa a ser a 1a tecla dela e sai de qualquer outra acao.
func remap_key(action: String, key_name: String) -> void:
	var custom := {}
	for a: String in WorldConfig.remappable():
		var ks: Array = keys_for(a).duplicate()
		ks.erase(key_name)
		custom[a] = ks
	var mine: Array = custom.get(action, [])
	if mine.is_empty():
		mine.append(key_name)
	else:
		mine[0] = key_name
	custom[action] = mine
	settings["keys"] = custom
	apply_settings()


## Volta as teclas ao padrao.
func reset_keys() -> void:
	settings.erase("keys")
	apply_settings()



## Aplica as opcoes (volumes nos buses de audio, teclas, tela cheia) e avisa quem mostra as outras (filtro CRT).
func apply_settings() -> void:
	WorldConfig.register_input()
	for action: String in WorldConfig.remappable():
		WorldConfig.set_keys(action, keys_for(action))
	# tela cheia so quando a opcao muda (nao briga com a tela cheia do sistema, ex.: botao verde do macOS)
	if fullscreen() != _fullscreen_applied and DisplayServer.get_name() != "headless":
		_fullscreen_applied = fullscreen()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if _fullscreen_applied
				else DisplayServer.WINDOW_MODE_WINDOWED)
	for bus: String in BUSES:
		var idx := AudioServer.get_bus_index(bus)
		if idx >= 0:
			if not _bus_base_db.has(bus):
				_bus_base_db[bus] = AudioServer.get_bus_volume_db(idx)
			var v := volume(bus)
			AudioServer.set_bus_mute(idx, v <= 0.0)
			AudioServer.set_bus_volume_db(idx, float(_bus_base_db[bus]) + linear_to_db(maxf(v, 0.0001)))
	Events.settings_changed.emit()
