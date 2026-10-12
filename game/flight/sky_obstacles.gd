## Cachorrinhos astronautas (eram satelites) no ceu da pista (world.json > sky_obstacles; regra em SkyField; arte
## assets/sprites/sky_obstacles.png, skill pixel-art). So existem as celulas perto da camera: follow() cria as que
## entram na tela e solta as que saem. A Flight chama follow() todo quadro e hit() para a batida.
class_name SkyObstacles
extends Node2D

const SHEET := "res://assets/sprites/sky_obstacles.png"
const META := "res://assets/sprites/sky_obstacles.json"
const MARGIN_CELLS := 2                         # celulas alem da borda da tela (aparecem antes de entrar)
const BOB_HZ := 0.35                            # flutuar devagar

var _cfg: Dictionary = {}
var _seed := 0
var _cell_px := 56.0
var _tex: Dictionary = {}                       # nome do atlas -> AtlasTexture
var _circles: Dictionary = {}                   # tipo -> [[dx, dy, r], ...]
var _cells: Dictionary = {}                     # Vector2i -> {kind, pos, phase, sprite} ou {} (celula vazia)
var _ref: Dictionary = {}                       # coluna -> y do ponto mais alto do relevo ao redor
var _t := 0.0


func setup(cfg: Dictionary, seed_value: int) -> void:
	_cfg = cfg
	_seed = seed_value
	_cell_px = WorldConfig.m_to_px(float(cfg["cell_m"]))
	var f := FileAccess.open(META, FileAccess.READ)
	if f == null:
		push_error("SkyObstacles: falta %s" % META)
		return
	var meta: Dictionary = JSON.parse_string(f.get_as_text())
	var sheet: Texture2D = load(SHEET)
	var w := float(meta["cell_w"])
	var h := float(meta["cell_h"])
	var names: Array = meta["names"]
	for i in names.size():
		var at := AtlasTexture.new()
		at.atlas = sheet
		at.region = Rect2(i * w, 0.0, w, h)
		_tex[str(names[i])] = at
	for k: Dictionary in cfg["kinds"]:
		_circles[str(k["name"])] = k["circles"]


func _process(delta: float) -> void:
	_t += delta
	var bob := float(_cfg.get("bob_px", 0.0))
	var blink := float(_cfg.get("blink_s", 0.6))
	for c: Dictionary in _cells.values():
		if c.is_empty():
			continue
		var sp: Sprite2D = c["sprite"]
		var ph := float(c["phase"])
		sp.position = (c["pos"] as Vector2) + Vector2(0.0, roundf(sin((_t * BOB_HZ + ph) * TAU) * bob))
		sp.texture = _texture(str(c["kind"]), int(floorf(_t / blink + ph * 2.0)) % 2 == 0)


## Cria as celulas visiveis (centro/tamanho da tela em px) e solta as que ficaram longe.
func follow(center: Vector2, view: Vector2, ridge: PackedVector2Array) -> void:
	if _tex.is_empty():
		return
	var lo := Vector2i(floori((center.x - view.x * 0.5) / _cell_px) - MARGIN_CELLS,
			floori((center.y - view.y * 0.5) / _cell_px) - MARGIN_CELLS)
	var hi := Vector2i(floori((center.x + view.x * 0.5) / _cell_px) + MARGIN_CELLS,
			floori((center.y + view.y * 0.5) / _cell_px) + MARGIN_CELLS)
	for i in range(lo.x, hi.x + 1):
		for j in range(lo.y, hi.y + 1):
			var key := Vector2i(i, j)
			if not _cells.has(key):
				_cells[key] = _spawn(SkyField.cell(i, j, _seed, _ref_y(i, ridge), _cfg))
	for key: Vector2i in _cells.keys():
		if key.x < lo.x - 1 or key.x > hi.x + 1 or key.y < lo.y - 1 or key.y > hi.y + 1:
			var c: Dictionary = _cells[key]
			if not c.is_empty():
				(c["sprite"] as Node).queue_free()
			_cells.erase(key)


## Primeira batida da nave (centro p, raio r px): {"normal", "at"} ou {} se nao encosta em nada.
func hit(p: Vector2, r: float) -> Dictionary:
	for c: Dictionary in _cells.values():
		if c.is_empty() or (c["pos"] as Vector2).distance_squared_to(p) > 70.0 * 70.0:
			continue
		var n := SkyField.hit_normal(p, r, c["pos"], _circles[c["kind"]])
		if n != Vector2.ZERO:
			return {"normal": n, "at": p - n * r}
	return {}


## Quantos obstaculos existem agora (testes).
func count() -> int:
	var n := 0
	for c: Dictionary in _cells.values():
		n += 0 if c.is_empty() else 1
	return n


func _spawn(c: Dictionary) -> Dictionary:
	if c.is_empty():
		return c
	var sp := Sprite2D.new()
	sp.texture = _texture(str(c["kind"]), true)
	sp.position = c["pos"]
	add_child(sp)
	c["sprite"] = sp
	return c


func _texture(kind: String, light: bool) -> Texture2D:
	if _tex.has(kind):
		return _tex[kind]
	return _tex.get("%s_%s" % [kind, "on" if light else "off"])


func _ref_y(i: int, ridge: PackedVector2Array) -> float:
	if not _ref.has(i):
		var xc := (i + 0.5) * _cell_px
		var span := WorldConfig.m_to_px(float(_cfg["ref_span_m"]))
		_ref[i] = TerrainGen.highest_between(ridge, xc - span, xc + span)
	return _ref[i]
