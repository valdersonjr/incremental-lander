## Perigos por mundo: deterministicos, so nos mundos certos, ciclo com aviso, efeito so dentro da zona.
extends TestCase


func _hop(planet: String, d: float) -> Array:
	var t := TerrainGen.generate(4, planet, [d] as Array[float])
	return [t, Hazards.generate(4, planet, t["pads"][0], t["pads"][1], t["ridge"])]


func test_lua_sem_perigos_e_salto_curto_sem_perigos() -> void:
	assert_eq(_hop("luna", 2000.0)[1].size(), 0, "Lua = planeta do arco puro")
	assert_eq(_hop("ares", 150.0)[1].size(), 0, "salto curto: so pousar")


func test_cada_mundo_tem_o_seu() -> void:
	var types := {}
	for p: String in ["ares", "kronos", "titan"]:
		for z: Dictionary in _hop(p, 3000.0)[1]:
			types[z["type"]] = p
	assert_eq(types.get("gust"), "ares")
	assert_eq(types.get("geyser"), "kronos")
	assert_eq(types.get("fan"), "titan")
	assert_eq(types.get("toy"), "titan")


func test_deterministico() -> void:
	assert_eq(_hop("ares", 3000.0)[1], _hop("ares", 3000.0)[1])


func test_rajada_avisa_antes_e_so_empurra_dentro() -> void:
	var z: Dictionary = _hop("ares", 3000.0)[1][0]
	var r: Rect2 = z["rect"]
	var zones: Array[Dictionary] = [z]
	var phases := {}
	for i in 120:
		var t := i * 0.1
		var c := Hazards.cycle(z, t)
		phases[c] = true
		var e := Hazards.effect_at(zones, r.get_center(), t)
		if c == "on":
			assert_true(absf(e["accel"].x) > 0.0, "rajada ligada empurra")
		else:
			assert_eq(e["accel"], Vector2.ZERO, "aviso/desligada nao empurra")
	assert_true(phases.has("warn") and phases.has("on") and phases.has("off"))
	var fora := Hazards.effect_at(zones, r.position - Vector2(50, 50), 0.0)
	assert_eq(fora["accel"], Vector2.ZERO)


func test_geiser_nasce_do_chao_e_freia() -> void:
	var h := _hop("kronos", 3000.0)
	var z: Dictionary = h[1][0]
	var r: Rect2 = z["rect"]
	assert_almost(r.end.y, TerrainGen.height_at(h[0]["ridge"], r.get_center().x), 1.0, "base no chao")
	var t_on := 0.0
	while Hazards.cycle(z, t_on) != "on":
		t_on += 0.05
	var zones: Array[Dictionary] = [z]
	var e := Hazards.effect_at(zones, r.get_center(), t_on)
	assert_true(e["drag"] > 0.0 and e["accel"].y < 0.0, "freia e empurra para cima")


func test_brinquedo_cai_e_destroi() -> void:
	var toys: Array[Dictionary] = []
	for z: Dictionary in _hop("titan", 3000.0)[1]:
		if z["type"] == "toy":
			toys.append(z)
	var z := toys[0]
	var t := 0.0
	while Hazards.cycle(z, t) != "warn":                        # inicio de um ciclo: aviso -> queda
		t += 0.02
	while Hazards.cycle(z, t) != "on":
		t += 0.02
	var p := Hazards.toy_pos(z, t + 0.5)
	assert_true(p.y > float(z["top"]), "esta caindo")
	assert_eq(Hazards.effect_at(toys, p, t + 0.5)["lethal"], "atingido")
	assert_eq(Hazards.effect_at(toys, p + Vector2(200, 0), t + 0.5)["lethal"], "")
