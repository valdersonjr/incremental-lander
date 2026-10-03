## Entrada do jogo: Main -> World (voo) + GUI (HUD, ofertas, resumo). Orquestra o run (Fase 2):
## ofertas -> voo -> entrega -> recompensas (GameState) -> ofertas ... -> resumo -> novo run.
## Args: --demo (piloto automatico escolhe, voa e compra), --seed=N, --hangar_wait=s; dev: ver _apply_dev_args. R reinicia.
extends Node

const FLIGHT_SCENE := preload("res://game/flight/flight.tscn")
const HUD_SCENE := preload("res://game/hud/hud.tscn")
const OFFER_SCENE := preload("res://game/run/offer_panel.tscn")
const SUMMARY_SCENE := preload("res://game/run/run_summary.tscn")
const HANGAR_SCENE := preload("res://game/hangar/hangar.tscn")
const ENDING_SCENE := preload("res://game/ending/ending.tscn")
const TITLE_SCENE := preload("res://game/title/title_screen.tscn")
const PAUSE_SCENE := preload("res://game/pause/pause_menu.tscn")

var _args: Dictionary = {}
var _demo := false
var _run_seed := 0
var _run: RunState = null
var _flight: Flight = null
var _hud: Hud = null
var _offers: OfferPanel = null
var _summary: RunSummary = null
var _hangar: Hangar = null
var _ending: Ending = null
var _title: TitleScreen = null
var _pause: PauseMenu = null
var _run_start_ms := 0

@onready var _world: Node2D = %World
@onready var _gui: CanvasLayer = %GUI


func _ready() -> void:
	WorldConfig.load_config()
	WorldConfig.register_input()
	_args = _parse_args(OS.get_cmdline_user_args())
	_demo = _args.has("demo")
	_run_seed = int(_args.get("seed", WorldConfig.load_config()["demo"]["seed"]))
	_apply_dev_args()
	_hangar = HANGAR_SCENE.instantiate()
	_gui.add_child(_hangar)
	_hangar.visible = false
	_hangar.launch_requested.connect(_on_launch_requested)
	_ending = ENDING_SCENE.instantiate()
	_gui.add_child(_ending)
	_ending.visible = false
	_ending.closed.connect(_open_hangar)
	Events.goal_reached.connect(_on_goal_reached)
	_hangar.title_requested.connect(_show_title)
	_title = TITLE_SCENE.instantiate()
	_gui.add_child(_title)
	_title.visible = false
	_title.play_requested.connect(_on_title_play)
	_title.slot_play_requested.connect(func(slot: int) -> void:
		SaveManager.load_slot(slot)
		_on_title_play())
	_title.new_game_requested.connect(func(slot: int) -> void:
		SaveManager.new_game(slot)
		_start_run())
	_title.current_slot_changed.connect(_build_title_world)
	_title.sandbox_requested.connect(func(planet_id: String, strong: bool) -> void:
		Sandbox.begin(planet_id, strong)
		_title.visible = false
		_build_title_world()                                   # fundo do hangar = o mundo escolhido
		_open_hangar())
	_title.quit_requested.connect(func() -> void:
		SaveManager.save_game()
		get_tree().quit())
	_pause = PAUSE_SCENE.instantiate()
	_gui.add_child(_pause)
	# menu do jogo a partir do hangar: o hangar some e o menu abre sobre o mundo escurecido
	_hangar.menu_requested.connect(func() -> void:
		_hangar.visible = false
		_gui.move_child(_pause, -1)
		_pause.open(PauseMenu.Mode.HANGAR))
	_pause.closed.connect(func() -> void:
		if _pause.mode == PauseMenu.Mode.HANGAR:
			_back_to_hangar())
	_pause.title_requested.connect(func() -> void:
		SaveManager.request_save()
		_show_title())
	_pause.new_game_requested.connect(func() -> void:
		SaveManager.new_game()
		_back_to_hangar())
	# verificacao (demo/dev/--no_title) vai direto ao voo; o jogo normal abre no menu inicial
	if _demo or _args.has("no_title") or _args.keys().any(func(k: String) -> bool: return k.begins_with("dev_") or k == "planet"):
		_start_run()
	else:
		_show_title()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"restart") and not _hangar.visible and not _title.visible and not _pause.visible:
		_start_run()
	elif event.is_action_pressed(&"ui_cancel") and _can_pause():
		get_viewport().set_input_as_handled()
		_pause.open()


## Janela perdeu o foco no meio do voo: pausa (o jogador volta e encontra a nave parada). Fora na gravacao de quadros
## (gdtool capture), em que a janela pode perder o foco sem ninguem jogando.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and _pause != null and _can_pause() \
			and Engine.get_write_movie_path() == "":
		_pause.open()


## Pausa so no voo (HUD na tela, sem resumo/hangar/menu/final por cima) e nunca no demo (verificacao automatica).
func _can_pause() -> bool:
	return not _demo and _hud != null and is_instance_valid(_hud) and _hud.visible and not _summary.visible \
			and not _hangar.visible and not _title.visible and not _ending.visible and not _pause.visible


## Volta do menu do jogo ao hangar, na mesma aba (refresh atualiza o tema e o foco).
func _back_to_hangar() -> void:
	_hangar.visible = true
	_hangar.refresh()


## Abre o hangar (no sandbox, repoe antes os recursos de teste).
func _open_hangar() -> void:
	if Sandbox.active():
		Sandbox.top_up()
	_hangar.open()


## Menu inicial por cima da cena do mundo atual (nave parada na plataforma de partida, sem entrega). Voltar ao menu
## encerra o sandbox (o jogo salvo verdadeiro volta).
func _show_title() -> void:
	Sandbox.end()
	_hangar.visible = false
	_ending.visible = false
	_build_title_world()
	_gui.move_child(_title, -1)
	_title.open()


## Cena de fundo do menu: o mundo do jogo em uso, nave parada na plataforma.
func _build_title_world() -> void:
	_clear_run()
	_flight = FLIGHT_SCENE.instantiate()
	_world.add_child(_flight)
	_flight.start(GameState.current_planet, _run_seed, GameState.ship_stats(), false)


## Continuar: com progresso vai ao hangar (gastar o que ganhou); sem progresso, decola o primeiro run.
func _on_title_play() -> void:
	_title.visible = false
	if TitleScreen.has_progress():
		_open_hangar()
	else:
		_start_run()


func _clear_run() -> void:
	for n: Node in [_flight, _hud, _offers, _summary]:
		if n != null:
			n.queue_free()
	_flight = null
	_hud = null
	_offers = null
	_summary = null


func _start_run() -> void:
	_hangar.visible = false
	_title.visible = false
	_clear_run()
	var stats := GameState.ship_stats()
	_run = RunState.create(GameState.current_planet, stats, _run_seed)
	_flight = FLIGHT_SCENE.instantiate()
	_world.add_child(_flight)
	_hud = HUD_SCENE.instantiate()
	_gui.add_child(_hud)
	_offers = OFFER_SCENE.instantiate()
	_gui.add_child(_offers)
	_summary = SUMMARY_SCENE.instantiate()
	_gui.add_child(_summary)
	_summary.visible = false
	_gui.move_child(_hangar, -1)  # hangar sempre por cima
	_gui.move_child(_ending, -1)
	_gui.move_child(_title, -1)
	_gui.move_child(_pause, -1)
	var ui := UiKit.theme_for(GameState.current_planet)        # cor da interface acompanha o mundo
	for c: Control in [_hud, _offers, _summary, _ending, _pause]:
		c.theme = ui
	_flight.start(GameState.current_planet, _run_seed, stats, _demo)
	_hud.bind(_flight, _run)
	_flight.delivery_finished.connect(_on_delivery_finished)
	_flight.stranded.connect(_on_stranded)
	_offers.offer_chosen.connect(_on_offer_chosen)
	_offers.end_requested.connect(_on_end_requested)
	_summary.continue_requested.connect(_on_continue)
	_run_start_ms = Time.get_ticks_msec()
	Events.run_started.emit(GameState.current_planet)
	_show_offers()


func _show_offers() -> void:
	var gas := _flight.lander.gas
	if not _run.over and not _run.can_continue(gas):
		_run.finish("sem_gas")
	if _run.over:
		_end_run()
		return
	_offers.show_offers(_run, gas)
	if _demo:
		await get_tree().create_timer(0.5).timeout
		var i := _run.best_offer(_flight.lander.gas)
		if i < 0:
			_run.finish("sem_gas")
			_end_run()
		else:
			_on_offer_chosen(i)


func _on_offer_chosen(index: int) -> void:
	Sound.ui("click")
	var d := _run.take_offer(index)
	_offers.visible = false
	_flight.set_target(d, _run.taken_tier)


func _on_end_requested() -> void:
	_run.finish("encerrado")
	_end_run()


func _on_delivery_finished(result: Dictionary) -> void:
	print("DELIVERY_RESULT ", JSON.stringify(result))  # verificacao automatica (gdtool run/capture)
	if result["crashed"]:
		_run.crash(str(result["reason"]))
		_end_run()
		return
	var rewards := _run.complete_delivery(result["distance"], result["quality"], result["gas_used"],
			int(result.get("crystals", 0)))
	GameState.add_rewards(rewards)
	_hud.show_delivery(_run.deliveries[-1], _run.streak)
	_show_offers()


func _on_stranded() -> void:
	_run.finish("sem_gas")
	_end_run()


func _end_run() -> void:
	_offers.visible = false
	# duracao do run em segundos do modelo (a frota trabalha enquanto voce voa)
	var model_s := (Time.get_ticks_msec() - _run_start_ms) / 1000.0 * float(WorldConfig.load_config()["time_scale"])
	var fleet := GameState.settle_run(_run.earned, model_s)
	var s := _run.summary()
	s["fleet"] = fleet
	_summary.show_summary(s)
	GameState.runs_done += 1
	Events.run_finished.emit(s)
	print("RUN_SUMMARY ", JSON.stringify(s))
	if _demo:
		await get_tree().create_timer(2.0).timeout
		_on_continue()


## Fim do run -> hangar (comprar upgrades) -> decolar novo run.
func _on_continue() -> void:
	_summary.visible = false
	_hud.visible = false
	_open_hangar()
	if _demo:
		_demo_shop()
		await get_tree().create_timer(float(_args.get("hangar_wait", 0.5))).timeout
		_on_launch_requested()


func _on_goal_reached(_planet_id: String) -> void:
	_hangar.visible = false
	_ending.show_ending()
	print("GOAL_REACHED ", JSON.stringify({"runs": GameState.runs_done, "points": GameState.prestige_points}))


func _on_launch_requested() -> void:
	_run_seed += 1
	_start_run()


## Demo: libera planetas quando pode e compra o upgrade acessivel mais barato (verificacao da progressao).
func _demo_shop() -> void:
	# prestigio pela regra "dobrar" (a mesma do jogador simulado da economy-balance) + loja por prioridade
	var st := GameState.prestige_state()
	if Prestige.can_prestige(st) and Prestige.gain(st) >= GameState.prestige_points:
		var g := GameState.begin_prestige()
		var items := EconMath.shop_items().duplicate()
		items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("priority", 99)) < int(b.get("priority", 99)))
		for it: Dictionary in items:
			while GameState.buy_shop_item(it["id"]):
				pass
			if int(GameState.shop.get(it["id"], 0)) < int(it.get("max_level", 1)):
				break  # guarda Poeira para o proximo item da fila
		GameState.finish_prestige()
		print("PRESTIGE ", JSON.stringify({"gain": g, "points": GameState.prestige_points, "shop": GameState.shop}))
	# etapas da Expedicao primeiro (progressao, como o jogador simulado)
	for r: Dictionary in GameState.upgrade_rows():
		for u: Dictionary in EconMath.spec["upgrades"]:
			if u["id"] == r["id"] and u.get("progress", false) and r["affordable"]:
				GameState.buy_upgrade(r["id"])
	# liberar o proximo planeta e ir para o melhor planeta em que a nave consegue voar
	for p: Dictionary in GameState.planet_rows():
		if not p["unlocked"] and p["available"] and p["affordable"]:
			GameState.unlock_planet(p["id"])
	while true:
		var best := ""
		var best_cost := INF
		for r: Dictionary in GameState.upgrade_rows():
			var c := float(r["cost"].get("credits", 0.0))
			if r["affordable"] and c < best_cost:
				best = r["id"]
				best_cost = c
		if best == "" or not GameState.buy_upgrade(best):
			break
	for p: Dictionary in GameState.planet_rows():
		if p["unlocked"] and p["can_fly"]:
			GameState.current_planet = p["id"]
	_hangar.refresh()
	print("HANGAR ", JSON.stringify({"planet": GameState.current_planet, "credits": GameState.amount("credits"), "levels": GameState.levels,
			"stats": GameState.ship_stats()}))


## Argumentos so de desenvolvimento/verificacao: --dev_levels=thrust:10,tank:5  --dev_credits=N  --dev_ore=N
## --dev_shop=warp_drive:1,star_charts:1
## --dev_unlock=ares,kronos  --planet=id. Nao existem no jogo normal (sem args).
func _apply_dev_args() -> void:
	if _args.has("dev_levels"):
		for pair in str(_args["dev_levels"]).split(","):
			GameState.levels[pair.get_slice(":", 0)] = int(pair.get_slice(":", 1))
	if _args.has("dev_credits"):
		GameState.resources["credits"] = float(_args["dev_credits"])
	if _args.has("dev_ore"):
		GameState.resources["ore"] = float(_args["dev_ore"])
	if _args.has("dev_shop"):
		for pair in str(_args["dev_shop"]).split(","):
			GameState.shop[pair.get_slice(":", 0)] = int(pair.get_slice(":", 1))
	if _args.has("dev_unlock"):
		for pid in str(_args["dev_unlock"]).split(","):
			if not pid in GameState.unlocked_planets:
				GameState.unlocked_planets.append(pid)
	if _args.has("planet"):
		var pid := str(_args["planet"])
		if EconMath.spec["planets"].any(func(p: Dictionary) -> bool: return p["id"] == pid):
			GameState.current_planet = pid
		else:
			push_warning("--planet=%s nao existe na spec; usando luna" % pid)
		if not GameState.current_planet in GameState.unlocked_planets:
			GameState.unlocked_planets.append(GameState.current_planet)


func _parse_args(args: PackedStringArray) -> Dictionary:
	var out := {}
	for a in args:
		var s := a.trim_prefix("--")
		if "=" in s:
			out[s.get_slice("=", 0)] = s.get_slice("=", 1)
		else:
			out[s] = true
	return out
