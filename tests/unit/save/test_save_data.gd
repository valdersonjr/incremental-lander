## Save: ida e volta, validacao de dados externos, ids removidos da spec.
extends TestCase


func before_each() -> void:
	EconMath.load_spec()


func _state() -> Dictionary:
	return {"resources": {"credits": 123.5, "ore": 2.0, "stardust": 7.0}, "levels": {"tank": 3, "exp1_station": 1},
			"shop": {"capital": 1}, "prestige_points": 40.0, "prestige_pending": false,
			"unlocked": ["luna", "ares"], "current_planet": "ares", "cycle_earned": {"credits": 99.0},
			"income_history": [{"earned": {"credits": 10.0}, "seconds": 5.0}], "reached_goal": false,
			"runs_done": 4, "play_seconds": 321.0, "settings": {"vol_Music": 0.5}}


func test_ida_e_volta_pelo_json() -> void:
	var saved := SaveData.serialize(_state())
	var back := SaveData.deserialize(JSON.parse_string(JSON.stringify(saved)))
	assert_true(back["ok"])
	var st: Dictionary = back["state"]
	assert_almost(st["resources"]["credits"], 123.5)
	assert_eq(st["levels"]["tank"], 3)
	assert_eq(st["unlocked"], ["luna", "ares"])
	assert_eq(st["current_planet"], "ares")
	assert_almost(st["prestige_points"], 40.0)
	assert_eq(st["runs_done"], 4)


func test_ids_removidos_da_spec_sao_ignorados() -> void:
	var saved := SaveData.serialize(_state())
	saved["levels"]["upgrade_que_nao_existe"] = 9
	saved["unlocked"].append("planeta_fantasma")
	var back := SaveData.deserialize(saved)
	assert_true(back["ok"])
	assert_false(back["state"]["levels"].has("upgrade_que_nao_existe"))
	assert_false("planeta_fantasma" in back["state"]["unlocked"])
	assert_true(back["warnings"].size() >= 1)


func test_dados_invalidos() -> void:
	assert_false(SaveData.deserialize("lixo")["ok"])
	assert_false(SaveData.deserialize({"save_version": 99})["ok"])
	var neg := SaveData.serialize(_state())
	neg["resources"]["credits"] = -500.0
	neg["current_planet"] = "kronos"
	var st: Dictionary = SaveData.deserialize(neg)["state"]
	assert_almost(st["resources"]["credits"], 0.0, 1e-9, "negativo vira 0")
	assert_eq(st["current_planet"], "luna", "planeta nao liberado volta para a Lua")
