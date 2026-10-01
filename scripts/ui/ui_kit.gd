## Kit de interface (arte da skill pixel-art: art/src/ui/ui_kit.py -> assets/ui/, contrato ui_kit.json).
## Monta um Theme por mundo (cor de destaque muda com o planeta; fixos: fundo escuro, dourado = dinheiro,
## vermelho = perigo, ambar = gas acabando, barra de gas ciano). Fonte bitmap: tamanho 11 (1x) ou 22 (2x), nunca
## fracionario. Variacoes de tipo: TitleLabel, SectionLabel, DimLabel, ValueLabel, MoneyLabel, DustLabel, BadLabel,
## PrimaryButton, GasBar, WarnBar, DangerBar, XpBar.
class_name UiKit
extends RefCounted

const DIR := "res://assets/ui/"
const FONT_SIZE := 11
const TITLE_SIZE := 22

static var _meta: Dictionary = {}
static var _themes: Dictionary = {}
static var _icons: Dictionary = {}


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
	# textos (sombra de 1 px escura para ler sobre qualquer cenario)
	t.set_color(&"font_color", &"Label", color("mist"))
	t.set_color(&"font_shadow_color", &"Label", color("ink"))
	t.set_constant(&"shadow_offset_x", &"Label", 1)
	t.set_constant(&"shadow_offset_y", &"Label", 1)
	_label_var(t, &"TitleLabel", color("title", world), TITLE_SIZE)
	_label_var(t, &"SectionLabel", color("accent", world))
	_label_var(t, &"DimLabel", color("lilac_grey"))
	_label_var(t, &"ValueLabel", color("white"))
	_label_var(t, &"MoneyLabel", color("gold"))
	_label_var(t, &"DustLabel", color("lavender"))
	_label_var(t, &"BadLabel", color("red"))
	_label_var(t, &"GoodLabel", color("leaf"))
	# botoes (4 estados) + principal
	var m := Vector4(6, 3, 6, 3)
	t.set_stylebox(&"normal", &"Button", _box(wd + "button_normal.png", 6, m))
	t.set_stylebox(&"hover", &"Button", _box(wd + "button_hover.png", 6, m))
	t.set_stylebox(&"pressed", &"Button", _box(wd + "button_pressed.png", 6, m + Vector4(0, 1, 0, -1)))
	t.set_stylebox(&"disabled", &"Button", _box(wd + "button_disabled.png", 6, m))
	t.set_stylebox(&"focus", &"Button", StyleBoxEmpty.new())
	t.set_color(&"font_color", &"Button", color("white"))
	t.set_color(&"font_hover_color", &"Button", color("white"))
	t.set_color(&"font_pressed_color", &"Button", color("mist"))
	t.set_color(&"font_focus_color", &"Button", color("white"))
	t.set_color(&"font_disabled_color", &"Button", color("slate"))
	t.set_color(&"font_shadow_color", &"Button", color("ink"))
	t.set_constant(&"shadow_offset_x", &"Button", 1)
	t.set_constant(&"shadow_offset_y", &"Button", 1)
	t.set_constant(&"h_separation", &"Button", 3)
	t.set_type_variation(&"PrimaryButton", &"Button")
	t.set_stylebox(&"normal", &"PrimaryButton", _box(wd + "button_primary.png", 6, m))
	t.set_stylebox(&"hover", &"PrimaryButton", _box(wd + "button_primary_hover.png", 6, m))
	t.set_stylebox(&"focus", &"PrimaryButton", StyleBoxEmpty.new())
	t.set_color(&"font_color", &"PrimaryButton", color("ink"))
	t.set_color(&"font_hover_color", &"PrimaryButton", color("ink"))
	t.set_color(&"font_focus_color", &"PrimaryButton", color("ink"))
	t.set_color(&"font_shadow_color", &"PrimaryButton", Color(0, 0, 0, 0))
	# barras
	t.set_stylebox(&"background", &"ProgressBar", _box(DIR + "bar_bg.png", 3, Vector4.ZERO))
	t.set_stylebox(&"fill", &"ProgressBar", _box(wd + "bar_fill.png", 3, Vector4.ZERO))
	t.set_constant(&"outline_size", &"ProgressBar", 0)
	for v: Array in [[&"GasBar", "bar_gas.png"], [&"WarnBar", "bar_warn.png"], [&"DangerBar", "bar_danger.png"],
			[&"XpBar", "bar_xp.png"]]:
		t.set_type_variation(v[0], &"ProgressBar")
		t.set_stylebox(&"fill", v[0], _box(DIR + str(v[1]), 3, Vector4.ZERO))
	# rolagem discreta
	t.set_constant(&"scrollbar_h_separation", &"ScrollContainer", 4)
	_themes[world] = t
	return t


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
