## Tela de final (arte: UiKit): chegou ao mundo objetivo (O Quarto, id titan). Mostra o resumo da jornada; permite continuar jogando.
class_name Ending
extends PanelContainer

signal closed

@onready var _title: Label = %Title
@onready var _text: Label = %Text
@onready var _continue: Button = %Continue


func _ready() -> void:
	_continue.pressed.connect(func() -> void:
		visible = false
		closed.emit())


func show_ending(play_seconds: float = -1.0) -> void:
	if play_seconds < 0.0:
		play_seconds = GameState.play_seconds
	_title.text = "VOCÊ CHEGOU AO QUARTO!"
	_text.text = "\n".join([
		"A Nave-mãe Aurora pousou no gigante.",
		"runs: %d" % GameState.runs_done,
		"Poeira Estelar acumulada: %s" % EconMath.fmt(GameState.prestige_points),
		"tempo de jogo: %s" % _fmt_time(play_seconds),
		"",
		"Obrigado por jogar este protótipo.",
	])
	visible = true
	_continue.grab_focus()


func _fmt_time(s: float) -> String:
	var t := int(s)
	return "%dh%02dm" % [t / 3600, (t % 3600) / 60] if t >= 3600 else "%dm%02ds" % [t / 60, t % 60]
