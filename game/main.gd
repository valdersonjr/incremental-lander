## Entrada do jogo: Main -> World (voo) + GUI (HUD, ofertas, resumo). Orquestra o run (Fase 2):
## ofertas -> voo -> entrega -> recompensas (GameState) -> ofertas ... -> resumo -> novo run.
## Args: --demo (piloto automatico escolhe, voa e compra), --seed=N, --hangar_wait=s; dev: ver _apply_dev_args. R reinicia.
extends Node

const FLIGHT_SCENE := preload("res://game/flight/flight.tscn")
const HUD_SCENE := preload("res://game/hud/hud.tscn")
const OFFER_SCENE := preload("res://game/run/offer_panel.tscn")
const SUMMARY_SCENE := preload("res://game/run/run_summary.tscn")
const HANGAR_SCENE := preload("res://game/hangar/hangar.tscn")
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
var _title: TitleScreen = null
var _pause: PauseMenu = null
## Segundos reais do run em andamento, sem pausa (o relogio para com o jogo pausado ou a janela sem foco): a frota
## e paga por este tempo, nao pelo relogio de parede.
var _run_time := 0.0
var _run_active := false
## Recordes batidos neste run (aparecem no resumo depois do final do jogo).
var _run_records: Array[String] = []
## Segundos restantes para o 2o toque de R confirmar o reinicio no meio de um salto.
var _restart_armed := 0.0
const CONFIRM_SECONDS := 2.0

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
	if _demo or _args.has("no_title") or _args.keys().any(func(k: String) -> bool: return k.begins_with("dev_")):
		_start_run()
	else:
		_show_title()


func _process(delta: float) -> void:
	if _run_active:
		_run_time += delta
	_restart_armed = maxf(_restart_armed - delta, 0.0)


## Tela cheia: F11 ou Alt+Enter, em qualquer tela.
func _input(event: InputEvent) -> void:
	var alt_enter: bool = event is InputEventKey and event.pressed and not event.is_echo() \
			and (event as InputEventKey).alt_pressed and (event as InputEventKey).keycode == KEY_ENTER
	if alt_enter or event.is_action_pressed(&"fullscreen"):
		get_viewport().set_input_as_handled()
		GameState.set_fullscreen(not GameState.fullscreen())
		SaveManager.request_save()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"restart") and not _hangar.visible and not _title.visible and not _pause.visible:
		# no meio de um salto, R pede confirmacao (a entrega em voo se perderia por um toque sem querer)
		var flying := _flight != null and _flight.lander.state == Lander.State.FLYING and _run != null and not _run.over
		if flying and _restart_armed <= 0.0 and not _demo:
			_restart_armed = CONFIRM_SECONDS
			_hud.confirm_hint("R de novo para reiniciar o run (a entrega em voo se perde)", CONFIRM_SECONDS)
		else:
			_restart_armed = 0.0
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
			and not _hangar.visible and not _title.visible and not _pause.visible


## Volta do menu do jogo ao hangar, na mesma aba (refresh atualiza o tema e o foco).
func _back_to_hangar() -> void:
	_hangar.visible = true
	_hangar.refresh()


## Abre o hangar (no sandbox, repoe antes os recursos de teste). O que for do voo some: nada atras do hangar recebe
## teclas (o painel de ofertas escutava 1-9 escondido atras dele).
func _open_hangar() -> void:
	if Sandbox.active():
		Sandbox.top_up()
	for c: Control in [_hud, _offers, _summary]:
		if c != null and is_instance_valid(c):
			c.visible = false
	_hangar.open()
	Sound.music("title")                                       # hangar = menu: a mesma musica calma do titulo
	Sound.ambience(GameState.current_planet)


## Menu inicial por cima da cena do mundo atual (nave parada na plataforma de partida, sem entrega). Voltar ao menu
## encerra o sandbox (o jogo salvo verdadeiro volta).
func _show_title() -> void:
	_abandon_run()                                             # run em andamento fecha a conta no jogo em uso
	Sandbox.end()
	_hangar.visible = false
	_build_title_world()
	_gui.move_child(_title, -1)
	_title.open()
	Sound.music("title")


## Cena de fundo do menu: o mundo do jogo em uso, nave parada na plataforma.
func _build_title_world() -> void:
	_clear_run()
	_flight = FLIGHT_SCENE.instantiate()
	_world.add_child(_flight)
	_flight.start(GameState.current_planet, _run_seed, GameState.ship_stats(), false)
	Sound.ambience(GameState.current_planet)


## Continuar: com progresso vai ao hangar (gastar o que ganhou); sem progresso, decola o primeiro run.
func _on_title_play() -> void:
	_title.visible = false
	if TitleScreen.has_progress():
		_open_hangar()
	else:
		_start_run()


func _note_record(key: String, value: float) -> void:
	if GameState.note_record(key, value) and not key in _run_records:
		_run_records.append(key)


## Saida do voo pelo menu (Menu inicial) ou R: fecha a contabilidade do run como um fim normal (frota paga pelo tempo
## voado, conta como run) sem mostrar o resumo. Run sem entregas nao conta. Fora de um run nao faz nada.
func _abandon_run() -> void:
	if not _run_active or _run == null or _run.over:
		return
	_run_active = false
	if _run.deliveries.is_empty():                             # nada entregue: nao conta como run (nem polui a frota)
		return
	_run.finish("encerrado")
	GameState.settle_run(_run.earned, _run_time * float(WorldConfig.load_config()["time_scale"]))
	GameState.runs_done += 1
	Events.run_finished.emit(_run.summary())


func _clear_run() -> void:
	_run_active = false
	for n: Node in [_flight, _hud, _offers, _summary]:
		if n != null:
			n.queue_free()
	_flight = null
	_hud = null
	_offers = null
	_summary = null


func _start_run() -> void:
	_abandon_run()                                             # R no meio do run: o que foi ganho fecha a conta antes
	_hangar.visible = false
	_title.visible = false
	_clear_run()
	var stats := GameState.ship_stats()
	_run = RunState.create(GameState.current_planet, stats, _run_seed)
	_force_offer_extras()
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
	_gui.move_child(_title, -1)
	_gui.move_child(_pause, -1)
	var ui := UiKit.theme_for(GameState.current_planet)        # cor da interface acompanha o mundo
	for c: Control in [_hud, _offers, _summary, _pause]:
		c.theme = ui
	_flight.start(GameState.current_planet, _run_seed, stats, _demo)
	Sound.music("flight")
	Sound.ambience(GameState.current_planet)
	_hud.bind(_flight, _run)
	_flight.delivery_finished.connect(_on_delivery_finished)
	_flight.stranded.connect(_on_stranded)
	_offers.ground_at = _flight.offer_ground_screen
	_offers.offer_chosen.connect(_on_offer_chosen)
	_offers.end_requested.connect(_on_end_requested)
	_summary.continue_requested.connect(_on_continue)
	_run_time = 0.0
	_run_active = true
	_run_records.clear()
	Events.run_started.emit(GameState.current_planet)
	_show_offers()


func _show_offers() -> void:
	var gas := _flight.lander.gas
	if not _run.over and not _run.can_continue(gas):
		_run.finish("sem_gas" if not _run.deliveries.is_empty() else "sem_alcance")
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
	_flight.set_target(d, _run.taken_tier, _run.taken_dir, _run.taken_cargo)


func _on_end_requested() -> void:
	_run.finish("encerrado")
	_end_run()


func _on_delivery_finished(result: Dictionary) -> void:
	_log("DELIVERY_RESULT ", JSON.stringify(result))  # verificacao automatica (gdtool run/capture)
	if result["crashed"]:
		_run.crash(str(result["reason"]))
		_end_run()
		return
	var rewards := _run.complete_delivery(result["distance"], result["quality"], result["gas_used"],
			bool(result.get("cargo_ok", true)), float(result.get("gift_pay", 0.0)))
	GameState.add_rewards(rewards)
	_note_record("best_delivery", float(rewards.get("credits", 0.0)))
	_note_record("longest_hop", float(result["distance"]))
	_note_record("best_combo", float(_run.streak))
	SaveManager.request_save()                                 # entrega paga ja fica salva (crash nao perde o run)
	_hud.show_delivery(_run.deliveries[-1], _run.streak)
	if _run.streak >= 2:                                       # combo: estalo que sobe com o tamanho, depois da entrega
		get_tree().create_timer(0.35).timeout.connect(Sound.sfx.bind("combo_%d" % mini(_run.streak, 5)))
	_show_offers()


func _on_stranded() -> void:
	_run.finish("sem_gas")
	_end_run()


func _end_run() -> void:
	_offers.visible = false
	# duracao do run em segundos do modelo (a frota trabalha enquanto voce voa)
	_run_active = false
	var model_s := _run_time * float(WorldConfig.load_config()["time_scale"])
	var fleet := GameState.settle_run(_run.earned, model_s)
	_note_record("best_run", float(_run.earned.get("credits", 0.0)) + float(fleet.get("credits", 0.0)))
	var s := _run.summary()
	s["fleet"] = fleet
	s["records"] = _run_records.duplicate()
	_summary.show_summary(s)
	GameState.runs_done += 1
	Events.run_finished.emit(s)
	_log("RUN_SUMMARY ", JSON.stringify(s))
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


func _on_launch_requested() -> void:
	_run_seed += 1
	_start_run()


## Demo: compra o upgrade acessivel mais barato (verificacao da progressao).
func _demo_shop() -> void:
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
	_hangar.refresh()
	print("HANGAR ", JSON.stringify({"planet": GameState.current_planet, "credits": GameState.amount("credits"), "levels": GameState.levels,
			"stats": GameState.ship_stats()}))


## Argumentos so de desenvolvimento/verificacao: --dev_levels=thrust:10,tank:5  --dev_credits=N.
## Nao existem no jogo normal (sem args).
func _apply_dev_args() -> void:
	if not OS.is_debug_build():                                # build publico: sem atalhos de desenvolvedor
		return
	if _args.has("dev_levels"):
		for pair in str(_args["dev_levels"]).split(","):
			GameState.levels[pair.get_slice(":", 0)] = int(pair.get_slice(":", 1))
	if _args.has("dev_credits"):
		GameState.resources["credits"] = float(_args["dev_credits"])


## Dev (verificacao/capturas): --dev_cargo=towed|fragile|urgent|rescue|box e --dev_dir=-1|1 forcam a carga e o
## lado de TODOS os pedidos do run (os que regeneram tambem nao mudam: so os iniciais sao forcados).
func _force_offer_extras() -> void:
	if not OS.is_debug_build():
		return
	for i in _run.offers.size():
		if _args.has("dev_cargo"):
			_run.offer_cargo[i] = str(_args["dev_cargo"])
		if _args.has("dev_dir"):
			_run.offer_dirs[i] = int(_args["dev_dir"])


## Linha de verificacao (gdtool run/capture leem o stdout); fora no build publico.
func _log(tag: String, data: String) -> void:
	if OS.is_debug_build():
		print(tag, data)


func _parse_args(args: PackedStringArray) -> Dictionary:
	var out := {}
	for a in args:
		var s := a.trim_prefix("--")
		if "=" in s:
			out[s.get_slice("=", 0)] = s.get_slice("=", 1)
		else:
			out[s] = true
	return out
