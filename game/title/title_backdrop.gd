## Cena propria da tela de titulo (arte: art/src/title/title_moon.py -> assets/bg/title_*.png, assets/sprites/title_*,
## posicoes em assets/bg/title_layout.json). Nao usa o mapa de voo: ceu fixo, nuvens a deriva, morros de tras e
## morro-palco da frente com parallax leve pelo mouse (pixel inteiro), gatinho heroi acenando/respirando, bandeira,
## nave com luzinhas, estrelas cintilando e estrela cadente de vez em quando. Sem camera nem fisica.
class_name TitleBackdrop
extends Control

const LAYOUT_PATH := "res://assets/bg/title_layout.json"
## Periodo (s) da deriva das nuvens (vai e volta).
const CLOUD_PERIOD := 9.0
## Quanto o parallax segue o mouse por segundo (suaviza; 1 = instantaneo).
const PARALLAX_FOLLOW := 3.0
## Intervalo (s) entre estrelas cadentes.
const STAR_GAP := Vector2(7.0, 13.0)
## Ciclo (s) de cintilar de cada estrela.
const TWINKLE_PERIOD := 2.4
## Cores do cintilar (Resurrect 64: white, cream).
const TWINKLE_HI := Color("ffffff")
const TWINKLE_GLOW := Color("fdcbb0")

var _layout: Dictionary = {}
var _pad := 0
var _time := 0.0
var _look := Vector2.ZERO                  # -1..1: para onde o mouse puxa a cena
var _star_wait := 0.0

@onready var _clouds: TextureRect = $Clouds
@onready var _back: TextureRect = $Back
@onready var _front: Control = $Front
@onready var _star: AnimatedSprite2D = $Star
@onready var _twinkle: Control = $Twinkle


func _ready() -> void:
	_layout = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT_PATH))
	_pad = int(_layout["layer_pad"])
	for n: String in ["Cat", "Flag", "Lander"]:
		var p: Array = _layout[n.to_lower()]
		($Front.get_node(n) as AnimatedSprite2D).position = Vector2(float(p[0]) + _pad, float(p[1]))
	_star.position = Vector2(float(_layout["star"][0]), float(_layout["star"][1]))
	_star.visible = false
	_star.animation_finished.connect(func() -> void: _star.visible = false)
	_twinkle.draw.connect(_draw_twinkle)
	_star_wait = randf_range(2.0, STAR_GAP.x)
	_place_layers()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	var m := get_local_mouse_position()
	var target := Vector2.ZERO
	if Rect2(Vector2.ZERO, size).has_point(m) and size.x > 0.0:
		target = ((m / size) - Vector2(0.5, 0.5)) * 2.0
	_look = _look.lerp(target.clampf(-1.0, 1.0), minf(PARALLAX_FOLLOW * delta, 1.0))
	_place_layers()
	_star_wait -= delta
	if _star_wait <= 0.0:
		_star_wait = randf_range(STAR_GAP.x, STAR_GAP.y)
		_star.visible = true
		_star.frame = 0
		_star.play(&"fall")
	_twinkle.queue_redraw()


## Posicoes das camadas: parallax (mais perto = anda mais, para o lado oposto do mouse) + deriva das nuvens.
## Tudo arredondado para pixel inteiro (arte pixel nitida).
func _place_layers() -> void:
	var px: Dictionary = _layout["parallax_px"]
	var drift := float(_layout["cloud_drift_px"]) * sin(TAU * _time / CLOUD_PERIOD)
	_clouds.position = (Vector2(drift, 0.0) - _look * float(px["clouds"])).round()
	_back.position = (Vector2(-_pad, 0) - _look * float(px["back"])).round()
	_front.position = (Vector2(-_pad, 0) - _look * float(px["front"])).round()


func _draw_twinkle() -> void:
	var points: Array = _layout["twinkle"]
	for i in points.size():
		var p := Vector2(float(points[i][0]), float(points[i][1]))
		var phase := fposmod(_time / TWINKLE_PERIOD + float(i) * 0.37, 1.0)
		if phase < 0.25:                                         # aceso: ponto branco
			_twinkle.draw_rect(Rect2(p, Vector2.ONE), TWINKLE_HI)
		if phase < 0.12:                                         # pico: cruzinha creme
			for d: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
				_twinkle.draw_rect(Rect2(p + d, Vector2.ONE), TWINKLE_GLOW)
