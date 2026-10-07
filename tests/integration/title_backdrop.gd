## Teste de integracao da tela de titulo com cena propria: aberto o titulo, nenhum voo fica montado (sem Flight) e o
## TitleBackdrop aparece com o gatinho animando; no menu so a coluna da esquerda (painel do meio escondido), nas
## subtelas o painel; Jogar (com progresso) leva ao hangar com o mundo montado atras; voltar ao titulo desmonta o
## mundo; Sandbox tambem monta o mundo. Imprime TITLE_BACKDROP_TEST OK ou FALHOU.
extends Node

const MAIN := preload("res://game/main.tscn")

var _main: Node
var _f := 0
var _log: Array[String] = []
var _ok := true


func _ready() -> void:
	SaveManager.set_dir("user://itest_title")
	GameState.runs_done = 1                                    # com progresso: Jogar leva ao hangar
	_main = MAIN.instantiate()
	add_child(_main)


func _check(what: String, cond: bool) -> void:
	_log.append("%s=%s" % [what, cond])
	_ok = _ok and cond


func _process(_d: float) -> void:
	_f += 1
	var title: TitleScreen = _main._title
	var hangar: Hangar = _main._hangar
	match _f:
		10:
			var bd := title.get_node("Backdrop") as TitleBackdrop
			var cat := bd.get_node("Front/Cat") as AnimatedSprite2D
			_check("titulo_visivel", title.visible)
			_check("sem_voo_atras", _main._flight == null)
			_check("cena_propria", bd.is_visible_in_tree() and cat.is_playing())
			_check("gato_no_morro", cat.position.y > 100.0 and cat.position.x > 200.0)
			_check("menu_na_coluna", (title.get_node("%Menu") as Control).visible
					and not (title.get_node("%Panel") as Control).visible)
			title._set_screen(TitleScreen.Screen.SAVES)
		20:
			_check("saves_no_painel", (title.get_node("%Panel") as Control).visible
					and not (title.get_node("%Menu") as Control).visible)
			title._set_screen(TitleScreen.Screen.MENU)
			title.play_requested.emit()
		30:
			_check("jogar_hangar_com_mundo", hangar.visible and _main._flight != null)
			_main._show_title()
		40:
			_check("voltar_desmonta_mundo", title.visible and _main._flight == null)
			title.sandbox_requested.emit("luna", true)
		50:
			_check("sandbox_hangar_com_mundo", hangar.visible and _main._flight != null)
			print("TITLE_BACKDROP_LOG ", " | ".join(_log))
			print("TITLE_BACKDROP_TEST ", "OK" if _ok else "FALHOU")
			get_tree().quit()
