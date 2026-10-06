## Cena de voo: terreno + lander + camera. Encadeia entregas: set_target() cria a proxima plataforma a partir
## da atual e estende o terreno. Devolve cada entrega por sinal; nao acessa GameState (godot-dev).
class_name Flight
extends Node2D

## Uma entrega terminou: pousou na plataforma alvo ou bateu. result = dados da entrega (ver _finish).
signal delivery_finished(result: Dictionary)
## Pousou fora do alvo sem gas para decolar de novo.
signal stranded

var planet_id := "luna"
var stats: Dictionary = {}
var target_distance_m := 0.0
var current_pad_id := 0
var target_pad_id := -1

const EXPLOSION_FRAMES := preload("res://assets/sprites/explosion_frames.tres")
const DUST_FRAMES := preload("res://assets/sprites/landing_dust_frames.tres")
## Som quando um perigo liga perto da nave (o ventilador fica sempre ligado: sem som de "ligou").
const HAZARD_SFX := {"gust": "gust", "geyser": "geyser", "toy": "toy_fall"}

var _zones: Array[Dictionary] = []                 # perigos do salto atual (Hazards)
var _hz_t := 0.0                                   # relogio dos perigos (segundos reais)
var _hz_last: Array[String] = []                   # fase anterior de cada zona (para o som ao ligar)
var _hazard_view: HazardView
var _assist_view: AssistView

var _seed := 0
var _pad_positions_m: Array[float] = [0.0]
var _pad_tiers: Array[String] = []                 # tipo de cada plataforma de entrega (sem a partida)
var _extend := Vector2.ZERO                        # terreno extra alem da margem (px; x esquerda, y direita)
const EXTEND_NEAR := 800.0                         # nave a menos disso (px) da borda -> estende
const EXTEND_STEP := 2400.0
var target_tier := "normal"
var target_dir := 1                                # lado do alvo: 1 direita, -1 esquerda
## Carga da entrega atual (economy.json contracts.cargo; regras em world.json cargo) e se a regra segue cumprida.
var cargo := "box"
var cargo_ok := true
var urgent_left := 0.0                             # sorvete: segundos reais que faltam (conta so voando)
var urgent_limit := 0.0
var rescued := false                               # ratinho resgatado neste salto
## Presente do salto (v10): "" sem presente, "gas" (galao) ou "gift" (creditos com a entrega). Gifts.place/touches.
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

@onready var lander: Lander = %Lander
@onready var terrain: Terrain = %Terrain
@onready var camera: Camera2D = %Camera
@onready var backdrop: Backdrop = %Backdrop


func _ready() -> void:
	_hazard_view = HazardView.new()
	add_child(_hazard_view)
	move_child(_hazard_view, lander.get_index())              # atras do lander
	_assist_view = AssistView.new()
	_assist_view.flight = self
	add_child(_assist_view)
	move_child(_assist_view, lander.get_index())              # ajudas de voo (Painel de bordo), atras do lander
	lander.landed.connect(_on_lander_landed)
	lander.crashed.connect(_on_lander_crashed)


func _physics_process(delta: float) -> void:
	camera.global_position = lander.global_position
	_tick_hazards(delta)
	_tick_cargo(delta)
	_tick_gift()
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
	backdrop.follow(camera.get_screen_center_position())


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
	_seed = seed_value
	_demo = demo
	_pad_positions_m = [0.0]
	_pad_tiers = []
	_extend = Vector2.ZERO
	current_pad_id = 0
	target_pad_id = -1
	_rebuild_terrain()
	lander.setup(stats, _planet_spec(planet_id), terrain.pads)
	lander.ridge = terrain.ridge
	lander.visible = true
	lander.can_takeoff = false
	var start_pad: Dictionary = terrain.pads[0]
	var feet := WorldConfig.m_to_px(float(WorldConfig.load_config()["lander"]["feet_offset_m"]))
	lander.global_position = Vector2(float(start_pad["x"]), float(start_pad["y"]) - feet - 0.5)
	lander.reset_physics_interpolation()
	camera.global_position = lander.global_position
	var cam: Dictionary = WorldConfig.load_config()["camera"]
	_lift_y = -float(cam["ground_lift_px"])
	_shake = 0.0
	camera.offset = Vector2(0.0, _lift_y)
	camera.reset_smoothing()
	camera.force_update_scroll()                              # ja no 1o quadro com o enquadramento certo
	backdrop.setup(planet_id, camera.global_position.y + camera.offset.y)


## Define a proxima entrega: plataforma do tipo tier (normal/narrow/tight) a distance_m da atual, para o lado dir
## (1 direita, -1 esquerda), levando a carga p_cargo. Pagamento usa distance_m; se a plataforma cairia em cima de
## outra, ela anda um pouco no mesmo sentido (target_position_m).
func set_target(distance_m: float, tier: String = "normal", dir: int = 1, p_cargo: String = "box") -> void:
	target_distance_m = distance_m
	target_tier = tier
	target_dir = 1 if dir >= 0 else -1
	cargo = p_cargo
	_pad_positions_m.append(target_position_m(distance_m, target_dir, tier))
	_pad_tiers.append(tier)
	target_pad_id = _pad_positions_m.size() - 1
	_rebuild_terrain()
	lander.pads = terrain.pads
	lander.ridge = terrain.ridge
	lander.can_takeoff = true
	_zones = Hazards.generate(_seed + target_pad_id, planet_id, terrain.pads[current_pad_id],
			terrain.pads[target_pad_id], terrain.ridge)
	_hz_last.assign(_zones.map(func(_z: Dictionary) -> String: return "off"))
	_hazard_view.zones = _zones
	_setup_cargo()
	_setup_gift()
	if _demo:
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


## Ponto do chao (coordenadas da tela) onde nasceria a plataforma de um pedido a distance_m da atual (lado dir).
## Alem do terreno ja gerado, usa a altura da plataforma atual. Usado pelo painel de pedidos (pinos no mundo).
func offer_ground_screen(distance_m: float, dir: int = 1) -> Vector2:
	var pad: Dictionary = terrain.pads[current_pad_id]
	var x := WorldConfig.m_to_px(target_position_m(distance_m, dir))
	var y := float(pad["y"])
	var r := terrain.ridge
	if r.size() > 1 and x >= r[0].x and x <= r[r.size() - 1].x:
		y = TerrainGen.height_at(r, x)
	return get_viewport().get_canvas_transform() * Vector2(x, y)


## Plataforma alvo atual (ou a atual, se nao ha alvo).
func target_pad() -> Dictionary:
	return terrain.pads[target_pad_id if target_pad_id >= 0 else current_pad_id]


func _rebuild_terrain() -> void:
	var distances: Array[float] = []
	for i in range(1, _pad_positions_m.size()):
		distances.append(_pad_positions_m[i])
	terrain.target_pad_id = target_pad_id
	terrain.build(_seed, planet_id, distances, _pad_tiers, _extend)


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


## Perigos do mundo: relogio, efeito no lander (vento/calda/ventilador; brinquedo destroi), som ao ligar perto.
func _tick_hazards(delta: float) -> void:
	_hz_t += delta
	_hazard_view.t = _hz_t
	var half := get_viewport_rect().size * 0.5
	_hazard_view.view = Rect2(camera.get_screen_center_position() - half, half * 2.0)
	lander.env_accel = Vector2.ZERO
	lander.env_drag = 0.0
	if _zones.is_empty():
		return
	for i in _zones.size():
		var c := Hazards.cycle(_zones[i], _hz_t)
		var snd: String = HAZARD_SFX.get(str(_zones[i]["type"]), "")
		if snd != "" and c == "on" and _hz_last[i] != "on" and _near(_zones[i]):
			Sound.sfx(snd)
		_hz_last[i] = c
	if lander.state != Lander.State.FLYING:
		return
	var e := Hazards.effect_at(_zones, lander.global_position, _hz_t)
	lander.env_accel = e["accel"]
	lander.env_drag = e["drag"]
	if e["lethal"] != "":
		lander.crash_now(e["lethal"])


## Zona perto o bastante da nave para ser ouvida (~1 tela).
func _near(z: Dictionary) -> bool:
	var p: Vector2 = (z["rect"] as Rect2).get_center() if z.has("rect") else Vector2(float(z["x"]), float(z["ground"]))
	return absf(p.x - lander.global_position.x) < 700.0


## Texto que sobe e some no mundo (ratinho resgatado).
func _float_text(text: String, pos: Vector2) -> void:
	var l := Label.new()
	l.theme = UiKit.theme_for(planet_id)
	l.theme_type_variation = &"MoneyLabel"
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(60, 12)
	l.position = pos - Vector2(30, 6)
	add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 24.0, 0.9)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.9).set_delay(0.4)
	tw.tween_callback(l.queue_free)


func _on_lander_landed(pad: Dictionary, quality: float, info: Dictionary) -> void:
	# poeira (pixel-art: explosion.py): linha 15 do sprite = chao, x 24 = centro do lander
	_spawn_fx(DUST_FRAMES, &"puff", Vector2(lander.global_position.x - 24.0, float(pad["y"]) - 15.0), false)
	Sound.sfx("landing")
	var max_vy := float(WorldConfig.load_config()["landing"]["max_vy"])
	shake(float(WorldConfig.load_config()["camera"]["land_shake"]) * clampf(float(info.get("vy", 0.0)) / max_vy, 0.0, 1.0))
	current_pad_id = int(pad["id"])
	if current_pad_id == target_pad_id:
		_judge_cargo(info)
		Sound.sfx("delivered")
		lander.can_takeoff = false
		target_pad_id = -1
		terrain.target_pad_id = -1
		_finish(false, quality, "", info)
	elif lander.gas <= 0.001:
		stranded.emit()


func _on_lander_crashed(reason: String, info: Dictionary) -> void:
	# a nave some e explode; o resultado so sai depois da explosao (senao o resumo a cobre)
	lander.visible = false
	Sound.sfx("crash")
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
		"efficiency": stats["efficiency"],
		"tank": stats["tank"],
		"gas_used": info["gas_used"],
		"hop_time_s": info["flight_time_m"],
		"quality": quality,
		"tier": target_tier,
		"dir": target_dir,
		"cargo": cargo,
		"cargo_ok": cargo_ok and not crashed,
		"gift": gift_kind if gift_taken else "",
		"gift_pay": EconMath.gift_value(planet_id, target_distance_m, stats, gift_kind)
				if gift_taken and not crashed else 0.0,
		"crashed": crashed,
		"reason": reason,
		# velocidade e inclinacao no toque (m/s e rad do modelo): calibram as tolerancias de pouso (world.json > landing)
		"vy": snappedf(float(info.get("vy", 0.0)), 0.01),
		"vx": snappedf(float(info.get("vx", 0.0)), 0.01),
		"tilt": snappedf(float(info.get("tilt", 0.0)), 0.001),
	}
	Telemetry.record_delivery(result)
	_clear_cargo()
	_clear_gift()
	delivery_finished.emit(result)


# ---------------------------------------------------------------- presentes no alto do morro (v10, 2026-10-06)
## Sorteia (sorteador proprio) e poe o presente do salto no alto do morro; salto de resgate nao tem (o ratinho ocupa).
func _setup_gift() -> void:
	_clear_gift()
	var kind := "" if cargo == "rescue" else EconMath.draw_gift(planet_id, Gifts.rng_for(_seed, target_pad_id))
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
		var add := EconMath.gift_gas(stats, "gas")
		lander.gas = minf(float(lander.params["tank"]), lander.gas + add)
		_float_text("+" + EconMath.fmt(add) + " gás", _gift_pos + Vector2(0, -24))
	else:
		_float_text("+" + EconMath.fmt(EconMath.gift_value(planet_id, target_distance_m, stats, "gift")),
				_gift_pos + Vector2(0, -24))
	Sound.sfx("crystal_3")
	_gift_bob.kill()
	var tw := _gift_sprite.create_tween()
	tw.tween_property(_gift_sprite, "global_position", lander.global_position, 0.2)
	tw.tween_callback(_gift_sprite.hide)


# ---------------------------------------------------------------- cargas (Lua, 2026-10-05)

## Prepara a carga do salto: queijao no cabo ao lado da nave, ratinho no meio do caminho, prazo do sorvete.
func _setup_cargo() -> void:
	_clear_cargo()
	cargo_ok = true
	rescued = false
	var ccfg: Dictionary = WorldConfig.load_config()["cargo"]
	var a: Dictionary = terrain.pads[current_pad_id]
	var b: Dictionary = terrain.pads[target_pad_id]
	match cargo:
		"towed":
			_tow = CargoTow.create(_rope_anchor(), terrain.ridge, target_dir)
			_rope = Line2D.new()
			_rope.width = 1.0
			_rope.default_color = Color("#9e4539")              # corda (Resurrect 64)
			add_child(_rope)
			move_child(_rope, lander.get_index())              # atras da nave
			_tow_sprite = Sprite2D.new()
			_tow_sprite.texture = CargoArt.tex("wheel")
			add_child(_tow_sprite)
			_sync_tow_view()
		"rescue":
			var x := lerpf(float(a["x"]), float(b["x"]), float(ccfg["rescue"]["at"]))
			_rescue_pos = Vector2(roundf(x), roundf(TerrainGen.height_at(terrain.ridge, x)))
			_rescue_sprite = Sprite2D.new()
			_rescue_sprite.texture = CargoArt.tex("mouse_wait0")
			_rescue_sprite.position = _rescue_pos + Vector2(0, -8)
			add_child(_rescue_sprite)
		"urgent":
			var u: Dictionary = ccfg["urgent"]
			urgent_limit = float(u["base_s"]) + float(u["per_sqrt_m"]) * sqrt(target_distance_m)
			urgent_left = urgent_limit


func _clear_cargo() -> void:
	for n: Node in [_tow_sprite, _rope, _rescue_sprite]:
		if n != null and is_instance_valid(n):
			n.queue_free()
	_tow = null
	_tow_sprite = null
	_rope = null
	_rescue_sprite = null


## Ponto do cabo na nave: entre os pes (gira com a nave).
func _rope_anchor() -> Vector2:
	var feet := WorldConfig.m_to_px(float(WorldConfig.load_config()["lander"]["feet_offset_m"]))
	return lander.global_position + Vector2(0, feet).rotated(lander.rotation)


## Um passo das cargas: pendulo do queijao (puxa a nave), resgate do ratinho, relogio do sorvete (so voando).
func _tick_cargo(delta: float) -> void:
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
		if _tow.damaged and cargo_ok:
			_cargo_failed("wheel_cracked", _tow.pos)
		_sync_tow_view()
	if _rescue_sprite != null and not rescued:
		_rescue_sprite.texture = CargoArt.tex("mouse_wait%d" % (int(_anim_t * 3.0) % 2))   # acena
		var rc: Dictionary = cfg["cargo"]["rescue"]
		var center := _rescue_pos + Vector2(0, -8)
		if lander.state == Lander.State.FLYING \
				and lander.global_position.distance_to(center) <= WorldConfig.m_to_px(float(rc["radius_m"])) \
				and lander.vel_m.length() <= float(rc["max_speed"]):
			_rescue()
	if cargo == "urgent" and lander.state == Lander.State.FLYING and urgent_left > 0.0:
		urgent_left = maxf(urgent_left - delta, 0.0)
		if urgent_left <= 0.0 and cargo_ok:
			_cargo_failed("icecream_melted", lander.global_position + Vector2(0, -16))


func _sync_tow_view() -> void:
	if _tow == null:
		return
	_tow_sprite.position = _tow.pos.round()
	_tow_sprite.rotation = snappedf(_tow.spin, PI / 2.0)      # gira em passos de 90 graus (pixel limpo)
	_rope.points = PackedVector2Array([_rope_anchor(), _tow.pos])


## Ratinho pulou na nave: vai ate ela, nota alegre e um coracaozinho subindo.
func _rescue() -> void:
	rescued = true
	_rescue_sprite.texture = CargoArt.tex("mouse_safe")
	var tw := _rescue_sprite.create_tween()
	tw.tween_property(_rescue_sprite, "global_position", lander.global_position, 0.25)
	tw.tween_callback(_rescue_sprite.hide)
	Sound.sfx("crystal_3")
	_float_text("+♥", _rescue_pos + Vector2(0, -20))


## A regra da carga falhou (o run continua; a entrega paga menos): figura estragada subindo e sumindo.
func _cargo_failed(pic: String, pos: Vector2) -> void:
	cargo_ok = false
	if _tow_sprite != null and pic == "wheel_cracked":
		_tow_sprite.texture = CargoArt.tex(pic)
	var s := Sprite2D.new()
	s.texture = CargoArt.tex(pic)
	s.position = pos + Vector2(0, -14)
	add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "position:y", s.position.y - 16.0, 0.8)
	tw.parallel().tween_property(s, "modulate:a", 0.0, 0.8).set_delay(0.4)
	tw.tween_callback(s.queue_free)
	Sound.sfx("denied")
	shake(0.15)


## Pousou no alvo: confere a regra da carga (bolo: pouso suave; ratinho: resgatado). Sorvete e queijao ja foram
## julgados durante o voo.
func _judge_cargo(info: Dictionary) -> void:
	match cargo:
		"fragile":
			if float(info.get("vy", 0.0)) > float(WorldConfig.load_config()["cargo"]["fragile"]["max_vy"]):
				_cargo_failed("cake_squashed", lander.global_position)
		"rescue":
			if not rescued:
				cargo_ok = false
