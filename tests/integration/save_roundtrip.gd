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
	GameState.unlocked_planets = ["luna", "ares"]
	GameState.current_planet = "ares"
	GameState.prestige_points = 21.0
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
	if GameState.current_planet != "ares":
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
	print("SAVE_TEST " + ("OK" if fails.is_empty() else "FALHOU " + "; ".join(fails)))
	get_tree().quit(0 if fails.is_empty() else 1)
