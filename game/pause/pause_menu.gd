## Pausa do voo (arte: UiKit), janela modal: congela a arvore (SceneTree.paused) e mostra volumes + lista de controles.
## So apresentacao: nao mexe no run (a Main decide quando pode pausar). Roda com PROCESS_MODE_ALWAYS.
## Esc, Enter ou o botao continuam.
class_name PauseMenu
extends Control

signal closed

## Teclas do jogo (texto de jogador; as acoes vem de data/world.json -> input).
const CONTROLS := [
	["W, Espaço ou seta acima", "propulsor"],
	["A/D ou setas laterais", "girar"],
	["número da oferta ou clique", "escolher entrega"],
	["E (na escolha)", "encerrar o run"],
	["R", "reiniciar o run"],
]


func _ready() -> void:
	visible = false
	%Continue.pressed.connect(close)
	for c: Array in CONTROLS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 4)
		var key := Label.new()
		key.text = c[0]
		key.theme_type_variation = &"ValueLabel"
		key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(key)
		var what := Label.new()
		what.text = c[1]
		what.theme_type_variation = &"DimLabel"
		what.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(what)
		%Controls.add_child(row)


func open() -> void:
	for c in %Volumes.get_children():
		%Volumes.remove_child(c)
		c.queue_free()
	for bus: String in GameState.BUSES:
		%Volumes.add_child(UiKit.volume_row(bus))
	visible = true
	get_tree().paused = true
	Sound.ui("click")
	%Continue.grab_focus()
	UiKit.pulse(%Panel, 1.3, 0.25)


func close() -> void:
	if not visible:
		return
	Sound.ui("click")
	visible = false
	get_tree().paused = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"confirm")):
		get_viewport().set_input_as_handled()
		close()
