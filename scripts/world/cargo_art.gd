## Atlas das cargas e habilidades (skill pixel-art: art/src/sprites/cargo.py -> assets/sprites/cargo.png + .json).
## Celulas quadradas (cell px) em uma linha, na ordem de "names". Usado pelo voo, HUD, pedidos e oficina.
class_name CargoArt
extends RefCounted

const SHEET := "res://assets/sprites/cargo.png"
const META := "res://assets/sprites/cargo.json"
## Figura de cada carga na oferta/HUD (a mesma do mundo, parada).
const ICON := {"box": "box", "fragile": "cake", "urgent": "icecream", "towed": "wheel", "rescue": "mouse_wait0"}

static var _meta: Dictionary = {}
static var _cache: Dictionary = {}


## Textura (AtlasTexture) da celula name; null se o atlas nao tem esse nome.
static func tex(name: String) -> AtlasTexture:
	if _cache.has(name):
		return _cache[name]
	if _meta.is_empty():
		var f := FileAccess.open(META, FileAccess.READ)
		if f == null:
			push_error("CargoArt: falta %s" % META)
			return null
		_meta = JSON.parse_string(f.get_as_text())
	var names: Array = _meta["names"]
	var i := names.find(name)
	if i < 0:
		return null
	var cell := float(_meta["cell"])
	var at := AtlasTexture.new()
	at.atlas = load(SHEET)
	at.region = Rect2(i * cell, 0, cell, cell)
	_cache[name] = at
	return at


## Figura da carga kind (falhou = versao estragada: bolo amassado, sorvete derretido, queijo rachado;
## o ratinho nao resgatado continua esperando).
static func icon(kind: String, failed: bool = false) -> AtlasTexture:
	var base: String = ICON.get(kind, "box")
	if failed:
		var broken: String = {"cake": "cake_squashed", "icecream": "icecream_melted",
				"wheel": "wheel_cracked"}.get(base, base)
		return tex(broken)
	return tex(base)
