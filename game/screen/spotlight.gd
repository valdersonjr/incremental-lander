## Destaque de primeira visita (prototipo escolhido: art/previews/destaques/destaques.html, balao C, um passo por tela):
## a tela escurece com o xadrez de 1 px do jogo (UiKit.dim_rect) menos o botao alvo, que ganha moldura dourada pulsando,
## um balao com figura + 1 palavra e uma maozinha tocando. Clicar no alvo faz a acao e fecha; clicar fora so fecha.
## Cada destaque aparece uma vez (dica salva em GameState.tips). So em menus, nunca no voo.
class_name Spotlight
extends Control

const INK := Color("#2e222f")
const WHITE := Color("#ffffff")
const GOLD := Color("#f9c22b")
const PAD := 3.0                                   # folga entre o alvo e a luz
const HAND := ["..xx......", "..xwx.....", "..xwx.....", "..xwxxx...", "..xwxwxxx.", "xxxwxwxwxx", "xwxwwwwwwx",
		"xwwwwwwwwx", ".xwwwwwwwx", ".xwwwwwwx.", "..xwwwwwx.", "..xxxxxxx."]

var _target: Control = null
var _icon: Texture2D = null
var _word := ""
var _dims: Array[ColorRect] = []
var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE                 # so os 4 retangulos escuros pegam o clique
	visible = false
	for i in 4:
		var r := ColorRect.new()
		UiKit.dim_rect(r)
		r.mouse_filter = Control.MOUSE_FILTER_STOP
		r.gui_input.connect(_on_dim_input)
		add_child(r)
		_dims.append(r)


## Destaca target (uma vez por tip_id). icon = nome no atlas infantil (UiKit.kid), word = 1 palavra.
## Devolve true se mostrou.
func point(target: Control, tip_id: String, icon: String, word: String) -> bool:
	if target == null or GameState.tip_done(tip_id) or not target.is_visible_in_tree():
		return false
	GameState.learn_tip(tip_id)                                # fechou sem fazer? nao volta (nao insiste)
	_target = target
	_icon = UiKit.kid(icon)
	_word = word
	_t = 0.0
	if target is BaseButton:
		(target as BaseButton).pressed.connect(close, CONNECT_ONE_SHOT)
	visible = true
	_layout()
	Telemetry.event("spotlight", tip_id)
	return true


func close() -> void:
	if _target != null and is_instance_valid(_target) and _target is BaseButton \
			and (_target as BaseButton).pressed.is_connected(close):
		(_target as BaseButton).pressed.disconnect(close)
	_target = null
	visible = false


func _process(delta: float) -> void:
	if not visible:
		return
	if _target == null or not is_instance_valid(_target) or not _target.is_visible_in_tree():
		close()
		return
	_t += delta
	_layout()
	queue_redraw()


## Luz no alvo: 4 retangulos escuros em volta do buraco.
func _layout() -> void:
	var h := _hole()
	var s := size
	var rects := [Rect2(0, 0, s.x, h.position.y), Rect2(0, h.end.y, s.x, s.y - h.end.y),
			Rect2(0, h.position.y, h.position.x, h.size.y), Rect2(h.end.x, h.position.y, s.x - h.end.x, h.size.y)]
	for i in 4:
		_dims[i].position = rects[i].position
		_dims[i].size = rects[i].size.max(Vector2.ZERO)


func _hole() -> Rect2:
	var r := _target.get_global_rect()
	r.position -= global_position
	return r.grow(PAD)


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		accept_event()
		close()


func _draw() -> void:
	if _target == null:
		return
	var h := _hole()
	var pulse := 1.0 if fmod(_t, 0.8) < 0.4 else 0.0
	_frame(h.grow(2.0 + pulse), INK)
	_frame(h.grow(1.0 + pulse), GOLD)
	# balao em cima do alvo (embaixo se nao couber), com a ponta apontando o centro
	var font := get_theme_default_font()
	var fs := UiKit.FONT_SIZE
	var tw := font.get_string_size(_word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var bw := roundf(maxf(64.0, tw + 40.0))
	var bh := 32.0
	var up := h.position.y - 12.0 - bh >= 0.0
	var cx := clampf(h.get_center().x, bw * 0.5 + 6.0, size.x - bw * 0.5 - 6.0)
	var bob := roundf(sin(_t * 4.0) * 1.5)
	var b := Rect2(roundf(cx - bw * 0.5), (h.position.y - 10.0 - bh if up else h.end.y + 10.0) + bob, bw, bh)
	draw_rect(b, INK)
	draw_rect(b.grow(-1.0), WHITE)
	var tx := roundf(h.get_center().x)
	if up:
		draw_rect(Rect2(tx - 4.0, b.end.y - 1.0, 8.0, 4.0), INK)
		draw_rect(Rect2(tx - 3.0, b.end.y - 1.0, 6.0, 3.0), WHITE)
		draw_rect(Rect2(tx - 1.0, b.end.y + 3.0, 2.0, 2.0), INK)
	else:
		draw_rect(Rect2(tx - 4.0, b.position.y - 3.0, 8.0, 4.0), INK)
		draw_rect(Rect2(tx - 3.0, b.position.y - 2.0, 6.0, 3.0), WHITE)
		draw_rect(Rect2(tx - 1.0, b.position.y - 5.0, 2.0, 2.0), INK)
	if _icon != null:
		draw_texture(_icon, b.position + Vector2(5.0, 4.0))
	draw_string(font, Vector2(b.position.x + 32.0, b.position.y + 20.0), _word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
	# maozinha tocando o centro do alvo
	var press := 0.0 if fmod(_t, 1.0) < 0.5 else 3.0
	var hp := (h.get_center() + Vector2(2.0, -2.0 + press)).round()
	for j in HAND.size():
		var row: String = HAND[j]
		for i in row.length():
			if row[i] == "x":
				draw_rect(Rect2(hp + Vector2(i, j), Vector2.ONE), INK)
			elif row[i] == "w":
				draw_rect(Rect2(hp + Vector2(i, j), Vector2.ONE), WHITE)


func _frame(r: Rect2, c: Color) -> void:
	draw_rect(Rect2(r.position, Vector2(r.size.x, 1.0)), c)
	draw_rect(Rect2(Vector2(r.position.x, r.end.y - 1.0), Vector2(r.size.x, 1.0)), c)
	draw_rect(Rect2(r.position, Vector2(1.0, r.size.y)), c)
	draw_rect(Rect2(Vector2(r.end.x - 1.0, r.position.y), Vector2(1.0, r.size.y)), c)
