## Figuras dos minijogos (art/src/sprites/minigame_props.py): recortes do atlas e texturas que repetem.
## Contrato: assets/sprites/minigame_props.png + .json {"rects": {nome: [x, y, w, h]}, "sea_deep"} e mg_<nome>.png.
class_name MinigameArt
extends RefCounted

const DIR := "res://assets/sprites/"

static var _meta: Dictionary = {}
static var _cache: Dictionary = {}


static func meta() -> Dictionary:
	if _meta.is_empty():
		_meta = JSON.parse_string(FileAccess.get_file_as_string(DIR + "minigame_props.json"))
	return _meta


## Recorte do atlas pelo nome (ex.: "sheep0", "chest", "cap44").
static func tex(name: String) -> Texture2D:
	if _cache.has(name):
		return _cache[name]
	var r: Array = meta()["rects"][name]
	var at := AtlasTexture.new()
	at.atlas = load(DIR + "minigame_props.png")
	at.region = Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
	_cache[name] = at
	return at


## Sprite que repete a textura mg_<name> no retangulo rect (mundo): talo, caule, mar, gelo.
static func tiled(name: String, rect: Rect2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(DIR + "mg_%s.png" % name)
	s.centered = false
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.region_enabled = true
	s.region_rect = Rect2(Vector2.ZERO, rect.size)
	s.position = rect.position
	return s


## O chapeu de cogumelo mais proximo da largura pedida (56/44/36 px).
static func cap_for(width: float) -> String:
	var best := "cap56"
	for w: int in [56, 44, 36]:
		if absf(width - w) < absf(width - float(best.substr(3))):
			best = "cap%d" % w
	return best
