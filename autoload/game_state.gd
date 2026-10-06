## Estado do progresso do jogador (recursos, niveis, recordes). Regras numericas via EconMath.
## Fase 2: recursos da sessao (save na Fase 7). Emite Events.resources_changed ao mudar.
extends Node

var resources: Dictionary = {}
var levels: Dictionary = {}
var current_planet := "luna"          # so a Lua por enquanto (os outros mundos voltam depois)
var runs_done := 0
var income_history: Array = []        # [{earned, seconds}] dos ultimos runs (base da renda da frota)
var stars := 0                        # estrelas de missao para gastar (1 por entrega; contracts.missions.stars)
var mission_nodes: Array = []         # nos da arvore de missoes ja liberados (ids)
var missions_new: Dictionary = {}     # tipo recem-liberado -> runs em que ainda aparece mais (new_boost)
var play_seconds := 0.0               # tempo de jogo acumulado
var settings: Dictionary = {}         # opcoes (volumes por bus) — salvas junto
var records: Dictionary = {}          # recordes pessoais (pos-jogo): RECORDS -> maior valor ja feito

const BUSES := ["Music", "Ambience", "SFX", "UI"]
## Ajuda de voo que todo jogador ja tem (a raiz da arvore do Painel de bordo; as outras vem da spec, 'assist').
const ASSIST_FREE := "nav_arrow"
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
	current_planet = "luna"
	income_history = []
	stars = 0
	mission_nodes = []
	missions_new = {}
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
		Events.resources_changed.emit(res, resources[res])


## Stats atuais da nave (upgrades).
func ship_stats() -> Dictionary:
	return EconMath.ship_stats(levels)


## Compra 1 nivel de um upgrade (regras em Purchases/EconMath). Retorna true se comprou.
func buy_upgrade(upgrade_id: String) -> bool:
	var before := resources.duplicate()
	if not Purchases.buy(resources, levels, upgrade_id):
		return false
	_emit_changes(before)
	Events.upgrade_bought.emit(upgrade_id, int(levels[upgrade_id]))
	return true


## Compra o maximo de niveis possivel. Retorna quantos.
func buy_upgrade_max(upgrade_id: String) -> int:
	var before := resources.duplicate()
	var n := Purchases.buy_max(resources, levels, upgrade_id)
	if n > 0:
		_emit_changes(before)
		Events.upgrade_bought.emit(upgrade_id, int(levels[upgrade_id]))
	return n


## Linhas de upgrades disponiveis para o hangar.
func upgrade_rows() -> Array[Dictionary]:
	return Purchases.upgrade_rows(resources, levels)


func _emit_changes(before: Dictionary) -> void:
	for res: String in resources:
		if not is_equal_approx(float(before.get(res, 0.0)), float(resources[res])):
			Events.resources_changed.emit(res, resources[res])


## Melhorias da oficina ainda bloqueadas (mostradas com cadeado).
func locked_upgrades() -> Array[Dictionary]:
	return Purchases.locked_upgrades(levels)


## Missoes liberadas ({kind: maior estrela}; a Simples sempre).
func missions_unlocked() -> Dictionary:
	return EconMath.missions_unlocked(mission_nodes)


## Soma estrelas ganhas (entregas do run).
func add_stars(n: int) -> void:
	if n == 0:
		return
	stars += n
	Events.stars_changed.emit(stars)


## Libera um no da arvore de missoes com estrelas. Retorna true se liberou.
func unlock_mission(node_id: String) -> bool:
	for node: Dictionary in EconMath.mission_spec().get("nodes", []):
		if node["id"] != node_id:
			continue
		var cost := EconMath.mission_node_cost(node)
		if stars < cost or not EconMath.mission_node_ok(node, mission_nodes):
			return false
		stars -= cost
		mission_nodes.append(node_id)
		missions_new[node["kind"]] = int(EconMath.mission_spec().get("new_boost", {}).get("runs", 0))
		Events.stars_changed.emit(stars)
		Events.mission_unlocked.emit(node_id)
		return true
	return false


## Da para liberar algum no agora? (aviso na aba PEDIDOS e no resumo do run)
func can_unlock_mission() -> bool:
	for node: Dictionary in EconMath.mission_spec().get("nodes", []):
		if stars >= EconMath.mission_node_cost(node) and EconMath.mission_node_ok(node, mission_nodes):
			return true
	return false


## Fim de um run: os tipos recem-liberados perdem 1 run de destaque.
func tick_missions_new() -> void:
	var out := {}
	for k: String in missions_new:
		if int(missions_new[k]) > 1:
			out[k] = int(missions_new[k]) - 1
	missions_new = out


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


## Estado para o save (SaveData.serialize).
func save_state() -> Dictionary:
	return {"resources": resources, "levels": levels, "current_planet": current_planet,
			"income_history": income_history, "stars": stars, "mission_nodes": mission_nodes,
			"missions_new": missions_new, "runs_done": runs_done, "play_seconds": play_seconds, "settings": settings, "records": records}


## Aplica um estado ja validado por SaveData.deserialize.
func apply_save_state(st: Dictionary) -> void:
	resources = st["resources"]
	levels = st["levels"]
	current_planet = st["current_planet"]
	income_history = st["income_history"]
	stars = int(st.get("stars", 0))
	mission_nodes = st.get("mission_nodes", [])
	missions_new = st.get("missions_new", {})
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


## Ajuda de voo ativa no voo? (Painel de bordo: comprada — "nav_arrow" ja vem — e nao desligada pelo jogador).
func assist_on(id: String) -> bool:
	if bool((settings.get("assists_off", {}) as Dictionary).get(id, false)):
		return false
	return id == ASSIST_FREE or int(levels.get(id, 0)) >= 1


## Liga/desliga uma ajuda ja comprada (para quem quer o desafio). Fica nas opcoes do save.
func set_assist(id: String, on: bool) -> void:
	var off: Dictionary = settings.get("assists_off", {})
	off[id] = not on
	settings["assists_off"] = off
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
