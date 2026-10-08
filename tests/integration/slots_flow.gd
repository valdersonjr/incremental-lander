## Teste de integracao dos JOGOS SALVOS pelo fluxo do jogo (Main + menu inicial), numa pasta propria
## (user://itest_slots), nunca o save real. Novo jogo no espaco 2 -> menu -> jogo 1 (vazio: decola) -> menu ->
## jogo 2 (com progresso: hangar). Imprime SLOTS_TEST OK ou FALHOU.
extends Node

const MAIN := preload("res://game/main.tscn")


func _ready() -> void:
	var fails: Array[String] = []
	SaveManager.enabled = true
	SaveManager.set_dir("user://itest_slots")
	for n in range(1, SaveManager.SLOTS + 1):
		SaveManager.delete_slot(n)
	var main := MAIN.instantiate()
	add_child(main)
	await _frames(3)
	var title := main.find_child("TitleScreen", true, false) as TitleScreen
	var hangar := main.find_child("Hangar", true, false) as Hangar
	var map := main.find_child("WorldMap", true, false) as WorldMap
	if not title.visible:
		fails.append("o jogo nao abriu no menu inicial")
	# novo jogo no espaco 2
	title.new_game_requested.emit(2)
	await _frames(3)
	if SaveManager.slot != 2 or title.visible or not map.visible:
		fails.append("novo jogo no espaco 2 deveria abrir o Mapa (slot=%d)" % SaveManager.slot)
	GameState.runs_done = 5
	GameState.resources["credits"] = 321.0
	GameState.stars = 4
	SaveManager.save_game()
	# volta ao menu pelo hangar; Jogar abre os 5 cartoes: o do jogo 2 e o em uso, com a progressao
	hangar.title_requested.emit()
	await _frames(3)
	(title.find_child("Play", true, false) as Button).pressed.emit()
	await _frames(3)
	var cards := title.find_children("*", "Button", true, false).filter(func(b: Node) -> bool:
		return b is Button and b.get_parent() is SaveSlots)
	if not title.visible or cards.size() != SaveManager.SLOTS:
		fails.append("Jogar deveria abrir %d cartoes (veio %d)" % [SaveManager.SLOTS, cards.size()])
	else:
		var card2 := cards[1] as Button
		var texts := card2.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)
		var card_text := " ".join(texts)
		if card2.tooltip_text != "jogo em uso" or not "321" in texts or not "4" in texts:   # creditos e estrelas
			fails.append("cartao do jogo 2 sem a progressao/destaque: '%s'" % card_text)
		if not "Novo jogo" in " ".join((cards[4] as Button).find_children("*", "Label", true, false).map(
				func(l: Label) -> String: return l.text)):
			fails.append("jogo 5 vazio deveria oferecer Novo jogo")
	title._set_screen(TitleScreen.Screen.MENU)
	# jogo 1 vazio: decola um run novo; o jogo 2 continua salvo
	title.slot_play_requested.emit(1)
	await _frames(3)
	if SaveManager.slot != 1 or GameState.runs_done != 0 or not map.visible:
		fails.append("jogo 1 vazio deveria abrir o Mapa do zero (slot=%d runs=%d)" % [SaveManager.slot, GameState.runs_done])
	if int(SaveManager.slot_summary(2)["runs"]) != 5:
		fails.append("trocar de jogo mexeu no jogo 2: %s" % SaveManager.slot_summary(2))
	# jogo 2 com progresso: vai ao hangar com o progresso dele
	hangar.title_requested.emit()
	await _frames(3)
	title.slot_play_requested.emit(2)
	await _frames(3)
	if SaveManager.slot != 2 or not map.visible or not is_equal_approx(GameState.amount("credits"), 321.0):
		fails.append("jogo 2 deveria abrir o Mapa com 321 cr (slot=%d mapa=%s cr=%s)" % [SaveManager.slot,
				map.visible, GameState.amount("credits")])
	# Salvar no menu do jogo: grava o jogo 2 no espaco 4 (vazio: 1 clique) e passa a usar o 4
	var pause := main.find_child("PauseMenu", true, false) as PauseMenu
	pause.open(PauseMenu.Mode.HANGAR)
	pause._open_saves()
	await _frames(2)
	var slots := pause._slots
	(slots.get_child(3) as Button).pressed.emit()
	await _frames(2)
	if SaveManager.slot != 4 or not is_equal_approx(float(SaveManager.slot_summary(4)["credits"]), 321.0) \
			or not SaveManager.slot_summary(2)["ok"]:
		fails.append("Salvar no espaco 4 vazio deveria gravar la e manter o 2 (slot=%d)" % SaveManager.slot)
	# por cima do jogo 1 (com jogo, outro espaco): o 1o clique so pede confirmacao
	SaveManager.save_to_slot(1)
	SaveManager.load_slot(4)
	GameState.resources["credits"] = 999.0
	slots.fill()
	await _frames(1)
	(slots.get_child(0) as Button).pressed.emit()
	await _frames(1)
	if SaveManager.slot != 4 or is_equal_approx(float(SaveManager.slot_summary(1)["credits"]), 999.0):
		fails.append("por cima de outro jogo deveria pedir um 2o clique")
	(slots.get_child(0) as Button).pressed.emit()
	await _frames(1)
	if SaveManager.slot != 1 or not is_equal_approx(float(SaveManager.slot_summary(1)["credits"]), 999.0):
		fails.append("2o clique deveria gravar por cima do jogo 1 (slot=%d)" % SaveManager.slot)
	pause.close()
	for n in range(1, SaveManager.SLOTS + 1):
		SaveManager.delete_slot(n)
	print("SLOTS_TEST " + ("OK" if fails.is_empty() else "FALHOU " + "; ".join(fails)))
	get_tree().quit(0 if fails.is_empty() else 1)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
