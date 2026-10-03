## Filtro CRT por cima de tudo (CanvasLayer 128 + ColorRect com game/screen/crt.gdshader). Ligado por padrao; a opcao
## "Filtro CRT" (GameState.crt_enabled / set_crt, salva em settings.json) liga e desliga. So apresentacao.
extends CanvasLayer

const SHADER := preload("res://game/screen/crt.gdshader")

var _rect: ColorRect


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	_rect.material = mat
	add_child(_rect)
	Events.settings_changed.connect(_apply)
	_apply()


func _apply() -> void:
	visible = GameState.crt_enabled()
