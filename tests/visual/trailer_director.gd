## Diretor de captura de takes de trailer: roda o jogo real (main.tscn) e "joga" sozinho um roteiro curto, para
## gravar com o Movie Maker (tests/tools/trailer_capture.py). Fica em tests/visual/: nunca le nem grava o save real.
## Nao muda nenhuma regra do jogo: escolhe as entregas, pilota pelo arco dos cristais e enquadra a camera.
## Args (alem dos do main: --planet= --seed= --dev_levels= ...):
##   --hops=1000:narrow,1300:tight   entregas em sequencia (distancia m : tipo normal|narrow|tight)
##   --pilot=arc|auto|crash           arc = segue o arco dos cristais e pousa; auto = piloto do --demo;
##                                    crash = arco sem frear no fim (bate); --crash_hop=N bate so na N-esima (1..)
##   --offer_wait=s                   segundos com o painel de ofertas na tela antes de escolher (padrao 0)
##   --pad_wait=s                     segundos parado na plataforma antes de decolar (padrao 0.3)
##   --no_hud                         esconde HUD/ofertas (plano limpo)     --zoom=2  camera mais perto
##   --arc_k=0.7                      arco mais baixo/alto que o dos cristais (so o piloto; os cristais ficam onde estao)
##   --sync_hazards=lead_s            ao decolar, acerta a fase dos perigos para a nave passar por eles ligados
##                                    (brinquedo cruza a altura da nave lead_s depois dela: >0 por pouco, 0 acerta)
##   --no_summary                     esconde o resumo do fim do run (take de batida)
##   --title                          menu inicial sobre o mundo de --world=id
##   --hangar=id1,id2,...             hangar comprando esses upgrades em sequencia (--tab=worlds no fim)
extends Node

const MAIN := preload("res://game/main.tscn")


## Piloto de trailer: segue o arco balistico dos cristais (vx constante; a gravidade faz a curva) e, depois do
## ultimo cristal, entrega a frenagem/pouso ao Autopilot do demo. crash=true: nao freia no fim.
class ArcPilot extends Autopilot:
	var from_pad: Dictionary = {}
	var crash := false
	var k := 1.0

	func control(pos_px: Vector2, vel_m: Vector2, rotation: float, params: Dictionary) -> Dictionary:
		var cfg: Dictionary = WorldConfig.load_config()
		var feet := WorldConfig.m_to_px(float(cfg["lander"]["feet_offset_m"]))
		var xa := float(from_pad["x"])
		var ya := float(from_pad["y"])
		var xb := float(target["x"])
		var yb := float(target["y"])
		var d := xb - xa
		var u := clampf((pos_px.x - xa) / d, 0.0, 1.0)
		# freia a tempo: depois do ultimo cristal ou quando a distancia de frenagem do demo pede (mundos pesados)
		var brake := vel_m.x * vel_m.x / (2.0 * 0.5 * maxf(float(params["thrust"]) - float(params["gravity"]) * 0.5, 0.5)) + 60.0
		if mode == "land" or u > 0.8 or (u > 0.5 and absf(xb - pos_px.x) / float(cfg["px_per_m"]) < brake):
			mode = "land"
			if crash:
				return {"rotate": clampf(wrapf(0.5 * signf(d) - rotation, -PI, PI) * 4.0, -1.0, 1.0), "thrust": false}
			return _land(pos_px, vel_m, rotation, params)
		var g: float = params["gravity"]
		var ppm := float(cfg["px_per_m"])
		var y_arc := lerpf(ya, yb, u) - absf(d) * u * (1.0 - u) * k - feet
		var slope := ((yb - ya) - absf(d) * k * (1.0 - 2.0 * u)) / d          # dy/dx do arco
		var vx := signf(d) * sqrt(g * absf(d) / ppm / (2.0 * k))               # vx do arco balistico (m/s)
		var err_y := (y_arc - pos_px.y) / ppm                                  # >0: o arco esta abaixo
		var v_des := Vector2(vx, vx * slope + clampf(err_y * 0.8, -15.0, 15.0))
		var t_vec := (v_des - vel_m) * 1.2                                     # no arco a gravidade ja faz a curva
		var rot_des := clampf(atan2(t_vec.x, -t_vec.y), -1.3, 1.3)
		var err := wrapf(rot_des - rotation, -PI, PI)
		var nose := Vector2.UP.rotated(rotation)
		var thrust := false
		if absf(err) < 0.5 or u < 0.02:
			_duty_acc += clampf(t_vec.dot(nose) / float(params["thrust"]), 0.0, 1.0) if t_vec.length() > 0.6 else 0.0
			if _duty_acc >= 1.0:
				_duty_acc -= 1.0
				thrust = true
		return {"rotate": clampf(err * 4.0, -1.0, 1.0), "thrust": thrust}


	## Frenagem e pouso como o Autopilot do demo, mas descendo mais decidido (take sem minutos pairando).
	func _land(pos_px: Vector2, vel_m: Vector2, rotation: float, params: Dictionary) -> Dictionary:
		var cfg: Dictionary = WorldConfig.load_config()
		var ppm := float(cfg["px_per_m"])
		var feet := float(cfg["lander"]["feet_offset_m"])
		var pos := pos_px / ppm
		var dx := float(target["x"]) / ppm - pos.x
		var pad_y := float(target["y"]) / ppm
		var height := pad_y - (pos.y + feet)
		var g: float = params["gravity"]
		var a_net := maxf(float(params["thrust"]) - g, 0.3)
		var v_des := Vector2(clampf(dx * 0.5, -14.0, 14.0), 0.0)
		var max_tilt := 0.9
		if absf(dx) < 10.0:
			v_des.x = clampf(dx * 0.4, -1.5, 1.5)
			v_des.y = clampf(minf(height * 0.5, sqrt(2.0 * a_net * 0.6 * maxf(height, 0.0))), 0.8, 22.0)
			if absf(vel_m.x) > 1.0:
				v_des.y = minf(v_des.y, 2.0)                  # primeiro para de deslizar, depois desce
			if height < 4.0:
				v_des.y = 1.0                                 # toque suave (pouso bom mantem o combo)
			elif height < 16.0:
				v_des.y = minf(v_des.y, 3.0)
			if height < 30.0:
				max_tilt = 0.15
		else:
			var top := TerrainGen.highest_between(ridge, pos_px.x, float(target["x"])) / ppm - feet
			v_des.y = clampf((minf(pad_y, top) - 30.0 - pos.y) * 0.5, -6.0, 12.0)
		var t_vec := (v_des - vel_m) * 1.2 - Vector2(0.0, g)
		var rot_des := clampf(atan2(t_vec.x, -t_vec.y), -max_tilt, max_tilt)
		var err := wrapf(rot_des - rotation, -PI, PI)
		var thrust := false
		if absf(err) < 0.6:
			_duty_acc += clampf(t_vec.dot(Vector2.UP.rotated(rotation)) / float(params["thrust"]), 0.0, 1.0)
			if _duty_acc >= 1.0:
				_duty_acc -= 1.0
				thrust = true
		return {"rotate": clampf(err * 4.0, -1.0, 1.0), "thrust": thrust}


var _args: Dictionary = {}
var _main: Node
var _hops: Array = []
var _hop_i := 0
var _choosing := false
var _was_flying := false


func _ready() -> void:
	Telemetry.enabled = false
	for a in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		_args[s.get_slice("=", 0)] = s.get_slice("=", 1) if "=" in s else ""
	for h in str(_args.get("hops", "")).split(",", false):
		_hops.append({"d": float(h.get_slice(":", 0)), "tier": h.get_slice(":", 1) if ":" in h else "normal"})
	if _args.has("world"):
		GameState.current_planet = str(_args["world"])
	_main = MAIN.instantiate()
	add_child(_main)
	if _args.has("hangar"):
		_hangar_take.call_deferred()


func _process(_delta: float) -> void:
	var flight: Flight = _main._flight
	if flight != null and is_instance_valid(flight) and _args.has("zoom"):
		var z := float(_args["zoom"])
		flight.camera.zoom = Vector2(z, z)
	if _args.has("no_hud"):
		for n: Node in [_main._hud, _main._offers]:
			if n != null and is_instance_valid(n):
				(n as CanvasItem).modulate.a = 0.0
	if _args.has("no_summary") and _main._summary != null and is_instance_valid(_main._summary):
		(_main._summary as CanvasItem).modulate.a = 0.0
	if flight != null and is_instance_valid(flight):
		var flying := flight.lander.state == Lander.State.FLYING
		if flying != _was_flying:                              # marcas de tempo para escolher o corte do take
			print("TAKE_EVENT %s t=%.2f" % ["decolou" if flying else str(Lander.State.keys()[flight.lander.state]).to_lower(),
					Engine.get_process_frames() / 60.0])
		if flying and _args.has("sync_hazards"):
			_sync_hazards(flight, not _was_flying)
		_was_flying = flying
		if _args.has("debug") and Engine.get_process_frames() % 15 == 0:
			print("DBG t=%.2f x=%.0f y=%.0f st=%d zones=%s" % [flight._hz_t, flight.lander.global_position.x,
					flight.lander.global_position.y, flight.lander.state,
					str(flight._zones.map(func(z: Dictionary) -> String: return "%s:%s x=%.0f toy=%s" % [z["type"], Hazards.cycle(z, flight._hz_t), float(z.get("x", (z.get("rect", Rect2()) as Rect2).get_center().x)), str(Hazards.toy_pos(z, flight._hz_t)) if z["type"] == "toy" else ""]))])
	var offers: OfferPanel = _main._offers
	if offers != null and is_instance_valid(offers) and offers.visible and not _choosing and _hop_i < _hops.size() \
			and not _args.has("hangar"):
		_choose_next()


## Coloca a proxima entrega do roteiro na oferta 1 e a escolhe (depois de offer_wait), com o piloto pedido.
func _choose_next() -> void:
	_choosing = true
	var hop: Dictionary = _hops[_hop_i]
	_hop_i += 1
	var run: RunState = _main._run
	run.offers[0] = hop["d"]
	run.offer_tiers[0] = hop["tier"]
	_main._offers.show_offers(run, _main._flight.lander.gas)
	await get_tree().create_timer(float(_args.get("offer_wait", "0"))).timeout
	var flight: Flight = _main._flight
	flight.lander.can_takeoff = false
	_main._on_offer_chosen(0)
	flight.lander.can_takeoff = false
	var pilot := str(_args.get("pilot", "arc"))
	var ap: Autopilot
	if pilot == "auto":
		ap = Autopilot.new()
	else:
		var arc := ArcPilot.new()
		arc.from_pad = flight.terrain.pads[flight.current_pad_id]
		arc.k = float(_args.get("arc_k", "1.0"))
		arc.crash = pilot == "crash" and (not _args.has("crash_hop") or int(_args["crash_hop"]) == _hop_i)
		ap = arc
	ap.target = flight.terrain.pads[flight.target_pad_id]
	ap.ridge = flight.terrain.ridge
	await get_tree().create_timer(float(_args.get("pad_wait", "0.3"))).timeout
	flight.lander.autopilot = ap
	flight.lander.can_takeoff = true
	_choosing = false


## Acerta a fase de cada perigo com ciclo para quando a nave chegar nele (estimativa pelo arco: vx constante).
## first=false: so o brinquedo, e so enquanto ainda nao esta caindo (a chegada fica mais precisa com a nave em cruzeiro).
func _sync_hazards(flight: Flight, first: bool) -> void:
	var cfg: Dictionary = WorldConfig.load_config()
	var a: Dictionary = flight.terrain.pads[flight.current_pad_id]
	var b: Dictionary = flight.target_pad()
	var d := float(b["x"]) - float(a["x"])
	var g := float(flight.lander.params["gravity"])
	var vx_px_s := sqrt(g * absf(d) / float(cfg["px_per_m"]) / 2.0) * float(cfg["px_per_m"]) * float(cfg["time_scale"])
	var lead := float(_args["sync_hazards"])
	for z: Dictionary in flight._zones:
		if not z.has("period_s"):
			continue
		if not first and (z["type"] != "toy" or Hazards.cycle(z, flight._hz_t) == "on"):
			continue
		var zx: float = float(z["x"]) if z.has("x") else (z["rect"] as Rect2).get_center().x
		var dx := zx - flight.lander.global_position.x
		if dx * signf(d) < 0.0:
			continue                                           # ja passou
		var v_now := absf(flight.lander.vel_m.x) * float(cfg["px_per_m"]) * float(cfg["time_scale"])
		var ta := flight._hz_t + (absf(dx) / v_now if v_now > vx_px_s * 0.8 else absf(dx) / vx_px_s + 0.5)
		var p_want: float
		if z["type"] == "toy":
			var u := (zx - float(a["x"])) / d
			var arc_y := lerpf(float(a["y"]), float(b["y"]), u) - absf(d) * u * (1.0 - u)
			p_want = float(z["warn_s"]) + (arc_y - float(z["top"])) / float(z["speed"])
			ta += lead
		else:
			p_want = 0.4                                       # acabou de ligar quando a nave chega
		z["phase"] = fposmod(p_want - ta, float(z["period_s"]))


## Hangar: abre com creditos de sobra e compra os upgrades da lista em sequencia (foco + clique, como o jogador).
func _hangar_take() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_main._on_continue()
	var hangar: Hangar = _main._hangar
	await get_tree().create_timer(0.8).timeout
	for id in str(_args["hangar"]).split(",", false):
		var b := _find_button(hangar, "buy:" + id)
		if b != null and not b.disabled:
			b.grab_focus()
			await get_tree().create_timer(0.25).timeout
			b = _find_button(hangar, "buy:" + id)
			b.pressed.emit()
		await get_tree().create_timer(0.45).timeout
	if str(_args.get("tab", "")) == "worlds":
		hangar._cycle_tab(1)


func _find_button(root: Node, key: String) -> Button:
	for c in root.find_children("*", "Button", true, false):
		if c.get_meta(&"focus_key", "") == key:
			return c
	return null
