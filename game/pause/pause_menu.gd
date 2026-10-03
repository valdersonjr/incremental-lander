## Menu do jogo (arte: UiKit), janela modal sobre o mundo escurecido. Dois modos:
## FLIGHT (Esc no voo): "PAUSA", congela a arvore (SceneTree.paused), volumes + controles + CONTINUAR.
## HANGAR (Esc/Opções no hangar; a Main esconde o hangar): "MENU", volumes + controles + Menu inicial + Novo jogo
## (2 cliques, Esc cancela) + VOLTAR AO HANGAR. No sandbox: "Sair do sandbox" no lugar do menu inicial e sem Novo jogo. So apresentacao/navegacao: emite sinais, a Main decide o fluxo.
## Roda com PROCESS_MODE_ALWAYS.
class_name PauseMenu
extends Control

signal closed
## Modo HANGAR: voltar ao menu inicial (a Main salva e mostra o titulo).
signal title_requested
## Modo HANGAR: apagar o jogo em uso e comecar do zero (confirmado com 2 cliques).
signal new_game_requested

enum Mode { FLIGHT, HANGAR }

## Teclas do jogo (texto de jogador; as acoes vem de data/world.json -> input).
const CONTROLS := [
	["W, Espaço ou seta acima", "propulsor"],
	["A/D ou setas laterais", "girar"],
	["número da oferta ou clique", "escolher entrega"],
	["E (na escolha)", "encerrar o run"],
	["R", "reiniciar o run"],
]

var mode := Mode.FLIGHT
var _confirm_new_game := false


func _ready() -> void:
	visible = false
	%Continue.pressed.connect(close)
	%MenuButton.pressed.connect(func() -> void:
		Sound.ui("click")
		visible = false
		title_requested.emit())
	%NewGame.pressed.connect(_on_new_game)
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


## Abre o menu. FLIGHT pausa o jogo; HANGAR nao pausa (nada corre no hangar) e mostra as acoes do jogo salvo.
func open(p_mode: Mode = Mode.FLIGHT) -> void:
	mode = p_mode
	_confirm_new_game = false
	theme = UiKit.theme_for(GameState.current_planet)
	for c in %Volumes.get_children():
		%Volumes.remove_child(c)
		c.queue_free()
	for bus: String in GameState.BUSES:
		%Volumes.add_child(UiKit.volume_row(bus))
	%Volumes.add_child(UiKit.crt_row())
	var hangar := mode == Mode.HANGAR
	%Title.text = "MENU" if hangar else "PAUSA"
	%GameTitle.visible = hangar
	%Game.visible = hangar
	%Continue.text = "VOLTAR AO HANGAR  [Esc]" if hangar else "CONTINUAR  [Esc]"
	var sandbox := Sandbox.active()                            # no sandbox: sair dele; nunca apagar o jogo salvo
	%MenuLabel.text = "Voltar ao menu inicial (seu jogo salvo volta intacto)" if sandbox else "Voltar ao menu inicial (salva)"
	%MenuButton.text = "Sair do sandbox" if sandbox else "Menu inicial"
	%NewGameRow.visible = not sandbox
	_show_new_game()
	visible = true
	if not hangar:
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
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		if _confirm_new_game:                                  # Esc primeiro desiste da confirmacao
			_confirm_new_game = false
			Sound.ui("click")
			_show_new_game()
		else:
			close()
	elif event.is_action_pressed(&"confirm"):
		get_viewport().set_input_as_handled()
		close()


func _on_new_game() -> void:
	Sound.ui("click")
	if not _confirm_new_game:
		_confirm_new_game = true
		_show_new_game()
		return
	_confirm_new_game = false
	visible = false
	new_game_requested.emit()


func _show_new_game() -> void:
	%NewGameLabel.text = "Apagar o Jogo %d e recomeçar do zero" % SaveManager.slot
	%NewGame.text = "Apagar? Clique de novo" if _confirm_new_game else "Novo jogo"
