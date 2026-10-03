## Resumo do fim do run (arte: UiKit), janela modal sobre o voo escurecido. Enter ou o botao levam ao hangar
## (a Main abre o hangar; de la sai o proximo run).
class_name RunSummary
extends Control

signal continue_requested

## Segundos ate o botao ganhar foco (Espaco do propulsor nao fecha o resumo sem querer; Enter vale na hora).
const FOCUS_DELAY := 0.4

@onready var _reason: Label = %Reason
@onready var _rows: VBoxContainer = %Rows
@onready var _continue: Button = %Continue


func _ready() -> void:
	_continue.pressed.connect(func() -> void: continue_requested.emit())
	continue_requested.connect(func() -> void: Sound.ui("click"))


func show_summary(summary: Dictionary) -> void:
	var reason := str(summary["reason"])
	_reason.text = _reason_text(reason)
	_reason.theme_type_variation = &"BadLabel" if reason.begins_with("batida") else &"DimLabel"
	for c in _rows.get_children():
		_rows.remove_child(c)
		c.queue_free()
	_rows.add_child(UiKit.stat_row("expedition", "entregas", "%d" % int(summary["deliveries"])))
	_rows.add_child(UiKit.stat_row("quality", "qualidade média", "%d%%" % int(float(summary["avg_quality"]) * 100.0)))
	var icons := {"credits": "credits", "ore": "ore"}
	var names := {"credits": "créditos", "ore": "minério"}
	var earned: Dictionary = summary["earned"]
	for res: String in earned:
		_rows.add_child(UiKit.stat_row(icons.get(res, "credits"), names.get(res, res), "+" + EconMath.fmt(
				float(earned[res])), &"MoneyLabel"))
	var fleet: Dictionary = summary.get("fleet", {})
	for res: String in fleet:
		_rows.add_child(UiKit.stat_row("fleet", "frota de drones (%s)" % names.get(res, res), "+" + EconMath.fmt(
				float(fleet[res])), &"MoneyLabel"))
	for key: String in summary.get("records", []):             # pos-jogo: recorde batido neste run
		var info: Array = GameState.RECORDS.get(key, [key, ""])
		_rows.add_child(UiKit.stat_row(str(info[1]), "NOVO RECORDE: " + str(info[0]), "!", &"GoodLabel"))
	visible = true
	# foco visivel no botao, mas so depois de um instante: Espaco (propulsor) apertado na hora da batida nao pula o resumo
	get_tree().create_timer(FOCUS_DELAY).timeout.connect(func() -> void:
		if visible and is_inside_tree():
			_continue.grab_focus())
	UiKit.pulse(%Panel, 1.3, 0.25)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"confirm"):
		get_viewport().set_input_as_handled()
		continue_requested.emit()


func _reason_text(reason: String) -> String:
	if reason.begins_with("batida"):
		return "a nave bateu: " + UiKit.crash_text(reason.get_slice(":", 1))
	return {"limite_de_entregas": "limite de entregas", "sem_gas": "acabou o gás", "encerrado": "run encerrado",
			"sem_alcance": "nenhuma entrega ao alcance: melhore a nave ou troque de mundo"}.get(
			reason, reason)
