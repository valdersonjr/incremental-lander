## Tela de final (arte: UiKit): chegou ao mundo objetivo (O Quarto, id titan). Janela modal com o resumo da jornada e
## os recordes pessoais (pos-jogo: continuar jogando para bater recordes); continua com Enter ou o botao.
class_name Ending
extends Control

signal closed

@onready var _title: Label = %Title
@onready var _text: Label = %Text
@onready var _rows: VBoxContainer = %Rows
@onready var _continue: Button = %Continue


func _ready() -> void:
	_continue.pressed.connect(func() -> void:
		Sound.ui("click")
		visible = false
		closed.emit())


func show_ending(play_seconds: float = -1.0) -> void:
	if play_seconds < 0.0:
		play_seconds = GameState.play_seconds
	_title.text = "VOCÊ CHEGOU AO QUARTO!"
	_text.text = "A Nave-mãe Aurora pousou no gigante."
	for c in _rows.get_children():
		_rows.remove_child(c)
		c.queue_free()
	_rows.add_child(UiKit.stat_row("expedition", "runs", "%d" % GameState.runs_done))
	_rows.add_child(UiKit.stat_row("stardust", "Poeira Estelar acumulada", EconMath.fmt(GameState.prestige_points),
			&"DustLabel"))
	_rows.add_child(UiKit.stat_row("", "tempo de jogo", _fmt_time(play_seconds)))
	for row: Control in Ending.record_rows():
		_rows.add_child(row)
	visible = true
	_continue.grab_focus()
	UiKit.pulse(%Panel, 1.3, 0.4)


func _fmt_time(s: float) -> String:
	var t := int(s)
	return "%dh%02dm" % [t / 3600, (t % 3600) / 60] if t >= 3600 else "%dm%02ds" % [t / 60, t % 60]


## Linhas "RECORDES" (titulo + uma por recorde ja feito) para o final e o hangar; vazio se ainda nao ha recorde.
static func record_rows() -> Array[Control]:
	var out: Array[Control] = []
	for key: String in GameState.RECORDS:
		var v := float(GameState.records.get(key, 0.0))
		if v <= 0.0:
			continue
		if out.is_empty():
			var t := Label.new()
			t.text = "RECORDES"
			t.theme_type_variation = &"SectionLabel"
			out.append(t)
		var info: Array = GameState.RECORDS[key]
		var shown := "%d" % int(v) if key == "best_combo" else EconMath.fmt(v)
		out.append(UiKit.stat_row(str(info[1]), str(info[0]), shown, &"MoneyLabel" if key in ["best_delivery", "best_run"]
				else &"ValueLabel"))
	return out
