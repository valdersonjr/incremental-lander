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
## Tanque "vazio" para encerrar o run na escolha de pedido (menos que isso nao tira a nave do chao).
const GAS_EMPTY := 0.5

var _args: Dictionary = {}
var _demo := false
var _run_seed := 0
var _run: RunState = null
var _flight: Flight = null
var _hud: Hud = null
var _offers: OfferPanel = null
var _summary: RunSummary = null
var _fade: ColorRect = null                # tela escura entre missoes (cada missao tem o seu mapa)
var _hangar: Hangar = null
var _world_map: WorldMap = null                 # Mapa das estrelas (v17: tela principal, cartao do mundo)
var _worlds_before := 0                         # mundos liberados no inicio do run (completar um = viagem no Mapa)
var _title: TitleScreen = null
var _pause: PauseMenu = null
var _spotlight: Spotlight = null                # destaque de 1a visita (cartao, NAVE, Mapa)
## Segundos reais do run em andamento, sem pausa (o relogio para com o jogo pausado ou a janela sem foco): a frota
## e paga por este tempo, nao pelo relogio de parede.
var _run_time := 0.0
var _run_active := false
## Recordes batidos neste run (aparecem no resumo depois do final do jogo).
var _run_records: Array[String] = []
var _rec_start: Dictionary = {}                 # recordes no inicio do run (o HUD e o resumo comparam com eles)
## Taxi (Passageiro 2-3): distancia do 1o trecho e presente pego nele (pagos ao fim do 2o trecho).
var _taxi_first_m := 0.0
var _taxi_gift_pay := 0.0
## Primeiros minutos (world.json > onboarding): gas no comeco do salto em andamento (o aprendiz que bate tenta o
## mesmo salto de novo com ele) e se o salto e o 1o do jogo (ja aceito, relevo baixo, sem minijogo).
var _hop_gas := 0.0
var _first_hop := false
var _arrived := false                              # o nome do mundo ja apareceu neste run
var _retries := 0                                  # tentativas repetidas do salto atual (aprendiz)
var _no_auto_hop := false                          # o aprendiz desistiu do 1o salto: escolhe no cartao
var _guided := false                               # o "Veja como!" ja voou este salto (falhou de novo -> cartao)
## O salto atual esta coberto pelo aprendiz (o gas alcancava o pedido na escolha). Pedido longe demais pode ser
## tentado (o run so acaba com o tanque vazio), mas sem repeticao: senao o gas do comeco voltaria para sempre.
var _hop_safe := true
## Segundos restantes para o 2o toque de R confirmar o reinicio no meio de um salto.
var _restart_armed := 0.0
const CONFIRM_SECONDS := 2.0
const MAX_TIPS_PER_SCREEN := 2                     # destaques de 1a visita em fila na mesma tela

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
	_hangar.launch_requested.connect(_on_launch_requested)   # DECOLAR na NAVE = voar no mundo escolhido no Mapa
	_world_map = WorldMap.new()
	_world_map.name = "WorldMap"
	_world_map.fly_requested.connect(_on_world_chosen)
	_world_map.ship_requested.connect(_open_hangar)
	_gui.add_child(_world_map)
	_hangar.title_requested.connect(_show_title)
	_title = TITLE_SCENE.instantiate()
	_gui.add_child(_title)
	_title.visible = false
	_title.play_requested.connect(_on_title_play)
	_title.slot_play_requested.connect(func(slot: int) -> void:
		SaveManager.load_slot(slot)
		Telemetry.event("load")
		_on_title_play())
	# jogo novo abre o Mapa (2026-10-09, usuario: "jogado no voo"): destaque em VOAR; o 1o salto ja vem aceito
	_title.new_game_requested.connect(func(slot: int) -> void:
		SaveManager.new_game(slot)
		Telemetry.event("new_game")
		_title.visible = false
		_open_map())
	_title.sandbox_requested.connect(func(planet_id: String, strong: bool) -> void:
		Sandbox.begin(planet_id, strong)
		_title.visible = false
		_open_map())                                           # v17: o Mapa com tudo liberado, no mundo escolhido
	_title.quit_requested.connect(func() -> void:
		SaveManager.save_game()
		Telemetry.event("close")
		get_tree().quit())
	_pause = PAUSE_SCENE.instantiate()
	_gui.add_child(_pause)
	_spotlight = Spotlight.new()
	_spotlight.name = "Spotlight"
	_gui.add_child(_spotlight)
	# v17: o Mapa e a tela principal. Esc na NAVE volta ao Mapa; Esc no Mapa abre o menu do jogo; fechar o menu volta
	# ao Mapa.
	_hangar.menu_requested.connect(func() -> void: _open_map())
	_world_map.menu_requested.connect(func() -> void:
		_gui.move_child(_pause, -1)
		_pause.open(PauseMenu.Mode.HANGAR))
	_pause.closed.connect(func() -> void:
		if _pause.mode == PauseMenu.Mode.HANGAR:
			_open_map())
	_pause.title_requested.connect(func() -> void:
		SaveManager.request_save()
		_show_title())
	_pause.new_game_requested.connect(func() -> void:
		SaveManager.new_game()
		Telemetry.event("new_game")
		_open_map())
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
			_hud.confirm_hint("R de novo para recomeçar a viagem (a entrega em voo se perde)", CONFIRM_SECONDS)
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
	if _flight == null:                                        # vindo do titulo (cena propria): monta o mundo atras
		_build_hangar_world()
	for c: Control in [_hud, _offers, _summary]:
		if c != null and is_instance_valid(c):
			c.visible = false
	Telemetry.event("nave")
	_hangar.open()
	_hangar_tips()
	Sound.music("title")                                       # hangar = menu: a mesma musica calma do titulo
	Sound.ambience(GameState.current_planet)


## Menu inicial com cena propria (TitleBackdrop, dentro da TitleScreen): nenhum voo fica montado atras. Voltar ao
## menu encerra o sandbox (o jogo salvo verdadeiro volta).
func _show_title() -> void:
	_abandon_run()                                             # run em andamento fecha a conta no jogo em uso
	Sandbox.end()
	_hangar.visible = false
	_clear_run()
	_gui.move_child(_title, -1)
	Telemetry.event("title")
	_title.open()
	Sound.music("theme")                                       # tema do gatinho (o Mapa e a NAVE tocam a calma "title")
	Sound.ambience("")                                         # tela inicial: so o tema (sem vento/drone por baixo)


## Stats da nave para o voo + a versao de cada peca no desenho (pecas que crescem por degrau; o Flight nao le o
## GameState). Copia: o RunState continua so com os numeros.
func _flight_stats(stats: Dictionary) -> Dictionary:
	var s := stats.duplicate()
	s["parts"] = ShipArt.tiers(GameState.levels)
	return s


## Cena de fundo do hangar: o mundo do jogo em uso, nave parada na plataforma.
func _build_hangar_world() -> void:
	_clear_run()
	_flight = FLIGHT_SCENE.instantiate()
	_world.add_child(_flight)
	_flight.start(GameState.current_planet, _run_seed, _flight_stats(GameState.ship_stats()), false)
	Sound.ambience(GameState.current_planet)


## Jogar: o jogo abre no Mapa das estrelas (v17), com o mundo escolhido por ultimo.
func _on_title_play() -> void:
	_title.visible = false
	_open_map()


## Mapa das estrelas (tela principal): esconde o resto; travel_from = mundo que acabou de ficar completo (viagem).
func _open_map(travel_from: String = "") -> void:
	if Sandbox.active():
		Sandbox.top_up()
	for c: Control in [_hud, _offers, _summary, _hangar]:
		if c != null and is_instance_valid(c):
			c.visible = false
	_clear_run()
	_world_map.theme = UiKit.theme_for(GameState.current_planet)
	Telemetry.event("map")
	_gui.move_child(_world_map, -1)
	_gui.move_child(_pause, -1)
	_world_map.open(travel_from)
	var opened := GameState.worlds()
	if opened.size() >= 2 and not GameState.tip_done("spot_world2") and travel_from == "" and not Sandbox.active():
		# 2o mundo aberto: o planetinha novo + as setas que trocam de mundo (depois da viagem, na proxima visita)
		_point(_world_map.world_box.bind(opened[1]), "spot_world2", "star_on", "Novo!", ["←", "→"])
	else:
		_point(func() -> Control: return _world_map.spotlight_target()[0], "spot_map", "", "")
	Sound.music("title")
	Sound.ambience(GameState.current_planet)


## Recordes do run ate agora (a cada entrega: bater a nave depois nao perde a marca).
func _note_records() -> void:
	var values := _run.record_values()
	for key: String in values:
		_note_record(key, float(values[key]))


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
	for n: Node in [_flight, _hud, _offers, _summary, _fade]:
		if n != null:
			n.queue_free()
	_flight = null
	_hud = null
	_offers = null
	_summary = null
	_fade = null


func _start_run() -> void:
	_abandon_run()                                             # R no meio do run: o que foi ganho fecha a conta antes
	_hangar.visible = false
	_title.visible = false
	_world_map.visible = false
	_worlds_before = GameState.worlds().size()
	_first_hop = false
	_no_auto_hop = false
	_arrived = false
	_clear_run()
	var stats := GameState.ship_stats()
	_run = RunState.create(GameState.current_planet, stats, _run_seed, GameState.missions_unlocked(),
			GameState.missions_new)
	_run.rep_points = GameState.rep_points.duplicate()        # Reputacao por ratinho (permanente)
	_force_offer_extras()
	_flight = FLIGHT_SCENE.instantiate()
	_world.add_child(_flight)
	_hud = HUD_SCENE.instantiate()
	_gui.add_child(_hud)
	_offers = OFFER_SCENE.instantiate()
	_gui.add_child(_offers)
	_fade = ColorRect.new()
	_fade.color = UiKit.color("ink")
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_gui.add_child(_fade)
	_summary = SUMMARY_SCENE.instantiate()
	_gui.add_child(_summary)
	_summary.visible = false
	_gui.move_child(_hangar, -1)  # hangar sempre por cima
	_gui.move_child(_title, -1)
	_gui.move_child(_pause, -1)
	var ui := UiKit.theme_for(GameState.current_planet)        # cor da interface acompanha o mundo
	for c: Control in [_hud, _offers, _summary, _pause]:
		c.theme = ui
	_flight.start(GameState.current_planet, _run_seed, _flight_stats(stats), _demo)
	_flight.landscapes = GameState.landscapes()
	Sound.music("flight", GameState.current_planet)        # base do voo + camada do mundo
	Sound.ambience(GameState.current_planet)
	_hud.bind(_flight, _run)
	_flight.delivery_finished.connect(_on_delivery_finished)
	_flight.stranded.connect(_on_stranded)
	_flight.rested.connect(func(_i: Dictionary) -> void: Telemetry.event("rest"))
	_flight.took_over.connect(func() -> void: Telemetry.event("take_over"))
	_flight.lander.took_off.connect(func() -> void: Telemetry.event("takeoff"))
	_offers.offer_chosen.connect(_on_offer_chosen)
	_offers.end_requested.connect(_on_end_requested)
	_summary.continue_requested.connect(_on_continue)
	_run_time = 0.0
	_run_active = true
	_run_records.clear()
	_rec_start = GameState.world_records().duplicate()
	_hud.set_records(_rec_start)
	Events.run_started.emit(GameState.current_planet)
	Telemetry.event("run_start", GameState.current_planet)
	_show_offers()


func _show_offers() -> void:
	var gas := _flight.lander.gas
	# o run so acaba com o tanque vazio de verdade (ou na batida): pedido que parece longe demais fica em vermelho no
	# cartao, mas o jogador pode tentar (pilotar bem / pegar o galao no caminho). Gas acabou no voo -> Flight.stranded.
	if not _run.over and gas <= GAS_EMPTY:
		_run.finish("sem_gas")
	if _run.over:
		_end_run()
		return
	if GameState.first_hop() and _run.deliveries.is_empty() and not _demo and not _no_auto_hop:   # 1o salto (C1)
		var first := _first_simple_offer()
		if first >= 0:
			_first_hop = true
			_on_offer_chosen(first)
			return
	Telemetry.event("offers")
	_offers.show_offers(_run, gas)
	_point(_offers.accept_button, "spot_offer", "check", "Aceite!")
	if _demo:
		await get_tree().create_timer(0.5).timeout
		var i := _run.best_offer(_flight.lander.gas)
		if i < 0:
			_run.finish("sem_gas")
			_end_run()
		else:
			_on_offer_chosen(i)


## Pedido mais perto do mineiro (Simples, normal) para o 1o salto do jogo; -1 se nao ha.
func _first_simple_offer() -> int:
	for i in _run.offers.size():                               # ofertas ja vem ordenadas por distancia
		if str(_run.offer_mission[i]["kind"]) == "simple":
			return i
	return -1


func _on_offer_chosen(index: int) -> void:
	if not _first_hop:
		Sound.ui("click")
	_hop_safe = _first_hop or bool(_run.offer_info(index, _flight.lander.gas)["reachable"])
	var d := _run.take_offer(index)
	if _first_hop:                                             # perto e na plataforma normal (a maior)
		d = float(WorldConfig.load_config()["onboarding"]["first_hop"]["distance_m"])
		_run.taken_tier = "normal"
	_offers.visible = false
	var m := _run.taken_mission
	_hop_gas = _flight.lander.gas
	_retries = 0
	_guided = false
	_flight.guided = false
	# relevo baixo no 1o salto e em todo salto antes da 1a entrega (quem desistiu do 1o nao ganha um mais dificil)
	_flight.gentle = _first_hop or (GameState.first_hop() and not _demo)
	_flight.minigame_on = (GameState.shows_minigame() or _demo) and not _first_hop
	_flight.apprentice = _apprentice_hop()
	Telemetry.event("mission", "%s:%d" % [str(m.get("kind", "simple")), int(d)])
	# cada missao tem o seu mapa: a tela escurece, o mapa novo nasce e a nave desce do ceu ate a partida
	var fade_s := float(WorldConfig.load_config()["missions"]["arrival"]["fade_s"])
	var flight := _flight
	var tw := _fade.create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, fade_s)
	await tw.finished
	if flight != _flight or _run == null:                      # o run acabou/recomecou durante a tela escura
		return
	var seed_value := hash([_run_seed, _run.deliveries.size()])
	_flight.set_fatigue(_run.fatigue())
	if EconMath.mission_leg2(m) > 0.0:                         # taxi: 1o trecho ate a plataforma de busca
		var tiers: Array = WorldConfig.load_config()["missions"]["passenger"]["pickup_tier"]
		var pickup: String = tiers[clampi(EconMath.mission_has(m, "passenger"), 1, tiers.size()) - 1]
		_flight.begin_mission(seed_value, d, pickup, _run.taken_dir, m, 1)
	else:
		_flight.begin_mission(seed_value, d, _run.taken_tier, _run.taken_dir, m)
	_show_goal()
	_fade.create_tween().tween_property(_fade, "modulate:a", 0.0, fade_s)


## Aviso grande do comeco do salto: o verbo do minijogo com o que fazer (A5); sem minijogo, "Pouse!".
func _show_goal() -> void:
	if not _arrived:                                           # chegada no mundo: o nome dele no alto (1a missao do run)
		_arrived = true
		_hud.show_world_name(str(EconMath._find("planets", GameState.current_planet).get("name",
				GameState.current_planet)).to_upper())
		Sound.jingle("world_arrive")                           # vinheta de chegada (a musica abaixa enquanto toca)
	if _flight.minigame_total > 0:
		_hud.show_verb(_flight.minigame_verb(), str(Minigames.spec(GameState.current_planet).get("say", "")))
	else:
		_hud.show_verb("Pouse!", "na plataforma do outro lado")


func _on_end_requested() -> void:
	_run.finish("encerrado")
	_end_run()


func _on_delivery_finished(result: Dictionary) -> void:
	_log("DELIVERY_RESULT ", JSON.stringify(result))  # verificacao automatica (gdtool run/capture)
	if result["crashed"]:
		Telemetry.event("crash", str(result["reason"]))
		if _apprentice_hop():                                     # aprendiz: tenta o mesmo salto de novo (C2)
			_retry_hop(str(result["reason"]))
			return
		_run.crash(str(result["reason"]))
		_end_run()
		return
	_first_hop = false
	if int(result.get("leg", 0)) == 1:                         # taxi: passageiro a bordo, agora o trecho de volta
		var d1 := float(result["distance"])
		_taxi_gift_pay = float(result.get("gift_pay", 0.0))
		_taxi_first_m = d1
		var f: Array[String] = []
		f.assign(result.get("failed", []))
		_flight.set_target(_run.leg2_m(_run.taken_mission, d1), _run.taken_tier, -_run.taken_dir,
				_run.taken_mission, 2, f)
		_hud.taxi_step(2)
		return
	var dist := float(result["distance"])
	var gift := float(result.get("gift_pay", 0.0))
	if int(result.get("leg", 0)) == 2:                         # taxi: paga os 2 trechos pela distancia do 1o
		dist = _taxi_first_m
		gift += _taxi_gift_pay
	Telemetry.event("delivery", "%.2f" % float(result["quality"]))
	var stars_before := _run.stars
	var was_apprentice := GameState.apprentice()
	var rewards := _run.complete_delivery(dist, result["quality"], result["gas_used"], result.get("failed", []), gift,
			bool(result.get("perfect", false)), result.get("partial", {}), result.get("minigame", [0, 0]))
	var rep_kind := str(_run.deliveries[-1].get("rep_kind", "simple"))
	var rep_before := GameState.rep_level(rep_kind)
	GameState.rep_points = _run.rep_points.duplicate()
	var rep_up := GameState.rep_level(rep_kind) > rep_before
	GameState.add_stars(_run.stars - stars_before)
	if _run.stars > stars_before:                              # estrela de missao: depois do "entregue"
		get_tree().create_timer(0.55).timeout.connect(Sound.sfx.bind("star"))
	GameState.add_rewards(rewards)
	_note_records()
	SaveManager.request_save()                                 # entrega paga ja fica salva (crash nao perde o run)
	_hud.show_delivery(_run.deliveries[-1])
	if bool(_run.deliveries[-1].get("perfect", false)):        # pouso perfeito: estalo, depois da entrega
		get_tree().create_timer(0.35).timeout.connect(Sound.sfx.bind("combo_%d" % clampi(_run.perfect_streak + 1, 2, 5)))
	if rep_up:                                                 # subiu a reputacao com o ratinho: festa
		Events.reputation_up.emit(rep_kind, GameState.rep_level(rep_kind))
		var tw := _hud.create_tween()                          # tween do HUD: some junto se o run acabar antes
		tw.tween_interval(0.9)
		tw.tween_callback(_hud.show_reputation_up.bind(rep_kind, GameState.rep_level(rep_kind)))
		tw.tween_callback(Sound.jingle.bind("unlock"))
	if was_apprentice and not GameState.apprentice() and not _demo:   # fim do aprendiz: festa (bater acaba o run)
		Telemetry.event("graduated")
		var tg := _hud.create_tween()
		tg.tween_interval(1.8 if rep_up else 0.9)
		tg.tween_callback(_hud.show_graduation.bind(_graduation_line()))
		tg.tween_callback(Sound.jingle.bind("milestone"))
	_show_offers()


## 2a linha do "PILOTO FORMADO!": a ajuda emprestada ao aprendiz agora e dele (fica na NAVE) ou volta na Estrada.
func _graduation_line() -> String:
	var lent: Array = WorldConfig.load_config()["onboarding"].get("lent_assists", [])
	if lent.is_empty():
		return ""
	var id := str(lent[0])
	var name := str(EconMath._find("upgrades", id).get("name", id))
	if int(GameState.levels.get(id, 0)) >= 1:
		return "%s: agora é seu, na NAVE" % name
	return "%s: ganhe de volta na Estrada" % name


func _on_stranded() -> void:
	if _apprentice_hop() and _run != null and not _run.over:
		Telemetry.event("crash", "sem_gas")
		_retry_hop("sem_gas")
		return
	_run.finish("sem_gas")
	_end_run()


## Destaque de 1a visita (Spotlight, uma vez por tip): espera o layout e acende o botao de target_fn(). Mapa: icone e
## palavra vem do proprio Mapa (NAVE com "!" ou VOAR). Fora no demo e no modo livre. Devolve true se mostrou.
func _point(target_fn: Callable, tip: String, icon: String, word: String, keys: Array = []) -> bool:
	if _demo or Sandbox.active() or GameState.tip_done(tip):
		return false
	await get_tree().process_frame
	await get_tree().process_frame
	var target: Control = target_fn.call()
	if tip == "spot_map":
		var info := _world_map.spotlight_target()
		icon = str(info[1])
		word = str(info[2])
	_gui.move_child(_spotlight, -1)
	_gui.move_child(_pause, -1)
	return _spotlight.point(target, tip, icon, word, keys)


## Destaques da NAVE (prototipo art/previews/menus_intro/menus_intro.html): no maximo MAX_TIPS_PER_SCREEN por visita,
## na ordem: "Compre!" (da para comprar), "Mapa!" (o caminho de volta), aba AJUDAS ("Ajuda!") seguida do liga/desliga,
## abas novas (REPUTACAO, FROTA sem cadeado) com as teclas Q/E. Fechar clicando fora encerra a fila da visita.
func _hangar_tips() -> void:
	var steps: Array = []
	if GameState.can_afford_any():
		steps.append([_hangar.first_affordable_buy, "spot_ship", "coin", "Compre!", []])
	steps.append([_hangar.map_button, "spot_back", "pin", "Mapa!", []])
	steps.append([_hangar.tab_button.bind(Hangar.Tab.ASSISTS), "spot_assists", "arrow", "Ajuda!", []])
	steps.append([_hangar.first_assist_toggle, "spot_toggle", "check", "Liga/desliga", []])
	steps.append([_hangar.tab_button.bind(Hangar.Tab.REPUTATION), "spot_tab_rep", "heart_on", "Novo!", ["Q", "E"]])
	steps.append([_hangar.tab_button.bind(Hangar.Tab.FLEET), "spot_tab_fleet", "drone", "Novo!", ["Q", "E"]])
	var shown := 0
	for st: Array in steps:
		if shown >= MAX_TIPS_PER_SCREEN or not _hangar.visible:
			return
		if GameState.tip_done(str(st[1])):
			continue
		if not await _point(st[0], str(st[1]), str(st[2]), str(st[3]), st[4]):
			continue
		shown += 1
		var acted: bool = await _spotlight.closed
		if not acted:
			return


## O salto atual tem a protecao do aprendiz (repete na batida, para no chao fora da plataforma)?
func _apprentice_hop() -> bool:
	return GameState.apprentice() and not _demo and _hop_safe


## Aprendiz (world.json > onboarding): a batida (ou o gas que acabou) nao acaba o run. A tela escurece, a nave volta
## para a partida do MESMO salto com o gas do comeco dele, e o aviso diz o jeito de acertar. Depois de retries_per_hop
## repeticoes (ou sem gas) vem o "Veja como!" (Super Guide do New Super Mario Bros. Wii): o piloto automatico voa o
## mesmo salto e qualquer comando devolve a nave ao jogador; a entrega vale normalmente. Se ainda assim nao der, a nave
## volta para a partida e o cartao abre para escolher outra missao (missao dificil demais nunca prende o jogador).
func _retry_hop(reason: String) -> void:
	_retries += 1
	var onb: Dictionary = WorldConfig.load_config()["onboarding"]
	var over_limit := reason == "sem_gas" or _retries > int(onb["retries_per_hop"])
	var guide := bool(onb.get("guide", false)) and not _guided and over_limit   # desligado (usuario, 2026-10-08)
	var give_up := _guided or (over_limit and not guide)
	Telemetry.event("give_up" if give_up else ("guide" if guide else "retry"), reason)
	var fade_s := float(WorldConfig.load_config()["onboarding"]["retry_fade_s"])
	var flight := _flight
	await get_tree().create_timer(0.5, false).timeout          # o "BATEU!" aparece um instante
	if flight != _flight or _run == null or _run.over:
		return
	var teach := not give_up and not guide and not GameState.crash_taught()   # figura so na 1a batida do jogo
	if teach:
		GameState.learn_tip("crash_" + reason)
	if teach:                                                  # fantasma: o movimento certo em cima da plataforma
		var ghost_s := _flight.play_ghost(reason)
		if ghost_s > 0.0:
			await get_tree().create_timer(ghost_s + 0.3, false).timeout
			if flight != _flight or _run == null or _run.over:
				return
	var tw := _fade.create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, fade_s)
	await tw.finished
	if flight != _flight or _run == null or _run.over:         # o run acabou/recomecou durante a tela escura
		return
	_flight.end_ghost()
	if give_up:
		_retries = 0
		_guided = false
		_first_hop = false
		_no_auto_hop = true
		_flight.guided = false
		_flight.reset_to_start(_hop_gas)
		_hud.show_other_mission()
		_show_offers()
	else:
		_guided = guide
		_flight.guided = guide
		_flight.retry_mission(_hop_gas)
		if guide:
			_hud.show_guide()
		else:
			_hud.show_retry(reason, teach)
			if teach:
				_flight.retry_hint.show_balloon(reason)      # a cena do jeito certo fica em cima da nave ate decolar
	_fade.create_tween().tween_property(_fade, "modulate:a", 0.0, fade_s)


func _end_run() -> void:
	_offers.visible = false
	# duracao do run em segundos do modelo (a frota trabalha enquanto voce voa)
	_run_active = false
	var model_s := _run_time * float(WorldConfig.load_config()["time_scale"])
	var fleet := GameState.settle_run(_run.earned, model_s)
	GameState.tick_missions_new()
	var values := _run.record_values()
	# bonus de recorde (v16): bater o recorde de dinheiro deste mundo (ou a 1a visita) paga uma parte do run
	var bonus := EconMath.record_bonus(float(values["run_money"]), float(_rec_start.get("run_money", 0.0)))
	if bonus > 0.0:
		GameState.add_rewards({"credits": bonus})
	_note_records()
	var s := _run.summary()
	s["rec_values"] = values
	s["rec_start"] = _rec_start.duplicate()
	s["record_bonus"] = bonus
	s["fleet"] = fleet
	s["records"] = _run_records.duplicate()
	s["road_news"] = GameState.road_news().size()
	_summary.show_summary(s)
	Telemetry.event("run_end", str(s["reason"]))
	GameState.runs_done += 1
	Events.run_finished.emit(s)
	_log("RUN_SUMMARY ", JSON.stringify(s))
	if _demo:
		await get_tree().create_timer(2.0).timeout
		_on_continue()


## Fim do run (auditoria dos primeiros minutos A1): mundo completo -> Mapa com a viagem; da para comprar uma peca ->
## NAVE (a peca que da pulsa); senao o Mapa (tambem o aprendiz, 2026-10-09: o Mapa e a casa). Demo: hangar -> decola.
func _on_continue() -> void:
	_summary.visible = false
	_hud.visible = false
	if not _demo:
		var opened := GameState.worlds()
		var travel := ""
		if opened.size() > _worlds_before and _worlds_before > 0:
			travel = opened[_worlds_before - 1]
			GameState.select_world(opened[_worlds_before])        # o mundo novo ja escolhido
		if travel == "" and GameState.can_afford_any() and not Sandbox.active():
			_open_hangar()
		else:
			_open_map(travel)
		return
	_open_hangar()
	if _demo:
		_demo_shop()
		await get_tree().create_timer(float(_args.get("hangar_wait", 0.5))).timeout
		_on_launch_requested()


func _on_world_chosen(planet_id: String) -> void:
	GameState.select_world(planet_id)
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
	if _args.has("dev_missions"):
		GameState.mission_nodes.assign(str(_args["dev_missions"]).split(","))
	if _args.has("dev_world"):                                 # v17: voar direto num mundo (verificacao/capturas)
		GameState.current_planet = str(_args["dev_world"])
	if _args.has("dev_stars"):                                 # anda na Estrada sem festa (tudo ja visto)
		GameState.stars = int(_args["dev_stars"])
		GameState.world_stars[GameState.current_planet] = int(_args["dev_stars"])   # v17: na Estrada do mundo atual
		GameState._check_road(true)


## Dev (verificacao/capturas): --dev_mission=kind:estrela (ex.: tow:2, passenger:3, double:heavy+soft) e
## --dev_dir=-1|1 forcam a missao e o lado de TODOS os pedidos do run (os que regeneram nao: so os iniciais).
## --dev_missions=heavy1,soft1,... libera nos da arvore; --dev_stars=N = total de estrelas (anda na Estrada).
func _force_offer_extras() -> void:
	if not OS.is_debug_build():
		return
	for i in _run.offers.size():
		if _args.has("dev_mission"):
			_run.offer_mission[i] = _dev_mission(str(_args["dev_mission"]))
		if _args.has("dev_dir"):
			_run.offer_dirs[i] = int(_args["dev_dir"])


func _dev_mission(txt: String) -> Dictionary:
	var kind := txt.get_slice(":", 0)
	var rest := txt.get_slice(":", 1)
	if kind == "simple":
		return EconMath.simple_mission()
	if kind == "double":
		var parts := []
		for k: String in rest.split("+"):
			parts.append({"kind": k, "star": 1})
		return {"kind": "double", "star": 1, "parts": parts}
	var star := maxi(1, int(rest))
	return {"kind": kind, "star": star, "parts": [{"kind": kind, "star": star}]}


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
