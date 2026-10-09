## Estado do progresso do jogador (recursos, niveis, recordes). Regras numericas via EconMath.
## Fase 2: recursos da sessao (save na Fase 7). Emite Events.resources_changed ao mudar.
extends Node

var resources: Dictionary = {}
var levels: Dictionary = {}
var current_planet := "luna"          # so a Lua por enquanto (os outros mundos voltam depois)
var runs_done := 0
var income_history: Array = []        # [{earned, seconds}] dos ultimos runs (base da renda da frota)
var stars := 0                        # estrelas ACUMULADAS no jogo todo (1 por entrega; estatistica)
var world_stars: Dictionary = {}      # v17: estrelas feitas em cada mundo -> andam a Estrada DAQUELE mundo
var mission_nodes: Array = []         # nos da arvore de missoes ja liberados (ids; vem da Estrada)
var road_reached: Array = []          # paradas da Estrada das Estrelas ja alcancadas (ids; EconMath.road)
var road_seen: Array = []             # paradas que o jogador ja viu festejar na PROGRESSAO
var rep_points: Dictionary = {}       # Reputacao por ratinho (v14): tipo de missao -> pontos (permanentes)
var missions_new: Dictionary = {}     # tipo recem-liberado -> runs em que ainda aparece mais (new_boost)
var play_seconds := 0.0               # tempo de jogo acumulado
var settings: Dictionary = {}         # opcoes (volumes por bus) — salvas junto
var records: Dictionary = {}          # recordes pessoais POR MUNDO (v16): planeta -> {RECORDS id -> maior valor}
var tips: Array = []                  # dicas sem texto ja aprendidas (Coach: "thrust", "rotate"); nunca voltam

const BUSES := ["Master", "Music", "Ambience", "SFX", "UI"]   # Master = "Geral" (0 = silencia tudo)
## Dicas do comeco (lista e significado no SaveData.TIP_IDS).
const TIPS := SaveData.TIP_IDS
## Ajuda de voo que todo jogador ja tem (a raiz da arvore do Painel de bordo; as outras vem da spec, 'assist').
const ASSIST_FREE := "nav_arrow"
## Recordes pessoais (estatistica, nao economia; v15 "bata seu recorde": todos medidos num run, RunState.record_values):
## id -> [nome para o jogador, icone 12 px, figura 24 px do cartao do resumo]. A ordem e a da tela (dinheiro primeiro).
const RECORDS := {
	"run_money": ["dinheiro numa viagem", "credits", "coin"],
	"run_deliveries": ["entregas numa viagem", "expedition", "rat"],
	"run_distance": ["distância voada numa viagem", "distance", "arrow"],
	"run_perfect": ["pousos perfeitos numa viagem", "quality", "check"],
	"best_delivery": ["maior entrega", "credits", "coins"],
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
	world_stars = {}
	mission_nodes = []
	missions_new = {}
	road_reached = []
	road_seen = []
	rep_points = {}
	runs_done = 0
	play_seconds = 0.0
	records = {}
	tips = []
	_check_road(true)


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
	if not can_buy(upgrade_id):
		return false
	var before := resources.duplicate()
	if not Purchases.buy(resources, levels, upgrade_id):
		return false
	_emit_changes(before)
	Events.upgrade_bought.emit(upgrade_id, int(levels[upgrade_id]))
	return true


## Compra o maximo de niveis possivel. Retorna quantos.
func buy_upgrade_max(upgrade_id: String) -> int:
	if not can_buy(upgrade_id):
		return 0
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


## A Estrada deixa comprar este upgrade? (habilidades/ajudas vem prontas; Frota/Piloto so depois da parada)
func can_buy(upgrade_id: String) -> bool:
	return EconMath.road_can_buy(upgrade_id, road_reached)


## Soma estrelas ganhas (entregas do run) no total e no mundo atual, e anda a Estrada desse mundo.
func add_stars(n: int) -> void:
	if n == 0:
		return
	stars += n
	world_stars[current_planet] = stars_in(current_planet) + n
	Events.stars_changed.emit(stars)
	_check_road()


## Estrelas feitas num mundo (planet "" = o atual).
func stars_in(planet: String = "") -> int:
	return int(world_stars.get(planet if planet != "" else current_planet, 0))


## Marca as paradas da Estrada que o total de estrelas ja alcanca e entrega o premio de cada uma: ratinho (no da
## arvore de missoes), habilidade/ajuda (nivel 1), Frota/Piloto (passam a poder ser comprados). quiet = sem festa
## (jogo novo, save carregado): a parada ja conta como vista.
func _check_road(quiet: bool = false) -> void:
	var changed := true
	while changed:                                             # completar um mundo abre o proximo (parada 0 dele)
		changed = false
		for w: String in worlds():
			for stop: Dictionary in EconMath.road_reached_now(stars_in(w), road_reached, w):
				_reach_stop(stop, quiet)
				changed = true


func _reach_stop(stop: Dictionary, quiet: bool) -> void:
	var id := str(stop["id"])
	road_reached.append(id)
	match str(stop["type"]):
		"mission":
			if not mission_nodes.has(id):
				mission_nodes.append(id)
			for node: Dictionary in EconMath.mission_spec().get("nodes", []):
				if node["id"] == id:
					missions_new[node["kind"]] = int(EconMath.mission_spec().get("new_boost", {}).get("runs", 0))
		"grant":
			levels[id] = maxi(int(levels.get(id, 0)), 1)
	if quiet or stop["type"] == "start":
		road_seen.append(id)
	else:
		Events.road_reached.emit(id)


## Paisagens do relevo liberadas (v15): as do jogo novo (world.json terrain.landscapes.start) + as paradas
## "land_<id>" alcancadas na Estrada. Cada missao sorteia uma delas (TerrainGen.pick_landscape).
func landscapes() -> Array[String]:
	var out: Array[String] = []
	out.assign(WorldConfig.load_config()["terrain"]["landscapes"]["start"])
	for id: String in road_reached:
		if id.begins_with("land_") and not id.substr(5) in out:
			out.append(id.substr(5))
	return out


## Nivel de reputacao (0..3) com o ratinho do tipo kind.
func rep_level(kind: String) -> int:
	return EconMath.reputation_level(int(rep_points.get(kind, 0)))


## Paradas alcancadas que o jogador ainda nao viu na PROGRESSAO (em ordem).
func road_news() -> Array:
	return road_reached.filter(func(id: String) -> bool: return not road_seen.has(id))


## A parada ja foi mostrada ao jogador.
func mark_road_seen(id: String) -> void:
	if not road_seen.has(id):
		road_seen.append(id)


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


## Valor de um recorde como texto (dinheiro e maior entrega = moedas; distancia em m/km; contagens inteiras).
static func record_text(key: String, value: float) -> String:
	match key:
		"run_money", "best_delivery":
			return EconMath.fmt(value)
		"run_distance":
			return ("%d m" % int(value)) if value < 1000.0 else ("%.1f km" % (value / 1000.0)).replace(".", ",")
	return "%d" % int(value)


## Recordes de um mundo ({id: valor}; vazio = nunca voou la). planet "" = mundo atual.
func world_records(planet: String = "") -> Dictionary:
	return records.get(planet if planet != "" else current_planet, {})


## Registra um valor para um recorde do mundo atual. Retorna true se bateu o recorde anterior (e havia um: a primeira
## marca nao conta).
func note_record(key: String, value: float) -> bool:
	if not records.has(current_planet):
		records[current_planet] = {}
	var rec: Dictionary = records[current_planet]
	var old := float(rec.get(key, 0.0))
	if value <= old:
		return false
	rec[key] = value
	return old > 0.0


## Mundos liberados (v17, viagem): o primeiro + cada mundo cujo anterior esta completo (parada complete_<id>).
func worlds() -> Array[String]:
	var out: Array[String] = []
	var prev := ""
	for p: Dictionary in EconMath.spec["planets"]:
		var id := str(p["id"])
		if prev == "" or world_done(prev):
			out.append(id)
		else:
			break
		prev = id
	return out


## O mundo esta completo (alcancou a ultima parada da Estrada dele)?
func world_done(planet: String) -> bool:
	return road_reached.has("complete_" + planet)


## Escolhe o mundo do proximo voo (so os liberados). Retorna false se o mundo ainda esta fechado.
func select_world(planet: String) -> bool:
	if not planet in worlds():
		return false
	current_planet = planet
	return true


## Estado para o save (SaveData.serialize).
func save_state() -> Dictionary:
	return {"resources": resources, "levels": levels, "current_planet": current_planet,
			"income_history": income_history, "stars": stars, "mission_nodes": mission_nodes,
			"world_stars": world_stars, "missions_new": missions_new, "road_reached": road_reached, "road_seen": road_seen, "rep_points": rep_points, "runs_done": runs_done, "play_seconds": play_seconds, "settings": settings, "records": records, "tips": tips}


## Aplica um estado ja validado por SaveData.deserialize.
func apply_save_state(st: Dictionary) -> void:
	resources = st["resources"]
	levels = st["levels"]
	current_planet = st["current_planet"]
	income_history = st["income_history"]
	stars = int(st.get("stars", 0))
	world_stars = st.get("world_stars", {})
	mission_nodes = st.get("mission_nodes", [])
	missions_new = st.get("missions_new", {})
	road_reached = st.get("road_reached", [])
	road_seen = st.get("road_seen", [])
	rep_points = st.get("rep_points", {})
	runs_done = st["runs_done"]
	play_seconds = st["play_seconds"]
	settings = st["settings"]
	records = st.get("records", {})
	tips = st.get("tips", [])
	_check_road(true)                                          # save antigo/migrado: o que as estrelas ja alcancam
	apply_settings()
	for res: String in resources:
		Events.resources_changed.emit(res, resources[res])


# ---------------------------------------------------------------- primeiros minutos (world.json > onboarding)
## Regras do comeco do jogo (auditoria dos primeiros minutos, 2026-10-08).
func onboarding() -> Dictionary:
	return WorldConfig.load_config().get("onboarding", {})


## Aprendiz: ainda nao fez apprentice_stars entregas (1 estrela por entrega). Batida nao acaba o run, pouso devagar
## fora da plataforma nao bate, pedidos fora do alcance ficam escondidos. Fora no sandbox.
func apprentice() -> bool:
	return not Sandbox.active() and stars < int(onboarding().get("apprentice_stars", 0))


## 1o salto do jogo (nenhuma entrega ainda): ja aceito, perto, relevo baixo e sem minijogo.
func first_hop() -> bool:
	return not Sandbox.active() and stars == 0


## Revelacao por etapas: minijogo, placar de recordes, reputacao e x10/MAX aparecem depois do comeco.
func shows_minigame() -> bool:
	return Sandbox.active() or stars >= int(onboarding().get("minigame_from_stars", 0))


func shows_records() -> bool:
	return Sandbox.active() or runs_done >= int(onboarding().get("records_from_runs", 0))


func shows_reputation() -> bool:
	return Sandbox.active() or stars >= int(onboarding().get("reputation_from_stars", 0))


func shows_bulk() -> bool:
	var n := 0
	for id: String in levels:
		n += int(levels[id])
	return Sandbox.active() or n >= int(onboarding().get("bulk_from_levels", 0))


## Ajuda de voo emprestada ao aprendiz (world.json > onboarding.lent_assists; Smart Steering do Mario Kart): aparece no
## voo como se fosse comprada; a NAVE continua mostrando so as compradas (assist_on).
func assist_lent(id: String) -> bool:
	return apprentice() and id in (onboarding().get("lent_assists", []) as Array)


## Dica sem texto ja aprendida (o jogador usou o comando)?
func tip_done(id: String) -> bool:
	return id in tips


## O "tente de novo" em figura ja apareceu (uma vez no jogo todo, na 1a batida; o id guarda o motivo dela).
func crash_taught() -> bool:
	for id: Variant in tips:
		if str(id).begins_with("crash_"):
			return true
	return false


func learn_tip(id: String) -> void:
	if id in TIPS and not id in tips:
		tips.append(id)


## Alguma peca da NAVE (aba PECAS) da para comprar agora (Mapa: "!" na NAVE; fim do run: vai direto para a NAVE).
func can_afford_any() -> bool:
	for r: Dictionary in upgrade_rows():
		if r["affordable"] and str(r["id"]) in RoadText.PARTS and can_buy(str(r["id"])):
			return true
	return false


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
