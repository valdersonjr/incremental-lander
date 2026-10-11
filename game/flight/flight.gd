## Cena de voo: terreno + lander + camera. Cada missao tem o seu mapa (v15): begin_mission() gera um terreno novo
## (seed da missao) com a plataforma de partida em x=0, cria o alvo e faz a nave descer do ceu ate a partida.
## set_target() cria a proxima plataforma a partir da atual no MESMO mapa (2o trecho do taxi) e estende o terreno.
## Devolve cada entrega por sinal; nao acessa GameState (godot-dev).
class_name Flight
extends Node2D

## Uma entrega terminou: pousou na plataforma alvo ou bateu. result = dados da entrega (ver _finish).
signal delivery_finished(result: Dictionary)
## Pousou fora do alvo sem gas para decolar de novo.
signal stranded
## Aprendiz: a nave parou no chao fora da plataforma (pode decolar de novo).
signal rested(info: Dictionary)
## "Veja como!": o jogador apertou um comando e assumiu a nave do piloto automatico.
signal took_over

var planet_id := "luna"
var stats: Dictionary = {}
var fatigue := 1.0                                 # cansaco do run (v15): gas da missao x fatigue
var landscapes: Array[String] = []                 # paisagens liberadas (Main; vazio = relevo de sempre)
var landscape_id := ""                             # paisagem do mapa atual
var target_distance_m := 0.0
var current_pad_id := 0
var target_pad_id := -1

const EXPLOSION_FRAMES := preload("res://assets/sprites/explosion_frames.tres")
const DUST_FRAMES := preload("res://assets/sprites/landing_dust_frames.tres")

var _assist_view: AssistView
## "Tente de novo" sem texto (aprendiz): fantasma do movimento certo + balao em cima da nave (RetryHint).
var retry_hint: RetryHint
var _focus_ghost := false                          # camera olha o fantasma (plataforma alvo) em vez da nave

var _seed := 0
var _pad_positions_m: Array[float] = [0.0]
var _pad_tiers: Array[String] = []                 # tipo de cada plataforma de entrega (sem a partida)
var _extend := Vector2.ZERO                        # terreno extra alem da margem (px; x esquerda, y direita)
const EXTEND_NEAR := 800.0                         # nave a menos disso (px) da borda -> estende
const EXTEND_STEP := 2400.0
var target_tier := "normal"
var target_dir := 1                                # lado do alvo: 1 direita, -1 esquerda
## Primeiros minutos (world.json > onboarding; o Main liga antes de begin_mission): gentle = 1o salto do jogo (relevo
## baixo, sem crista e sem paisagem sorteada); minigame_on = minijogo do mundo neste salto; apprentice = pouso devagar
## fora da plataforma nao bate (Lander.ground_rest); guided = "Veja como!" (o piloto automatico voa o salto ate o
## jogador apertar um comando, como o Super Guide; ver _unhandled_input).
var gentle := false
var minigame_on := true
var apprentice := false
var guided := false
var _last_mission: Array = []                      # argumentos do ultimo begin_mission (retry_mission repete o salto)
## Missao da entrega atual (economy.json contracts.missions; fisica em world.json missions): {kind, star, parts}.
## failed = kinds das regras que falharam (a entrega paga menos; o run continua).
var mission: Dictionary = {"kind": "simple", "star": 1, "parts": []}
var failed: Array[String] = []
## Taxi (Passageiro 2-3): 1 = indo buscar o passageiro (pousar NAO e entrega), 2 = levando; 0 = sem taxi.
var taxi_stage := 0
var urgent_left := 0.0                             # Rapida: segundos reais que faltam (conta so voando)
var urgent_limit := 0.0
var rescued := false                               # Passageiro 1: passageiro resgatado neste salto
## Presente do salto (v10): "" sem presente, "gas" (galao) ou "gift" (creditos com a entrega). Gifts.place/touches.
var minigame_got := 0                              # v17: minijogo do mundo (Lua: queijinhos pegos)
var minigame_total := 0
var minigame_extra := 0.0                          # medida do minijogo para a telemetria (ver Telemetry.record_delivery)
var _trail: Array[Dictionary] = []                  # Lua: queijinhos {pos, sprite, got}
var _sheep: Array[Dictionary] = []                  # Nuvens: carneirinhos {pos, sprite, got}
var _tail: Array[Dictionary] = []                   # Nuvens: fila atras da nave (Snake)
var _history := PackedVector2Array()                # Nuvens: posicoes recentes da nave (a fila segue)
var _updrafts: Array = []                           # Nuvens: colunas de corrente {x, half}
var _updraft_lines: Array[Node] = []
var _caps: Array[Dictionary] = []                   # Cogumelos: chapeus-mola {x, y, half, node}
var _rings: Array[Node] = []                        # Sorvete: anéis do alvo
var _stems: Array[Dictionary] = []                  # Jardim: caules {x, half, gap_top, gap_bot, passed, bumped, node}
var chest_got := false                              # Bolhas: o bau esta na garra
var chest_wet := false                              # Bolhas: o bau molhou (falhou a regra)
var _chest_pos := Vector2.ZERO
var _chest_sprite: Sprite2D = null
var _water := {}                                    # Bolhas: {x0, x1, y} (px)
var _water_node: Node2D = null
var _bubble_sprites: Array[Sprite2D] = []
var _bubbles: Array = []                            # Bolhas: colunas {x, half}
var _wet_t := 0.0
var _wind_t := 0.0
var _calm_t := 0.0                                  # Jardim: segundos sem vento depois de bater num caule
var _seeds: Array[Sprite2D] = []                    # Jardim: sementes de dente-de-leao que mostram o vento
var sliding := false                                # Sorvete: deslizando no gelo depois do pouso
var _slide_v := 0.0                                 # m/s
var _slide_info: Dictionary = {}
var _ghost: Node2D = null
var _pointer: Sprite2D = null                       # seta na borda da tela para o proximo item do minijogo                           # Sorvete: marca de onde a nave vai parar se tocar agora
var gift_kind := ""
var gift_taken := false
var _gift_pos := Vector2.ZERO                       # pes do presente (px do mundo)
var _gift_sprite: Sprite2D = null
var _gift_bob: Tween = null
var _tow: CargoTow = null
var _tow_sprite: Sprite2D = null
var _rope: Line2D = null
var _rescue_pos := Vector2.ZERO                    # pes do ratinho (px do mundo)
var _rescue_sprite: Sprite2D = null
var _anim_t := 0.0
var _demo := false
var _lift_y := 0.0                                 # camera olhando para cima perto do chao (px; sem o tremor)
var _shake := 0.0                                  # trauma do tremor de tela (0..1; world.json > camera)
var _shape: Dictionary = {}                        # relevo da missao do mapa (TerrainGen shape; world.json)
var _bg_ground := 0.0                              # altura media do chao perto da camera - partida (px, suavizada)
var _bg_origin := 0.0                              # deslocamento do cenario de fundo (px): cada mapa mostra um trecho
var _env_sound: AudioStreamPlayer                  # loop da mecanica do mundo (gelo, vento, bolhas), volume pela forca
var _env_level := 0.0                              # 0..1 suavizado
var _wind_now := 0.0                               # Jardim: vento deste passo e o maximo da estrela (m/s2)
var _wind_max := 1.0

const ICE_SLIDE := preload("res://assets/audio/sfx/ice_slide.wav")
const WIND_LOOP := preload("res://assets/audio/sfx/wind_loop.wav")
const BUBBLES_LOOP := preload("res://assets/audio/sfx/bubbles_loop.wav")
## Velocidade de deslize (m/s) que soa no volume cheio; o pitch do gelo vai de ICE_PITCH.x a .y com ela.
const ICE_FULL_MPS := 8.0
const ICE_PITCH := Vector2(0.8, 1.15)
## Pouso: volume e pitch pela descida (vy / max_vy); acima de HEAVY_FROM entra a camada de pancada.
const LAND_DB := Vector2(-9.0, 0.0)
const LAND_PITCH := Vector2(1.06, 0.94)
const HEAVY_FROM := 0.6

@onready var lander: Lander = %Lander
@onready var terrain: Terrain = %Terrain
@onready var camera: Camera2D = %Camera
@onready var backdrop: Backdrop = %Backdrop


func _ready() -> void:
	UiKit.outline(lander.get_node("Visual") as CanvasItem)      # contorno branco: a nave nao some nos cenarios carregados
	_assist_view = AssistView.new()
	_assist_view.flight = self
	add_child(_assist_view)
	move_child(_assist_view, lander.get_index())              # ajudas de voo (Painel de bordo), atras do lander
	lander.landed.connect(_on_lander_landed)
	lander.crashed.connect(_on_lander_crashed)
	lander.rested.connect(_on_lander_rested)
	lander.scraped.connect(_on_lander_scraped)
	var coach := Coach.new()                                   # dicas sem texto + medidor de descida (comeco do jogo)
	coach.name = "Coach"
	coach.flight = self
	add_child(coach)
	retry_hint = RetryHint.new()
	retry_hint.name = "RetryHint"
	retry_hint.flight = self
	add_child(retry_hint)
	_env_sound = AudioStreamPlayer.new()
	_env_sound.bus = &"SFX"
	add_child(_env_sound)


func _exit_tree() -> void:
	if _env_sound != null:                                     # loop tocando ao fechar o jogo = playback vivo na saida
		_env_sound.stop()
		_env_sound.stream = null


func _physics_process(delta: float) -> void:
	camera.global_position = retry_hint.ghost_focus() if _focus_ghost else lander.global_position
	_tick_mission(delta)
	_tick_gift()
	_tick_minigame()
	_update_pointer()
	_extend_terrain_if_near_edge()
	var cam: Dictionary = WorldConfig.load_config()["camera"]
	var alt := TerrainGen.height_at(terrain.ridge, lander.global_position.x) - lander.global_position.y
	var target := -CameraMath.lift(alt, float(cam["ground_lift_px"]), float(cam["lift_fade_alt_px"]))
	_lift_y = lerpf(_lift_y, target, clampf(float(cam["lift_speed"]) * delta, 0.0, 1.0))


func _process(delta: float) -> void:
	var cam: Dictionary = WorldConfig.load_config()["camera"]
	_shake = maxf(_shake - float(cam["shake_decay"]) * delta, 0.0)
	var amp := _shake * _shake * float(cam["shake_px"]) if GameState.shake_enabled() else 0.0
	camera.offset = Vector2(roundf(randf_range(-amp, amp)), _lift_y + roundf(randf_range(-amp, amp)))
	var center := camera.get_screen_center_position()
	var gf: Dictionary = WorldConfig.load_config()["background"].get("ground_follow", {})
	if float(gf.get("speed", 0.0)) > 0.0 and not terrain.pads.is_empty():   # fundo desce/sobe com o chao (vale, mesa)
		var target := TerrainGen.mean_height(terrain.ridge, center.x, float(gf["span_px"])) - float(terrain.pads[0]["y"])
		_bg_ground = lerpf(_bg_ground, target, 1.0 - exp(-float(gf["speed"]) * delta))
	backdrop.follow(center + Vector2(_bg_origin, -_bg_ground))
	_update_env_sound(delta)


## Loop da mecanica do mundo: gelo (Sorvete, pela velocidade do deslize), vento (Jardim, pela forca da rajada),
## correntes (Nuvens, vento mais agudo dentro da corrente) e bolhas (Bolhas, dentro da coluna). Volume suavizado.
func _update_env_sound(delta: float) -> void:
	var stream: AudioStream = null
	var level := 0.0
	var pitch := 1.0
	var flying := lander.state == Lander.State.FLYING
	match planet_id:
		"sorvete":
			stream = ICE_SLIDE
			level = clampf(absf(_slide_v) / ICE_FULL_MPS, 0.0, 1.0) if sliding else 0.0
			pitch = lerpf(ICE_PITCH.x, ICE_PITCH.y, level)
		"jardim":
			stream = WIND_LOOP
			level = clampf(absf(_wind_now) / maxf(_wind_max, 0.01), 0.0, 1.0) if not _stems.is_empty() else 0.0
		"nuvens":
			stream = WIND_LOOP
			pitch = 1.33
			level = 1.0 if flying and lander.env_accel.y < 0.0 else 0.0
		"bolhas":
			stream = BUBBLES_LOOP
			level = 1.0 if flying and lander.env_accel.y < 0.0 else 0.0
	if lander.state == Lander.State.CRASHED:
		level = 0.0
	_env_level = lerpf(_env_level, level, clampf(delta * 6.0, 0.0, 1.0))
	if stream == null or _env_level < 0.02:
		if _env_sound.playing:
			_env_sound.stop()
		return
	if _env_sound.stream != stream:
		_env_sound.stream = stream
	if not _env_sound.playing:
		_env_sound.play()
	_env_sound.volume_db = linear_to_db(_env_level)
	_env_sound.pitch_scale = pitch


## Aprendiz que bateu: a nave pontilhada refaz o movimento certo em cima da plataforma alvo (a camera vai ate la).
## Devolve a duracao (s) ou 0 se o motivo nao tem fantasma.
func play_ghost(reason: String) -> float:
	if not retry_hint.play_ghost(reason):
		return 0.0
	_focus_ghost = true
	return RetryHint.PAN_S + RetryHint.LOOP_S


## Fim do fantasma: a camera volta a seguir a nave.
func end_ghost() -> void:
	_focus_ghost = false
	retry_hint.hide_all()


## "Veja como!" (aprendiz): qualquer comando de voo tira o piloto automatico e devolve a nave ao jogador.
func _unhandled_input(event: InputEvent) -> void:
	if not guided or lander.autopilot == null:
		return
	for a: StringName in [&"thrust", &"rotate_left", &"rotate_right"]:
		if event.is_action_pressed(a):
			lander.autopilot = null
			guided = false
			took_over.emit()
			return


## Tremor de tela (somado; 1 = batida). Desligavel nas opcoes.
func shake(trauma: float) -> void:
	_shake = clampf(_shake + trauma, 0.0, 1.0)


## Fixa o "olhar para cima" da camera (previas).
func set_camera_lift(px: float) -> void:
	_lift_y = px
	camera.offset.y = px


## Gera o terreno inicial e posiciona o lander na plataforma de partida (sem alvo ainda).
func start(p_planet_id: String, seed_value: int, p_stats: Dictionary, demo: bool) -> void:
	planet_id = p_planet_id
	stats = p_stats
	_demo = demo
	_reset_map(seed_value)
	_rebuild_terrain()
	lander.setup(stats, _planet_spec(planet_id), terrain.pads)
	lander.ridge = terrain.ridge
	lander.visible = true
	lander.can_takeoff = false
	_place_on_start_pad()


## Missao nova num mapa proprio (seed_value): terreno novo com a partida em x=0, alvo como em set_target e a nave
## descendo do ceu ate a partida (world.json > missions.arrival; sem gastar gas). O gas do lander continua o mesmo.
func begin_mission(seed_value: int, distance_m: float, tier: String = "normal", dir: int = 1,
		p_mission: Dictionary = {}, stage: int = 0) -> void:
	_last_mission = [seed_value, distance_m, tier, dir, p_mission, stage]
	lander.ground_rest = apprentice
	_reset_map(seed_value)
	_shape = TerrainGen.mission_shape(p_mission, stage)
	var mg := Minigames.spec(planet_id)
	if mg.has("basin_floor_m") and _shape.has("basin_m"):     # Bolhas: vale garantido para o mar e o bau
		_shape["basin_floor_m"] = float(mg["basin_floor_m"])
	landscape_id = "" if gentle else TerrainGen.pick_landscape(landscapes, seed_value)
	if landscape_id != "":                                     # paisagem sorteada pela seed (mesma seed = mesma)
		_shape["land"] = TerrainGen.landscape(landscape_id, seed_value)
	if gentle:                                                 # 1o salto do jogo: chao quase plano, sem crista
		_shape["crest_scale"] = 0.0
		_shape["land"] = {"amplitude_m": float(WorldConfig.load_config()["onboarding"]["first_hop"]["amplitude_m"])}
	set_target(distance_m, tier, dir, p_mission, stage)
	_place_on_start_pad()
	_arrive()


## Aprendiz: a nave bateu (ou ficou sem gas) e tenta o MESMO salto de novo, com o gas do comeco dele. Mesmo mapa
## (mesma seed), nave nova descendo do ceu ate a partida.
func retry_mission(gas: float) -> void:
	if _last_mission.is_empty():
		return
	lander.setup(stats, _planet_spec(planet_id), terrain.pads)
	set_fatigue(fatigue)                                       # setup volta a eficiencia base
	lander.gas = gas
	lander.visible = true
	lander.reset_physics_interpolation()
	begin_mission(_last_mission[0], _last_mission[1], _last_mission[2], _last_mission[3], _last_mission[4],
			_last_mission[5])


## Aprendiz que nao conseguiu o salto: nave nova parada na partida do mapa atual, com o gas do comeco do salto e sem
## alvo (o cartao de missoes abre por cima; a missao escolhida gera o mapa novo).
func reset_to_start(gas: float) -> void:
	lander.setup(stats, _planet_spec(planet_id), terrain.pads)
	set_fatigue(fatigue)
	lander.gas = gas
	lander.visible = true
	lander.can_takeoff = false
	current_pad_id = 0
	target_pad_id = -1
	terrain.target_pad_id = -1
	_place_on_start_pad()


## Cansaco do run (v15, RunState.fatigue): a missao gasta fatigue x o gas normal (motor igual, eficiencia / fatigue);
## o galao devolve gas / fatigue. O Main chama antes de cada begin_mission.
func set_fatigue(f: float) -> void:
	fatigue = f
	lander.params["efficiency"] = float(stats["efficiency"]) / f


## Stats com a eficiencia da missao atual (cansaco do run) para as ajudas que estimam o gas.
func eff_stats() -> Dictionary:
	var s := stats.duplicate()
	s["efficiency"] = float(stats["efficiency"]) / fatigue
	return s


func _reset_map(seed_value: int) -> void:
	_seed = seed_value
	_shape = {}
	_bg_origin = float(posmod(seed_value, 997)) * 37.0          # trecho do fundo de cada mapa (mesma seed = mesmo)
	_pad_positions_m = [0.0]
	_pad_tiers = []
	_extend = Vector2.ZERO
	current_pad_id = 0
	target_pad_id = -1


## Nave parada na plataforma de partida (pads[0]) com a camera ja enquadrada.
func _place_on_start_pad() -> void:
	var start_pad: Dictionary = terrain.pads[0]
	var feet := WorldConfig.m_to_px(float(WorldConfig.load_config()["lander"]["feet_offset_m"]))
	lander.global_position = Vector2(float(start_pad["x"]), float(start_pad["y"]) - feet - 0.5)
	_bg_ground = 0.0
	lander.reset_physics_interpolation()
	camera.global_position = lander.global_position
	# a Flight nova entra enquanto a anterior (fundo do menu) ainda nao saiu da arvore: com a interpolacao de fisica,
	# a Camera2D so liga o proprio processamento se ja for a atual -> sem make_current a tela ficava parada
	# (ate um Esc pausar/despausar) no 1o voo de um jogo novo
	camera.make_current()
	var cam: Dictionary = WorldConfig.load_config()["camera"]
	_lift_y = -float(cam["ground_lift_px"])
	_shake = 0.0
	camera.offset = Vector2(0.0, _lift_y)
	camera.reset_smoothing()
	camera.force_update_scroll()                              # ja no 1o quadro com o enquadramento certo
	backdrop.setup(planet_id, camera.global_position.y + camera.offset.y)


## Chegada: a nave aparece arrival.height_px acima da partida e desce com a chama acesa (estado LANDED: sem fisica e
## sem gas); so pode decolar quando tocar a plataforma.
func _arrive() -> void:
	var cfg: Dictionary = WorldConfig.load_config()["missions"]["arrival"]
	var end_pos := lander.global_position
	lander.can_takeoff = false
	lander.arriving = true
	lander.global_position = end_pos - Vector2(0.0, float(cfg["height_px"]))
	lander.reset_physics_interpolation()
	camera.global_position = lander.global_position
	camera.reset_smoothing()
	var tw := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_property(lander, "global_position", end_pos, float(cfg["seconds"])) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		lander.arriving = false
		lander.can_takeoff = true
		if lander.autopilot != null:                       # o piloto do demo viu a descida: recomeça decolando
			lander.autopilot.mode = "takeoff"
		_spawn_fx(DUST_FRAMES, &"puff", Vector2(end_pos.x - 24.0, float(terrain.pads[0]["y"]) - 15.0), false))


## Define a proxima entrega: plataforma do tipo tier (normal/narrow/tight) a distance_m da atual, para o lado dir
## (1 direita, -1 esquerda), com a missao p_mission. Pagamento usa distance_m; se a plataforma cairia em cima de
## outra, ela anda um pouco no mesmo sentido (target_position_m). Taxi: stage 1 = plataforma de busca (pousar so
## embarca o passageiro), stage 2 = trecho de volta (failed_before = falhas do 1o trecho, ex.: passageiro enjoado).
func set_target(distance_m: float, tier: String = "normal", dir: int = 1, p_mission: Dictionary = {},
		stage: int = 0, failed_before: Array[String] = []) -> void:
	target_distance_m = distance_m
	target_tier = tier
	target_dir = 1 if dir >= 0 else -1
	mission = p_mission if not p_mission.is_empty() else EconMath.simple_mission()
	taxi_stage = stage
	failed = failed_before.duplicate()
	var phys := str(Minigames.spec(planet_id).get("rink_tier", tier)) if taxi_stage <= 1 else tier   # Sorvete: pista
	_pad_positions_m.append(target_position_m(distance_m, target_dir, phys))
	_pad_tiers.append(phys)
	target_pad_id = _pad_positions_m.size() - 1
	_rebuild_terrain()
	lander.pads = terrain.pads
	lander.ridge = terrain.ridge
	lander.can_takeoff = true
	_setup_mission()
	_setup_gift()
	_setup_minigame()
	if _demo or guided:
		var ap := Autopilot.new()
		ap.target = terrain.pads[target_pad_id]
		ap.ridge = terrain.ridge
		lander.autopilot = ap


## Posicao (m do modelo, a partir da partida) da plataforma de um pedido: distance_m para o lado dir; se cairia
## perto de uma plataforma que ja existe (world.json routes.clear_m alem das larguras), anda nudge_m no mesmo sentido.
func target_position_m(distance_m: float, dir: int, tier: String = "normal") -> float:
	var routes: Dictionary = WorldConfig.load_config().get("routes", {})
	var tiers: Dictionary = WorldConfig.load_config()["terrain"]["pad_tiers"]
	var half_new := float((tiers.get(tier, tiers["normal"]) as Dictionary)["width_m"]) * 0.5
	var x := _pad_positions_m[current_pad_id] + float(dir) * distance_m
	for guard in 200:
		var clear := true
		for i in _pad_positions_m.size():
			var t: String = "normal" if i == 0 else _pad_tiers[i - 1]
			var half_old := float((tiers.get(t, tiers["normal"]) as Dictionary)["width_m"]) * 0.5
			if absf(_pad_positions_m[i] - x) < half_new + half_old + float(routes.get("clear_m", 40.0)):
				clear = false
				break
		if clear:
			break
		x += float(dir) * float(routes.get("nudge_m", 60.0))
	return x


## Plataforma alvo atual (ou a atual, se nao ha alvo).
func target_pad() -> Dictionary:
	return terrain.pads[target_pad_id if target_pad_id >= 0 else current_pad_id]


func _rebuild_terrain() -> void:
	var distances: Array[float] = []
	for i in range(1, _pad_positions_m.size()):
		distances.append(_pad_positions_m[i])
	terrain.target_pad_id = target_pad_id
	terrain.build(_seed, planet_id, distances, _pad_tiers, _extend, _shape)


func _planet_spec(pid: String) -> Dictionary:
	for p: Dictionary in EconMath.spec["planets"]:
		if p["id"] == pid:
			return p
	push_error("planeta '%s' nao existe na spec" % pid)
	return EconMath.spec["planets"][0]


## O mapa nao acaba: perto de uma borda, estende o terreno naquele lado (o que ja existia nao muda).
func _extend_terrain_if_near_edge() -> void:
	var ridge := terrain.ridge
	if ridge.is_empty():
		return
	var x := lander.global_position.x
	# passo cresce com o mapa (1/4 da largura): mapas de centenas de km se estendem poucas vezes (cada vez refaz tudo)
	var step := maxf(EXTEND_STEP, (ridge[ridge.size() - 1].x - ridge[0].x) * 0.25)
	var grow := Vector2.ZERO
	if x < ridge[0].x + EXTEND_NEAR:
		grow.x = step
	if x > ridge[ridge.size() - 1].x - EXTEND_NEAR:
		grow.y = step
	if grow == Vector2.ZERO:
		return
	_extend += grow
	_rebuild_terrain()
	lander.pads = terrain.pads
	lander.ridge = terrain.ridge
	if lander.autopilot != null:
		lander.autopilot.ridge = terrain.ridge


## Texto que sobe e some no mundo (ratinho resgatado).
func _float_text(text: String, pos: Vector2) -> void:
	var l := Label.new()
	l.theme = UiKit.theme_for(planet_id)
	l.theme_type_variation = &"MoneyLabel"
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(120, 12)
	l.position = pos - Vector2(60, 6)
	add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 24.0, 0.9)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.9).set_delay(0.4)
	tw.tween_callback(l.queue_free)


func _on_lander_landed(pad: Dictionary, quality: float, info: Dictionary) -> void:
	# poeira (pixel-art: explosion.py): linha 15 do sprite = chao, x 24 = centro do lander
	_spawn_fx(DUST_FRAMES, &"puff", Vector2(lander.global_position.x - 24.0, float(pad["y"]) - 15.0), false)
	var max_vy := float(WorldConfig.load_config()["landing"]["max_vy"])
	_landing_sound(clampf(float(info.get("vy", 0.0)) / max_vy, 0.0, 1.0))
	shake(float(WorldConfig.load_config()["camera"]["land_shake"]) * clampf(float(info.get("vy", 0.0)) / max_vy, 0.0, 1.0))
	current_pad_id = int(pad["id"])
	if current_pad_id == target_pad_id and planet_id == "sorvete" and not _rings.is_empty():
		_start_slide(info)                                     # curling: a entrega so fecha quando a nave para
	elif current_pad_id == target_pad_id:
		_complete_landing(pad, quality, info)
	elif lander.gas <= 0.001:
		stranded.emit()


## Aprendiz: parou no chao fora da plataforma (Lander.ground_rest). Poeira e aviso; sem gas = sem como sair dali.
func _on_lander_rested(info: Dictionary) -> void:
	var ground := TerrainGen.height_at(terrain.ridge, lander.global_position.x)
	_spawn_fx(DUST_FRAMES, &"puff", Vector2(lander.global_position.x - 24.0, ground - 15.0), false)
	_landing_sound(0.2)
	_float_text("decole de novo!", lander.global_position - Vector2(0.0, 26.0))
	rested.emit(info)
	if lander.gas <= 0.001:
		stranded.emit()


## Raspao (Lander.scraped): quicou no chao fora da plataforma. Pancada, poeira e a nave pisca vermelho; o ultimo
## amassado que ainda aguenta pisca mais forte (o proximo explode).
func _on_lander_scraped(count: int, at: Vector2) -> void:
	var last := count >= int(WorldConfig.load_config()["landing"]["scrape"]["per_hop"])
	Sound.sfx("bump", 0.0, 0.85 if last else 1.0)
	shake(0.55 if last else 0.4)
	_spawn_fx(DUST_FRAMES, &"puff", at - Vector2(24.0, 15.0), false)
	var tw := lander.create_tween()
	for i in (3 if last else 1):
		tw.tween_property(lander, "modulate", Color(1.0, 0.45, 0.45), 0.06)
		tw.tween_property(lander, "modulate", Color.WHITE, 0.12)
	Telemetry.event("scrape", str(count))


## Pouso com a forca da descida k (0 = pena, 1 = no limite): mais alto e mais grave; forte = camada de pancada.
func _landing_sound(k: float) -> void:
	Sound.sfx("landing", lerpf(LAND_DB.x, LAND_DB.y, k), lerpf(LAND_PITCH.x, LAND_PITCH.y, k))
	if k > HEAVY_FROM:
		Sound.sfx("landing_heavy", lerpf(-10.0, 0.0, (k - HEAVY_FROM) / (1.0 - HEAVY_FROM)))


func _complete_landing(_pad: Dictionary, quality: float, info: Dictionary) -> void:
	_judge_mission(info, quality)
	Sound.sfx("delivered")
	lander.can_takeoff = false
	target_pad_id = -1
	terrain.target_pad_id = -1
	_finish(false, quality, "", info)


func _on_lander_crashed(reason: String, info: Dictionary) -> void:
	# a nave some e explode; o resultado so sai depois da explosao (senao o resumo a cobre)
	lander.visible = false
	Sound.sfx("splash" if reason == "mar" else "crash_soft")   # batida fofa (puf + apito); no mar, tchibum
	shake(1.0)
	var fx := _spawn_fx(EXPLOSION_FRAMES, &"boom", lander.global_position, true)
	await fx.animation_finished
	_finish(true, 0.0, reason, info)


## Efeito de uma vez (AnimatedSprite2D) no mundo, por cima do lander; se apaga ao terminar.
func _spawn_fx(frames: SpriteFrames, anim: StringName, pos: Vector2, centered: bool) -> AnimatedSprite2D:
	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = frames
	fx.centered = centered
	add_child(fx)
	fx.global_position = pos
	fx.play(anim)
	fx.animation_finished.connect(fx.queue_free)
	return fx


func _finish(crashed: bool, quality: float, reason: String, info: Dictionary) -> void:
	var result := {
		"planet": planet_id,
		"distance": target_distance_m,
		"thrust": stats["thrust"],
		"efficiency": float(lander.params["efficiency"]),
		"tank": stats["tank"],
		"gas_used": info["gas_used"],
		"hop_time_s": info["flight_time_m"],
		"quality": quality,
		"perfect": not crashed and LandingRules.is_perfect(float(info.get("vy", 0.0)), float(info.get("tilt", 0.0)),
				WorldConfig.load_config()["landing"]),
		"tier": target_tier,
		"dir": target_dir,
		"mission": mission,
		"failed": failed.duplicate(),
		"partial": minigame_partial(),
		"mission_ok": failed.is_empty() and not crashed,
		"leg": taxi_stage,
		"gift": gift_kind if gift_taken else "",
		"gift_pay": (EconMath.gift_value(planet_id, target_distance_m, stats, gift_kind) if gift_taken else 0.0)
				+ (EconMath.minigame_pay(planet_id, target_distance_m, stats, float(minigame_got) / minigame_total,
						maxi(1, int(mission.get("star", 1))))
				if minigame_total > 0 else 0.0) if not crashed else 0.0,
		"minigame": [minigame_got, minigame_total],
		"mg_extra": snappedf(minigame_extra, 0.01),
		"crashed": crashed,
		"reason": reason,
		# velocidade e inclinacao no toque (m/s e rad do modelo): calibram as tolerancias de pouso (world.json > landing)
		"vy": snappedf(float(info.get("vy", 0.0)), 0.01),
		"vx": snappedf(float(info.get("vx", 0.0)), 0.01),
		"tilt": snappedf(float(info.get("tilt", 0.0)), 0.001),
		"scrapes": int(info.get("scrapes", 0)),
		"hard": bool(info.get("hard", false)),
	}
	Telemetry.record_delivery(result)
	_clear_mission()
	_clear_gift()
	_clear_minigame()
	delivery_finished.emit(result)


# ---------------------------------------------------------------- minijogos do mundo (v17, world.json > minigames)
## Monta o minijogo do mundo para o salto atual (so no 1o trecho; o pedido tem que ser o do mundo).
func _setup_minigame() -> void:
	_clear_minigame()
	var cfg := Minigames.spec(planet_id)
	if cfg.is_empty() or taxi_stage > 1 or not minigame_on:    # comeco do jogo: so pousar (onboarding)
		return
	var star := maxi(1, int(mission.get("star", 1)))
	if planet_id == "luna":                                    # trilha de queijinhos (Subway Surfers)
		var n := int(Minigames.by_star(cfg["coins"], star))
		var pts := Minigames.trail_points(terrain.pads[current_pad_id], terrain.pads[target_pad_id], n,
				float(Minigames.by_star(cfg["arc_mult"], star)), WorldConfig.m_to_px(float(cfg.get("max_extra_lift_m", INF))))
		for p: Vector2 in pts:
			var sp := Sprite2D.new()
			sp.texture = MinigameArt.tex("cheese")
			sp.position = p
			add_child(sp)
			move_child(sp, lander.get_index())
			_trail.append({"pos": p, "sprite": sp, "got": false})
		minigame_total = n
	elif planet_id == "cogumelos":                             # cogumelos-mola (Doodle Jump) + ovinho (Pouso suave)
		_setup_caps(cfg, star)
	elif planet_id == "bolhas":                                # garra do bau (maquina de garra) + mar + bolhas
		_setup_claw(cfg, star)
	elif planet_id == "jardim":                                # caules das flores (Flappy Bird) + vento + mel pesado
		_setup_stems(cfg, star)
	elif planet_id == "sorvete":                               # curling: aneis no meio da pista de gelo
		var pad: Dictionary = terrain.pads[target_pad_id]
		lander.ice_pad_id = target_pad_id
		lander.ice_vx_mult = float(cfg.get("ice_vx_mult", 4.0))
		var ice := MinigameArt.tiled("ice", Rect2(float(pad["x"]) - float(pad["half_width"]), float(pad["y"]) - 4.0,
				float(pad["half_width"]) * 2.0, 4.0))               # a pista de gelo inteira
		add_child(ice)
		_rings.append(ice)
		var r := WorldConfig.m_to_px(float((cfg["ring_m"] as Dictionary).get(target_tier, 46.0)))
		for ring: Array in [[r, "#e83b3b"], [r * 0.66, "#ffffff"], [r * 0.33, "#4d9be6"]]:
			var bar := ColorRect.new()
			bar.color = Color(str(ring[1]))
			bar.position = Vector2(float(pad["x"]) - float(ring[0]), float(pad["y"]) - 3.0)
			bar.size = Vector2(float(ring[0]) * 2.0, 5.0)
			add_child(bar)
			_rings.append(bar)
		_ghost = Node2D.new()                                  # placeholder (pino branco com contorno ink)
		for part: Array in [[Rect2(-2, -13, 5, 15), "#2e222f"], [Rect2(-1, -12, 3, 13), "#ffffff"],
				[Rect2(-4, -14, 9, 4), "#2e222f"], [Rect2(-3, -13, 7, 2), "#ffffff"]]:
			var cr := ColorRect.new()
			cr.color = Color(str(part[1]))
			cr.position = (part[0] as Rect2).position
			cr.size = (part[0] as Rect2).size
			_ghost.add_child(cr)
		_ghost.hide()
		add_child(_ghost)
		_rings.append(_ghost)
		minigame_total = 1
	elif planet_id == "nuvens":                                # fila de carneirinhos (Snake) + correntes
		var a: Dictionary = terrain.pads[current_pad_id]
		var b: Dictionary = terrain.pads[target_pad_id]
		var n := int(Minigames.by_star(cfg["sheep"], star))
		var hv: Array = cfg["hover_m"]
		var rng := RandomNumberGenerator.new()
		rng.seed = _seed * 13 + 5
		var up: Dictionary = cfg["updrafts"]
		var half := WorldConfig.m_to_px(float(up["width_m"])) * 0.5
		for x: float in Minigames.spread_x(a, b, int(up["count"])):
			_updrafts.append({"x": x + (rng.randf() - 0.5) * half, "half": half})
		var xs := Minigames.sheep_xs(Minigames.spread_x(a, b, n), _updrafts,
				WorldConfig.m_to_px(float(cfg.get("updraft_clear_m", 0.0))),
				int(Minigames.by_star(cfg.get("updraft_sheep", [0]), star)), float(a["x"]), float(b["x"]))
		for x: float in xs:
			var p := Vector2(x, TerrainGen.height_at(terrain.ridge, x) - WorldConfig.m_to_px(rng.randf_range(hv[0], hv[1])))
			var sp := Sprite2D.new()
			sp.texture = MinigameArt.tex("sheep%d" % (_sheep.size() % 2))
			sp.position = p
			add_child(sp)
			move_child(sp, lander.get_index())
			_sheep.append({"pos": p, "sprite": sp, "got": false})
		minigame_total = n
		for u: Dictionary in _updrafts:
			var x := float(u["x"])
			var gy := TerrainGen.height_at(terrain.ridge, x)
			var top := gy - WorldConfig.m_to_px(float(up["height_m"]))
			var y := gy - 10.0
			var k := 0
			while y > top:                                       # lufadas de vento subindo (sobem no _tick_sheep)
				var puff := Sprite2D.new()
				puff.texture = MinigameArt.tex("puff")
				puff.position = Vector2(x + (float(k % 3) - 1.0) * half * 0.5, y)
				puff.set_meta("x0", puff.position.x)
				puff.set_meta("bottom", gy - 10.0)
				puff.set_meta("top", top)
				add_child(puff)
				move_child(puff, lander.get_index())
				_updraft_lines.append(puff)
				y -= 34.0
				k += 1


## Cogumelos: chapeus-mola em escada entre as plataformas (placeholder desenhado ate a arte).
func _setup_caps(cfg: Dictionary, star: int) -> void:
	var a: Dictionary = terrain.pads[current_pad_id]
	var b: Dictionary = terrain.pads[target_pad_id]
	var n := int(Minigames.by_star(cfg["caps"], star))
	var half := WorldConfig.m_to_px(float(Minigames.by_star(cfg["cap_half_m"], star)))
	var above := WorldConfig.m_to_px(float(Minigames.by_star(cfg["cap_above_target_m"], star)))
	var clear := WorldConfig.m_to_px(float(cfg.get("cap_min_clear_m", 20.0)))
	var xs := Minigames.spread_x(a, b, n)
	for i in n:
		var x: float = xs[i]
		var gy := TerrainGen.height_at(terrain.ridge, x)
		var cy := Minigames.cap_y(float(a["y"]), float(b["y"]), i, n, above, gy, clear)   # escada ate acima do alvo
		var node := Node2D.new()
		node.add_child(MinigameArt.tiled("stalk", Rect2(x - 4.0, cy - 2.0, 8.0, gy - cy + 6.0)))
		var cap := Sprite2D.new()
		cap.texture = MinigameArt.tex(MinigameArt.cap_for(half * 2.0))
		cap.centered = false
		cap.position = Vector2(roundf(x - cap.texture.get_width() * 0.5), cy - cap.texture.get_height() + 2.0)
		node.add_child(cap)
		add_child(node)
		move_child(node, lander.get_index())
		_caps.append({"x": x, "y": cy, "half": half, "node": node, "hit": false})
	minigame_total = n


## Jardim: N caules entre as plataformas, o vao no arco ideal (quem voa o arco passa).
func _setup_stems(cfg: Dictionary, star: int) -> void:
	var a: Dictionary = terrain.pads[current_pad_id]
	var b: Dictionary = terrain.pads[target_pad_id]
	var n := int(Minigames.by_star(cfg["stems"], star))
	var gap := WorldConfig.m_to_px(float(Minigames.by_star(cfg["gap_m"], star)))
	var half := WorldConfig.m_to_px(float(cfg.get("stem_half_m", 7.0)))
	var arc := Assists.arc(a, b, 40)
	for x: float in Minigames.spread_x(a, b, n):
		var u := clampf((x - float(a["x"])) / (float(b["x"]) - float(a["x"])), 0.0, 1.0)
		var gy := TerrainGen.height_at(terrain.ridge, x)
		var cy := minf(arc[roundi(u * 40.0)].y, gy - 10.0 - gap * 0.5)   # perto do chao o vao sobe inteiro
		var top := cy - gap * 0.5
		var bot := cy + gap * 0.5
		var node := Node2D.new()
		for seg: Array in [[top - 1200.0, top], [bot, gy + 4.0]]:
			var h := maxf(0.0, float(seg[1]) - float(seg[0]))
			node.add_child(MinigameArt.tiled("stem", Rect2(roundf(x - half), float(seg[0]), half * 2.0, h)))
		for edge: Array in [[top, "bloom_top", 4.0], [bot, "bloom_bot", -4.0]]:   # flor na borda do vao
			var fl := Sprite2D.new()
			fl.texture = MinigameArt.tex(str(edge[1]))
			fl.position = Vector2(roundf(x), float(edge[0]) + float(edge[2]))
			node.add_child(fl)
		add_child(node)
		move_child(node, lander.get_index())
		_stems.append({"x": x, "half": half, "gap_top": top, "gap_bot": bot, "passed": false, "bumped": false,
				"node": node})
	minigame_total = n
	_wind_t = 0.0
	_calm_t = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed * 7 + 3
	var view := get_viewport_rect().size
	for i in int(cfg.get("seeds", 16)):                        # sementes espalhadas na tela (andam no _tick_stems)
		var sd := Sprite2D.new()
		sd.texture = MinigameArt.tex("seed")
		sd.position = lander.global_position + Vector2(rng.randf_range(-0.5, 0.5) * view.x,
				rng.randf_range(-0.5, 0.5) * view.y)
		sd.set_meta("phase", rng.randf() * TAU)
		add_child(sd)
		_seeds.append(sd)


## Bolhas: faixa de mar entre as plataformas, o bau no meio (no fundo raso) e colunas de bolhas.
func _setup_claw(cfg: Dictionary, star: int) -> void:
	var a: Dictionary = terrain.pads[current_pad_id]
	var b: Dictionary = terrain.pads[target_pad_id]
	var x0 := minf(float(a["x"]), float(b["x"])) + float(a["half_width"])
	var x1 := maxf(float(a["x"]), float(b["x"])) - float(b["half_width"])
	var low_pad := maxf(float(a["y"]), float(b["y"]))
	var wy := low_pad + WorldConfig.m_to_px(float(cfg.get("water_below_m", 18.0)))
	var depth := WorldConfig.m_to_px(float(Minigames.by_star(cfg.get("chest_depth_m", [24.0]), star)))
	var cx := Minigames.deepest_x(terrain.ridge, lerpf(x0, x1, 0.3), lerpf(x0, x1, 0.7))
	var gy := TerrainGen.height_at(terrain.ridge, cx)
	if gy - 6.0 < wy + depth:                                  # vale raso: o mar sobe (no maximo ate a plataforma mais baixa)
		wy = maxf(low_pad + 2.0, gy - 6.0 - depth)
	_water = {"x0": x0, "x1": x1, "y": wy}
	_water_node = Node2D.new()
	var top := MinigameArt.tiled("sea", Rect2(x0, wy - 2.0, maxf(0.0, x1 - x0), 12.0))
	_water_node.add_child(top)
	var deep := ColorRect.new()
	deep.color = Color(str(MinigameArt.meta()["sea_deep"]))
	deep.position = Vector2(x0, wy + 10.0)
	deep.size = Vector2(maxf(0.0, x1 - x0), 2000.0)
	_water_node.add_child(deep)
	add_child(_water_node)
	move_child(_water_node, terrain.get_index())               # atras do relevo: o mar so aparece nos vales
	_chest_pos = Vector2(cx, minf(gy - 6.0, wy + depth))       # no fundo do vale, depth abaixo do mar (estrela)
	_chest_sprite = Sprite2D.new()
	_chest_sprite.texture = MinigameArt.tex("chest")
	_chest_sprite.position = _chest_pos
	add_child(_chest_sprite)
	var bub: Dictionary = cfg["bubbles"]
	var half := WorldConfig.m_to_px(float(bub["width_m"])) * 0.5
	var n := int(Minigames.by_star(bub["count"], star))
	var reach := WorldConfig.m_to_px(float(bub["height_m"]))
	for i in n:
		var bx := lerpf(x0, x1, float(i + 1) / float(n + 1))
		_bubbles.append({"x": bx, "half": half})
		for j in 6:                                            # bolhinhas subindo (anda no _tick_claw)
			var bs := Sprite2D.new()
			bs.texture = MinigameArt.tex("bubble3" if j % 2 else "bubble2")
			bs.position = Vector2(bx + (float(j % 3) - 1.0) * half * 0.5, wy - reach * float(j) / 6.0)
			bs.set_meta("x0", bs.position.x)
			bs.set_meta("bottom", wy + 6.0)
			bs.set_meta("top", wy - reach)
			add_child(bs)
			_bubble_sprites.append(bs)
	chest_got = false
	chest_wet = false
	_wet_t = 0.0
	minigame_total = 1


func _clear_minigame() -> void:
	if _chest_sprite != null and is_instance_valid(_chest_sprite):
		_chest_sprite.queue_free()
	_chest_sprite = null
	if _water_node != null and is_instance_valid(_water_node):
		_water_node.queue_free()
	_water_node = null
	_water = {}
	_bubbles.clear()
	for b: Sprite2D in _bubble_sprites:
		if is_instance_valid(b):
			b.queue_free()
	_bubble_sprites.clear()
	for c: Dictionary in _stems:
		if is_instance_valid(c["node"]):
			(c["node"] as Node).queue_free()
	_stems.clear()
	for sd: Sprite2D in _seeds:
		if is_instance_valid(sd):
			sd.queue_free()
	_seeds.clear()
	for n: Node in _rings:
		if is_instance_valid(n):
			n.queue_free()
	_rings.clear()
	_ghost = null                                          # foi liberado junto com _rings
	sliding = false
	lander.ice_pad_id = -1
	for c: Dictionary in _caps:
		if is_instance_valid(c["node"]):
			(c["node"] as Node).queue_free()
	_caps.clear()
	for c: Dictionary in _trail + _sheep + _tail:
		if is_instance_valid(c["sprite"]):
			(c["sprite"] as Node).queue_free()
	for n: Node in _updraft_lines:
		if is_instance_valid(n):
			n.queue_free()
	_updraft_lines.clear()
	_updrafts.clear()
	_sheep.clear()
	_tail.clear()
	_history.clear()
	lander.env_accel = Vector2.ZERO
	_trail.clear()
	minigame_got = 0
	minigame_total = 0
	minigame_extra = 0.0


func _tick_minigame() -> void:
	if planet_id == "nuvens":
		_tick_sheep()
		return
	if planet_id == "cogumelos":
		_tick_caps()
		return
	if planet_id == "sorvete":
		_tick_slide()
		return
	if planet_id == "jardim":
		_tick_stems()
		return
	if planet_id == "bolhas":
		_tick_claw()
		return
	if _trail.is_empty() or lander.state != Lander.State.FLYING:
		return
	var r := WorldConfig.m_to_px(float(Minigames.spec(planet_id).get("radius_m", 14.0)))
	for c: Dictionary in _trail:
		if not c["got"] and Minigames.touches(lander.global_position, c["pos"], r):
			c["got"] = true
			minigame_got += 1
			(c["sprite"] as Sprite2D).hide()
			Sound.sfx("crystal_%d" % clampi(minigame_got % 3 + 1, 1, 3))
			if minigame_got == minigame_total:                 # trilha completa: festa
				_float_text("trilha completa!", lander.global_position + Vector2(0, -22))
				Sound.sfx("star")


## Nuvens: pega carneirinhos ao encostar (entram na fila), a fila segue a nave, encostar no chao perde o ultimo;
## dentro de uma corrente de ar a nave e empurrada para cima.
func _tick_sheep() -> void:
	_rise(_updraft_lines, 40.0)
	_anim_sheep()
	var cfg := Minigames.spec(planet_id)
	var flying := lander.state == Lander.State.FLYING
	var gy := TerrainGen.height_at(terrain.ridge, lander.global_position.x)
	var up: Dictionary = cfg.get("updrafts", {})
	lander.env_accel = Vector2(0.0, -float(up.get("accel", 0.0))) if flying and Minigames.in_updraft(
			lander.global_position, _updrafts, gy, WorldConfig.m_to_px(float(up.get("height_m", 0.0)))) else Vector2.ZERO
	if minigame_total <= 0:
		return
	if flying:
		_history.insert(0, lander.global_position + Vector2(0, 6))
		if _history.size() > 400:
			_history.resize(400)
		var r := WorldConfig.m_to_px(float(cfg.get("radius_m", 16.0)))
		for c: Dictionary in _sheep:
			if not c["got"] and Minigames.touches(lander.global_position, c["pos"], r):
				c["got"] = true
				_tail.append(c)
				minigame_got += 1
				Sound.sfx("sheep_%d" % clampi(minigame_got, 1, 5))
	var step := int(cfg.get("follow_frames", 9))
	for i in _tail.size():
		var p := Minigames.follow_point(_history, i, step)
		(_tail[i]["sprite"] as Sprite2D).position = p
	if flying and not _tail.is_empty():                         # o ultimo da fila encostou no chao: caiu
		var last: Dictionary = _tail[-1]
		var lp: Vector2 = (last["sprite"] as Sprite2D).position
		if lp.y >= TerrainGen.height_at(terrain.ridge, lp.x) - 2.0:
			_tail.pop_back()
			minigame_got -= 1
			last["got"] = false                                # volta pulando para o lugar dele (da para buscar de novo)
			var sp := last["sprite"] as Sprite2D
			var tw := sp.create_tween()
			tw.tween_property(sp, "position", last["pos"] as Vector2, 0.6).set_trans(Tween.TRANS_QUAD)
			_float_text("caiu!", lp + Vector2(0, -12))


## Cogumelos: caindo sobre um chapeu, a nave quica (conta o quique; nao e pouso nem batida).
func _tick_caps() -> void:
	if _caps.is_empty() or lander.state != Lander.State.FLYING:
		return
	var feet := lander.global_position + Vector2(0, WorldConfig.m_to_px(
			float(WorldConfig.load_config()["lander"]["feet_offset_m"])))
	var cfg := Minigames.spec(planet_id)
	for ci in _caps.size():
		var c: Dictionary = _caps[ci]
		if Minigames.hits_cap(feet, lander.vel_m.y, c):
			lander.vel_m.y = Minigames.bounce_vy(lander.vel_m.y, float(cfg.get("bounce_mps", 10.0)))
			minigame_extra += 1.0                              # quiques totais (telemetria)
			if not c["hit"]:                                   # cada chapeu conta uma vez no placar
				c["hit"] = true
				minigame_got += 1
			Sound.sfx("boing_%d" % clampi(ci + 1, 1, 3))           # cada degrau da escada soa mais alto
			UiKit.pulse(c["node"], 1.6, 0.25)
			break


## Sorvete: depois do pouso a nave desliza no gelo; quando para, a qualidade e a distancia ao centro do alvo.
func _start_slide(info: Dictionary) -> void:
	var cfg := Minigames.spec(planet_id)
	sliding = true
	_slide_info = info
	var vx := float(info.get("vx", 0.0))
	_slide_v = signf(vx if vx != 0.0 else float(target_dir)) * maxf(absf(vx), float(cfg.get("min_slide_mps", 5.0)))
	lander.can_takeoff = false


func _tick_slide() -> void:
	if not sliding:
		_tick_ghost()
		return
	var cfg := Minigames.spec(planet_id)
	var dt_m := get_physics_process_delta_time() * float(WorldConfig.load_config()["time_scale"])
	var pad: Dictionary = terrain.pads[target_pad_id]
	var nx := lander.global_position.x + WorldConfig.m_to_px(_slide_v * dt_m)
	var lim := float(pad["half_width"]) - 6.0
	nx = clampf(nx, float(pad["x"]) - lim, float(pad["x"]) + lim)      # a borda da pista segura a nave
	lander.global_position.x = nx
	_slide_v = Minigames.slide_step(_slide_v, float(cfg.get("friction_mps2", 5.0)), dt_m)
	if absf(_slide_v) <= float(cfg.get("stop_mps", 0.6)) or absf(nx - float(pad["x"])) >= lim:
		sliding = false
		var dist := WorldConfig.px_to_m(absf(nx - float(pad["x"])))
		minigame_extra = dist
		var q := Minigames.curling_quality(dist, float((cfg["ring_m"] as Dictionary).get(target_tier, 46.0)))
		minigame_got = 1 if q > 0.0 else 0
		_float_text("no miolo!" if q > 0.66 else ("no alvo!" if q > 0.0 else "fora do alvo"),
				lander.global_position + Vector2(0, -26))
		Sound.sfx("star" if q > 0.66 else ("target_hit" if q > 0.0 else "oops"))
		_complete_landing(pad, q, _slide_info)


## Sorvete: perto da pista (ghost_below_m), mostra onde a nave pararia se tocasse no gelo com a velocidade de agora.
func _tick_ghost() -> void:
	if _ghost == null or target_pad_id < 0 or lander.state != Lander.State.FLYING:
		if _ghost != null:
			_ghost.hide()
		return
	var cfg := Minigames.spec(planet_id)
	var pad: Dictionary = terrain.pads[target_pad_id]
	var feet := WorldConfig.m_to_px(float(WorldConfig.load_config()["lander"]["feet_offset_m"]))
	var h := WorldConfig.px_to_m(float(pad["y"]) - lander.global_position.y - feet)
	var x := Minigames.slide_stop_x(lander.global_position.x, lander.vel_m, h, float(cfg.get("min_slide_mps", 4.0)),
			float(cfg.get("friction_mps2", 0.6)), float(target_dir))
	var lim := float(pad["half_width"]) - 6.0
	var over := absf(lander.global_position.x - float(pad["x"])) <= float(pad["half_width"])
	_ghost.visible = h >= 0.0 and h <= float(cfg.get("ghost_below_m", 40.0)) and over
	_ghost.position = Vector2(roundf(clampf(x, float(pad["x"]) - lim, float(pad["x"]) + lim)), float(pad["y"]) - 3.0)


## Jardim: vento de dente-de-leao empurra de lado; bater num caule empurra de volta (sem explodir) e o caule nao
## conta; passar o caule pelo vao conta.
func _tick_stems() -> void:
	var cfg := Minigames.spec(planet_id)
	var flying := lander.state == Lander.State.FLYING
	if _stems.is_empty():
		return
	var dt := get_physics_process_delta_time()
	_wind_t += dt
	_calm_t = maxf(0.0, _calm_t - dt)
	var star := maxi(1, int(mission.get("star", 1)))
	_wind_max = float(Minigames.by_star(cfg["wind_mps2"], star))
	var wind := Minigames.wind_at(_wind_t, _wind_max, float(cfg.get("wind_period_s", 5.0)))
	_wind_now = wind
	_move_seeds(wind, float(cfg.get("seed_px_per_mps2", 20.0)), dt)
	lander.env_accel = Vector2(wind if _calm_t <= 0.0 else 0.0, 0.0) if flying else Vector2.ZERO
	if not flying:
		return
	var dir := 1.0 if float(terrain.pads[target_pad_id]["x"]) >= float(terrain.pads[current_pad_id]["x"]) else -1.0
	for st: Dictionary in _stems:
		if Minigames.hits_stem(lander.global_position, st):
			if not st["bumped"]:
				st["bumped"] = true
				_float_text("ai! o caule", lander.global_position + Vector2(0, -20))
				Sound.sfx("bump")
			lander.vel_m.x = -dir * maxf(absf(lander.vel_m.x) * float(cfg.get("bump_back", 0.5)), 2.0)
			lander.global_position.x = float(st["x"]) - dir * (float(st["half"]) + 2.0)
			_calm_t = float(cfg.get("bump_calm_s", 0.3))         # o vento nao empurra de volta contra o caule
		elif not st["passed"] and (lander.global_position.x - float(st["x"])) * dir > float(st["half"]):
			st["passed"] = true
			if not st["bumped"]:
				minigame_got += 1
				Sound.sfx("pass_%d" % ((minigame_got - 1) % 3 + 1))


## Jardim: as sementes andam com o vento (px/s = vento x px_per) e balancam; quem sai da tela volta do outro lado.
func _move_seeds(wind: float, px_per: float, dt: float) -> void:
	var c := camera.get_screen_center_position()
	var half := get_viewport_rect().size * 0.5 + Vector2(8, 8)
	for sd: Sprite2D in _seeds:
		var ph := float(sd.get_meta("phase"))
		sd.position += Vector2(wind * px_per + sin(_wind_t * 2.0 + ph) * 6.0, 3.0 + cos(_wind_t * 1.3 + ph) * 4.0) * dt
		var rel := sd.position - c
		if absf(rel.x) > half.x:
			sd.position.x = c.x - signf(rel.x) * (half.x - 1.0)
		if absf(rel.y) > half.y:
			sd.position.y = c.y - signf(rel.y) * (half.y - 1.0)
		sd.rotation = clampf(wind * 0.12, -0.5, 0.5)


## Bolhas: a garra pega o bau ao encostar (vira a carga com o peso da estrela); o bau no mar por wet_s = molhou;
## a nave no mar = splash (batida); bolhas empurram nave e carga para cima.
func _tick_claw() -> void:
	if _water.is_empty():
		return
	_rise(_bubble_sprites, 30.0)
	var cfg := Minigames.spec(planet_id)
	var flying := lander.state == Lander.State.FLYING
	var over_sea := lander.global_position.x > float(_water["x0"]) and lander.global_position.x < float(_water["x1"])
	if flying and over_sea and lander.global_position.y > float(_water["y"]):
		lander.crash_now("mar")                                # splash
		return
	var bub: Dictionary = cfg["bubbles"]
	var star := maxi(1, int(mission.get("star", 1)))
	var acc := float(Minigames.by_star(bub["accel"], star))
	var reach := WorldConfig.m_to_px(float(bub["height_m"]))
	var in_bub := func(p: Vector2) -> bool:
		return p.y > float(_water["y"]) - reach and _bubbles.any(func(c: Dictionary) -> bool:
			return absf(p.x - float(c["x"])) <= float(c["half"]))
	lander.env_accel = Vector2(0.0, -acc) if flying and in_bub.call(lander.global_position) else Vector2.ZERO
	if _tow == null:
		return
	var dt_m := get_physics_process_delta_time() * float(WorldConfig.load_config()["time_scale"])
	if in_bub.call(_tow.pos):
		_tow.vel.y -= acc * dt_m
	if not chest_got and _tow.pos.distance_to(_chest_pos) <= WorldConfig.m_to_px(float(cfg.get("grab_m", 10.0))):
		chest_got = true                                       # pegou: o bau vira a carga do cabo
		var lv: Array = WorldConfig.load_config()["missions"]["tow"]["levels"]
		_tow.mass = float(lv[clampi(int(mission.get("star", 1)), 1, lv.size()) - 1]["mass"])
		_tow.radius_px = WorldConfig.m_to_px(float(WorldConfig.load_config()["missions"]["tow"]["radius_m"]))
		_tow_sprite.texture = MinigameArt.tex("chest")
		_chest_sprite.hide()
		minigame_got = 1
		Sound.sfx("chest")
	if chest_got and not chest_wet:
		var wet: bool = _tow.pos.x > float(_water["x0"]) and _tow.pos.x < float(_water["x1"]) \
				and _tow.pos.y > float(_water["y"])
		_wet_t = _wet_t + get_physics_process_delta_time() if wet else 0.0
		minigame_extra = maxf(minigame_extra, _wet_t)
		var wet_s := float(Minigames.by_star(cfg.get("wet_s", [0.6]), star))
		var k := clampf(_wet_t / wet_s, 0.0, 1.0)              # aviso: o bau pisca de amarelo a vermelho enquanto molha
		var blink := 1.0 if int(_wet_t * 12.0) % 2 == 0 else 0.0
		if k <= 0.0 or blink == 0.0:                           # piscar em silhueta ambar -> vermelha (cores da paleta)
			_tow_sprite.material = null
		else:
			UiKit.silhouette(_tow_sprite, UiKit.color("amber") if k < 0.6 else UiKit.color("red"))
		if _wet_t >= wet_s:
			chest_wet = true
			_mission_failed("tow", "", _tow.pos)
			_float_text("molhou!", _tow.pos + Vector2(0, -14))


## Carneirinhos pulando (2 quadros), de frente para a nave quando estao na fila.
func _anim_sheep() -> void:
	var fr := int(Time.get_ticks_msec() / 250) % 2
	for c: Dictionary in _sheep:
		var sp := c["sprite"] as Sprite2D
		if is_instance_valid(sp):
			sp.texture = MinigameArt.tex("sheep%d" % fr)
			sp.flip_h = bool(c["got"]) and lander.global_position.x > sp.position.x


## Sobe as figurinhas (bolhas, lufadas) em laco entre as metas "bottom" e "top", balancando de lado.
func _rise(nodes: Array, speed: float) -> void:
	var dt := get_physics_process_delta_time()
	for n: Variant in nodes:
		var s := n as Node2D
		if s == null or not is_instance_valid(s):
			continue
		var y := s.position.y - speed * dt
		if y < float(s.get_meta("top")):
			y = float(s.get_meta("bottom"))
		s.position = Vector2(float(s.get_meta("x0")) + sin(y * 0.08) * 2.0, y)


## v18: credito parcial da regra do mundo que falhou pelo minijogo ({kind: parte cumprida 0..1}): Nuvens = carneirinhos
## que chegaram, Jardim = vaos passados, Bolhas = 0,5 se o bau chegou (molhado/rachado) e 0 sem bau.
func minigame_partial() -> Dictionary:
	if minigame_total <= 0:
		return {}
	var frac := float(minigame_got) / float(minigame_total)
	match planet_id:
		"nuvens":
			return {"passenger": frac}
		"jardim":
			return {"heavy": frac}
		"bolhas":
			return {"tow": 0.5 if chest_got else 0.0}
	return {}


## Placar do minijogo para o HUD ("" sem minijogo): figura (minigame_icon) + "n/N"; estados em palavra curta.
func minigame_text() -> String:
	if minigame_total <= 0:
		return ""
	if planet_id == "sorvete":
		return "deslizando..." if sliding else "deslize até o alvo"
	if planet_id == "bolhas":
		return ("molhou!" if chest_wet else "baú na garra!") if chest_got else "pegue o baú"
	return "%d/%d" % [minigame_got, minigame_total]


## Figura do item do minijogo (atlas MinigameArt) para o placar do HUD ("" = usa o icone padrao).
func minigame_icon() -> String:
	return {"luna": "cheese", "nuvens": "sheep0", "cogumelos": "cap36", "jardim": "bloom_top", "bolhas": "chest"}.get(
			planet_id, "")


## Posicao (px do mundo) do proximo item do minijogo ainda nao feito, ou Vector2.INF se nao ha: Lua/Nuvens = o mais
## perto nao pego; Cogumelos = o proximo chapeu nao quicado; Jardim = o vao do proximo caule; Bolhas = o bau.
func minigame_next_target() -> Vector2:
	if not _water.is_empty():
		return Vector2.INF if chest_got else _chest_pos
	var cands: Array[Vector2] = []
	for c: Dictionary in _trail + _sheep:
		if not c["got"]:
			cands.append(c["pos"] as Vector2)
	for c: Dictionary in _caps:
		if not c["hit"]:
			cands.append(Vector2(float(c["x"]), float(c["y"])))
	for st: Dictionary in _stems:
		if not st["passed"]:
			cands.append(Vector2(float(st["x"]), (float(st["gap_top"]) + float(st["gap_bot"])) * 0.5))
	var p := lander.global_position
	var best := Vector2.INF
	for q: Vector2 in cands:
		if best == Vector2.INF or p.distance_to(q) < p.distance_to(best):
			best = q
	return best


## Seta na borda da tela apontando o proximo item do minijogo quando ele esta fora da vista (so voando).
func _update_pointer() -> void:
	var t := minigame_next_target() if lander.state == Lander.State.FLYING and target_pad_id >= 0 else Vector2.INF
	var c := camera.get_screen_center_position()
	var half := get_viewport_rect().size * 0.5 - Vector2(18, 18)
	var rel := t - c
	if t == Vector2.INF or (absf(rel.x) <= half.x + 10.0 and absf(rel.y) <= half.y + 10.0):
		if _pointer != null:
			_pointer.hide()
		return
	if _pointer == null:
		_pointer = Sprite2D.new()
		_pointer.texture = UiKit.kid("arrow")
		_pointer.scale = Vector2(0.75, 0.75)
		add_child(_pointer)
	var k := minf(half.x / maxf(absf(rel.x), 0.001), half.y / maxf(absf(rel.y), 0.001))
	_pointer.global_position = (c + rel * minf(k, 1.0)).round()
	_pointer.rotation = rel.angle()
	_pointer.show()


## Verbo do minijogo do mundo (WarioWare): mostrado pelo HUD quando a missao comeca.
func minigame_verb() -> String:
	return str(Minigames.spec(planet_id).get("verb", ""))


# ---------------------------------------------------------------- presentes no alto do morro (v10, 2026-10-06)
## Sorteia (sorteador proprio) e poe o presente do salto no alto do morro; salto de resgate nao tem (o passageiro
## ocupa o meio do caminho).
func _setup_gift() -> void:
	_clear_gift()
	var rescue := _rescue_star() > 0
	var kind := "" if rescue else EconMath.draw_gift(planet_id, Gifts.rng_for(_seed, target_pad_id))
	if kind != "":
		_spawn_gift(kind)


## Poe o presente kind ("gas" | "gift") no alto do morro do salto atual (tambem usado pelos testes).
func _spawn_gift(kind: String) -> void:
	_clear_gift()
	gift_kind = kind
	_gift_pos = Gifts.place(terrain.pads[current_pad_id], terrain.pads[target_pad_id], terrain.ridge)
	_gift_sprite = Sprite2D.new()
	_gift_sprite.texture = CargoArt.tex("gas_can" if gift_kind == "gas" else "gift")
	_gift_sprite.position = _gift_pos + Vector2(0, -8)
	add_child(_gift_sprite)
	move_child(_gift_sprite, lander.get_index())
	_gift_bob = _gift_sprite.create_tween().set_loops()         # pulinho chamando o olho
	_gift_bob.tween_property(_gift_sprite, "position:y", _gift_pos.y - 11.0, 0.35).set_trans(Tween.TRANS_SINE)
	_gift_bob.tween_property(_gift_sprite, "position:y", _gift_pos.y - 8.0, 0.35).set_trans(Tween.TRANS_SINE)
	_gift_bob.tween_interval(0.6)


func _clear_gift() -> void:
	if _gift_sprite != null and is_instance_valid(_gift_sprite):
		_gift_sprite.queue_free()
	_gift_sprite = null
	gift_kind = ""
	gift_taken = false


## Encostou devagar no presente: galao enche o tanque na hora; presente vira creditos pagos com a entrega.
func _tick_gift() -> void:
	if gift_kind == "" or gift_taken or lander.state != Lander.State.FLYING:
		return
	if not Gifts.touches(lander.global_position, lander.vel_m, _gift_pos):
		return
	gift_taken = true
	if gift_kind == "gas":
		var add := EconMath.gift_gas(stats, "gas") / fatigue
		lander.gas = minf(float(lander.params["tank"]), lander.gas + add)
		_float_text("+" + EconMath.fmt(add) + " gás", _gift_pos + Vector2(0, -24))
	else:
		_float_text("+" + EconMath.fmt(EconMath.gift_value(planet_id, target_distance_m, stats, "gift")),
				_gift_pos + Vector2(0, -24))
	Sound.sfx("gas_glug" if gift_kind == "gas" else "gift_coin")
	_gift_bob.kill()
	var tw := _gift_sprite.create_tween()
	tw.tween_property(_gift_sprite, "global_position", lander.global_position, 0.2)
	tw.tween_callback(_gift_sprite.hide)


# ---------------------------------------------------------------- missoes (v12, 2026-10-06)

## Estrela do resgate (Passageiro 1, sozinho ou na Dupla); 0 se o salto nao tem resgate.
func _rescue_star() -> int:
	if planet_id == "nuvens":                                  # v17: nas Nuvens o Passageiro e a fila de carneirinhos
		return 0
	var st := EconMath.mission_has(mission, "passenger")
	return st if st > 0 and EconMath.mission_leg2(mission) <= 0.0 else 0


## Prepara as regras do salto: carga no cabo ao lado da nave, passageiro no meio do caminho (resgate) ou esperando na
## plataforma de busca (taxi), relogio da Rapida, motor mais fraco da Pesada.
func _setup_mission() -> void:
	_clear_mission()
	rescued = false
	urgent_left = 0.0
	urgent_limit = 0.0
	var mcfg: Dictionary = WorldConfig.load_config()["missions"]
	var a: Dictionary = terrain.pads[current_pad_id]
	var b: Dictionary = terrain.pads[target_pad_id]
	lander.load_div = EconMath.mission_thrust_div(mission)
	var tow := EconMath.mission_has(mission, "tow")
	if tow > 0:
		_tow = CargoTow.create(_rope_anchor(), terrain.ridge, target_dir, tow)
		_rope = Line2D.new()
		_rope.width = 1.0
		_rope.default_color = Color("#9e4539")                  # corda (Resurrect 64)
		add_child(_rope)
		move_child(_rope, lander.get_index())                  # atras da nave
		_tow_sprite = Sprite2D.new()
		_tow_sprite.texture = CargoArt.tex("wheel")
		if planet_id == "bolhas":                              # v17: a corda comeca com a garra vazia (leve)
			_tow.mass = float(Minigames.spec("bolhas").get("hook_mass", 0.15))
			_tow.radius_px = 3.0
			_tow.rope_px = WorldConfig.m_to_px(float(Minigames.spec("bolhas").get("rope_m", _tow.rope_px)))
			_tow_sprite.texture = MinigameArt.tex("hook")
		add_child(_tow_sprite)
		_sync_tow_view()
	if _rescue_star() > 0:
		var x := lerpf(float(a["x"]), float(b["x"]), float(mcfg["passenger"]["at"]))
		_rescue_pos = Vector2(roundf(x), roundf(TerrainGen.height_at(terrain.ridge, x)))
		_rescue_sprite = Sprite2D.new()
		_rescue_sprite.texture = CargoArt.tex("mouse_wait0")
		_rescue_sprite.position = _rescue_pos + Vector2(0, -8)
		add_child(_rescue_sprite)
	elif taxi_stage == 1:                                        # passageiro acenando na plataforma de busca
		_rescue_pos = Vector2(float(b["x"]) + float(b["half_width"]) * 0.6, float(b["y"]))
		_rescue_sprite = Sprite2D.new()
		_rescue_sprite.texture = CargoArt.tex("mouse_wait0")
		_rescue_sprite.position = _rescue_pos + Vector2(0, -8)
		add_child(_rescue_sprite)
	var fast := EconMath.mission_has(mission, "fast")
	if fast > 0 and taxi_stage != 1:
		var f: Dictionary = mcfg["fast"]
		var factor: Array = f["factor"]
		urgent_limit = (float(f["base_s"]) + float(f["per_sqrt_m"]) * sqrt(target_distance_m)) \
				* float(factor[clampi(fast, 1, factor.size()) - 1])
		urgent_left = urgent_limit


func _clear_mission() -> void:
	for n: Node in [_tow_sprite, _rope, _rescue_sprite]:
		if n != null and is_instance_valid(n):
			n.queue_free()
	_tow = null
	_tow_sprite = null
	_rope = null
	_rescue_sprite = null
	lander.load_div = 1.0


## Ponto do cabo na nave: entre os pes (gira com a nave).
func _rope_anchor() -> Vector2:
	var feet := WorldConfig.m_to_px(float(WorldConfig.load_config()["lander"]["feet_offset_m"]))
	return lander.global_position + Vector2(0, feet).rotated(lander.rotation)


## Um passo das regras: pendulo da carga no cabo (puxa a nave), resgate do passageiro, relogio da Rapida (so voando).
func _tick_mission(delta: float) -> void:
	if target_pad_id < 0:
		return
	var cfg: Dictionary = WorldConfig.load_config()
	_anim_t += delta
	if _tow != null:
		var flying := lander.state == Lander.State.FLYING
		var dv := _tow.step(_rope_anchor(), lander.vel_m if flying else Vector2.ZERO, delta * float(cfg["time_scale"]),
				float(lander.params.get("gravity", 1.62)), terrain.ridge, flying)
		if flying:
			lander.vel_m += dv
		if planet_id == "bolhas" and not chest_got:
			_tow.damaged = false                               # garra vazia batendo no fundo nao estraga nada
		if _tow.damaged and not failed.has("tow"):
			_mission_failed("tow", "wheel_cracked", _tow.pos)
		_sync_tow_view()
	if _rescue_sprite != null and not rescued:
		_rescue_sprite.texture = CargoArt.tex("mouse_wait%d" % (int(_anim_t * 3.0) % 2))   # acena
		var rc: Dictionary = cfg["missions"]["passenger"]
		var center := _rescue_pos + Vector2(0, -8)
		if _rescue_star() > 0 and lander.state == Lander.State.FLYING \
				and lander.global_position.distance_to(center) <= WorldConfig.m_to_px(float(rc["radius_m"])) \
				and lander.vel_m.length() <= float(rc["max_speed"]):
			_rescue()
	if urgent_limit > 0.0 and lander.state == Lander.State.FLYING and urgent_left > 0.0:
		urgent_left = maxf(urgent_left - delta, 0.0)
		if urgent_left <= 0.0 and not failed.has("fast"):
			_mission_failed("fast", "icecream_melted", lander.global_position + Vector2(0, -16))


func _sync_tow_view() -> void:
	if _tow == null:
		return
	_tow_sprite.position = _tow.pos.round()
	_tow_sprite.rotation = snappedf(_tow.spin, PI / 2.0)      # gira em passos de 90 graus (pixel limpo)
	_rope.points = PackedVector2Array([_rope_anchor(), _tow.pos])


## Passageiro pulou na nave: vai ate ela, nota alegre e um coracaozinho subindo.
func _rescue() -> void:
	rescued = true
	_rescue_sprite.texture = CargoArt.tex("mouse_safe")
	var tw := _rescue_sprite.create_tween()
	tw.tween_property(_rescue_sprite, "global_position", lander.global_position, 0.25)
	tw.tween_callback(_rescue_sprite.hide)
	Sound.sfx("squeak")
	_float_text("+♥", _rescue_pos + Vector2(0, -20))


## Uma regra falhou (o run continua; a entrega paga menos): figura estragada subindo e sumindo.
func _mission_failed(kind: String, pic: String, pos: Vector2) -> void:
	if not failed.has(kind):
		failed.append(kind)
	if _tow_sprite != null and pic == "wheel_cracked":
		_tow_sprite.texture = CargoArt.tex(pic)
	if pic != "":
		var s := Sprite2D.new()
		s.texture = CargoArt.tex(pic)
		s.position = pos + Vector2(0, -14)
		add_child(s)
		var tw := s.create_tween()
		tw.tween_property(s, "position:y", s.position.y - 16.0, 0.8)
		tw.parallel().tween_property(s, "modulate:a", 0.0, 0.8).set_delay(0.4)
		tw.tween_callback(s.queue_free)
	Sound.sfx("oops")
	shake(0.15)


## Pousou no alvo: confere as regras do pouso (Suave: vy abaixo do limite da estrela; resgate: passageiro a bordo;
## taxi na busca: pouso ruim enjoa o passageiro). Rapida e Cabo ja foram julgadas durante o voo.
func _judge_mission(info: Dictionary, quality: float) -> void:
	var mcfg: Dictionary = WorldConfig.load_config()["missions"]
	var soft := EconMath.mission_has(mission, "soft")
	if soft > 0 and taxi_stage != 1 and float(info.get("vy", 0.0)) > soft_vy_limit(soft):
		_mission_failed("soft", "cake_squashed", lander.global_position)
	if _rescue_star() > 0 and not rescued and not failed.has("passenger"):
		failed.append("passenger")
	if planet_id == "nuvens" and minigame_total > 0 and minigame_got < minigame_total and not failed.has("passenger"):
		failed.append("passenger")                             # chegou sem todos os carneirinhos: paga menos
	if planet_id == "bolhas" and minigame_total > 0 and not chest_got and not failed.has("tow"):
		failed.append("tow")                                   # chegou sem o bau: paga menos
	if planet_id == "jardim" and minigame_total > 0 and minigame_got < minigame_total and not failed.has("heavy"):
		failed.append("heavy")                                 # bateu ou pulou caule: o mel paga menos
	if taxi_stage == 1:
		if quality < float(mcfg["passenger"]["board_q"]):
			_mission_failed("passenger", "", lander.global_position)
		elif _rescue_sprite != null:
			_rescue()


## Limite de velocidade vertical (m/s do modelo) do Pouso suave na estrela star.
static func soft_vy_limit(star: int) -> float:
	var cfg: Dictionary = WorldConfig.load_config()
	var fr: Array = cfg["missions"]["soft"]["vy_frac"]
	return float(cfg["landing"]["max_vy"]) * float(fr[clampi(star, 1, fr.size()) - 1])
