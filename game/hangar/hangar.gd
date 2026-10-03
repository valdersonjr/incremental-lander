## Hangar entre runs (arte: UiKit, cor de destaque do mundo atual). Abas: NAVE (upgrades, padrao), MUNDOS (planetas),
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

enum Tab { SHIP, WORLDS, PRESTIGE }

const UNITS := {"thrust": "m/s2", "tank": "gás", "efficiency": "m/s/gás", "pay_mult": "×", "gear": "×",
		"drones": "", "autopilot": "×"}
const ICONS := {"thrust": "thrust", "tank": "tank", "efficiency": "efficiency", "contracts": "reputation",
		"gear": "gear", "refinery": "refinery", "fleet": "fleet", "autopilot": "autopilot"}
const RES := {"credits": ["credits", "MoneyLabel"], "ore": ["ore", "ValueLabel"], "stardust": ["stardust", "DustLabel"]}
const TAB_INFO := [[Tab.SHIP, "NAVE", "thrust"], [Tab.WORLDS, "MUNDOS", "planet"], [Tab.PRESTIGE, "PRESTÍGIO", "prestige"]]
## Larguras das colunas das tabelas (px da arte) — iguais em todas as abas para alinhar.
const COL_LEVEL := 40
const COL_EFFECT := 118
const COL_ACTION := 120
const COL_MAX := 30
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
	_clear(_rows)
	if GameState.prestige_pending:
		_tabs.visible = false
		_expedition.visible = false
		_add_pending_prestige()
		_after_rebuild(focus_key)
		return
	_launch.disabled = false
	_launch.text = "DECOLAR  [Enter]"
	if _tab == Tab.PRESTIGE and not _prestige_unlocked():
		_tab = Tab.SHIP
	_fill_expedition()
	_fill_tabs()
	match _tab:
		Tab.SHIP:
			_add_upgrades()
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
	elif event.is_action_pressed(&"ui_cancel") and not GameState.prestige_pending:
		get_viewport().set_input_as_handled()
		if _confirm_prestige:                                  # Esc primeiro desiste da confirmacao pendente
			_confirm_prestige = false
			Sound.ui("click")
			refresh()
		else:
			_request_menu()
	elif event is InputEventKey and event.pressed and not event.echo and not GameState.prestige_pending:
		var k: int = event.keycode
		if k == KEY_Q or k == KEY_E:
			get_viewport().set_input_as_handled()
			_cycle_tab(-1 if k == KEY_Q else 1)


# --- cabecalho ---------------------------------------------------------------------------------------------------

func _fill_resources() -> void:
	_clear(_resources)
	if _flash_money:
		_flash_money = false
		UiKit.pulse(_resources, 1.5)
	_resources.add_child(UiKit.icon_label("credits", EconMath.fmt(GameState.amount("credits")), &"MoneyLabel"))
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
	_ship.add_child(UiKit.icon_label("tank", "tanque %s gás" % _num(s["tank"])))
	_ship.add_child(UiKit.icon_label("efficiency", "bocais %s m/s/gás" % _num(s["efficiency"])))
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
		if t == Tab.PRESTIGE and not _prestige_unlocked():
			continue
		var b := Button.new()
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
	var order: Array[Tab] = [Tab.SHIP, Tab.WORLDS]
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
				return r["affordable"] and not _is_stage(str(r["id"])))
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
	_rows.add_child(_header_row(["UPGRADE", "NÍVEL", "ATUAL > PRÓXIMO", "CUSTO"]))
	for r: Dictionary in GameState.upgrade_rows():
		if not _is_stage(str(r["id"])):
			_rows.add_child(_make_row(r))


## Linha de upgrade: icone | nome (+ proximo marco) | nivel | atual > proximo | custo (compra 1) | MAX
func _make_row(r: Dictionary) -> HBoxContainer:
	var id: String = r["id"]
	var row := _table_row(ICONS.get(id, "options"), str(r["name"]))
	row.set_meta(&"row_key", "up:" + id)
	if not (r["milestone"] as Dictionary).is_empty():
		var ms := Label.new()
		ms.text = "marco nv %d: ×%s " % [int(r["milestone"]["level"]), str(r["milestone"]["mult"])]
		ms.theme_type_variation = &"DimLabel"
		ms.tooltip_text = "no nível %d o pagamento é multiplicado por %s" % [int(r["milestone"]["level"]),
				str(r["milestone"]["mult"])]
		ms.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(ms)
	row.add_child(_cell("nv %d" % int(r["level"]), COL_LEVEL, &"DimLabel"))
	row.add_child(_cell("%s > %s %s" % [_num(r["current"]), _num(r["next"]), UNITS.get(r["stat"], "")], COL_EFFECT,
			&"ValueLabel"))
	row.add_child(_buy_button(r, COL_ACTION))
	var mx := Button.new()
	mx.text = "MÁX"
	mx.tooltip_text = "comprar o máximo de níveis possível"
	mx.custom_minimum_size = Vector2(COL_MAX, 15)
	mx.disabled = not r["affordable"]
	mx.set_meta(&"focus_key", "max:" + id)
	mx.pressed.connect(func() -> void:
		_bought(GameState.buy_upgrade_max(id) > 0, "up:" + id))
	row.add_child(mx)
	return row


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
		_bought(GameState.buy_upgrade(id), "up:" + id))
	return buy


# --- aba MUNDOS --------------------------------------------------------------------------------------------------

func _add_worlds() -> void:
	_rows.add_child(_header_row(["MUNDO", "GRAVIDADE", "PAGAMENTO", ""],
			[0, COL_LEVEL + 34, COL_EFFECT - 34, COL_ACTION + COL_MAX + 4]))
	for p: Dictionary in GameState.planet_rows():
		if p["unlocked"] or p["available"]:
			_rows.add_child(_make_planet_row(p))
	var note := Label.new()
	note.text = "Mundos novos pagam muito mais, mas a gravidade gasta mais gás: compre Motor e Tanque antes."
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
		row.add_child(_cell("VOCÊ ESTÁ AQUI", COL_ACTION + COL_MAX + 4, &"GoodLabel"))
		return row
	var b := Button.new()
	b.custom_minimum_size = Vector2(COL_ACTION + COL_MAX + 4, 15)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.set_meta(&"focus_key", "planet:" + id)
	if p["unlocked"]:
		b.icon = UiKit.icon("distance")
		if p["can_fly"]:
			b.text = "Voar para cá"
			b.tooltip_text = "a próxima decolagem será neste mundo"
			b.pressed.connect(func() -> void:
				Sound.ui("click")
				GameState.current_planet = id
				_flash_row = "planet:" + id
				refresh())
		else:
			b.text = "motor fraco: compre Motor"
			b.tooltip_text = "o motor ainda não vence a gravidade deste mundo"
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
func _bought(ok: bool, row_key: String) -> void:
	Sound.ui("buy" if ok else "denied")
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
	for n: Node in _rows.find_children("*", "HBoxContainer", true, false):
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
