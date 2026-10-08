## Resumo do fim do run (arte: UiKit), janela modal sobre o voo escurecido. Enter ou o botao continuam (a Main decide:
## NAVE se da para comprar alguma peca, voo de novo para o aprendiz, senao o Mapa).
class_name RunSummary
extends Control

signal continue_requested

## Segundos ate o botao ganhar foco (Espaco do propulsor nao fecha o resumo sem querer; Enter vale na hora).
const FOCUS_DELAY := 0.4

@onready var _title: Label = %Title
@onready var _reason: Label = %Reason
@onready var _rows: VBoxContainer = %Rows
@onready var _continue: Button = %Continue


func _ready() -> void:
	_continue.pressed.connect(func() -> void: continue_requested.emit())
	continue_requested.connect(func() -> void: Sound.ui("click"))


func show_summary(summary: Dictionary) -> void:
	var reason := str(summary["reason"])
	_title.text = _title_text(reason)
	_reason.text = _reason_text(reason)
	_reason.visible = not _reason.text.is_empty()
	_reason.theme_type_variation = &"BadLabel" if reason.begins_with("batida") else &"DimLabel"
	for c in _rows.get_children():
		_rows.remove_child(c)
		c.queue_free()
	_add_records(summary.get("rec_values", {}), summary.get("rec_start", {}))
	var bonus := float(summary.get("record_bonus", 0.0))
	if bonus > 0.0:                                            # bonus de recorde do mundo (v16)
		var first := float((summary.get("rec_start", {}) as Dictionary).get("run_money", 0.0)) <= 0.0
		var brow := UiKit.stat_row("trophy", "primeira visita!" if first else "bônus de recorde",
				"+" + EconMath.fmt(bonus), &"MoneyLabel")
		_rows.add_child(brow)
	var fleet: Dictionary = summary.get("fleet", {})
	for res: String in fleet:
		_rows.add_child(UiKit.stat_row("fleet", "drones trouxeram", "+" + EconMath.fmt(
				float(fleet[res])), &"MoneyLabel"))
	var mg: Array = summary.get("minigames", [0, 0])
	if int(mg[1]) > 0:                                         # selo dos minijogos feitos por inteiro (auditoria T4)
		var mrow := UiKit.stat_row("trophy", "minijogos completos", "%d/%d" % [int(mg[0]), int(mg[1])],
				&"GoodLabel" if int(mg[0]) == int(mg[1]) else &"MoneyLabel")
		_rows.add_child(mrow)
	if int(summary.get("stars", 0)) > 0:                       # estrelas: andam na Estrada da PROGRESSAO
		var row := UiKit.stat_row("", "estrelas", "+%d" % int(summary["stars"]), &"MoneyLabel")
		(row.get_child(0) as TextureRect).texture = UiKit.kid("star_on")
		(row.get_child(0) as TextureRect).expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_rows.add_child(row)
	if int(summary.get("road_news", 0)) > 0:                    # premio novo na Estrada das Estrelas
		var n := int(summary["road_news"])
		var hint := UiKit.stat_row("", "prêmio novo na estrada!" if n == 1 else "%d prêmios novos na estrada!" % n,
				"!", &"GoodLabel")
		(hint.get_child(0) as TextureRect).texture = UiKit.kid("star_on")
		(hint.get_child(0) as TextureRect).expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_rows.add_child(hint)
	visible = true
	# foco visivel no botao, mas so depois de um instante: Espaco (propulsor) apertado na hora da batida nao pula o resumo
	get_tree().create_timer(FOCUS_DELAY).timeout.connect(func() -> void:
		if visible and is_inside_tree():
			_continue.grab_focus())
	UiKit.pulse(%Panel, 1.3, 0.25)


## Recordes (variante "troféus" aprovada): dinheiro do run grande + "NOVO RECORDE!"/recorde; 4 cartões (entregas,
## distância, pousos perfeitos, maior entrega) que viram troféu quando passam o recorde. 0 = ainda sem recorde.
func _add_records(values: Dictionary, start: Dictionary) -> void:
	var money := float(values.get("run_money", 0.0))
	var rec := float(start.get("run_money", 0.0))
	var hero := HBoxContainer.new()
	hero.alignment = BoxContainer.ALIGNMENT_CENTER
	hero.add_theme_constant_override(&"separation", 4)
	hero.add_child(_figure(UiKit.icon("credits")))
	var big := Label.new()
	big.text = EconMath.fmt(money)
	big.theme_type_variation = &"BigMoneyLabel"
	hero.add_child(big)
	_rows.add_child(hero)
	var line := HBoxContainer.new()
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_theme_constant_override(&"separation", 3)
	if rec > 0.0 and money > rec:
		var t := TextureRect.new()
		t.texture = UiKit.icon("trophy")
		t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		line.add_child(t)
		line.add_child(_label("NOVO RECORDE!", &"MoneyLabel"))
		line.add_child(_label("antes " + EconMath.fmt(rec), &"DimLabel"))
	elif rec > 0.0:
		line.add_child(_label("recorde " + EconMath.fmt(rec), &"DimLabel"))
	else:
		line.add_child(_label("seu primeiro recorde!", &"DimLabel"))
	_rows.add_child(line)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override(&"separation", 4)
	for key: String in GameState.RECORDS:
		if key == "run_money":
			continue
		var v := float(values.get(key, 0.0))
		var r := float(start.get(key, 0.0))
		var beaten := r > 0.0 and v > r
		var card := PanelContainer.new()
		card.theme_type_variation = &"SlimPanel"
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.tooltip_text = str(GameState.RECORDS[key][0])
		var box := VBoxContainer.new()
		box.add_theme_constant_override(&"separation", 0)
		var fig := _figure(UiKit.kid(str(GameState.RECORDS[key][2])))   # sempre a figura da categoria (o trofeu vai embaixo)
		fig.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(fig)
		var val := _label(GameState.record_text(key, v), &"MoneyLabel" if beaten else &"ValueLabel")
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(val)
		var cap := HBoxContainer.new()                         # trofeuzinho + "NOVO!" ou o recorde antigo
		cap.alignment = BoxContainer.ALIGNMENT_CENTER
		cap.add_theme_constant_override(&"separation", 2)
		if beaten or r > 0.0:
			var cup := TextureRect.new()
			cup.texture = UiKit.icon("trophy")
			cup.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
			cap.add_child(cup)
		cap.add_child(_label("NOVO!" if beaten else (GameState.record_text(key, r) if r > 0.0 else " "),
				&"MoneyLabel" if beaten else &"DimLabel"))
		box.add_child(cap)
		card.add_child(box)
		cards.add_child(card)
		if beaten:
			UiKit.pulse(card, 1.6, 0.6)
	_rows.add_child(cards)


static func _figure(tex: Texture2D) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.custom_minimum_size = Vector2(24, 24)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


static func _label(text: String, variation: StringName) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = variation
	return l


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"confirm"):
		get_viewport().set_input_as_handled()
		continue_requested.emit()


## Titulo da janela conforme o motivo do fim (o comum e o gas acabar).
func _title_text(reason: String) -> String:
	if reason.begins_with("batida"):
		return "A NAVE BATEU!"
	return {"sem_gas": "ACABOU O GÁS!", "encerrado": "FIM DA VIAGEM",
			"sem_alcance": "O GÁS NÃO DÁ!"}.get(reason, "ACABOU O GÁS!")


## Detalhe sob o titulo (vazio quando o titulo ja diz tudo).
func _reason_text(reason: String) -> String:
	if reason.begins_with("batida"):                       # o que deu errado + o jeito de acertar (auditoria A4)
		var why := reason.get_slice(":", 1)
		var tip := UiKit.crash_tip(why)
		return UiKit.crash_text(why) + ("\n" + tip if tip != "" else "")
	return {"sem_gas": "", "encerrado": "",
			"sem_alcance": "nenhuma entrega ao alcance: melhore a nave"}.get(
			reason, reason)
