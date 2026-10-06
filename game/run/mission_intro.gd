## "Novo amiguinho!" (v15): apresenta um tipo de missao recem-liberado, uma vez (abre quando a oficina libera o no ★1
## do tipo). Ratinho em 2x falando a regra no balao (MissionText.balloon), o nome do tipo e um par certo x errado com as
## figuras das cargas (bolo inteiro x amassado...). Fecha com o botao, Enter/Esc ou clique depois de FOCUS_DELAY.
class_name MissionIntro
extends Control

signal closed

## Segundos ate poder fechar (o clique que liberou a missao nao fecha a telinha na hora).
const FOCUS_DELAY := 0.4
## Figuras de cada tipo (atlas das cargas): [certo, errado]; "" = sem par (Pesada e Dupla nao "estragam" a carga).
const PICS := {"heavy": ["weight", ""], "soft": ["cake", "cake_squashed"], "fast": ["icecream", "icecream_melted"],
		"passenger": ["mouse_safe", "mouse_wait0"], "tow": ["wheel", "wheel_cracked"], "double": ["star", ""]}

var _ready_at := 0.0

@onready var _face: TextureRect = %Face
@onready var _say: Label = %Say
@onready var _balloon: PanelContainer = %Balloon
@onready var _name: Label = %Name
@onready var _good: TextureRect = %Good
@onready var _bad: TextureRect = %Bad
@onready var _good_mark: TextureRect = %GoodMark
@onready var _bad_mark: TextureRect = %BadMark
@onready var _ok: Button = %Ok


func _ready() -> void:
	var tail := load("res://assets/ui/balloon_tail.png") as Texture2D
	_balloon.draw.connect(func() -> void:
		_balloon.draw_texture(tail, Vector2(-5.0, roundf(_balloon.size.y * 0.5) - 4.0)))
	_good_mark.texture = UiKit.kid("check")
	_bad_mark.texture = UiKit.kid("cross")
	_ok.pressed.connect(close)


## Apresenta o tipo de missao kind (heavy, soft, fast, passenger, tow, double).
func show_kind(kind: String) -> void:
	_face.texture = UiKit.kid("rat_" + kind)
	_say.text = MissionText.balloon({"kind": kind, "star": 1, "parts": [{"kind": kind, "star": 1}]})
	_name.text = str(EconMath.mission_kind(kind)["name"])
	var pics: Array = PICS.get(kind, ["box", ""])
	_good.texture = CargoArt.tex(str(pics[0]))
	var has_bad := str(pics[1]) != ""
	_bad.texture = CargoArt.tex(str(pics[1])) if has_bad else null
	_bad.get_parent().visible = has_bad
	visible = true
	_ready_at = FOCUS_DELAY
	UiKit.pulse(%Panel, 1.3, 0.25)


func close() -> void:
	if not visible or _ready_at > 0.0:
		return
	visible = false
	Sound.ui("click")
	closed.emit()


func _process(delta: float) -> void:
	if visible and _ready_at > 0.0:
		_ready_at -= delta
		if _ready_at <= 0.0:
			_ok.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"ui_cancel") \
			or (event is InputEventMouseButton and event.pressed):
		get_viewport().set_input_as_handled()
		close()
