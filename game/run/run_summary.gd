## Resumo do fim do run (arte: UiKit). Enter ou o botao comecam um novo run.
class_name RunSummary
extends PanelContainer

signal continue_requested

@onready var _reason: Label = %Reason
@onready var _rows: VBoxContainer = %Rows
@onready var _continue: Button = %Continue


func _ready() -> void:
	_continue.pressed.connect(func() -> void: continue_requested.emit())
	continue_requested.connect(func() -> void: Sound.ui("click"))


func show_summary(summary: Dictionary) -> void:
	_reason.text = _reason_text(str(summary["reason"]))
	for c in _rows.get_children():
		c.queue_free()
	_rows.add_child(UiKit.icon_label("expedition", "entregas: %d" % int(summary["deliveries"]), &"ValueLabel"))
	_rows.add_child(UiKit.icon_label("quality", "qualidade média: %d%%" % int(float(summary["avg_quality"]) * 100.0),
			&"ValueLabel"))
	var icons := {"credits": "credits", "ore": "ore"}
	var names := {"credits": "créditos", "ore": "minério"}
	var earned: Dictionary = summary["earned"]
	for res: String in earned:
		_rows.add_child(UiKit.icon_label(icons.get(res, "credits"), "+%s %s" % [EconMath.fmt(float(earned[res])),
				names.get(res, res)], &"MoneyLabel"))
	var fleet: Dictionary = summary.get("fleet", {})
	for res: String in fleet:
		_rows.add_child(UiKit.icon_label("fleet", "frota de drones: +%s %s" % [EconMath.fmt(float(fleet[res])),
				names.get(res, res)], &"MoneyLabel"))
	visible = true


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"confirm"):
		get_viewport().set_input_as_handled()
		continue_requested.emit()


func _reason_text(reason: String) -> String:
	if reason.begins_with("batida"):
		return "a nave bateu"
	return {"limite_de_entregas": "limite de entregas", "sem_gas": "acabou o gás", "encerrado": "run encerrado"}.get(
			reason, reason)
