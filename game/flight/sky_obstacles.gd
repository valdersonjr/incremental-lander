## Ossos de pedra (asteroides em formato de osso) no ceu da pista (world.json > sky_obstacles; regra em SkyField; arte
## e areas de batida em assets/sprites/sky_obstacles.png/.json, skill pixel-art). So existem as celulas perto da camera:
## follow() cria as que entram na tela e solta as que saem. A Flight chama follow() todo quadro, hit() para a batida e
## take() quando o cachorrinho leva o osso.
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
	var meta_circles: Dictionary = meta.get("circles", {})
	for k: Dictionary in cfg["kinds"]:
		_circles[str(k["name"])] = k.get("circles", meta_circles.get(str(k["name"]), []))


func _process(delta: float) -> void:
	_t += delta
	var bob := float(_cfg.get("bob_px", 0.0))
	for c: Dictionary in _cells.values():
		if c.is_empty():
			continue
		var sp: Sprite2D = c["sprite"]
		sp.position = (c["pos"] as Vector2) + Vector2(0.0, roundf(sin((_t * BOB_HZ + float(c["phase"])) * TAU) * bob))


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


## Primeira batida da nave (centro p, raio r px): {"key", "pos", "normal", "at"} ou {} se nao encosta em nada.
func hit(p: Vector2, r: float) -> Dictionary:
	for key: Vector2i in _cells.keys():
		var c: Dictionary = _cells[key]
		if c.is_empty() or (c["pos"] as Vector2).distance_squared_to(p) > 70.0 * 70.0:
			continue
		var n := SkyField.hit_normal(p, r, c["pos"], _circles[c["kind"]])
		if n != Vector2.ZERO:
			return {"key": key, "pos": (c["sprite"] as Sprite2D).position, "normal": n, "at": p - n * r}
	return {}


## O cachorrinho levou o osso da celula key: some (a celula fica vazia ate sair da tela).
func take(key: Vector2i) -> void:
	var c: Dictionary = _cells.get(key, {})
	if not c.is_empty():
		(c["sprite"] as Node).queue_free()
	_cells[key] = {}


## Textura do atlas pelo nome (ossos e quadros do cachorrinho: dog_0, dog_1, dog_bone).
func texture(name_: String) -> Texture2D:
	return _tex.get(name_)


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
	sp.texture = _tex.get(str(c["kind"]))
	sp.position = c["pos"]
	add_child(sp)
	c["sprite"] = sp
	return c


func _ref_y(i: int, ridge: PackedVector2Array) -> float:
	if not _ref.has(i):
		var xc := (i + 0.5) * _cell_px
		var span := WorldConfig.m_to_px(float(_cfg["ref_span_m"]))
		_ref[i] = TerrainGen.highest_between(ridge, xc - span, xc + span)
	return _ref[i]
