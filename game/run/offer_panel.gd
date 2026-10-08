## Escolha do pedido = JANELA DE CONVERSA (2026-10-07, maquete aprovada em art/previews/mission_talk/; arte:
## art/src/ui/mission_talk.py). No alto, a FILA com TODOS os ratinhos de missão do planeta, sempre na mesma ordem:
## os ainda não liberados ficam em silhueta (sem cor) e não dão para escolher. Um rostinho por tipo: os pedidos do
## mesmo ratinho (ex.: o mineiro com perto/médio/longe) viram a coluna "Distância" da janela.
## Janela: palco com o gatinho herói (esquerda) e o ratinho (direita) com UM balão (pedido + regra com certo × errado);
## colunas Distância | Tamanho da plataforma | Dificuldade (cada uma só aparece se houver opção; clicar só marca);
## embaixo "Você ganha" + ACEITAR MISSÃO. Gás pouco: o gatinho fica preocupado e avisa. Aceitar: gatinho faz joinha
## ("Deixa comigo!"), ratinho comemora, e o pedido parte (offer_chosen) depois de ACCEPT_S.
## Teclado/controle: esquerda/direita trocam o ratinho, cima/baixo a plataforma, Shift + cima/baixo a dificuldade,
## 1..3 a distância, Enter aceita; E encerra o run (2 toques). Se o jogador tenta pilotar antes de aceitar, a janela pula.
class_name OfferPanel
extends Control

signal offer_chosen(index: int)
signal end_requested

## Tamanhos de plataforma escolhiveis (v12.1), do mais facil ao mais dificil.
const TIERS := ["normal", "narrow", "tight"]
## Nomes das distancias de um ratinho, do mais perto ao mais longe (2 opcoes = perto/longe).
const DIST_NAMES := ["perto", "médio", "longe"]
## Tamanho da plataforma em palavra de crianca ("estreita" e "apertada" pareciam a mesma coisa).
const TIER_NAMES := {"normal": "grande", "narrow": "média", "tight": "pequena"}
const CHIP := Vector2(35, 50)
const OPTION := Vector2(124, 17)
const CUT_COIN := Rect2(6, 9, 12, 12)
const CUT_STAR := Rect2(6, 6, 12, 12)
const CUT_MARK := Rect2(4, 6, 16, 16)
## Tempo entre o clique em aceitar e a partida (joinha + comemoracao).
const ACCEPT_S := 0.5
## Ultima escolha do jogador por tipo de missao ({kind: [plataforma, estrela, distancia]}): pedidos novos ja vem assim.
static var last_choice: Dictionary = {}

## Segundos restantes do aviso (tentou pilotar antes de escolher). Exposto para o teste de controles.
var hint_flash := 0.0
## Segundos restantes para o 2o toque de E confirmar o fim do run (um toque sem querer nao encerra).
var end_armed := 0.0
var _run: RunState = null
var _gas_left := 0.0
var _kinds: Array[String] = []          # todos os ratinhos do planeta, na ordem da spec
var _groups: Dictionary = {}            # kind -> Array[int] (indices dos pedidos, perto -> longe)
var _dsel: Dictionary = {}              # kind -> indice escolhido dentro do grupo
var _chips: Dictionary = {}             # kind -> Button
var _kind := ""
var _peek := ""                         # ratinho bloqueado sob o mouse ("" = nenhum)
var _accepting := false
var _option_buttons: Dictionary = {}    # "tier:normal" / "dist:0" / "star:2" -> Button (teste)
var _board_y := 0.0
var _talk_left := 0.0

@onready var _dim: ColorRect = %Dim
@onready var _board: Control = %Board
@onready var _chip_row: HBoxContainer = %Chips
@onready var _window: PanelContainer = %Window
@onready var _cat: AnimatedSprite2D = %Cat
@onready var _mouse: AnimatedSprite2D = %Mouse
@onready var _mouse_balloon: PanelContainer = %MouseBalloon
@onready var _ask: Label = %Ask
@onready var _rule_row: HBoxContainer = %RuleRow
@onready var _rule: Label = %Rule
@onready var _pics: HBoxContainer = %Pics
@onready var _dots: ColorRect = %Dots
@onready var _cat_balloon: PanelContainer = %CatBalloon
@onready var _cat_say: Label = %CatSay
@onready var _columns: HBoxContainer = %Columns
@onready var _total: Label = %Total
@onready var _accept: Button = %Accept
@onready var _hint: Label = %Hint


func _ready() -> void:
	_board_y = _board.position.y
	_dim.color = Color(UiKit.color("ink"), 0.55)
	_apply_world()
	_dots.color = UiKit.color("peach")
	(%Line as ColorRect).color = UiKit.color("purple")
	(%Coin as TextureRect).texture = _cut("coin", CUT_COIN)
	(%Gain as Label).add_theme_color_override(&"font_color", UiKit.color("white"))
	_total.add_theme_color_override(&"font_color", UiKit.color("gold"))
	_rule.add_theme_color_override(&"font_color", UiKit.color("wine"))
	var tail := load("res://assets/ui/balloon_tail.png") as Texture2D
	var img := tail.get_image()
	img.flip_x()
	var tail_r := ImageTexture.create_from_image(img)
	_mouse_balloon.draw.connect(func() -> void:                # rabinho na borda direita, para o ratinho
		_mouse_balloon.draw_texture(tail_r, Vector2(_mouse_balloon.size.x - 1.0,
				roundf(_mouse_balloon.size.y * 0.5) - 4.0)))
	_cat_balloon.draw.connect(func() -> void:                  # rabinho na borda esquerda, para o gatinho
		_cat_balloon.draw_texture(tail, Vector2(-5.0, roundf(_cat_balloon.size.y * 0.5) - 4.0)))
	_accept.pressed.connect(_on_accept)


## Mostra os pedidos do run com o gas que resta.
## Palco e chao da conversa do mundo atual (Fase 18.5: cada mundo tem o seu).
func _apply_world() -> void:
	var g := TalkArt.ground(GameState.current_planet)
	(%Ground as ColorRect).color = UiKit.color(str(g[0]))
	(%GroundTop as ColorRect).color = UiKit.color(str(g[1]))
	(%Bg as TextureRect).texture = TalkArt.stage(GameState.current_planet)


func show_offers(run: RunState, gas_left: float) -> void:
	_apply_world()
	_run = run
	_gas_left = gas_left
	_accepting = false
	_peek = ""
	hint_flash = 0.0
	end_armed = 0.0
	_kinds.clear()
	for k: Dictionary in EconMath.mission_kinds(run.planet_id):
		_kinds.append(str(k["id"]))
	if _kinds.is_empty():
		_kinds.append("simple")
	_groups.clear()
	for i in run.offers.size():                                # pedidos ja vem ordenados por distancia
		var kind := str(run.offer_mission[i]["kind"])
		if not _groups.has(kind):
			_groups[kind] = []
		(_groups[kind] as Array).append(i)
	for kind: String in _groups:                               # pedido novo ja vem com a ultima escolha do tipo
		var lc: Array = last_choice.get(kind, [])
		var g: Array = _groups[kind]
		_dsel[kind] = clampi(int(lc[2]) if lc.size() > 2 else 0, 0, g.size() - 1)
		if GameState.apprentice() and not run.offer_info(int(g[_dsel[kind]]), gas_left)["reachable"]:
			for d in g.size():                                 # aprendiz: comeca num pedido que o gas alcanca (M1)
				if run.offer_info(int(g[d]), gas_left)["reachable"]:
					_dsel[kind] = d
					break
		if lc.size() >= 2:
			for i: int in g:
				run.set_choice(i, str(lc[0]), int(lc[1]))
	_build_chips()
	visible = true
	_kind = ""
	var first := ""                                            # 1o ratinho com pedido alcancavel (o mais perto)
	for i in run.offers.size():
		if run.offer_info(i, gas_left)["reachable"]:
			first = str(run.offer_mission[i]["kind"])
			break
	if first == "" and not _groups.is_empty():
		first = str(run.offer_mission[0]["kind"])
	if first != "":
		_select(first)
	_window.pivot_offset = _window.size * 0.5
	_window.scale = Vector2(0.92, 0.92)
	create_tween().tween_property(_window, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK) \
			.set_ease(Tween.EASE_OUT)


## Indice (em run.offers) do pedido marcado na janela.
func selected_offer() -> int:
	if _kind == "" or not _groups.has(_kind):
		return -1
	var g: Array = _groups[_kind]
	return int(g[clampi(int(_dsel.get(_kind, 0)), 0, g.size() - 1)])


## Centro (tela) do rostinho do ratinho do pedido i (teste de controles).
func offer_line_center(i: int) -> Vector2:
	return (_chips[str(_run.offer_mission[i]["kind"])] as Button).get_global_rect().get_center()


## Centro (tela) do botao da plataforma tier (teste de controles).
func pad_button_center(tier: String) -> Vector2:
	return (_option_buttons["tier:" + tier] as Button).get_global_rect().get_center()


## Centro (tela) do botao ACEITAR MISSAO (teste de controles).
func accept_button_center() -> Vector2:
	return _accept.get_global_rect().get_center()


func _process(delta: float) -> void:
	if not visible:
		return
	if end_armed > 0.0:
		end_armed -= delta
		_set_hint("E de novo para terminar a viagem (o que você ganhou fica)", &"MoneyLabel")
	elif hint_flash > 0.0:
		hint_flash -= delta
		_set_hint("ACEITE UMA MISSÃO PRIMEIRO!", &"BadLabel" if fmod(hint_flash, 0.4) > 0.2 else &"MoneyLabel")
	else:
		_set_hint("", &"DimLabel")
	_window.position.y = _board_y + 54.0 - (3.0 if hint_flash > 0.0 and fmod(hint_flash, 0.4) > 0.2 else 0.0)
	if _talk_left > 0.0:                                       # o ratinho fala um pouquinho e volta a respirar
		_talk_left -= delta
		if _talk_left <= 0.0 and not _accepting and _mouse.animation == &"talk":
			_mouse.play(&"idle")


func _set_hint(text: String, variation: StringName) -> void:
	_hint.text = text
	_hint.visible = text != ""
	_hint.theme_type_variation = variation


# --- fila de ratinhos -------------------------------------------------------------------------------------------------

func _build_chips() -> void:
	for c in _chip_row.get_children():
		_chip_row.remove_child(c)
		c.queue_free()
	_chips.clear()
	for kind in _kinds:
		var open := _groups.has(kind)
		var chip := Button.new()
		chip.flat = true
		chip.focus_mode = Control.FOCUS_NONE                   # setas sao tratadas em _input
		chip.custom_minimum_size = CHIP
		chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if open else Control.CURSOR_ARROW
		var box := VBoxContainer.new()
		box.name = "Box"
		box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_theme_constant_override(&"separation", 0)
		chip.add_child(box)
		var pin := Control.new()
		pin.name = "Pin"
		pin.custom_minimum_size = Vector2(24, 24)
		pin.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(pin)
		for part: String in ["bg", "face"]:
			var tr := TextureRect.new()
			tr.name = part.capitalize()
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tr.texture = TalkArt.face(kind) if part == "face" else UiKit.kid("pin" if open else "pin_off")
			if part == "face" and not open:                    # ainda nao liberado: silhueta sem cor
				UiKit.silhouette(tr, Color("#6b3e75"))
			pin.add_child(tr)
		var prize := Label.new()
		prize.name = "Prize"
		prize.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prize.mouse_filter = Control.MOUSE_FILTER_IGNORE
		prize.custom_minimum_size = Vector2(0, 22)
		prize.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		box.add_child(prize)
		if open:
			chip.mouse_entered.connect(func() -> void: _peek_locked(""))
			chip.pressed.connect(_select.bind(kind))
		else:
			chip.mouse_entered.connect(_peek_locked.bind(kind))
			chip.mouse_exited.connect(func() -> void: _peek_locked(""))
		_chip_row.add_child(chip)
		_chips[kind] = chip
		_update_chip(kind)


## Premio do pedido marcado no rostinho (cinza se o gas nao chega; vazio se ainda nao liberado).
func _update_chip(kind: String) -> void:
	var prize := _chips[kind].get_node("Box/Prize") as Label
	prize.visible = _groups.has(kind) and _groups.size() > 1  # um ratinho so: o premio ja esta em "Voce ganha"
	if not prize.visible:
		prize.text = ""
		return
	var g: Array = _groups[kind]
	var i := int(g[clampi(int(_dsel.get(kind, 0)), 0, g.size() - 1)])
	var info := _run.offer_info(i, _gas_left)
	prize.text = "+" + EconMath.fmt(info["pay_typical"])
	prize.theme_type_variation = &"MoneyLabel" if info["reachable"] else &"DimLabel"


func _select(kind: String) -> void:
	if _accepting or not _groups.has(kind):
		return
	if _kind != "" and _chips.has(_kind):
		(_chips[_kind].get_node("Box/Pin/Bg") as TextureRect).texture = UiKit.kid("pin")
	var changed := kind != _kind
	_kind = kind
	(_chips[kind].get_node("Box/Pin/Bg") as TextureRect).texture = UiKit.kid("pin_sel")
	if changed:
		UiKit.pulse(_chips[kind], 1.4, 0.2)
		Sound.ui("click")
	_show_talk(changed)


## Ratinho bloqueado sob o mouse: aparece apagado na janela com "Ainda não liberado!" (kind "" = volta ao marcado).
func _peek_locked(kind: String) -> void:
	if _accepting or kind == _peek:
		return
	_peek = kind
	_show_talk(false)


# --- janela de conversa -----------------------------------------------------------------------------------------------

func _show_talk(talk: bool) -> void:
	var kind := _peek if _peek != "" else _kind
	if kind == "":
		return
	_mouse.sprite_frames = TalkArt.frames(kind, GameState.current_planet)
	var fr := _mouse.sprite_frames.get_frame_texture(&"idle", 0)
	_mouse.position = Vector2(408.0 - 30.0 - fr.get_width(), 112.0 - 6.0 - fr.get_height())
	var cfr := _cat.sprite_frames.get_frame_texture(&"idle", 0)
	_cat.position = Vector2(22.0, 112.0 - 6.0 - cfr.get_height())
	for c in _pics.get_children():
		_pics.remove_child(c)
		c.queue_free()
	if _peek != "":                                            # bloqueado: silhueta + aviso
		UiKit.silhouette(_mouse, Color("#3e3546"))
		_mouse.play(&"idle")
		_ask.text = "Ainda não liberado!"
		_rule.text = "Junte estrelas para liberar."
		_cat.play(&"idle")
		_cat_balloon.visible = false
		_columns.modulate.a = 0.0                              # some sem mudar o tamanho da janela
		_accept.disabled = true
		_set_gain_visible(false)
		_place_balloons()
		return
	_mouse.material = null
	_columns.modulate.a = 1.0
	_set_gain_visible(true)
	var i := selected_offer()
	var info := _run.offer_info(i, _gas_left)
	var m: Dictionary = info["mission"]
	_ask.text = MissionText.ask(m)
	_rule.text = MissionText.say_rule(m)
	var pics: Array = MissionIntro.PICS.get(MissionText._key(m) if MissionText._key(m) != "taxi" else "passenger",
			["box", ""])
	if str(m["kind"]) == "simple":
		pics = ["box", ""]
	for p: int in 2:
		if str(pics[p]) == "":
			continue
		var pic := TextureRect.new()
		pic.texture = CargoArt.tex(str(pics[p]))
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pics.add_child(pic)
		var mark := TextureRect.new()
		mark.texture = _cut("check" if p == 0 else "cross", CUT_MARK)
		mark.custom_minimum_size = Vector2(10, 10)
		mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mark.size_flags_vertical = Control.SIZE_SHRINK_END
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pics.add_child(mark)
	if talk:
		_mouse.play(&"talk")
		_talk_left = 0.7
	elif _mouse.animation != &"talk":
		_mouse.play(&"idle")
	var worried := not bool(info["reachable"])
	_cat.play(&"worried" if worried else &"idle")
	_cat_balloon.visible = worried
	_cat_say.text = "Hmm... acho que a gasolina não dá!"
	_accept.disabled = false
	_total.text = "+" + EconMath.fmt(info["pay_typical"])
	_fill_rep()
	_fill_columns()
	_place_balloons()
	_update_chip(_kind)


## "Você ganha" + moeda + valor (some no ratinho bloqueado, que nao tem premio).
func _set_gain_visible(on: bool) -> void:
	for n: CanvasItem in [%Gain, %Coin, _total]:
		n.visible = on
	%RepTag.visible = on and _run != null and _run.rep_level(_kind) > 0
	%RepBadge.visible = %RepTag.visible


## Reputacao com o ratinho escolhido (v14): coracao + bonus no "Voce ganha" (so com nivel >= 1).
func _fill_rep() -> void:
	var lv := _run.rep_level(_kind)
	%RepBadge.texture = UiKit.kid("heart_on")
	%RepTag.text = "+%d%%" % roundi((EconMath.reputation_mult(lv) - 1.0) * 100.0)
	%RepBadge.tooltip_text = "reputação com este ratinho: nível %d de %d" % [lv, EconMath.reputation_levels().size()]
	for n: CanvasItem in [%RepBadge, %RepTag]:
		n.visible = lv > 0


## Balao do ratinho encostado nele (direita, meio da cabeca); balao do gatinho no alto, do lado do capacete.
func _place_balloons() -> void:
	_mouse_balloon.reset_size()
	_mouse_balloon.size = _mouse_balloon.get_combined_minimum_size()
	_mouse_balloon.position = Vector2(_mouse.position.x - 6.0 - _mouse_balloon.size.x, 40.0)
	_mouse_balloon.queue_redraw()
	_cat_balloon.reset_size()
	_cat_balloon.size = _cat_balloon.get_combined_minimum_size()
	var cfr := _cat.sprite_frames.get_frame_texture(&"idle", 0)
	_cat_balloon.position = Vector2(_cat.position.x + cfr.get_width() - 2.0, 4.0)
	_cat_balloon.queue_redraw()


## Colunas de escolha: Distancia (se o ratinho tem mais de 1 pedido) | Tamanho da plataforma | Dificuldade (se ha
## mais de 1 estrela). Clicar so marca; partir e no ACEITAR MISSAO.
func _fill_columns() -> void:
	for c in _columns.get_children():
		_columns.remove_child(c)
		c.queue_free()
	_option_buttons.clear()
	var i := selected_offer()
	var info := _run.offer_info(i, _gas_left)
	var g: Array = _groups[_kind]
	if g.size() > 1:
		var opts: Array = []
		for d in g.size():
			var name: String = DIST_NAMES[0 if d == 0 else (DIST_NAMES.size() - 1 if d == g.size() - 1 else 1)]
			var ok: bool = _run.offer_info(int(g[d]), _gas_left)["reachable"]
			if not ok and d != int(_dsel[_kind]) and GameState.apprentice():
				continue                                       # aprendiz nao ve "falta gas" (auditoria M1)
			opts.append({"key": "dist:%d" % d, "text": name, "on": d == int(_dsel[_kind]), "ok": ok,
					"do": _choose_dist.bind(d)})
		_add_column("Distância", opts)
	var opts_t: Array = []
	for t: String in TIERS:
		opts_t.append({"key": "tier:" + t, "text": str(TIER_NAMES.get(t, EconMath.pad_tier(t)["name"])), "on": t == info["tier"], "ok": true,
				"do": _choose.bind(t, int(info["mission"]["star"]))})
	_add_column("Tamanho da plataforma", opts_t)
	var stars: Array[int] = _run.stars_for(i)
	if stars.size() > 1:
		var opts_s: Array = []
		for st: int in stars:
			opts_s.append({"key": "star:%d" % st, "stars": st, "on": st == int(info["mission"]["star"]), "ok": true,
					"do": _choose.bind(str(info["tier"]), st)})
		_add_column("Dificuldade", opts_s)


func _add_column(title: String, opts: Array) -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", 2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lab := Label.new()
	lab.text = title
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.add_theme_color_override(&"font_color", UiKit.color("lemon"))
	col.add_child(lab)
	for o: Dictionary in opts:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = OPTION
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if o["on"]:
			b.theme_type_variation = &"PrimaryButton"
			var frame := Panel.new()
			frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
			frame.add_theme_stylebox_override(&"panel", UiKit.gold_frame())
			b.add_child(frame)
		if o.has("stars"):
			var row := HBoxContainer.new()
			row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override(&"separation", -4)
			for k in int(o["stars"]):
				var s := TextureRect.new()
				s.texture = _cut("star_on", CUT_STAR)
				s.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
				s.mouse_filter = Control.MOUSE_FILTER_IGNORE
				row.add_child(s)
			b.add_child(row)
		else:
			b.text = str(o["text"])
			if not o["ok"]:                                    # o gas pode nao dar: diz o motivo, em cor de alerta legivel
				b.text += ": falta gás"
				for c: StringName in [&"font_color", &"font_hover_color", &"font_focus_color", &"font_pressed_color"]:
					b.add_theme_color_override(c, UiKit.color("crimson") if o["on"] else UiKit.color("peach"))
		b.pressed.connect(o["do"])
		col.add_child(b)
		_option_buttons[o["key"]] = b
	_columns.add_child(col)


## Parte r de uma celula do atlas kids.
func _cut(name: String, r: Rect2) -> AtlasTexture:
	var base := UiKit.kid(name) as AtlasTexture
	var at := AtlasTexture.new()
	at.atlas = base.atlas
	at.region = Rect2(base.region.position + r.position, r.size)
	return at


# --- escolhas ---------------------------------------------------------------------------------------------------------

## Aplica plataforma e estrela no pedido marcado (e guarda como ultima escolha do tipo).
func _choose(tier: String, star: int) -> void:
	if _run == null or _accepting or _kind == "" or _peek != "":
		return
	var i := selected_offer()
	_run.set_choice(i, tier, star)
	_remember()
	Sound.ui("click")
	_show_talk(false)


## Troca a distancia do ratinho marcado, levando junto a plataforma e a estrela escolhidas.
func _choose_dist(d: int) -> void:
	if _run == null or _accepting or _kind == "" or _peek != "":
		return
	var g: Array = _groups[_kind]
	d = clampi(d, 0, g.size() - 1)
	var old := _run.offer_info(selected_offer(), _gas_left)
	_dsel[_kind] = d
	_run.set_choice(int(g[d]), str(old["tier"]), int(old["mission"]["star"]))
	_remember()
	Sound.ui("click")
	_show_talk(false)


func _remember() -> void:
	var info := _run.offer_info(selected_offer(), _gas_left)
	last_choice[_kind] = [str(info["tier"]), int(info["mission"]["star"]), int(_dsel.get(_kind, 0))]


func _on_accept() -> void:
	if _accepting or _peek != "" or selected_offer() < 0:
		return
	_accepting = true
	_remember()
	var i := selected_offer()
	_cat.play(&"thumb")
	_mouse.play(&"happy")
	_cat_say.text = "Deixa comigo!"
	_cat_balloon.visible = true
	_ask.text = "Obaaa!"
	_rule_row.visible = false
	_dots.visible = false
	_place_balloons()
	await get_tree().create_timer(ACCEPT_S).timeout
	_rule_row.visible = true
	_dots.visible = true
	if visible and _accepting:
		offer_chosen.emit(i)


## Muda de ratinho na fila (so os liberados), no sentido step.
func _step_kind(step: int) -> void:
	var open: Array[String] = []
	for k in _kinds:
		if _groups.has(k):
			open.append(k)
	if open.is_empty():
		return
	var j := open.find(_kind)
	_select(open[clampi(j + step, 0, open.size() - 1)])


## Setas, 1..3 e Enter antes do aviso de pilotar (cima/esquerda/direita tambem sao teclas da nave).
func _input(event: InputEvent) -> void:
	if not visible or _kind == "" or _accepting:
		return
	if event.is_action_pressed(&"ui_left") or event.is_action_pressed(&"ui_right"):
		get_viewport().set_input_as_handled()
		_step_kind(-1 if event.is_action_pressed(&"ui_left") else 1)
	elif event.is_action_pressed(&"ui_up") or event.is_action_pressed(&"ui_down"):
		get_viewport().set_input_as_handled()
		var step := 1 if event.is_action_pressed(&"ui_up") else -1
		var info := _run.offer_info(selected_offer(), _gas_left)
		if event is InputEventKey and (event as InputEventKey).shift_pressed:
			var stars: Array[int] = _run.stars_for(selected_offer())
			var j := stars.find(int(info["mission"]["star"]))
			if stars.size() > 1:
				_choose(str(info["tier"]), stars[clampi(j + step, 0, stars.size() - 1)])
		else:
			var t := TIERS.find(str(info["tier"]))
			_choose(TIERS[clampi(t - step, 0, TIERS.size() - 1)], int(info["mission"]["star"]))
	elif event.is_action_pressed(&"ui_accept"):
		get_viewport().set_input_as_handled()
		_on_accept()
	elif event is InputEventKey and event.pressed and not event.echo:
		var k: int = (event as InputEventKey).keycode
		var n := -1
		if k >= KEY_1 and k <= KEY_3:
			n = k - KEY_1
		elif k >= KEY_KP_1 and k <= KEY_KP_3:
			n = k - KEY_KP_1                                   # teclado numerico tambem vale
		if n >= 0 and n < (_groups[_kind] as Array).size():
			get_viewport().set_input_as_handled()
			_choose_dist(n)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"end_run"):
		get_viewport().set_input_as_handled()
		if end_armed > 0.0:
			end_armed = 0.0
			end_requested.emit()
		else:
			end_armed = 2.0
	elif event.is_action_pressed(&"thrust") or event.is_action_pressed(&"rotate_left") \
			or event.is_action_pressed(&"rotate_right"):
		hint_flash = 2.0                                       # tentou pilotar antes de aceitar: avisa
