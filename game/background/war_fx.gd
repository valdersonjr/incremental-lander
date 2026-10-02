## Guerra no fundo (narrativa da Lua): discos voadores cruzando o ceu, lasers verdes nas bases humanas,
## tracantes ambar das torres, discos abatidos caindo e clarões de explosao.
## Coordenadas = camada "mid" do Backdrop (laco de 640 px); o Backdrop posiciona o no e passa a rolagem.
## Contrato: assets/bg/<planeta>_layers.json > "war" (gerado por art/src/bg/moon_war.py).
class_name WarFx
extends Node2D

const PERIOD := 640.0
const LASER_TIME := 0.35
const TRACER_SPEED := 150.0
const TRACER_LIFE := 1.1
const HIT_RADIUS := 7.0
const SHOOT_DOWN_CHANCE := 0.3
const FALL_GRAVITY := 40.0
const RESPAWN_TIME := 4.0

## Rolagem horizontal da camada mid (px), atualizada pelo Backdrop.
var scroll_x := 0.0

var _rng := RandomNumberGenerator.new()
var _time := 0.0
var _band := Vector2(70, 175)
var _speed := Vector2(10, 26)
var _laser_colors: Array[Color] = []
var _tracer_colors: Array[Color] = []
var _smoke_colors: Array[Color] = []
var _tex: Dictionary = {}       # nome -> Texture2D
var _frames: Dictionary = {}    # nome -> [w, h, quadros, ms]
var _targets: Array[Vector2] = []
var _saucers: Array[Dictionary] = []
var _turrets: Array[Dictionary] = []
var _lasers: Array[Dictionary] = []
var _tracers: Array[Dictionary] = []
var _blasts: Array[Dictionary] = []
var _smoke: Array[Dictionary] = []


## Monta a batalha a partir do contrato do planeta. seed_value deixa a cena reproduzivel (demo/testes).
func setup(cfg: Dictionary, seed_value: int) -> void:
	_rng.seed = seed_value
	_band = _vec(cfg["sky_band"])
	_speed = _vec(cfg["speed"])
	_laser_colors.assign((cfg["laser"] as Array).map(func(c: Variant) -> Color: return Color(str(c))))
	_tracer_colors.assign((cfg["tracer"] as Array).map(func(c: Variant) -> Color: return Color(str(c))))
	_smoke_colors.assign((cfg["smoke"] as Array).map(func(c: Variant) -> Color: return Color(str(c))))
	var sprites: Dictionary = cfg["sprites"]
	for key: String in sprites:
		_tex[key] = load(str(sprites[key])) as Texture2D
	_frames = cfg["frames"]
	_targets.clear()
	for t: Variant in cfg["targets"]:
		_targets.append(_vec(t))
	_turrets.clear()
	for m: Variant in cfg["muzzles"]:
		_turrets.append({"pos": _vec(m), "cool": _rng.randf_range(0.3, 2.0), "left": 0, "aim": Vector2.UP})
	_saucers.clear()
	for i in int(cfg["saucers"]):
		_saucers.append(_new_saucer(_rng.randf_range(0.0, PERIOD), i == int(cfg["saucers"]) - 1))


func _process(delta: float) -> void:
	_time += delta
	_step(delta)
	queue_redraw()


func _draw() -> void:
	for s in _saucers:
		if s["state"] == "dead":
			continue
		var key := "saucer_far" if s["far"] else "saucer"
		_draw_sprite(key, s["pos"], int(s["phase"]))
	for l in _lasers:
		var from: Vector2 = l["from"]
		var to: Vector2 = from + Vector2(WarMath.wrap_dx(from.x, (l["to"] as Vector2).x, PERIOD),
			(l["to"] as Vector2).y - from.y)
		var k := 0
		for p in WarMath.line_points(Vector2i(from), Vector2i(to)):
			var c := _laser_colors[0] if k % 5 else _laser_colors[1]
			_draw_px(Vector2(p), c)
			_draw_px(Vector2(p) + Vector2.RIGHT, _laser_colors[2])
			k += 1
	for t in _tracers:
		var pos: Vector2 = t["pos"]
		var back: Vector2 = -(t["vel"] as Vector2).normalized()
		for k in 5:
			_draw_px((pos + back * k).round(), _tracer_colors[0] if k == 0 else _tracer_colors[1])
	for sm in _smoke:
		_draw_px(sm["pos"], _smoke_colors[0] if float(sm["t"]) < 0.6 else _smoke_colors[1])
	for b in _blasts:
		var f: Array = _frames["blast"]
		var idx := int(float(b["t"]) * 1000.0 / float(f[3]))
		if float(b["t"]) >= 0.0 and idx < int(f[2]):
			_draw_sprite("blast", (b["pos"] as Vector2) - Vector2(8, 8), idx)


func _step(delta: float) -> void:
	for s in _saucers:
		_step_saucer(s, delta)
	for tr in _turrets:
		_step_turret(tr, delta)
	for l in _lasers:
		l["t"] = float(l["t"]) + delta
	_lasers = _lasers.filter(func(l: Dictionary) -> bool: return float(l["t"]) < LASER_TIME)
	for t in _tracers:
		t["pos"] = (t["pos"] as Vector2) + (t["vel"] as Vector2) * delta
		t["t"] = float(t["t"]) + delta
		_check_hit(t)
	_tracers = _tracers.filter(func(t: Dictionary) -> bool: return float(t["t"]) < TRACER_LIFE)
	for b in _blasts:
		b["t"] = float(b["t"]) + delta
	_blasts = _blasts.filter(func(b: Dictionary) -> bool: return float(b["t"]) < 1.0)
	for sm in _smoke:
		sm["t"] = float(sm["t"]) + delta
		sm["pos"] = (sm["pos"] as Vector2) + Vector2(3, -6) * delta
	_smoke = _smoke.filter(func(sm: Dictionary) -> bool: return float(sm["t"]) < 1.4)
	if _rng.randf() < delta * 0.5:                                # flak estourando no ceu
		_blasts.append({"pos": Vector2(_rng.randf_range(0, PERIOD), _rng.randf_range(_band.x, _band.y)), "t": 0.0})


func _step_saucer(s: Dictionary, delta: float) -> void:
	var f: Array = _frames["saucer_far" if s["far"] else "saucer"]
	s["phase"] = int(_time * 1000.0 / float(f[3])) % int(f[2])
	match s["state"]:
		"fly":
			var pos: Vector2 = s["pos"]
			pos.x = fposmod(pos.x + float(s["dir"]) * float(s["speed"]) * delta, PERIOD)
			pos.y = float(s["base_y"]) + 4.0 * sin(_time * 2.0 + float(s["seed"]))
			s["pos"] = pos
			s["cool"] = float(s["cool"]) - delta
			if float(s["cool"]) <= 0.0 and not s["far"]:
				_fire_laser(s)
		"fall":
			s["vy"] = float(s["vy"]) + FALL_GRAVITY * delta
			s["pos"] = (s["pos"] as Vector2) + Vector2(float(s["dir"]) * 12.0, float(s["vy"])) * delta
			if _rng.randf() < 0.6:
				_smoke.append({"pos": ((s["pos"] as Vector2) + Vector2(12, 4)).round(), "t": 0.0})
			if (s["pos"] as Vector2).y > _band.y + 45.0:
				_blasts.append({"pos": (s["pos"] as Vector2) + Vector2(12, 5), "t": 0.0})
				s["state"] = "dead"
				s["cool"] = RESPAWN_TIME
		"dead":
			s["cool"] = float(s["cool"]) - delta
			if float(s["cool"]) <= 0.0:
				var fresh := _new_saucer(scroll_x - 40.0 if _rng.randf() < 0.5 else scroll_x + PERIOD + 10.0, false)
				s.merge(fresh, true)


func _step_turret(tr: Dictionary, delta: float) -> void:
	tr["cool"] = float(tr["cool"]) - delta
	if float(tr["cool"]) > 0.0:
		return
	var target := _nearest_saucer(tr["pos"])
	if target.is_empty():
		tr["cool"] = 1.0
		return
	if int(tr["left"]) <= 0:                                       # nova rajada mira no disco mais proximo
		tr["left"] = _rng.randi_range(3, 5)
		var to: Vector2 = target["pos"] + Vector2(12, 5)
		var from: Vector2 = tr["pos"]
		tr["aim"] = Vector2(WarMath.wrap_dx(from.x, to.x, PERIOD), to.y - from.y).normalized()
	var spread := _rng.randf_range(-0.08, 0.08)
	_tracers.append({"pos": tr["pos"], "vel": (tr["aim"] as Vector2).rotated(spread) * TRACER_SPEED, "t": 0.0})
	tr["left"] = int(tr["left"]) - 1
	tr["cool"] = 0.12 if int(tr["left"]) > 0 else _rng.randf_range(1.2, 2.8)


func _fire_laser(s: Dictionary) -> void:
	s["cool"] = _rng.randf_range(2.0, 5.0)
	if _targets.is_empty():
		return
	var from: Vector2 = (s["pos"] as Vector2) + Vector2(12, 10)
	var best := _targets[0]
	for t in _targets:
		if absf(WarMath.wrap_dx(from.x, t.x, PERIOD)) < absf(WarMath.wrap_dx(from.x, best.x, PERIOD)):
			best = t
	if absf(WarMath.wrap_dx(from.x, best.x, PERIOD)) > 220.0:
		return                                                      # longe demais: so atira quando passa perto
	_lasers.append({"from": from, "to": best, "t": 0.0})
	_blasts.append({"pos": best, "t": -LASER_TIME * 0.6})


func _check_hit(t: Dictionary) -> void:
	for s in _saucers:
		if s["state"] != "fly" or s["far"]:
			continue
		var c: Vector2 = (s["pos"] as Vector2) + Vector2(12, 5)
		var p: Vector2 = t["pos"]
		if Vector2(WarMath.wrap_dx(c.x, p.x, PERIOD), p.y - c.y).length() < HIT_RADIUS:
			t["t"] = TRACER_LIFE
			_blasts.append({"pos": p.round(), "t": 0.2})
			if _rng.randf() < SHOOT_DOWN_CHANCE:
				s["state"] = "fall"
				s["vy"] = 0.0
			return


func _nearest_saucer(from: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_d := INF
	for s in _saucers:
		if s["state"] != "fly" or s["far"]:
			continue
		var d := absf(WarMath.wrap_dx(from.x, (s["pos"] as Vector2).x, PERIOD))
		if d < best_d and d < 260.0:
			best_d = d
			best = s
	return best


func _new_saucer(x: float, far: bool) -> Dictionary:
	var y := _rng.randf_range(_band.x, _band.x + 25.0) if far else _rng.randf_range(_band.x + 20.0, _band.y)
	return {"pos": Vector2(fposmod(x, PERIOD), y), "base_y": y, "dir": 1.0 if _rng.randf() < 0.5 else -1.0,
		"speed": _rng.randf_range(_speed.x, _speed.y) * (0.6 if far else 1.0), "far": far,
		"cool": _rng.randf_range(0.5, 3.0), "state": "fly", "vy": 0.0, "phase": 0, "seed": _rng.randf() * 6.0}


## Desenha nas duas copias do laco (a tela tem a largura do laco).
func _draw_sprite(key: String, pos: Vector2, frame: int) -> void:
	var f: Array = _frames[key]
	var size := Vector2(float(f[0]), float(f[1]))
	var src := Rect2(Vector2(size.x * frame, 0), size)
	var sx := WarMath.screen_x(pos.x, scroll_x, PERIOD)
	for x: float in [sx, sx - PERIOD]:
		draw_texture_rect_region(_tex[key], Rect2(Vector2(x, pos.y).round(), size), src)


func _draw_px(p: Vector2, c: Color) -> void:
	var sx := WarMath.screen_x(p.x, scroll_x, PERIOD)
	for x: float in [sx, sx - PERIOD]:
		draw_rect(Rect2(Vector2(x, p.y).round(), Vector2.ONE), c)


func _vec(a: Variant) -> Vector2:
	var arr: Array = a
	return Vector2(float(arr[0]), float(arr[1]))
