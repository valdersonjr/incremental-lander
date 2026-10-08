## Arte da conversa do pedido por mundo: o morador (corpo inteiro) e o palco.
## Lua = ratinhos por tipo de pedido (talk_mouse_<tipo>); os outros mundos = um morador so (talk_<mundo>,
## art/src/sprites/world_npcs.py) e palco talk_stage_<mundo>.
class_name TalkArt
extends RefCounted

## [chao, borda de cima] do palco, nomes da paleta (cor do chao de cada mundo).
const GROUND := {"luna": ["amber", "gold"], "nuvens": ["lavender", "white"], "cogumelos": ["purple", "violet"],
	"sorvete": ["ice", "white"], "jardim": ["leaf", "lemon"], "bolhas": ["gold", "lemon"]}


static func frames(kind: String, planet: String) -> SpriteFrames:
	var path := "res://assets/sprites/talk_%s_frames.tres" % planet
	if planet != "luna" and ResourceLoader.exists(path):
		return load(path) as SpriteFrames
	return load("res://assets/sprites/talk_mouse_%s_frames.tres" % kind) as SpriteFrames


static func stage(planet: String) -> Texture2D:
	var path := "res://assets/ui/talk_stage_%s.png" % planet
	return load(path if ResourceLoader.exists(path) else "res://assets/ui/talk_stage_luna.png") as Texture2D


static func ground(planet: String) -> Array:
	return GROUND.get(planet, GROUND["luna"])


## Rostinho 24x24 do pedido: Lua = ratinho do tipo; outros mundos = o morador (kids npc_<mundo>).
static func face(kind: String, planet: String = "") -> Texture2D:
	var p := planet if planet != "" else GameState.current_planet
	if p != "luna" and UiKit.has_kid("npc_" + p):
		return UiKit.kid("npc_" + p)
	return UiKit.kid("rat_" + kind)
