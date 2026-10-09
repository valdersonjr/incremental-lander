## Kit de interface (arte da skill pixel-art: art/src/ui/ui_kit.py -> assets/ui/, contrato ui_kit.json).
## Monta um Theme por mundo (cor de destaque muda com o planeta; fixos: fundo escuro, dourado = dinheiro,
## vermelho = perigo, ambar = gas acabando, barra de gas ciano). Fonte bitmap: tamanho 11 (1x) ou 22 (2x), nunca
## fracionario. Variacoes de tipo: SlimPanel, TitleLabel, SectionLabel, DimLabel, ValueLabel, MoneyLabel, DustLabel, BadLabel,
## PrimaryButton, DangerButton, GasBar, WarnBar, DangerBar, XpBar. Foco de teclado = moldura de 1 px na cor de titulo
## do mundo (toda tela navegavel por setas/Tab mostra onde esta). Widgets compartilhados: volume_row, toggle_row (crt_row, shake_row, fullscreen_row), key_row, stat_row, pulse.
class_name UiKit
extends RefCounted

const DIR := "res://assets/ui/"
const FONT_SIZE := 11
const TITLE_SIZE := 22
## Passo do volume nas opcoes (botoes - e +).
const VOLUME_STEP := 0.1
const BUS_NAMES := {"Master": "Geral", "Music": "Música", "Ambience": "Ambiente", "SFX": "Efeitos", "UI": "Interface"}
## Motivo da batida (LandingRules.crash_reason) em texto de jogador.
const CRASH_TEXT := {"mar": "caiu no mar (splash!)", "atingido": "atingido por um brinquedo", "fora_da_plataforma": "fora da plataforma", "vertical_rapido": "desceu rápido demais",
		"horizontal_rapido": "rápido demais de lado", "inclinado": "pousou inclinado"}
## Como acertar da proxima vez (aprendiz e resumo da batida; auditoria dos primeiros minutos A4).
const CRASH_TIP := {"vertical_rapido": "segure o motor perto do chão para descer devagar",
		"fora_da_plataforma": "pouse em cima da plataforma", "horizontal_rapido": "pare de ir de lado antes de pousar",
		"inclinado": "deixe a nave reta antes de tocar o chão", "sem_gas": "voe em arco, sem ficar parado no ar"}
## Estados de interface dentro da paleta (bloqueado, silhueta, escurecer): ver set_locked/silhouette/dim_rect.
const FX_SHADER := preload("res://game/screen/palette_fx.gdshader")

static var _meta: Dictionary = {}
static var _themes: Dictionary = {}
static var _icons: Dictionary = {}
static var _kids: Dictionary = {}
static var _kids_meta: Dictionary = {}
static var _fx: Dictionary = {}                 # materiais do palette_fx por modo+cor (compartilhados)


## Solta os caches estaticos (chamado na saida do jogo; senao o Godot acusa recursos vivos no fim).
static func clear_cache() -> void:
	_themes.clear()
	_icons.clear()
	_kids.clear()
	_kids_meta.clear()
	_fx.clear()
	_meta.clear()


static func meta() -> Dictionary:
	if _meta.is_empty():
		_meta = JSON.parse_string(FileAccess.get_file_as_string(DIR + "ui_kit.json"))
	return _meta


## Cor do contrato (nome da paleta usado pela UI, ex. "gold") ou do mundo ("accent", "title", "base", "deep").
static func color(name: String, world: String = "luna") -> Color:
	var w: Dictionary = meta()["worlds"].get(world, meta()["worlds"]["luna"])
	if w.has(name):
		return Color(str(w[name]))
	return Color(str(meta()["colors"][name]))


## Icone 12x12 do atlas (nomes em ui_kit.json -> icons.names).
static func icon(name: String) -> Texture2D:
	if _icons.has(name):
		return _icons[name]
	var names: Array = meta()["icons"]["names"]
	var size := int(meta()["icons"]["size"])
	var at := AtlasTexture.new()
	at.atlas = load(DIR + "icons.png")
	at.region = Rect2(names.find(name) * size, 0, size, size)
	_icons[name] = at
	return at


static func theme_for(world: String) -> Theme:
	if not meta()["worlds"].has(world):
		world = "luna"
	if _themes.has(world):
		return _themes[world]
	var t := Theme.new()
	var font := load(DIR + "font.fnt") as FontFile
	font.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	t.default_font = font
	t.default_font_size = FONT_SIZE
	var wd := DIR + world + "/"
	# paineis
	var panel := _box(wd + "panel.png", 8, Vector4(8, 6, 8, 6), true)
	for type: StringName in [&"PanelContainer", &"Panel"]:
		t.set_stylebox(&"panel", type, panel)
	# painel fino (uma linha de texto: dica de teclas no HUD)
	t.set_type_variation(&"SlimPanel", &"PanelContainer")
	t.set_stylebox(&"panel", &"SlimPanel", _box(wd + "panel.png", 8, Vector4(6, 2, 6, 2), true))
	# balao de fala do ratinho (creme em todo mundo; rabinho = balloon_tail.png, posto a esquerda pelo cartao)
	t.set_type_variation(&"Balloon", &"PanelContainer")
	t.set_stylebox(&"panel", &"Balloon", _box(DIR + "balloon.png", 5, Vector4(5, 2, 5, 3)))
	# textos (sombra de 1 px escura para ler sobre qualquer cenario)
	t.set_color(&"font_color", &"Label", color("mist"))
	t.set_color(&"font_shadow_color", &"Label", color("ink"))
	t.set_constant(&"shadow_offset_x", &"Label", 1)
	t.set_constant(&"shadow_offset_y", &"Label", 1)
	_label_var(t, &"TitleLabel", color("title", world), TITLE_SIZE)
	_label_var(t, &"SectionLabel", color("accent", world))
	_label_var(t, &"DimLabel", color("steel"))           # steel: contraste 5,4:1 no painel (lilac_grey dava 2,8)
	_label_var(t, &"ValueLabel", color("white"))
	_label_var(t, &"MoneyLabel", color("gold"))
	_label_var(t, &"BigMoneyLabel", color("gold"), TITLE_SIZE)     # numero principal (placar de recordes)
	_label_var(t, &"BigValueLabel", color("white"), TITLE_SIZE)
	_label_var(t, &"DustLabel", color("lavender"))
	_label_var(t, &"BadLabel", color("red"))
	_label_var(t, &"GoodLabel", color("leaf"))
	_label_var(t, &"BalloonLabel", color("ink"))
	t.set_color(&"font_shadow_color", &"BalloonLabel", Color(0, 0, 0, 0))
	# botoes (4 estados) + principal
	var m := Vector4(6, 3, 6, 3)
	t.set_stylebox(&"normal", &"Button", _box(wd + "button_normal.png", 6, m))
	t.set_stylebox(&"hover", &"Button", _box(wd + "button_hover.png", 6, m))
	t.set_stylebox(&"pressed", &"Button", _box(wd + "button_pressed.png", 6, m + Vector4(0, 1, 0, -1)))
	t.set_stylebox(&"disabled", &"Button", _box(wd + "button_disabled.png", 6, m))
	var focus := _focus_box(color("title", world))
	t.set_stylebox(&"focus", &"Button", focus)
	t.set_color(&"font_color", &"Button", color("white"))
	t.set_color(&"font_hover_color", &"Button", color("white"))
	t.set_color(&"font_pressed_color", &"Button", color("mist"))
	t.set_color(&"font_focus_color", &"Button", color("white"))
	t.set_color(&"font_disabled_color", &"Button", color("steel"))     # slate sumia no fundo do desabilitado (1,7:1)
	t.set_color(&"font_shadow_color", &"Button", color("ink"))
	t.set_constant(&"shadow_offset_x", &"Button", 1)
	t.set_constant(&"shadow_offset_y", &"Button", 1)
	t.set_constant(&"h_separation", &"Button", 3)
	t.set_type_variation(&"PrimaryButton", &"Button")
	t.set_stylebox(&"normal", &"PrimaryButton", _box(wd + "button_primary.png", 6, m))
	t.set_stylebox(&"hover", &"PrimaryButton", _box(wd + "button_primary_hover.png", 6, m))
	t.set_stylebox(&"pressed", &"PrimaryButton", _box(wd + "button_primary.png", 6, m + Vector4(0, 1, 0, -1)))
	t.set_stylebox(&"focus", &"PrimaryButton", _focus_box(color("white")))
	t.set_color(&"font_color", &"PrimaryButton", color("ink"))
	t.set_color(&"font_hover_color", &"PrimaryButton", color("ink"))
	t.set_color(&"font_focus_color", &"PrimaryButton", color("ink"))
	t.set_color(&"font_pressed_color", &"PrimaryButton", color("ink"))
	t.set_color(&"font_shadow_color", &"PrimaryButton", Color(0, 0, 0, 0))
	t.set_color(&"font_disabled_color", &"PrimaryButton", color("steel"))
	# partir (VOAR, DECOLAR, ACEITAR MISSAO): botao principal recolorido em verde, texto branco
	t.set_type_variation(&"GoButton", &"Button")
	var go := wd + "button_go.png" if ResourceLoader.exists(wd + "button_go.png") else DIR + "luna/button_go.png"
	var go_hover := go.replace("button_go.png", "button_go_hover.png")
	t.set_stylebox(&"normal", &"GoButton", _box(go, 6, m))
	t.set_stylebox(&"hover", &"GoButton", _box(go_hover, 6, m))
	t.set_stylebox(&"pressed", &"GoButton", _box(go, 6, m + Vector4(0, 1, 0, -1)))
	t.set_stylebox(&"focus", &"GoButton", _focus_box(color("white")))
	# acao destrutiva (apagar progresso, recomecar): botao vinho (art/src/ui/button_danger.py), texto branco
	t.set_type_variation(&"DangerButton", &"Button")
	var danger := DIR + "luna/button_danger.png"
	t.set_stylebox(&"normal", &"DangerButton", _box(danger, 6, m))
	t.set_stylebox(&"hover", &"DangerButton", _box(DIR + "luna/button_danger_hover.png", 6, m))
	t.set_stylebox(&"pressed", &"DangerButton", _box(danger, 6, m + Vector4(0, 1, 0, -1)))
	# barras
	t.set_stylebox(&"background", &"ProgressBar", _box(DIR + "bar_bg.png", 3, Vector4.ZERO))
	t.set_stylebox(&"fill", &"ProgressBar", _box(wd + "bar_fill.png", 3, Vector4.ZERO))
	t.set_constant(&"outline_size", &"ProgressBar", 0)
	for v: Array in [[&"GasBar", "bar_gas.png"], [&"WarnBar", "bar_warn.png"], [&"DangerBar", "bar_danger.png"],
			[&"XpBar", "bar_xp.png"]]:
		t.set_type_variation(v[0], &"ProgressBar")
		t.set_stylebox(&"fill", v[0], _box(DIR + str(v[1]), 3, Vector4.ZERO))
	# rolagem discreta, com a arte das barras (trilho escuro + puxador na cor do mundo)
	t.set_constant(&"scrollbar_h_separation", &"ScrollContainer", 4)
	for sb_type: StringName in [&"VScrollBar", &"HScrollBar"]:
		t.set_stylebox(&"scroll", sb_type, _box(DIR + "bar_bg.png", 3, Vector4.ZERO))
		t.set_stylebox(&"scroll_focus", sb_type, _box(DIR + "bar_bg.png", 3, Vector4.ZERO))
		for g: StringName in [&"grabber", &"grabber_highlight", &"grabber_pressed"]:
			t.set_stylebox(g, sb_type, _box(wd + "bar_fill.png", 3, Vector4.ZERO))
	# dicas (tooltip) no mesmo painel e fonte do jogo
	t.set_stylebox(&"panel", &"TooltipPanel", _box(wd + "panel.png", 8, Vector4(6, 4, 6, 4), true))
	t.set_color(&"font_color", &"TooltipLabel", color("mist"))
	t.set_color(&"font_shadow_color", &"TooltipLabel", color("ink"))
	t.set_constant(&"shadow_offset_x", &"TooltipLabel", 1)
	t.set_constant(&"shadow_offset_y", &"TooltipLabel", 1)
	_themes[world] = t
	return t


## Peca 24x24 do atlas da interface "para criancas" (assets/ui/kids.png, contrato kids.json): pinos dos pedidos,
## rostinhos dos clientes (rat, bunny, alien, bear), estrelas de dificuldade, pilha de moedas, navezinha.
static func kid(name: String) -> Texture2D:
	if _kids.has(name):
		return _kids[name]
	if _kids_meta.is_empty():
		_kids_meta = JSON.parse_string(FileAccess.get_file_as_string(DIR + "kids.json"))
	var size := int(_kids_meta["size"])
	var at := AtlasTexture.new()
	at.atlas = load(DIR + "kids.png")
	at.region = Rect2((_kids_meta["names"] as Array).find(name) * size, 0, size, size)
	_kids[name] = at
	return at


## O atlas kids tem essa peca? (mundos novos usam "mystery" ate a arte chegar)
static func has_kid(name: String) -> bool:
	if _kids_meta.is_empty():
		_kids_meta = JSON.parse_string(FileAccess.get_file_as_string(DIR + "kids.json"))
	return (_kids_meta["names"] as Array).has(name)


## Linha "icone + texto" pronta (HBox) — usada pelas telas.
static func icon_label(icon_name: String, text: String, variation: StringName = &"") -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 3)
	var tr := TextureRect.new()
	tr.texture = icon(icon_name)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	tr.custom_minimum_size = Vector2(12, 12)
	row.add_child(tr)
	var l := Label.new()
	l.text = text
	if variation != &"":
		l.theme_type_variation = variation
	row.add_child(l)
	return row


## Linha de volume de um bus: nome | - | barra | + | %. Muda em passos de VOLUME_STEP, salva e toca o clique.
static func volume_row(bus: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 4)
	var name := Label.new()
	name.text = BUS_NAMES.get(bus, bus)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.custom_minimum_size = Vector2(56, 0)
	row.add_child(name)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(60, 8)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pct := Label.new()
	pct.custom_minimum_size = Vector2(30, 0)
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct.theme_type_variation = &"ValueLabel"
	var show := func() -> void:
		var v := GameState.volume(bus)
		bar.value = v * 100.0
		pct.text = "%d%%" % int(round(v * 100.0))
		pct.theme_type_variation = &"DimLabel" if v <= 0.0 else &"ValueLabel"
	for step: float in [-VOLUME_STEP, VOLUME_STEP]:
		var b := Button.new()
		b.text = "-" if step < 0.0 else "+"
		b.custom_minimum_size = Vector2(16, 15)
		b.tooltip_text = ("diminuir" if step < 0.0 else "aumentar") + " o volume (%s)" % name.text
		b.set_meta(&"focus_key", "vol%s:%s" % [b.text, bus])
		b.pressed.connect(func() -> void:
			GameState.set_volume(bus, snappedf(GameState.volume(bus) + step, VOLUME_STEP))
			SaveManager.request_save()
			Sound.preview(bus)                                 # amostra no proprio canal: ouve o volume novo
			show.call())
		row.add_child(b)
		if step < 0.0:
			row.add_child(bar)
	row.add_child(pct)
	show.call()
	return row


## Linha liga/desliga: nome | botao com o estado (alterna, salva e toca o clique). Igual no titulo e nos menus.
static func toggle_row(title: String, tooltip: String, focus_key: String, getter: Callable, setter: Callable,
		on_text: String = "Ligado", off_text: String = "Desligado") -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 4)
	var name := Label.new()
	name.text = title
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name)
	var b := Button.new()
	b.custom_minimum_size = Vector2(70, 15)
	b.tooltip_text = tooltip
	b.set_meta(&"focus_key", focus_key)
	var show := func() -> void:
		b.text = on_text if getter.call() else off_text
	b.pressed.connect(func() -> void:
		setter.call(not getter.call())
		SaveManager.request_save()
		Sound.ui("click")
		show.call())
	show.call()
	row.add_child(b)
	return row


## Linha "Filtro CRT" (efeito de TV de tubo).
static func crt_row() -> HBoxContainer:
	return toggle_row("Efeito TV antiga", "efeito de TV de tubo (linhas e brilho); desligue se preferir a imagem limpa", "crt",
			GameState.crt_enabled, GameState.set_crt)


## Linha "Tremor da tela" (batida e pouso duro sacodem a camera; desligue se incomodar).
static func shake_row() -> HBoxContainer:
	return toggle_row("Tremor da tela", "a câmera sacode na batida e em pousos duros; desligue se incomodar", "shake",
			GameState.shake_enabled, GameState.set_shake)


## Linha "Tela cheia" (tambem F11 ou Alt+Enter).
static func fullscreen_row() -> HBoxContainer:
	return toggle_row("Tela cheia", "ocupar a tela inteira (F11 ou Alt+Enter também alternam)", "fullscreen",
			GameState.fullscreen, GameState.set_fullscreen, "Ligada", "Desligada")


## Linha de controle remapeavel: o que faz | botao com a tecla principal (+ as outras, apagadas). Clicar (ou Enter)
## espera a proxima tecla; Esc desiste. A tecla escolhida sai de qualquer outra acao (GameState.remap_key).
static func key_row(action: String, title: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 4)
	var what := Label.new()
	what.text = title
	what.theme_type_variation = &"DimLabel"
	what.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(what)
	var b := Button.new()
	b.custom_minimum_size = Vector2(96, 13)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.set_meta(&"focus_key", "key:" + action)
	b.tooltip_text = "clique e aperte a nova tecla (Esc desiste)"
	var show := func() -> void:
		var names := GameState.keys_for(action).map(func(k: String) -> String: return WorldConfig.key_label(k))
		b.text = " / ".join(names) if not names.is_empty() else "(sem tecla)"
	b.pressed.connect(func() -> void:
		Sound.ui("click")
		b.set_meta(&"listening", true)
		b.text = "aperte uma tecla...")
	b.gui_input.connect(func(ev: InputEvent) -> void:
		if not b.get_meta(&"listening", false) or not ev is InputEventKey or not ev.pressed or ev.echo:
			return
		b.accept_event()
		b.set_meta(&"listening", false)
		var k := ev as InputEventKey
		if k.keycode != KEY_ESCAPE and k.physical_keycode != KEY_NONE:
			GameState.remap_key(action, OS.get_keycode_string(k.physical_keycode))
			SaveManager.request_save()
		Sound.ui("click")
		for r: Node in row.get_parent().get_children():           # outras linhas podem ter perdido a tecla
			if r.has_meta(&"refresh"):
				(r.get_meta(&"refresh") as Callable).call())
	b.focus_exited.connect(func() -> void:
		if b.get_meta(&"listening", false):
			b.set_meta(&"listening", false)
			show.call())
	row.set_meta(&"refresh", show)
	show.call()
	row.add_child(b)
	return row


## Linha de estatistica (resumo/final): icone | nome apagado | valor a direita.
static func stat_row(icon_name: String, title: String, value: String, variation: StringName = &"ValueLabel") -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 4)
	var tr := TextureRect.new()
	tr.texture = icon(icon_name) if icon_name != "" else null   # "" = sem icone, mas a coluna fica alinhada
	tr.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	tr.custom_minimum_size = Vector2(12, 12)
	row.add_child(tr)
	var l := Label.new()
	l.text = title
	l.theme_type_variation = &"DimLabel"
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var v := Label.new()
	v.text = value
	v.theme_type_variation = variation
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(v)
	return row


## Brilho curto (compra, ganho): o item clareia e volta ao normal.
## Moldura dourada de 1 px por fora (escolha atual: plataforma do cartao, ratinho da fila) — mesma cor do pino escolhido.
static func gold_frame() -> StyleBoxFlat:
	return _focus_box(color("gold"))


static func pulse(item: CanvasItem, strength: float = 1.7, seconds: float = 0.35) -> void:
	item.modulate = Color(strength, strength, strength)
	item.create_tween().tween_property(item, "modulate", Color.WHITE, seconds).set_trans(Tween.TRANS_QUAD) \
			.set_ease(Tween.EASE_OUT)


## Estado "bloqueado" dentro da paleta (shader palette_fx, modo rampa fria) no item e em todos os filhos ja criados.
## Substitui o modulate cinza (que gerava cores fora da Resurrect 64). on = false volta ao normal.
static func set_locked(item: CanvasItem, on: bool = true) -> void:
	item.material = _fx_material(1, Color.BLACK) if on else null
	for c in item.find_children("*", "CanvasItem", true, false):
		(c as CanvasItem).use_parent_material = on


## Silhueta de uma cor so da paleta (ex.: ratinho ainda nao liberado).
static func silhouette(item: CanvasItem, fill: Color) -> void:
	item.material = _fx_material(2, fill)


## Contorno externo de 1 px (cor da paleta) num sprite com margem transparente: o heroi nao some no cenario.
static func outline(item: CanvasItem, color_name: String = "white") -> void:
	item.material = _fx_material(4, color(color_name))


## Fantasma de 1 px em xadrez (metade dos pixels na cor fill): a nave pontilhada que mostra o movimento certo.
static func ghost(item: CanvasItem, color_name: String = "white") -> void:
	item.material = _fx_material(5, color(color_name))


## Escurecimento atras de janelas: xadrez de 1 px em ink (sem semitransparencia).
static func dim_rect(rect: CanvasItem) -> void:
	rect.material = _fx_material(3, Color.BLACK)


static func _fx_material(mode: int, fill: Color) -> ShaderMaterial:
	var key := "%d:%s" % [mode, fill.to_html(false)]
	if _fx.has(key):
		return _fx[key]
	var m := ShaderMaterial.new()
	_fx[key] = m
	m.shader = FX_SHADER
	m.set_shader_parameter(&"mode", mode)
	m.set_shader_parameter(&"fill", fill)
	return m


## Multiplicador para a tela: 1.5 -> "×1,5", 2.0 -> "×2" (virgula decimal, como o resto da interface).
static func mult_text(m: float) -> String:
	var s := ("%.1f" % m) if absf(m - roundf(m)) > 0.001 else str(int(roundf(m)))
	return "×" + s.replace(".", ",")


static func crash_text(reason: String) -> String:
	return CRASH_TEXT.get(reason, reason.replace("_", " "))


## Dica curta do jeito certo para um motivo de batida (ou "sem_gas"); "" se nao ha.
static func crash_tip(reason: String) -> String:
	return str(CRASH_TIP.get(reason, ""))


## Moldura de foco (teclado): 1 px fora do botao, sem preencher.
static func _focus_box(c: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.anti_aliasing = false
	sb.border_color = c
	sb.set_border_width_all(1)
	sb.set_expand_margin_all(1)
	return sb


static func _box(path: String, margin: int, content: Vector4, tile_center: bool = false) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load(path)
	sb.texture_margin_left = margin
	sb.texture_margin_top = margin if path.ends_with("panel.png") else (5 if path.find("button") >= 0 else margin)
	sb.texture_margin_right = margin
	sb.texture_margin_bottom = sb.texture_margin_top
	sb.content_margin_left = content.x
	sb.content_margin_top = content.y
	sb.content_margin_right = content.z
	sb.content_margin_bottom = content.w
	if tile_center:
		sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	return sb


static func _label_var(t: Theme, name: StringName, c: Color, size: int = FONT_SIZE) -> void:
	t.set_type_variation(name, &"Label")
	t.set_color(&"font_color", name, c)
	if size != FONT_SIZE:
		t.set_font_size(&"font_size", name, size)
