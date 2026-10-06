## Save: ida e volta, validacao de dados externos, ids removidos da spec.
extends TestCase


func before_each() -> void:
	EconMath.load_spec()


func _state() -> Dictionary:
	return {"resources": {"credits": 123.5}, "levels": {"tank": 3, "fleet": 1}, "current_planet": "luna",
			"income_history": [{"earned": {"credits": 10.0}, "seconds": 5.0}], "runs_done": 4, "play_seconds": 321.0, "settings": {"vol_Music": 0.5}}


func test_ida_e_volta_pelo_json() -> void:
	var saved := SaveData.serialize(_state())
	var back := SaveData.deserialize(JSON.parse_string(JSON.stringify(saved)))
	assert_true(back["ok"])
	var st: Dictionary = back["state"]
	assert_almost(st["resources"]["credits"], 123.5)
	assert_eq(st["levels"]["tank"], 3)
	assert_eq(st["current_planet"], "luna")
	assert_eq(st["runs_done"], 4)


func test_ids_removidos_da_spec_sao_ignorados() -> void:
	var saved := SaveData.serialize(_state())
	saved["levels"]["upgrade_que_nao_existe"] = 9
	var back := SaveData.deserialize(saved)
	assert_true(back["ok"])
	assert_false(back["state"]["levels"].has("upgrade_que_nao_existe"))
	assert_true(back["warnings"].size() >= 1)


func test_dados_invalidos() -> void:
	assert_false(SaveData.deserialize("lixo")["ok"])
	assert_false(SaveData.deserialize({"save_version": 99})["ok"])
	var neg := SaveData.serialize(_state())
	neg["resources"]["credits"] = -500.0
	neg["current_planet"] = "kronos"
	var st: Dictionary = SaveData.deserialize(neg)["state"]
	assert_almost(st["resources"]["credits"], 0.0, 1e-9, "negativo vira 0")
	assert_eq(st["current_planet"], "luna", "so a Lua existe")


func test_resumo_para_a_tela_de_jogos_salvos() -> void:
	var back := SaveData.deserialize(SaveData.serialize(_state()))
	var s := SaveData.summary(back["state"])
	assert_eq(s["planet"], "luna")
	assert_eq(s["runs"], 4)
	assert_almost(s["credits"], 123.5)
	assert_almost(s["play_seconds"], 321.0)


func test_valores_de_tipo_errado_viram_zero_sem_erro() -> void:
	var raw := SaveData.serialize(_state())
	raw["resources"]["credits"] = {"x": 1}
	raw["levels"]["tank"] = [3]
	raw["runs_done"] = {"a": 1}
	raw["income_history"] = {"earned": 1}
	var back := SaveData.deserialize(raw)
	assert_true(back["ok"])
	var st: Dictionary = back["state"]
	assert_almost(st["resources"]["credits"], 0.0)
	assert_eq(st["levels"]["tank"], 0)
	assert_eq(st["runs_done"], 0)
	assert_eq(st["income_history"], [])


func test_versao_de_save_mais_nova_nao_carrega() -> void:
	var raw := SaveData.serialize(_state())
	raw["save_version"] = SaveData.SAVE_VERSION + 1
	assert_false(SaveData.deserialize(raw)["ok"], "save de versao futura: guardar a parte, nunca interpretar")


func test_recordes_ida_e_volta() -> void:
	var st := _state()
	st["records"] = {"best_delivery": 1500.0, "best_combo": 4.0, "inventado": 9.0}
	var back := SaveData.deserialize(JSON.parse_string(JSON.stringify(SaveData.serialize(st))))
	assert_almost(back["state"]["records"]["best_delivery"], 1500.0)
	assert_almost(back["state"]["records"]["best_combo"], 4.0)
	assert_false(back["state"]["records"].has("inventado"))


## Save v1 (com prestigio e outros mundos) abre na v2: niveis e creditos ficam, o resto sai sem erro.
func test_save_v1_com_prestigio_migra() -> void:
	var v1 := {"save_version": 1, "resources": {"credits": 500.0, "ore": 9.0, "stardust": 3.0},
			"levels": {"tank": 4, "exp1_station": 1}, "shop": {"capital": 1}, "prestige_points": 12.0,
			"prestige_pending": true, "unlocked": ["luna", "ares"], "current_planet": "ares",
			"cycle_earned": {"credits": 99.0}, "reached_goal": true, "runs_done": 7, "play_seconds": 60.0,
			"income_history": [{"earned": {"credits": 10.0, "ore": 1.0}, "seconds": 5.0}], "settings": {}}
	var back := SaveData.deserialize(v1)
	assert_true(back["ok"])
	var st: Dictionary = back["state"]
	assert_almost(st["resources"]["credits"], 500.0)
	assert_false(st["resources"].has("ore"))
	assert_eq(st["levels"]["tank"], 4)
	assert_false(st["levels"].has("exp1_station"))
	assert_eq(st["current_planet"], "luna")
	assert_eq(st["runs_done"], 7)
	assert_false(st.has("prestige_points"))
	assert_eq(SaveData.serialize(st)["save_version"], 2)
