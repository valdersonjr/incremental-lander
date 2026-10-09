## Cena propria da tela de titulo (arte: art/src/title/title_moon.py -> assets/bg/title_*.png, assets/sprites/title_*,
## posicoes em assets/bg/title_layout.json). Nao usa o mapa de voo: ceu fixo, nuvens a deriva, morros de tras e
## morro-palco da frente com parallax leve pelo mouse (pixel inteiro), gatinho heroi acenando/respirando, bandeira,
## nave com luzinhas, estrelas cintilando e estrela cadente de vez em quando. Sem camera nem fisica.
## Tudo no tempo da musica (Sound.music_beat): o quadro de cada animacao sai da fase do compasso, nao de um relogio
## proprio — gatinho 1 compasso, bandeira 2 tempos, luzinhas da nave 1 compasso, estrelas acendendo em colcheias,
## nuvens 4 compassos, estrela cadente sempre no 1o tempo.
class_name TitleBackdrop
extends Control

const LAYOUT_PATH := "res://assets/bg/title_layout.json"
## Ciclos em batidas (4/4): deriva das nuvens (vai e volta), cintilar das estrelas e cada animacao do cenario.
const CLOUD_BEATS := 16.0
const TWINKLE_BEATS := 4.0
const ANIM_BEATS := {"Cat": 4.0, "Flag": 2.0, "Lander": 4.0}
## Quanto o parallax segue o mouse por segundo (suaviza; 1 = instantaneo).
const PARALLAX_FOLLOW := 3.0
## Compassos entre estrelas cadentes (sorteado; ela cai no 1o tempo do compasso).
const STAR_GAP_BARS := Vector2i(3, 5)
## Cores do cintilar (Resurrect 64: white, cream).
const TWINKLE_HI := Color("ffffff")
const TWINKLE_GLOW := Color("fdcbb0")

var _layout: Dictionary = {}
var _pad := 0
var _beat := 0.0                           # batidas da musica (Sound.music_beat)
var _look := Vector2.ZERO                  # -1..1: para onde o mouse puxa a cena
var _next_star_bar := 0
var _anims: Dictionary = {}                # nome -> AnimatedSprite2D (quadro escolhido pela fase da musica)

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
		var spr := $Front.get_node(n) as AnimatedSprite2D
		spr.position = Vector2(float(p[0]) + _pad, float(p[1]))
		spr.pause()                                             # o quadro vem da musica (_sync_anims)
		_anims[n] = spr
	_star.position = Vector2(float(_layout["star"][0]), float(_layout["star"][1]))
	_star.visible = false
	_star.animation_finished.connect(func() -> void: _star.visible = false)
	_twinkle.draw.connect(_draw_twinkle)
	_beat = Sound.music_beat()
	_next_star_bar = int(_beat / 4.0) + 2
	_place_layers()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_beat = Sound.music_beat()
	var m := get_local_mouse_position()
	var target := Vector2.ZERO
	if Rect2(Vector2.ZERO, size).has_point(m) and size.x > 0.0:
		target = ((m / size) - Vector2(0.5, 0.5)) * 2.0
	_look = _look.lerp(target.clampf(-1.0, 1.0), minf(PARALLAX_FOLLOW * delta, 1.0))
	_place_layers()
	_sync_anims()
	var bar := int(_beat / 4.0)
	if bar >= _next_star_bar:                                  # estrela cadente no 1o tempo do compasso
		_next_star_bar = bar + randi_range(STAR_GAP_BARS.x, STAR_GAP_BARS.y)
		_star.visible = true
		_star.frame = 0
		_star.play(&"fall")
	elif bar < _next_star_bar - STAR_GAP_BARS.y:              # a musica voltou ao comeco (loop/troca de faixa)
		_next_star_bar = bar + 1
	_twinkle.queue_redraw()


## Quadro de cada animacao = fase do ciclo dela (em batidas) x numero de quadros.
func _sync_anims() -> void:
	for n: String in _anims:
		var spr: AnimatedSprite2D = _anims[n]
		var count := spr.sprite_frames.get_frame_count(spr.animation)
		var phase := fposmod(_beat / float(ANIM_BEATS[n]), 1.0)
		var f := mini(int(phase * count), count - 1)
		if spr.frame != f:
			spr.frame = f


## Posicoes das camadas: parallax (mais perto = anda mais, para o lado oposto do mouse) + deriva das nuvens.
## Tudo arredondado para pixel inteiro (arte pixel nitida).
func _place_layers() -> void:
	var px: Dictionary = _layout["parallax_px"]
	var drift := float(_layout["cloud_drift_px"]) * sin(TAU * _beat / CLOUD_BEATS)
	_clouds.position = (Vector2(drift, 0.0) - _look * float(px["clouds"])).round()
	_back.position = (Vector2(-_pad, 0) - _look * float(px["back"])).round()
	_front.position = (Vector2(-_pad, 0) - _look * float(px["front"])).round()


func _draw_twinkle() -> void:
	var points: Array = _layout["twinkle"]
	for i in points.size():
		var p := Vector2(float(points[i][0]), float(points[i][1]))
		var phase := fposmod(_beat / TWINKLE_BEATS + float((i * 5) % 8) / 8.0, 1.0)   # cada estrela numa colcheia
		if phase < 0.25:                                         # aceso: ponto branco
			_twinkle.draw_rect(Rect2(p, Vector2.ONE), TWINKLE_HI)
		if phase < 0.12:                                         # pico: cruzinha creme
			for d: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
				_twinkle.draw_rect(Rect2(p + d, Vector2.ONE), TWINKLE_GLOW)
