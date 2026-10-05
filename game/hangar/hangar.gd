## Hangar entre runs (arte: UiKit, cor de destaque do mundo atual). Abas: NAVE (upgrades, padrao), AJUDAS (arvore do
## Painel de bordo: ajudas de voo compradas uma vez, ligar/desligar), MUNDOS (planetas),
## PRESTIGIO (recomeco + loja da Poeira); a Expedicao (meta final) fica fixa no topo. Esc (sem botao na tela) pede o menu do
## jogo (menu_requested: a Main esconde o hangar e abre o PauseMenu no modo HANGAR — volumes, menu inicial, novo jogo).
## Q/E trocam de aba, Enter decola (ou ativa o botao com foco, se o jogador navegou com setas/Tab). Tudo que e numero
## vem de GameState/EconMath. As linhas sao refeitas a cada refresh(): botoes levam meta "focus_key" para o foco do
## teclado sobreviver, e linhas levam "row_key" para o brilho de compra (UiKit.pulse).
class_name Hangar
extends PanelContainer

signal launch_requested
## Voltar ao menu inicial (contrato mantido; hoje o pedido sai do menu do jogo, PauseMenu.title_requested).
signal title_requested
## Esc: abrir o menu do jogo fora do hangar.
signal menu_requested

enum Tab { SHIP, ASSISTS, WORLDS, PRESTIGE }

const UNITS := {"thrust": "m/s2", "tank": "gás", "efficiency": "m/s/gás", "pay_mult": "×", "gear": "×",
		"drones": "", "autopilot": "×"}
const ICONS := {"thrust": "thrust", "tank": "tank", "efficiency": "efficiency", "contracts": "reputation",
		"gear": "gear", "fleet": "fleet", "autopilot": "autopilot"}
const RES := {"credits": ["credits", "MoneyLabel"], "ore": ["ore", "ValueLabel"], "stardust": ["stardust", "DustLabel"]}
const TAB_INFO := [[Tab.SHIP, "NAVE", "thrust"], [Tab.ASSISTS, "AJUDAS", "distance"], [Tab.WORLDS, "MUNDOS", "planet"], [Tab.PRESTIGE, "PRESTÍGIO", "prestige"]]
## Larguras das colunas das tabelas (px da arte) — iguais em todas as abas para alinhar.
const COL_LEVEL := 40
const COL_EFFECT := 118
const COL_ACTION := 120
const COL_MAX := 30
## Oficina: cartoes de cada lado da nave (de cima para baixo) e onde cada um encosta no sprite 32x32 da nave.
const WORKSHOP_SIDES := [["contracts", "tank", "thrust"], ["fleet", "autopilot", "efficiency", "gear"]]
const WORKSHOP_ANCHORS := {"contracts": Vector2(10, 2), "tank": Vector2(4, 17),
		"thrust": Vector2(16, 22), "fleet": Vector2(24, 3), "autopilot": Vector2(16, 9), "efficiency": Vector2(28, 17),
		"gear": Vector2(27, 25)}
## Efeito de cada melhoria em figura (atlas kids): antes > depois.
const WORKSHOP_FX := {"thrust": ["flame_s", "flame_b"], "tank": ["bar_s", "bar_b"], "efficiency": ["drop_b", "drop_s"],
		"contracts": ["coin", "coins"], "gear": ["pad_s", "pad_b"],
		"fleet": ["drone", "drones"], "autopilot": ["drone", "drone_coin"]}
const CARD_W := 176
## O que cada habilidade faz (tooltip do botao; a tecla vem do mapa de teclas).
const ABILITY_TIP := {"stabilizer": "a nave volta a ficar de pé sozinha", "turbo": "motor com o dobro da força"}
## Arvore de ajudas (aba AJUDAS): galhos na ordem da spec (upgrades com 'assist' = galho); a Setinha vem de graca
## na frente do galho "nav". Icone de cada galho e o que cada ajuda faz (tooltip).
const ASSIST_BRANCH_ICON := {"nav": "distance", "land": "quality", "gas": "gas"}
const ASSIST_TIP := {
	"nav_arrow": "uma setinha perto da nave aponta para onde pousar",
	"nav_color": "a setinha muda de cor: azul longe, amarela no meio, verde chegando",
	"nav_trail": "pontinhos mostram o melhor caminho logo à frente",
	"nav_route": "pontinhos mostram o melhor caminho inteiro, de plataforma a plataforma",
	"land_shadow": "uma sombra no chão mostra a altura da nave",
	"land_level": "perto do chão, uma linha mostra se a nave está reta (verde) ou torta (vermelha)",
	"land_predict": "mostra onde a nave cai se soltar o motor: X verde = pouso bom",
	"gas_need": "uma marquinha na barra mostra quanto gás sobra ao chegar",
}
const ASSIST_CARD_W := 112
const SHIP_SCALE := 4.0
const REACH_CAP_M := 1.0e6                                     # limite da busca de Purchases.max_reach_m

var _tab := Tab.SHIP
var _confirm_prestige := false
## Ultima interacao foi teclado/controle: refresh() devolve o foco ao mesmo botao (senao, ao DECOLAR).
var _keyboard_nav := false
## Linha que acabou de ser comprada (brilha no proximo refresh) e se o saldo mudou.
var _flash_row := ""
var _flash_money := false

@onready var _planet: Label = %Planet
@onready var _resources: HBoxContainer = %Resources
@onready var _ship: HBoxContainer = %Ship
@onready var _expedition: HBoxContainer = %Expedition
@onready var _tabs: HBoxContainer = %Tabs
@onready var _scroll: ScrollContainer = %Scroll
@onready var _rows: VBoxContainer = %Rows
@onready var _launch: Button = %Launch


func _ready() -> void:
	_launch.pressed.connect(func() -> void: launch_requested.emit())
	launch_requested.connect(func() -> void: Sound.ui("click"))


## Mostra o hangar atualizado, na aba NAVE (o que se compra a cada visita).
func open() -> void:
	_confirm_prestige = false
	_tab = Tab.SHIP
	visible = true
	refresh()
	if not _launch.disabled:
		_launch.grab_focus()


func refresh() -> void:
	var focus_key := _focused_key()
	var planet := GameState.current_planet
	theme = UiKit.theme_for(planet)                            # a cor do hangar acompanha o mundo atual
	_planet.text = _planet_name(planet) + ("   ·   SANDBOX: nada é salvo" if Sandbox.active() else "")
	_fill_resources()
	_fill_ship(planet)
	_ship.visible = true
	_clear(_rows)
	if GameState.prestige_pending:
		_tabs.visible = false
		_expedition.visible = false
		_add_pending_prestige()
		_after_rebuild(focus_key)
		return
	var launchable := Purchases.can_launch(planet, GameState.ship_stats())
	_launch.disabled = not launchable
	_launch.icon = UiKit.kid("ship") if launchable else null   # botao principal: navezinha (sem precisar ler)
	_launch.text = "DECOLAR!  [Enter]" if launchable else "nave fraca para este mundo: melhore a nave ou troque em MUNDOS"
	if _tab == Tab.PRESTIGE and not _prestige_unlocked():
		_tab = Tab.SHIP
	_fill_expedition()
	_fill_tabs()
	_ship.visible = _tab != Tab.SHIP                            # na oficina a nave e o alcance ficam no meio
	match _tab:
		Tab.SHIP:
			_add_upgrades()
		Tab.ASSISTS:
			_add_assists()
		Tab.WORLDS:
			_add_worlds()
		Tab.PRESTIGE:
			_add_prestige()
	_after_rebuild(focus_key)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey or event is InputEventJoypadButton:
		_keyboard_nav = true
	elif event is InputEventMouseButton:
		_keyboard_nav = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"confirm"):
		get_viewport().set_input_as_handled()
		if not _launch.disabled:
			launch_requested.emit()
	elif event.is_action_pressed(&"ui_cancel"):                # com recomeco pendente tambem: opcoes/menu/sair
		get_viewport().set_input_as_handled()
		if _confirm_prestige:                                  # Esc primeiro desiste da confirmacao pendente
			_confirm_prestige = false
			Sound.ui("click")
			refresh()
		else:
			_request_menu()
	elif (event.is_action_pressed(&"tab_prev") or event.is_action_pressed(&"tab_next")) and not event.is_echo() \
			and not GameState.prestige_pending:                # Q/E ou LB/RB
		get_viewport().set_input_as_handled()
		_cycle_tab(-1 if event.is_action_pressed(&"tab_prev") else 1)


# --- cabecalho ---------------------------------------------------------------------------------------------------

func _fill_resources() -> void:
	_clear(_resources)
	if _flash_money:
		_flash_money = false
		UiKit.pulse(_resources, 1.5)
	var money := UiKit.icon_label("credits", EconMath.fmt(GameState.amount("credits")), &"MoneyLabel")
	(money.get_child(1) as Label).add_theme_font_size_override(&"font_size", UiKit.TITLE_SIZE)   # moedas em destaque
	(money.get_child(0) as TextureRect).custom_minimum_size = Vector2(12, 22)
	_resources.add_child(money)
	if GameState.amount("ore") > 0.0:
		_resources.add_child(UiKit.icon_label("ore", EconMath.fmt(GameState.amount("ore")), &"ValueLabel"))
	var dust_id: String = EconMath.spec["prestige"]["resource"]
	if GameState.amount(dust_id) > 0.0:
		_resources.add_child(UiKit.icon_label("stardust", EconMath.fmt(GameState.amount(dust_id)), &"DustLabel"))


func _fill_ship(planet: String) -> void:
	var s := GameState.ship_stats()
	var reach := Purchases.max_reach_m(planet, s, float(s["tank"]))
	var reach_txt := "> %s" % EconMath.fmt(REACH_CAP_M) if reach >= REACH_CAP_M * 0.99 else "~%s" % EconMath.fmt(reach)
	_clear(_ship)
	_ship.add_child(UiKit.icon_label("thrust", "motor %s m/s2" % _num(s["thrust"])))   # mesmo formato da tabela
	_ship.add_child(UiKit.icon_label("tank", "gasolina %s gás" % _num(s["tank"])))
	_ship.add_child(UiKit.icon_label("efficiency", "eficiência %s m/s/gás" % _num(s["efficiency"])))
	_ship.add_child(UiKit.icon_label("distance", "alcance máx %s m" % reach_txt))


## Expedicao ao Quarto (meta final), fixa no topo: barra (gradiente de meta) + proxima etapa e seu botao.
func _fill_expedition() -> void:
	_clear(_expedition)
	var stages := GameState.upgrade_rows().filter(func(r: Dictionary) -> bool: return _is_stage(str(r["id"])))
	var done := _stages_done()
	_expedition.visible = not stages.is_empty() or done > 0
	if not _expedition.visible:
		return
	var total := 0
	for u: Dictionary in EconMath.spec["upgrades"]:
		if u.get("progress", false):
			total += 1
	_expedition.add_child(_section("EXPEDIÇÃO AO QUARTO"))
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(90, 8)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.max_value = total
	bar.value = done
	_expedition.add_child(bar)
	var n := Label.new()
	n.text = "%d/%d" % [done, total]
	n.theme_type_variation = &"ValueLabel"
	_expedition.add_child(n)
	var next := Label.new()
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next.clip_text = true
	next.theme_type_variation = &"DimLabel"
	_expedition.add_child(next)
	if stages.is_empty():
		next.text = "completa"
		return
	var r: Dictionary = stages[0]
	next.text = _stage_title(str(r["name"]))
	next.tooltip_text = "%s\n%s > %s %s" % [r["name"], _num(r["current"]), _num(r["next"]), UNITS.get(r["stat"], "")]
	next.mouse_filter = Control.MOUSE_FILTER_PASS
	_expedition.add_child(_buy_button(r, COL_ACTION + COL_MAX + 4))


func _fill_tabs() -> void:
	_clear(_tabs)
	_tabs.visible = true
	for info: Array in TAB_INFO:
		var t: Tab = info[0]
		var b := Button.new()
		if t == Tab.PRESTIGE and not _prestige_unlocked():    # existe, mas com cadeado ate chegar ao mundo exigido
			b.focus_mode = Control.FOCUS_NONE
			b.icon = UiKit.icon(info[2])
			b.text = str(info[1])
			b.disabled = true
			b.custom_minimum_size = Vector2(70, 15)
			b.tooltip_text = "libera quando você chegar a " + _planet_title(
					str(EconMath.spec["prestige"].get("requires_planet", "")))
			_tabs.add_child(b)
			continue
		b.focus_mode = Control.FOCUS_NONE
		b.icon = UiKit.icon(info[2])
		b.custom_minimum_size = Vector2(70, 15)
		var news := t != _tab and _tab_has_news(t)
		b.text = str(info[1]) + (" !" if news else "")
		if t == _tab:
			b.theme_type_variation = &"PrimaryButton"          # aba atual: destaque cheio
		elif news:                                             # algo compravel em outra aba: texto dourado
			for c: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color"]:
				b.add_theme_color_override(c, UiKit.color("gold"))
		b.pressed.connect(func() -> void: _set_tab(t))
		_tabs.add_child(b)
	var hint := Label.new()
	hint.text = "Q/E troca de aba"
	hint.theme_type_variation = &"DimLabel"
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_tabs.add_child(hint)


func _set_tab(t: Tab) -> void:
	if t == _tab:
		return
	Sound.ui("click")
	_tab = t
	_confirm_prestige = false
	refresh()
	_scroll.scroll_vertical = 0


func _cycle_tab(step: int) -> void:
	var order: Array[Tab] = [Tab.SHIP, Tab.ASSISTS, Tab.WORLDS]
	if _prestige_unlocked():
		order.append(Tab.PRESTIGE)
	var i := order.find(_tab)
	_set_tab(order[posmod((0 if i < 0 else i) + step, order.size())])


func _request_menu() -> void:
	_confirm_prestige = false
	menu_requested.emit()


func _tab_has_news(t: Tab) -> bool:
	match t:
		Tab.SHIP:
			return GameState.upgrade_rows().any(func(r: Dictionary) -> bool:
				return r["affordable"] and not _is_stage(str(r["id"])) and not _is_assist(str(r["id"])))
		Tab.ASSISTS:
			return GameState.upgrade_rows().any(func(r: Dictionary) -> bool:
				return r["affordable"] and _is_assist(str(r["id"])))
		Tab.WORLDS:
			return GameState.planet_rows().any(func(p: Dictionary) -> bool:
				return not p["unlocked"] and p["available"] and p["affordable"])
		Tab.PRESTIGE:
			var st := GameState.prestige_state()
			return Prestige.can_prestige(st) or Prestige.shop_rows(st).any(func(r: Dictionary) -> bool:
				return r["affordable"])
	return false


# --- aba NAVE ----------------------------------------------------------------------------------------------------

func _add_upgrades() -> void:
	_add_workshop()


## Oficina (2026-10-05, interface "para criancas"): a nave grande no meio e cada melhoria num cartao ligado por um
## tracejado a peca dela (motor embaixo, pezinhos na perna...). Nivel = numero + barrinha ate o proximo marco;
## botao de preco verde quando da para comprar. Os numeros tecnicos ficam no tooltip do cartao.
func _add_workshop() -> void:
	var rows := GameState.upgrade_rows().filter(func(r: Dictionary) -> bool:
		return not _is_stage(str(r["id"])) and not _is_ability(str(r["id"])) and not _is_assist(str(r["id"])))
	var by_id := {}
	for r: Dictionary in rows:
		by_id[r["id"]] = r
	for r: Dictionary in GameState.locked_upgrades():          # o que vem pela frente: apagado, com cadeado
		r["locked"] = true
		rows.append(r)
		by_id[r["id"]] = r
	var shop := HBoxContainer.new()
	shop.add_theme_constant_override(&"separation", 6)
	shop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var cols: Array[VBoxContainer] = []
	var stage := Control.new()
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in 2:
		var col := VBoxContainer.new()
		col.add_theme_constant_override(&"separation", 3)     # 4 cartoes com nome por lado cabem na tela
		col.custom_minimum_size = Vector2(CARD_W, 0)
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		cols.append(col)
	shop.add_child(cols[0])
	shop.add_child(stage)
	shop.add_child(cols[1])
	# cada melhoria no lado preferido (WORKSHOP_SIDES); a que nao esta no mapa vai para o lado mais curto; depois
	# equilibra os lados (no maximo 1 de diferenca) para nunca passar da altura da tela
	var sides: Array = [[], []]
	for side in 2:
		for id: String in WORKSHOP_SIDES[side]:
			if by_id.has(id):
				sides[side].append(id)
	for r: Dictionary in rows:
		if not (sides[0].has(r["id"]) or sides[1].has(r["id"])):
			sides[0 if sides[0].size() <= sides[1].size() else 1].append(r["id"])
	while absi(sides[0].size() - sides[1].size()) > 1:
		var big := 0 if sides[0].size() > sides[1].size() else 1
		sides[1 - big].append(sides[big].pop_back())
	var cards := {}
	for side in 2:
		for id: String in sides[side]:
			var card := _make_locked_card(by_id[id]) if by_id[id].get("locked", false) else _make_card(by_id[id])
			cols[side].add_child(card)
			cards[id] = card
	var ship := TextureRect.new()
	var at := AtlasTexture.new()
	at.atlas = load("res://assets/sprites/lander.png")
	at.region = Rect2(0, 0, 32, 32)
	ship.texture = at
	ship.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ship.stretch_mode = TextureRect.STRETCH_SCALE
	ship.size = Vector2(32, 32) * SHIP_SCALE
	ship.pivot_offset = ship.size * 0.5
	ship.name = "Ship"
	stage.add_child(ship)
	var s := GameState.ship_stats()
	var reach := Purchases.max_reach_m(GameState.current_planet, s, float(s["tank"]))
	var reach_row := UiKit.icon_label("distance", "%s m" % (("> " + EconMath.fmt(REACH_CAP_M))
			if reach >= REACH_CAP_M * 0.99 else EconMath.fmt(reach)), &"ValueLabel")
	reach_row.name = "Reach"
	stage.add_child(reach_row)
	var abilities := _ability_row()
	stage.add_child(abilities)
	stage.resized.connect(func() -> void:
		ship.position = ((stage.size - ship.size) * 0.5 - Vector2(0, 10)).round()
		reach_row.position = Vector2(roundf((stage.size.x - reach_row.get_combined_minimum_size().x) * 0.5),
				ship.position.y + ship.size.y + 6)
		abilities.position = Vector2(roundf((stage.size.x - abilities.get_combined_minimum_size().x) * 0.5),
				reach_row.position.y + 14)
		stage.queue_redraw())
	stage.draw.connect(_draw_links.bind(stage, ship, cards))
	for card: Control in cards.values():                       # cartoes centralizados mudam de lugar depois
		card.item_rect_changed.connect(stage.queue_redraw)
	_rows.add_child(shop)
	if _flash_row.begins_with("up:"):                          # comprou: a nave da um pulinho
		var tw := ship.create_tween()
		tw.tween_property(ship, "scale", Vector2(1.12, 0.9), 0.08)
		tw.tween_property(ship, "scale", Vector2(0.95, 1.08), 0.1)
		tw.tween_property(ship, "scale", Vector2.ONE, 0.12)


func _is_ability(id: String) -> bool:
	var u := EconMath._find("upgrades", id)
	return bool(u.get("ability", false)) and not u.has("assist")


func _is_assist(id: String) -> bool:
	return EconMath._find("upgrades", id).has("assist")


## Habilidades (2026-10-05): botoes com a figura embaixo da nave. Sem comprar: preco (cheio e "respirando" quando
## da). Comprada: a tecla que usa (nao e convencao de jogo: precisa aparecer). Tooltip explica.
func _ability_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Abilities"
	row.add_theme_constant_override(&"separation", 4)
	var rows := {}
	for r: Dictionary in GameState.upgrade_rows():
		rows[r["id"]] = r
	for u: Dictionary in EconMath.spec["upgrades"]:
		if not u.get("ability", false) or u.has("assist"):
			continue
		var id: String = u["id"]
		var b := Button.new()
		b.icon = CargoArt.tex(id)
		b.custom_minimum_size = Vector2(0, 20)
		b.set_meta(&"focus_key", "ability:" + id)
		var keys := WorldConfig.current_keys(id if id != "stabilizer" else "stabilize")
		var key_txt := WorldConfig.key_label(keys[0]) if not keys.is_empty() else ""
		b.tooltip_text = "%s: %s" % [u["name"], ABILITY_TIP.get(id, "")]
		if int(GameState.levels.get(id, 0)) >= int(u.get("max_level", 1)):
			b.text = key_txt
			b.tooltip_text += "\nsegure %s no voo" % key_txt
			b.focus_mode = Control.FOCUS_NONE
		elif rows.has(id):
			var r: Dictionary = rows[id]
			b.text = EconMath.fmt(float(r["cost"].get("credits", 0.0)))
			b.disabled = not r["affordable"]
			if r["affordable"]:
				b.theme_type_variation = &"PrimaryButton"
				var tw := b.create_tween().set_loops()
				tw.tween_property(b, "modulate", Color(1.25, 1.25, 1.25), 0.45).set_trans(Tween.TRANS_SINE)
				tw.tween_property(b, "modulate", Color.WHITE, 0.45).set_trans(Tween.TRANS_SINE)
			b.pressed.connect(func() -> void:
				_bought(GameState.buy_upgrade(id), "up:" + id, id, 0))
		else:
			continue
		row.add_child(b)
	return row


## Tracejado do cartao ate a peca da nave (pontos em WORKSHOP_ANCHORS, coordenadas do sprite 32x32).
func _draw_links(stage: Control, ship: TextureRect, cards: Dictionary) -> void:
	var inv := stage.get_global_transform().affine_inverse()
	var c := UiKit.color("mist")
	for id: String in cards:
		var card: Control = cards[id]
		if not is_instance_valid(card):
			continue
		var r := card.get_global_rect()
		var left_side := r.position.x < stage.get_global_rect().position.x
		var from := inv * Vector2(r.end.x if left_side else r.position.x, r.get_center().y)
		var to := ship.position + (WORKSHOP_ANCHORS.get(id, Vector2(16, 16)) as Vector2) * SHIP_SCALE
		var steps := int(from.distance_to(to) / 5.0)
		for i in steps:
			if i % 2 == 0:
				var p := from.lerp(to, float(i) / steps).round()
				stage.draw_rect(Rect2(p, Vector2(2, 2)), c)
		stage.draw_rect(Rect2(to.round() - Vector2(2, 2), Vector2(4, 4)), UiKit.color("gold"))


## Cartao de melhoria: nome do atributo + nivel | icone da peca | figura antes > depois | barrinha ate a estrela do
## marco; botao de preco + MAX. Os numeros ficam no tooltip.
func _make_card(r: Dictionary) -> PanelContainer:
	var id: String = r["id"]
	var card := PanelContainer.new()
	card.theme_type_variation = &"SlimPanel"                   # margens finas: cabem 4 cartoes por lado
	card.set_meta(&"row_key", "up:" + id)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.tooltip_text = "%s (nível %d)\nagora %s  >  depois %s %s" % [r["name"], int(r["level"]), _num(r["current"]),
			_num(r["next"]), UNITS.get(r["stat"], "")]
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 0)
	card.add_child(box)
	# nome de atributo + nivel (usuario, 2026-10-05: "motor, gasolina..."), encaixado sobre a borda de cima como
	# etiqueta: ocupa so 6 px de altura para 4 cartoes por lado caberem na tela
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, 6)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(holder)
	var title := Label.new()
	title.text = "%s  %d" % [r["name"], int(r["level"])]
	title.theme_type_variation = &"DimLabel"
	title.position = Vector2(2, -6)
	var tag := StyleBoxFlat.new()                              # fundo da cor do painel: a etiqueta "corta" a borda
	tag.bg_color = UiKit.color("deep", GameState.current_planet)
	tag.content_margin_left = 2
	tag.content_margin_right = 2
	title.add_theme_stylebox_override(&"normal", tag)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(title)
	var top := HBoxContainer.new()
	top.add_theme_constant_override(&"separation", 5)
	box.add_child(top)
	var ic := TextureRect.new()
	ic.texture = UiKit.icon(ICONS.get(id, "options"))
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_SCALE
	ic.custom_minimum_size = Vector2(24, 24)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(ic)
	# efeito em figura (antes > depois), sem texto: uma crianca de 6 anos entende olhando (usuario, 2026-10-05)
	var fx: Array = WORKSHOP_FX.get(id, [])
	for i in fx.size():
		if i == 1:
			top.add_child(_kid_rect("arrow"))
		var pic := _kid_rect(fx[i])
		top.add_child(pic)
		if i == 1:                                             # o "depois" pula de leve, chamando o olho
			pic.pivot_offset = Vector2(12, 12)
			var tw := pic.create_tween().set_loops()
			tw.tween_property(pic, "scale", Vector2(1.15, 1.15), 0.4).set_trans(Tween.TRANS_SINE)
			tw.tween_property(pic, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_SINE)
	var pad := Control.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(pad)
	var ms: Dictionary = r["milestone"]
	if not ms.is_empty():                                      # barrinha ate a estrela do proximo marco (premio ×N)
		var every := _milestone_every(id)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.theme_type_variation = &"XpBar"
		bar.custom_minimum_size = Vector2(30, 6)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.max_value = every
		bar.value = every - (int(ms["level"]) - int(r["level"]))
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top.add_child(bar)
		var star := _kid_rect("star_on")
		star.custom_minimum_size = Vector2(14, 24)
		top.add_child(star)
		card.tooltip_text += "\nno nível %d ganha um prêmio: ×%s" % [int(ms["level"]), str(ms["mult"])]
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override(&"separation", 3)
	box.add_child(bottom)
	var buy := _buy_button(r, 0)
	buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy.custom_minimum_size = Vector2(0, 16)
	if r["affordable"]:                                        # da para comprar: botao cheio que "respira"
		buy.theme_type_variation = &"PrimaryButton"
		var tw := buy.create_tween().set_loops()
		tw.tween_property(buy, "modulate", Color(1.25, 1.25, 1.25), 0.45).set_trans(Tween.TRANS_SINE)
		tw.tween_property(buy, "modulate", Color.WHITE, 0.45).set_trans(Tween.TRANS_SINE)
	bottom.add_child(buy)
	var mx := Button.new()
	mx.text = "MÁX"
	mx.tooltip_text = "comprar o máximo de níveis possível"
	mx.custom_minimum_size = Vector2(COL_MAX, 16)
	mx.disabled = not r["affordable"]
	mx.set_meta(&"focus_key", "max:" + id)
	mx.pressed.connect(func() -> void:
		var before := int(GameState.levels.get(id, 0))
		_bought(GameState.buy_upgrade_max(id) > 0, "up:" + id, id, before))
	bottom.add_child(mx)
	return card


## Cartao de melhoria que ainda vai liberar: mesmo formato do normal, apagado, com cadeado e o que falta.
## Exige planeta -> mostra o nome e o planeta; exige item da loja da Poeira -> "???" (surpresa).
func _make_locked_card(r: Dictionary) -> PanelContainer:
	var id: String = r["id"]
	var need_planet: String = r["requires_planet"]
	var surprise := need_planet.is_empty()
	var card := PanelContainer.new()
	card.theme_type_variation = &"SlimPanel"
	card.modulate = Color(0.6, 0.6, 0.68)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.tooltip_text = ("algo novo! libera com a Poeira Estelar" if surprise
			else "%s: libera quando você chegar a %s" % [r["name"], _planet_title(need_planet)])
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 0)
	card.add_child(box)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, 6)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(holder)
	var title := Label.new()
	title.text = "???" if surprise else str(r["name"])
	title.theme_type_variation = &"DimLabel"
	title.position = Vector2(2, -6)
	var tag := StyleBoxFlat.new()
	tag.bg_color = UiKit.color("deep", GameState.current_planet)
	tag.content_margin_left = 2
	tag.content_margin_right = 2
	title.add_theme_stylebox_override(&"normal", tag)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(title)
	var top := HBoxContainer.new()
	top.add_theme_constant_override(&"separation", 5)
	box.add_child(top)
	var ic := TextureRect.new()
	ic.texture = UiKit.icon(ICONS.get(id, "options"))
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_SCALE
	ic.custom_minimum_size = Vector2(24, 24)
	ic.modulate = Color.BLACK if surprise else Color.WHITE  # surpresa: so a silhueta da peca
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(ic)
	top.add_child(_kid_rect("lock"))
	top.add_child(_kid_rect("mystery" if surprise else "arrow"))
	if not surprise:                                           # cadeado -> planeta: "chegue la"
		var pl := TextureRect.new()
		pl.texture = UiKit.icon("planet")
		pl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pl.stretch_mode = TextureRect.STRETCH_SCALE
		pl.custom_minimum_size = Vector2(24, 24)
		pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top.add_child(pl)
	var b := Button.new()
	b.disabled = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 16)
	b.icon = UiKit.icon("stardust" if surprise else "planet")
	b.text = "???" if surprise else "chegue a " + _planet_title(need_planet)
	box.add_child(b)
	return card


## Nome curto do planeta para frases ("Silvânia (floresta fechada)" -> "Silvânia").
func _planet_title(id: String) -> String:
	for p: Dictionary in EconMath.spec["planets"]:
		if p["id"] == id:
			return str(p["name"]).get_slice(" (", 0)
	return id


func _kid_rect(name: String) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = UiKit.kid(name)
	tr.custom_minimum_size = Vector2(24, 24)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


func _milestone_every(id: String) -> int:
	for m: Dictionary in EconMath._find("upgrades", id).get("milestones", []):
		return int(m["every"])
	return 25


## Botao de compra de 1 nivel: icone do recurso principal + custo (largura fixa para alinhar a coluna).
func _buy_button(r: Dictionary, width: int) -> Button:
	var id: String = r["id"]
	var buy := Button.new()
	var cost_txt := []
	for res: String in r["cost"]:
		cost_txt.append(EconMath.fmt(float(r["cost"][res])) + ("" if res == "credits" else " " + _res_label(res)))
	buy.text = " + ".join(cost_txt)
	buy.icon = UiKit.icon(RES.get(r["cost"].keys()[0], ["credits"])[0]) if not (r["cost"] as Dictionary).is_empty() else null
	buy.custom_minimum_size = Vector2(width, 15)
	buy.clip_text = true
	buy.tooltip_text = "comprar 1 nível: " + buy.text + _missing_text(r["cost"])
	buy.alignment = HORIZONTAL_ALIGNMENT_LEFT
	buy.disabled = not r["affordable"]
	buy.set_meta(&"focus_key", "buy:" + id)
	buy.pressed.connect(func() -> void:
		var before := int(GameState.levels.get(id, 0))
		_bought(GameState.buy_upgrade(id), "up:" + id, id, before))
	return buy


# --- aba AJUDAS (Painel de bordo, 2026-10-05) ----------------------------------------------------------------------

## Arvore de ajudas de voo: um galho por linha (icone do galho + cartoes ligados por setas, da esquerda para a direita).
## Cartao = nome + figurinha do que a ajuda desenha no voo + botao: preco (da para comprar), LIGADA/DESLIGADA (ja tem:
## clicar alterna) ou apagado com "..." (falta a anterior). Compra unica que nao reseta no prestigio.
func _add_assists() -> void:
	var rows := {}
	for r: Dictionary in GameState.upgrade_rows():
		rows[r["id"]] = r
	var branches := {}
	var order: Array[String] = []
	for u: Dictionary in EconMath.spec["upgrades"]:
		if not u.has("assist"):
			continue
		var b := str(u["assist"])
		if not branches.has(b):
			branches[b] = [GameState.ASSIST_FREE] if b == "nav" else []
			order.append(b)
		branches[b].append(u)
	_rows.add_child(_section("AJUDAS DE VOO  ·  compra uma vez, fica para sempre"))
	for b: String in order:
		var line := HBoxContainer.new()
		line.add_theme_constant_override(&"separation", 2)
		line.alignment = BoxContainer.ALIGNMENT_BEGIN
		var ic := TextureRect.new()
		ic.texture = UiKit.icon(ASSIST_BRANCH_ICON.get(b, "options"))
		ic.custom_minimum_size = Vector2(14, 0)
		ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		line.add_child(ic)
		var first := true
		for item: Variant in branches[b]:
			if not first:
				line.add_child(_kid_rect("arrow"))
			first = false
			line.add_child(_make_assist_card(item, rows))
		_rows.add_child(line)


## item = id da ajuda gratis (String) ou o upgrade da spec (Dictionary).
func _make_assist_card(item: Variant, rows: Dictionary) -> PanelContainer:
	var free := item is String
	var id: String = item if free else str(item["id"])
	var name: String = "Setinha" if free else str(item["name"])
	var owned := free or int(GameState.levels.get(id, 0)) >= 1
	var on := GameState.assist_on(id)
	var can_buy := not owned and rows.has(id)
	var card := PanelContainer.new()
	card.theme_type_variation = &"SlimPanel"
	card.custom_minimum_size = Vector2(ASSIST_CARD_W, 0)
	card.set_meta(&"row_key", "up:" + id)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.tooltip_text = "%s: %s" % [name, ASSIST_TIP.get(id, "")]
	if not owned and not can_buy:
		card.modulate = Color(0.6, 0.6, 0.68)
		card.tooltip_text += "
compre a ajuda anterior primeiro"
	elif owned and not on:
		card.modulate = Color(0.75, 0.75, 0.8)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 1)
	card.add_child(box)
	var title := Label.new()
	title.text = name
	title.theme_type_variation = &"GoodLabel" if owned and on else &"DimLabel"
	title.clip_text = true
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var pic := AssistIcon.new(id)
	pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(pic)
	var btn: Button
	if owned:
		btn = Button.new()
		btn.text = "LIGADA" if on else "DESLIGADA"
		btn.tooltip_text = "clique para %s" % ("desligar (mais desafio)" if on else "ligar")
		btn.set_meta(&"focus_key", "assist:" + id)
		btn.pressed.connect(func() -> void:
			GameState.set_assist(id, not on)
			Sound.ui("click")
			refresh())
	elif can_buy:
		btn = _buy_button(rows[id], 0)
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.tooltip_text = "comprar: " + btn.text + _missing_text(rows[id]["cost"])
		if rows[id]["affordable"]:
			btn.theme_type_variation = &"PrimaryButton"
			var tw := btn.create_tween().set_loops()
			tw.tween_property(btn, "modulate", Color(1.25, 1.25, 1.25), 0.45).set_trans(Tween.TRANS_SINE)
			tw.tween_property(btn, "modulate", Color.WHITE, 0.45).set_trans(Tween.TRANS_SINE)
	else:
		btn = Button.new()
		btn.text = "..."
		btn.disabled = true
		btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 15)
	box.add_child(btn)
	return card


# --- aba MUNDOS --------------------------------------------------------------------------------------------------

func _add_worlds() -> void:
	_rows.add_child(_header_row(["MUNDO", "GRAVIDADE", "PAGAMENTO", ""],
			[0, COL_LEVEL + 34, COL_EFFECT - 34, COL_ACTION + COL_MAX + 4]))
	var prev := ""
	for p: Dictionary in GameState.planet_rows():
		if p["unlocked"] or p["available"]:
			_rows.add_child(_make_planet_row(p))
		else:                                                  # o que vem pela frente: cadeado (o Quarto = destino final)
			_rows.add_child(_make_locked_planet_row(p, prev))
		prev = p["id"]
	var note := Label.new()
	note.text = "Mundos novos pagam muito mais, mas a gravidade gasta mais gás: compre Motor e Gasolina antes."
	note.theme_type_variation = &"DimLabel"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rows.add_child(note)


## Linha de mundo: icone | nome | gravidade | pagamento | acao (aqui / voar / liberar com custo).
func _make_planet_row(p: Dictionary) -> HBoxContainer:
	var id: String = p["id"]
	var here := id == GameState.current_planet
	var row := _table_row("planet", str(p["name"]), &"GoodLabel" if here else &"")
	row.set_meta(&"row_key", "planet:" + id)
	row.add_child(_cell("%.2f" % float(p["gravity"]), COL_LEVEL + 34, &"ValueLabel"))
	row.add_child(_cell("×%s" % EconMath.fmt(float(p["pay_mult"])), COL_EFFECT - 34, &"MoneyLabel"))
	if here:
		var ok: bool = p["can_launch"]
		row.add_child(_cell("VOCÊ ESTÁ AQUI" if ok else "AQUI: nave fraca", COL_ACTION + COL_MAX + 4,
				&"GoodLabel" if ok else &"BadLabel"))
		return row
	var b := Button.new()
	b.custom_minimum_size = Vector2(COL_ACTION + COL_MAX + 4, 15)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.set_meta(&"focus_key", "planet:" + id)
	if p["unlocked"]:
		b.icon = UiKit.icon("distance")
		if p["can_launch"]:
			b.text = "Voar para cá"
			b.tooltip_text = "a próxima decolagem será neste mundo"
			b.pressed.connect(func() -> void:
				Sound.ui("click")
				GameState.current_planet = id
				_flash_row = "planet:" + id
				refresh())
		elif not p["can_fly"]:
			b.text = "motor fraco: compre Motor"
			b.tooltip_text = "o motor ainda não vence a gravidade deste mundo"
			b.disabled = true
		else:
			b.text = "alcance curto: compre Gasolina"
			b.tooltip_text = "com o tanque cheio a nave ainda não chega à entrega mais curta deste mundo"
			b.disabled = true
	else:
		var cost_txt := []
		for res: String in p["cost"]:
			cost_txt.append("%s %s" % [EconMath.fmt(float(p["cost"][res])), _res_label(res)])
		b.icon = UiKit.icon("credits")
		b.text = "Liberar  " + " + ".join(cost_txt)
		b.tooltip_text = "liberar " + str(p["name"]) + _missing_text(p["cost"])
		b.disabled = not p["affordable"]
		b.pressed.connect(func() -> void:
			_bought(GameState.unlock_planet(id), "planet:" + id))
	row.add_child(b)
	return row


## Mundo ainda bloqueado: nome apagado, "?" no lugar dos numeros e o que falta (o mundo anterior). O ultimo mundo
## (objetivo do jogo, targets.goal) aparece marcado como destino final desde o comeco.
func _make_locked_planet_row(p: Dictionary, prev: String) -> HBoxContainer:
	var id: String = p["id"]
	var goal := id == str(EconMath.spec["targets"]["goal"].get("planet", ""))
	var row := _table_row("planet", str(p["name"]), &"DimLabel")
	row.set_meta(&"row_key", "planet:" + id)
	row.modulate = Color(0.7, 0.7, 0.78)
	row.add_child(_cell("?", COL_LEVEL + 34, &"DimLabel"))
	row.add_child(_cell("?", COL_EFFECT - 34, &"DimLabel"))
	var b := Button.new()
	b.custom_minimum_size = Vector2(COL_ACTION + COL_MAX + 4, 15)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.disabled = true
	b.focus_mode = Control.FOCUS_NONE
	b.icon = UiKit.kid("lock")
	b.add_theme_constant_override(&"icon_max_width", 12)      # cadeado 24x24 do atlas kids cabe na linha
	if goal:
		b.text = "DESTINO FINAL"
		b.tooltip_text = "o fim da jornada: termine a Expedição ao Quarto"
		row.modulate = Color.WHITE
		b.add_theme_color_override(&"font_disabled_color", UiKit.color("gold"))
	else:
		b.text = "depois de " + _planet_title(prev)
		b.tooltip_text = "libera depois de chegar a " + _planet_title(prev)
	row.add_child(b)
	return row


# --- aba PRESTIGIO -----------------------------------------------------------------------------------------------

func _prestige_unlocked() -> bool:
	var req: String = EconMath.spec["prestige"].get("requires_planet", "")
	return GameState.prestige_points > 0.0 or req in GameState.unlocked_planets


func _add_prestige() -> void:
	var dust_id: String = EconMath.spec["prestige"]["resource"]
	var bonus := 0.0
	for b: Dictionary in EconMath.spec["prestige"]["bonuses"]:
		if b["stat"] == "pay_mult":
			bonus = float(b["per_point"]) * GameState.prestige_points * 100.0
	_rows.add_child(UiKit.icon_label("prestige", "nível de prestígio %s   (+%d%% pagamento para sempre)" % [
			EconMath.fmt(GameState.prestige_points), int(bonus)], &"DustLabel"))
	var how := Label.new()
	how.text = "Recomeçar zera créditos, upgrades e mundos, mas rende Poeira Estelar: ela sobe o nível de prestígio e compra melhorias permanentes na loja."
	how.theme_type_variation = &"DimLabel"
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rows.add_child(how)
	var st := GameState.prestige_state()
	var g := Prestige.gain(st)
	var b := Button.new()
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.icon = UiKit.icon("stardust")
	b.set_meta(&"focus_key", "prestige")
	if Prestige.can_prestige(st):
		if _confirm_prestige:                                  # 2o clique apaga o ciclo: texto de perigo
			b.theme_type_variation = &"DangerButton"
		else:                                                  # destaque so na cor: DECOLAR segue o unico principal
			for c: StringName in [&"font_color", &"font_hover_color", &"font_focus_color"]:
				b.add_theme_color_override(c, UiKit.color("lavender"))
		b.text = ("Recomeçar do zero por +%s Poeira? Clique de novo  (Esc cancela)" if _confirm_prestige
				else "Recomeçar agora: +%s Poeira Estelar") % EconMath.fmt(g)
		b.pressed.connect(func() -> void:
			Sound.ui("click")
			if _confirm_prestige:
				_confirm_prestige = false
				GameState.begin_prestige()
			else:
				_confirm_prestige = true
			refresh())
	else:
		b.text = "Recomeçar: +%s Poeira agora (mínimo %s); ganhe mais créditos" % [
				EconMath.fmt(g), EconMath.fmt(float(EconMath.spec["prestige"].get("min_gain", 1)))]
		b.disabled = true
	_rows.add_child(b)
	if GameState.prestige_points > 0.0 or GameState.amount(dust_id) > 0.0:
		_add_shop(st)
	if GameState.reached_goal:                                 # pos-jogo: recordes pessoais
		for row: Control in Ending.record_rows():
			_rows.add_child(row)


## Recomeco em andamento: so a loja + concluir (o reset usa o que foi comprado).
func _add_pending_prestige() -> void:
	_launch.disabled = true
	_launch.text = "conclua o recomeço para decolar"
	_launch.release_focus()                                    # sem foco: Enter nao conclui o recomeco por acidente
	var head := Label.new()
	head.text = "RECOMEÇO: gaste sua Poeira Estelar na loja e conclua. O progresso comum será zerado."
	head.theme_type_variation = &"DustLabel"
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rows.add_child(head)
	_add_shop(GameState.prestige_state())
	var done := Button.new()
	done.text = "CONCLUIR RECOMEÇO"
	done.theme_type_variation = &"PrimaryButton"
	done.set_meta(&"focus_key", "finish_prestige")
	done.pressed.connect(func() -> void:
		Sound.ui("click")
		GameState.finish_prestige()
		refresh())
	_rows.add_child(done)


## Loja da Poeira em tabela: icone | item | nivel | custo.
func _add_shop(st: Dictionary) -> void:
	var dust_id: String = EconMath.spec["prestige"]["resource"]
	_rows.add_child(_section("LOJA DA POEIRA   (%s disponível)" % EconMath.fmt(GameState.amount(dust_id))))
	for r: Dictionary in Prestige.shop_rows(st):
		var row := _table_row("prestige", str(r["name"]))
		row.set_meta(&"row_key", "shop:" + str(r["id"]))
		row.add_child(_cell("MÁX" if r["maxed"] else "nv %d/%d" % [int(r["level"]), int(r["max_level"])],
				COL_LEVEL + 10, &"DimLabel"))
		var sb := Button.new()
		sb.custom_minimum_size = Vector2(COL_ACTION + COL_MAX + 4, 15)
		sb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		sb.icon = UiKit.icon("stardust")
		sb.text = "comprado" if r["maxed"] else "%s poeira" % EconMath.fmt(float(r["cost"]))
		sb.disabled = not r["affordable"]
		var id: String = r["id"]
		sb.set_meta(&"focus_key", "shop:" + id)
		if not r["maxed"]:
			sb.tooltip_text = "%s poeira" % EconMath.fmt(float(r["cost"])) + _missing_text({dust_id: float(r["cost"])})
		sb.pressed.connect(func() -> void:
			_bought(GameState.buy_shop_item(id), "shop:" + id))
		row.add_child(sb)
		_rows.add_child(row)


# --- utilitarios -------------------------------------------------------------------------------------------------

## Resultado de uma compra: som, brilho na linha e no saldo (feedback imediato) e tela atualizada.
## Resultado de uma compra: som (jingle se passou um marco ou etapa da Expedicao), brilho na linha e no saldo.
func _bought(ok: bool, row_key: String, upgrade_id: String = "", before: int = 0) -> void:
	Sound.ui("buy" if ok else "denied")
	if ok and upgrade_id != "" and Purchases.milestone_crossed(upgrade_id, before,
			int(GameState.levels.get(upgrade_id, 0))):
		Sound.jingle("milestone")
	if ok:
		_flash_row = row_key
		_flash_money = true
	refresh()


## " - faltam X cr" para o tooltip de um custo que ainda nao da para pagar (so leitura do saldo).
func _missing_text(cost: Dictionary) -> String:
	var parts := []
	for res: String in cost:
		var miss := float(cost[res]) - GameState.amount(res)
		if miss > 0.0:
			parts.append("%s %s" % [EconMath.fmt(miss), _res_label(res)])
	return "" if parts.is_empty() else "\nfaltam " + " + ".join(parts)


func _focused_key() -> String:
	var f := get_viewport().gui_get_focus_owner()
	if f != null and is_ancestor_of(f) and f.has_meta(&"focus_key"):
		return str(f.get_meta(&"focus_key"))
	return ""


## Depois de refazer as linhas: brilho da compra e foco (mesmo botao se o jogador usa teclado; senao DECOLAR).
func _after_rebuild(focus_key: String) -> void:
	for n: Node in _rows.find_children("*", "Control", true, false):
		if _flash_row != "" and n.get_meta(&"row_key", "") == _flash_row:
			UiKit.pulse(n as CanvasItem)
	_flash_row = ""
	if _keyboard_nav and focus_key != "":
		for b: Node in find_children("*", "Button", true, false):
			if b.get_meta(&"focus_key", "") == focus_key and not b.is_queued_for_deletion():
				(b as Button).grab_focus.call_deferred()
				return
	if not _launch.disabled and visible:
		_launch.grab_focus.call_deferred()
	elif visible:                                              # recomeco: cursor na loja (nunca no CONCLUIR)
		for b: Node in _rows.find_children("*", "Button", true, false):
			if not (b as Button).disabled and b.get_meta(&"focus_key", "") != "finish_prestige":
				(b as Button).grab_focus.call_deferred()
				return

## Comeco de uma linha de tabela: icone + nome (expande e corta se faltar espaco).
func _table_row(icon_name: String, title: String, variation: StringName = &"") -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 4)
	row.custom_minimum_size = Vector2(0, 15)                   # mesma altura com ou sem botao
	var ic := TextureRect.new()
	ic.texture = UiKit.icon(icon_name)
	ic.custom_minimum_size = Vector2(12, 12)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	row.add_child(ic)
	var name := Label.new()
	name.text = title
	name.tooltip_text = title
	name.mouse_filter = Control.MOUSE_FILTER_PASS                # nome cortado: o tooltip mostra inteiro
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.clip_text = true
	if variation != &"":
		name.theme_type_variation = variation
	row.add_child(name)
	return row


## Cabecalho de tabela (rotulos apagados alinhados as colunas de _make_row).
func _header_row(titles: Array, widths: Array = [0, COL_LEVEL, COL_EFFECT, COL_ACTION + COL_MAX + 4]) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 4)
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(12, 0)
	row.add_child(pad)
	for i in titles.size():
		var l := _cell(str(titles[i]), widths[i], &"SectionLabel")
		if i == 0:
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
	return row


func _cell(text: String, width: int, variation: StringName) -> Label:
	var l := Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(width, 0)
	l.theme_type_variation = variation
	return l


func _section(title: String) -> Label:
	var l := Label.new()
	l.text = title
	l.theme_type_variation = &"SectionLabel"
	return l


func _clear(box: Node) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func _planet_name(id: String) -> String:
	for p: Dictionary in EconMath.spec["planets"]:
		if p["id"] == id:
			return str(p["name"]).to_upper()
	return id.to_upper()


## "Expedição ao Quarto 3/8: Escudo Térmico Ablativo" -> "próxima: Escudo Térmico Ablativo"
func _stage_title(full: String) -> String:
	var i := full.find(":")
	return "próxima: " + (full.substr(i + 1).strip_edges() if i >= 0 else full)


func _is_stage(id: String) -> bool:
	for u: Dictionary in EconMath.spec["upgrades"]:
		if u["id"] == id:
			return bool(u.get("progress", false))
	return false


func _stages_done() -> int:
	var n := 0
	for u: Dictionary in EconMath.spec["upgrades"]:
		if u.get("progress", false) and int(GameState.levels.get(u["id"], 0)) > 0:
			n += 1
	return n


## Valor de stat: 2 casas abaixo de 10, 1 casa ate 1000 (sem ",0" em inteiros: "100 gás"), depois K/M/B.
func _num(v: float) -> String:
	if v >= 1000.0:
		return EconMath.fmt(v)
	if v < 10.0:
		return "%.2f" % v
	return str(int(v)) if is_equal_approx(v, roundf(v)) else "%.1f" % v


func _res_label(res: String) -> String:
	return {"credits": "cr", "ore": "minério", "stardust": "poeira"}.get(res, res)
