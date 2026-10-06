## Teste de integracao do save (roda como cena: gdtool.py run res://tests/integration/save_roundtrip.tscn).
## Usa uma pasta propria (user://itest), nunca o save real. Imprime SAVE_TEST OK ou FALHOU.
extends Node


func _ready() -> void:
	var fails: Array[String] = []
	SaveManager.enabled = true
	SaveManager.set_dir("user://itest")
	GameState.reset()
	GameState.resources["credits"] = 12345.0
	GameState.levels["tank"] = 7
	GameState.set_volume("Music", 0.5)
	if not SaveManager.save_game():
		fails.append("save_game falhou")
	GameState.reset()
	if not SaveManager.load_game():
		fails.append("load_game falhou")
	if not is_equal_approx(GameState.amount("credits"), 12345.0):
		fails.append("creditos: %s" % GameState.amount("credits"))
	if int(GameState.levels.get("tank", 0)) != 7:
		fails.append("tank: %s" % GameState.levels.get("tank"))
	if GameState.current_planet != "luna":
		fails.append("planeta: %s" % GameState.current_planet)
	if not is_equal_approx(GameState.volume("Music"), 0.5):
		fails.append("volume: %s" % GameState.volume("Music"))
	# save corrompido -> usa o backup
	GameState.resources["credits"] = 999.0
	SaveManager.save_game()          # save.bak = versao com 12345
	var f := FileAccess.open(SaveManager.PATH, FileAccess.WRITE)
	f.store_string("{ corrompido")
	f.close()
	GameState.reset()
	if not SaveManager.load_game() or not is_equal_approx(GameState.amount("credits"), 12345.0):
		fails.append("backup nao recuperou: %s" % GameState.amount("credits"))
	_test_slots(fails)
	print("SAVE_TEST " + ("OK" if fails.is_empty() else "FALHOU " + "; ".join(fails)))
	get_tree().quit(0 if fails.is_empty() else 1)


## Varios jogos salvos: cada espaco tem seu progresso; opcoes e ultimo jogo usado sao globais.
func _test_slots(fails: Array[String]) -> void:
	for n in range(2, SaveManager.SLOTS + 1):
		SaveManager.delete_slot(n)
	SaveManager.load_slot(1)
	SaveManager.save_game()                                   # jogo 1 = 12345 creditos
	SaveManager.new_game(2)
	if SaveManager.slot != 2 or GameState.amount("credits") != 0.0:
		fails.append("novo jogo no espaco 2: slot=%d cr=%s" % [SaveManager.slot, GameState.amount("credits")])
	GameState.resources["credits"] = 77.0
	GameState.runs_done = 3
	GameState.set_volume("SFX", 0.25)
	SaveManager.save_game()
	var s1 := SaveManager.slot_summary(1)
	var s2 := SaveManager.slot_summary(2)
	var s3 := SaveManager.slot_summary(3)
	if not s1["ok"] or not is_equal_approx(s1["credits"], 12345.0) or s1["current"]:
		fails.append("resumo do jogo 1: %s" % s1)
	if not s2["ok"] or not is_equal_approx(s2["credits"], 77.0) or s2["runs"] != 3 or not s2["current"]:
		fails.append("resumo do jogo 2: %s" % s2)
	if s3["exists"]:
		fails.append("jogo 3 deveria estar vazio: %s" % s3)
	SaveManager.load_slot(1)
	if not is_equal_approx(GameState.amount("credits"), 12345.0):
		fails.append("trocar para o jogo 1: cr=%s" % GameState.amount("credits"))
	if not is_equal_approx(GameState.volume("SFX"), 0.25):
		fails.append("volume nao e global: %s" % GameState.volume("SFX"))
	var prefs: Variant = JSON.parse_string(FileAccess.get_file_as_string("user://itest/settings.json"))
	if not prefs is Dictionary or int(prefs.get("last_slot", 0)) != 1:
		fails.append("ultimo jogo usado nao salvo: %s" % prefs)
	SaveManager.delete_slot(2)
	if SaveManager.slot_summary(2)["exists"]:
		fails.append("apagar o jogo 2 nao apagou")
	if not is_equal_approx(GameState.amount("credits"), 12345.0):
		fails.append("apagar outro jogo mexeu no jogo em uso")
