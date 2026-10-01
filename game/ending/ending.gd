## Tela de final: chegou ao planeta objetivo (Titan). Mostra o resumo da jornada; permite continuar jogando.
class_name Ending
extends PanelContainer

signal closed

@onready var _text: Label = %Text
@onready var _continue: Button = %Continue


func _ready() -> void:
	_continue.pressed.connect(func() -> void:
		visible = false
		closed.emit())


func show_ending(play_seconds: float = -1.0) -> void:
	if play_seconds < 0.0:
		play_seconds = GameState.play_seconds
	_text.text = "\n".join([
		"VOCÊ CHEGOU AO QUARTO!",
		"",
		"A Nave-mae Aurora pousou no gigante.",
		"runs: %d   Poeira Estelar acumulada: %s" % [GameState.runs_done, EconMath.fmt(GameState.prestige_points)],
		"tempo de jogo: %s" % _fmt_time(play_seconds),
		"",
		"Obrigado por jogar este prototipo.",
	])
	visible = true
	_continue.grab_focus()


func _fmt_time(s: float) -> String:
	var t := int(s)
	return "%dh%02dm" % [t / 3600, (t % 3600) / 60] if t >= 3600 else "%dm%02ds" % [t / 60, t % 60]
