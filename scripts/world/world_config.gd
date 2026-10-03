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
	if f == null:                                              # build quebrado: avisa o jogador em vez de travar mudo
		push_error("world.json nao encontrado em %s" % path)
		OS.alert("Arquivo de dados do jogo ausente (%s). Reinstale o jogo." % path, "Incremental Lander")
		return data
	data = JSON.parse_string(f.get_as_text())
	return data


## Metros do modelo -> pixels do mundo.
static func m_to_px(meters: float) -> float:
	return meters * float(load_config()["px_per_m"])


## Pixels do mundo -> metros do modelo.
static func px_to_m(pixels: float) -> float:
	return pixels / float(load_config()["px_per_m"])


## Registra as acoes de input (teclas e controle em world.json -> InputMap). Idempotente.
## Espaco e o propulsor: sai de ui_accept/ui_select (senao, apertado no hangar ou num menu, ativa o botao com foco —
## ex.: DECOLAR sem querer logo depois de uma batida). Menus confirmam com Enter, A do controle ou clique.
static func register_input() -> void:
	for ui: StringName in [&"ui_accept", &"ui_select"]:
		for ev: InputEvent in InputMap.action_get_events(ui):
			if ev is InputEventKey and ((ev as InputEventKey).keycode == KEY_SPACE \
					or (ev as InputEventKey).physical_keycode == KEY_SPACE):
				InputMap.action_erase_event(ui, ev)
	var actions: Dictionary = load_config()["input"]
	for action: String in actions:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key_name: String in actions[action]:
			InputMap.action_add_event(action, _key_event(key_name))
		for j: Dictionary in load_config().get("joypad", {}).get(action, []):
			InputMap.action_add_event(action, _joy_event(j))
	# acoes da interface (ui_cancel...) ganham botoes do controle extras uma vez
	for action: String in load_config().get("joypad", {}):
		if actions.has(action) or not InputMap.has_action(action):
			continue
		for j: Dictionary in load_config()["joypad"][action]:
			var ev := _joy_event(j)
			if not InputMap.action_has_event(action, ev):
				InputMap.action_add_event(action, ev)


## Acoes que o jogador pode remapear (teclado), na ordem do menu.
static func remappable() -> Array:
	return load_config().get("remappable", [])


## Teclas padrao (nomes) de uma acao, de world.json.
static func default_keys(action: String) -> Array:
	return load_config()["input"].get(action, [])


## Teclas atuais (nomes, tecla fisica) de uma acao.
static func current_keys(action: String) -> Array[String]:
	var out: Array[String] = []
	if not InputMap.has_action(action):
		return out
	for ev: InputEvent in InputMap.action_get_events(action):
		if ev is InputEventKey:
			out.append(OS.get_keycode_string((ev as InputEventKey).physical_keycode))
	return out


## Troca as teclas (nomes) de uma acao, mantendo os botoes do controle.
static func set_keys(action: String, key_names: Array) -> void:
	if not InputMap.has_action(action):
		return
	for ev: InputEvent in InputMap.action_get_events(action):
		if ev is InputEventKey:
			InputMap.action_erase_event(action, ev)
	for key_name: String in key_names:
		if OS.find_keycode_from_string(key_name) != KEY_NONE:
			InputMap.action_add_event(action, _key_event(key_name))


## Nome de tecla para o jogador (layout do teclado dele; setas e espaco em portugues).
static func key_label(key_name: String) -> String:
	var phys := OS.find_keycode_from_string(key_name)
	var shown := key_name
	if phys != KEY_NONE and DisplayServer.get_name() != "headless":     # headless nao conhece o layout do teclado
		shown = OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(phys))
	return {"Up": "Seta acima", "Down": "Seta abaixo", "Left": "Seta esq.", "Right": "Seta dir.", "Space": "Espaço",
			"Enter": "Enter", "Escape": "Esc"}.get(shown, shown)


static func _key_event(key_name: String) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = OS.find_keycode_from_string(key_name)
	return ev


static func _joy_event(j: Dictionary) -> InputEvent:
	if j.has("axis"):
		var m := InputEventJoypadMotion.new()
		m.axis = int(j["axis"]) as JoyAxis
		m.axis_value = float(j.get("value", 1.0))
		return m
	var b := InputEventJoypadButton.new()
	b.button_index = int(j["button"]) as JoyButton
	return b
