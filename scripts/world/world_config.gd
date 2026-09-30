## Constantes de mundo e sensacao lidas de res://data/world.json (skill godot-dev).
## Economia NAO mora aqui (ver EconMath). Uso: WorldConfig.load_config(); WorldConfig.data["px_per_m"]
class_name WorldConfig
extends RefCounted

const PATH := "res://data/world.json"

static var data: Dictionary = {}


static func load_config(path: String = PATH) -> Dictionary:
	if not data.is_empty():
		return data
	var f := FileAccess.open(path, FileAccess.READ)
	assert(f != null, "world.json nao encontrado em %s" % path)
	data = JSON.parse_string(f.get_as_text())
	return data


## Metros do modelo -> pixels do mundo.
static func m_to_px(meters: float) -> float:
	return meters * float(load_config()["px_per_m"])


## Pixels do mundo -> metros do modelo.
static func px_to_m(pixels: float) -> float:
	return pixels / float(load_config()["px_per_m"])


## Registra as acoes de input (teclas em world.json -> InputMap). Idempotente.
static func register_input() -> void:
	var actions: Dictionary = load_config()["input"]
	for action: String in actions:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key_name: String in actions[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = OS.find_keycode_from_string(key_name)
			InputMap.action_add_event(action, ev)
