## Resumo do fim do run (Enter para um novo run). Placeholder de texto.
class_name RunSummary
extends PanelContainer

signal continue_requested

@onready var _text: Label = %Text


func show_summary(summary: Dictionary) -> void:
	var earned: Dictionary = summary["earned"]
	var lines := ["FIM DO RUN  (%s)" % _reason_text(str(summary["reason"])),
			"entregas: %d" % int(summary["deliveries"]),
			"qualidade media: %d%%" % int(float(summary["avg_quality"]) * 100.0)]
	var labels := {"credits": "creditos", "ore": "minerio"}
	for res: String in earned:
		lines.append("%s: +%s" % [labels.get(res, res), EconMath.fmt(float(earned[res]))])
	var fleet: Dictionary = summary.get("fleet", {})
	for res: String in fleet:
		lines.append("frota de drones: +%s %s" % [EconMath.fmt(float(fleet[res])), labels.get(res, res)])
	lines.append("")
	lines.append("[Enter] novo run")
	_text.text = "\n".join(lines)
	visible = true


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"confirm"):
		get_viewport().set_input_as_handled()
		continue_requested.emit()


func _reason_text(reason: String) -> String:
	if reason.begins_with("batida"):
		return "bateu"
	return {"limite_de_entregas": "limite de entregas", "sem_gas": "sem gas", "encerrado": "encerrado"}.get(reason, reason)
