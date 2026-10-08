## Teste de integracao dos minijogos do voo (v17): monta a Flight em cada mundo com o pedido-assinatura e confere a
## mecanica no voo de verdade. Lua: queijinhos no arco, pegar ao encostar, pagamento junto com a entrega.
## Imprime MINIGAME_TEST OK ou FALHOU.
extends Node

const FLIGHT_SCENE := preload("res://game/flight/flight.tscn")

var _fails: Array[String] = []


func _check(what: String, cond: bool) -> void:
	if not cond:
		_fails.append(what)


func _flight(planet: String, mission: Dictionary, dist := 800.0) -> Flight:
	var f: Flight = FLIGHT_SCENE.instantiate()
	add_child(f)
	f.start(planet, 7, EconMath.ship_stats({"thrust": 30, "tank": 20, "efficiency": 10}), false)
	f.begin_mission(11, dist, "normal", 1, mission)
	f.lander.state = Lander.State.FLYING
	return f


func _ready() -> void:
	await get_tree().process_frame
	# Lua: trilha de queijinhos
	var m2 := {"kind": "simple", "star": 2, "parts": [{"kind": "simple", "star": 2}]}
	var f := _flight("luna", m2)
	_check("lua_queijinhos_da_estrela_2", f.minigame_total == int(Minigames.by_star(Minigames.spec("luna")["coins"], 2)))
	var got_before := f.minigame_got
	for c: Dictionary in f._trail.slice(0, 3):
		f.lander.global_position = c["pos"]
		f._tick_minigame()
	_check("lua_pega_ao_encostar", f.minigame_got == got_before + 3)
	_check("lua_placar_no_hud", f.minigame_text() == "3/%d" % f.minigame_total and f.minigame_icon() == "cheese")
	f.lander.global_position = (f._trail[-1]["pos"] as Vector2) + Vector2(-900.0, 0.0)   # trilha fora da tela
	f.camera.global_position = f.lander.global_position
	f.camera.force_update_scroll()
	await get_tree().process_frame
	f._update_pointer()
	_check("lua_seta_aponta_item_fora_da_tela", f._pointer != null and f._pointer.visible
			and absf(f._pointer.global_position.x - f.lander.global_position.x) > 250.0)
	var res: Array = []
	f.delivery_finished.connect(func(r: Dictionary) -> void: res.append(r))
	f._finish(false, 0.9, "", {"gas_used": 10.0, "flight_time_m": 5.0})
	_check("lua_paga_os_queijinhos", not res.is_empty() and float(res[0]["gift_pay"]) > 0.0
			and res[0]["minigame"] == [3, f.minigame_total if f.minigame_total > 0 else res[0]["minigame"][1]])
	_check("lua_limpa_a_trilha", f._trail.is_empty())
	_check("verbo_da_lua", f.minigame_verb() == "Pegue!")
	f.queue_free()
	await get_tree().process_frame
	# Nuvens: fila de carneirinhos (Snake) + correntes de ar
	var p3 := {"kind": "passenger", "star": 3, "parts": [{"kind": "passenger", "star": 3}]}
	var n := _flight("nuvens", p3, 900.0)
	_check("nuvens_5_carneirinhos_na_estrela_3", n.minigame_total == 5 and n._sheep.size() == 5)
	_check("nuvens_sem_resgate_antigo", n._rescue_sprite == null)
	for c: Dictionary in n._sheep.slice(0, 2):
		n.lander.global_position = c["pos"]
		n._tick_minigame()
	_check("nuvens_entram_na_fila", n._tail.size() == 2 and n.minigame_got == 2)
	for i in 30:                                               # a nave anda: a fila segue atras
		n.lander.global_position += Vector2(3, 0)
		n._tick_minigame()
	var first_tail: Vector2 = (n._tail[0]["sprite"] as Sprite2D).position
	_check("nuvens_fila_segue_atras", first_tail.x < n.lander.global_position.x)
	var last: Dictionary = n._tail[-1]
	n._history.clear()
	var gx: float = n.lander.global_position.x
	for i in 40:                                               # nave rente ao chao: o ultimo da fila encosta e cai
		n._history.insert(0, Vector2(gx, TerrainGen.height_at(n.terrain.ridge, gx) + 10.0))
	n._tick_minigame()
	_check("nuvens_encostar_no_chao_perde_o_ultimo", n._tail.size() == 1 and n.minigame_got == 1)
	_check("nuvens_caiu_volta_para_buscar", not last["got"])
	var u: Dictionary = n._updrafts[0]
	n.lander.global_position = Vector2(float(u["x"]), TerrainGen.height_at(n.terrain.ridge, float(u["x"])) - 60.0)
	n._tick_minigame()
	_check("nuvens_corrente_empurra_para_cima", n.lander.env_accel.y < 0.0)
	n._judge_mission({"vy": 1.0}, 0.9)
	_check("nuvens_faltou_carneirinho_paga_menos", n.failed.has("passenger"))
	_check("nuvens_credito_parcial", is_equal_approx(float(n.minigame_partial().get("passenger", -1.0)),
			float(n.minigame_got) / float(n.minigame_total)))
	_check("verbo_das_nuvens", n.minigame_verb() == "Junte!")
	n.queue_free()
	await get_tree().process_frame
	# Cogumelos: chapeu-mola + ovinho (Pouso suave)
	var s3 := {"kind": "soft", "star": 3, "parts": [{"kind": "soft", "star": 3}]}
	var c := _flight("cogumelos", s3, 900.0)
	_check("cogumelos_3_chapeus", c._caps.size() == 3)
	var cap: Dictionary = c._caps[0]
	var feet_off := WorldConfig.m_to_px(float(WorldConfig.load_config()["lander"]["feet_offset_m"]))
	c.lander.global_position = Vector2(float(cap["x"]), float(cap["y"]) - feet_off + 2.0)
	c.lander.vel_m = Vector2(3.0, 6.0)
	c._tick_minigame()
	_check("cogumelos_chapeu_faz_quicar", c.lander.vel_m.y < -5.0 and c.minigame_got == 1)
	c.lander.vel_m = Vector2(0, -4.0)                          # subindo nao quica
	c._tick_minigame()
	_check("cogumelos_subindo_nao_quica", c.minigame_got == 1)
	c.lander.global_position = Vector2(float(cap["x"]), float(cap["y"]) - feet_off + 2.0)
	c.lander.vel_m = Vector2(0.0, 6.0)                         # 2o quique no mesmo chapeu: quica, mas nao conta
	c._tick_minigame()
	_check("cogumelos_chapeu_conta_uma_vez", c.lander.vel_m.y < 0.0 and c.minigame_got == 1 and c.minigame_extra == 2.0)
	_check("cogumelos_placar_n_de_N", c.minigame_text() == "1/3")
	c._judge_mission({"vy": 99.0}, 0.9)
	_check("cogumelos_pouso_forte_racha_o_ovo", c.failed.has("soft"))
	_check("verbo_dos_cogumelos", c.minigame_verb() == "Quique!")
	c.queue_free()
	await get_tree().process_frame
	# Sorvete: curling na pista de gelo (a plataforma escolhida vira o tamanho dos aneis)
	var f2 := {"kind": "fast", "star": 2, "parts": [{"kind": "fast", "star": 2}]}
	var sv: Flight = FLIGHT_SCENE.instantiate()
	add_child(sv)
	sv.start("sorvete", 7, EconMath.ship_stats({"thrust": 30, "tank": 20, "efficiency": 10}), false)
	sv.begin_mission(11, 900.0, "narrow", 1, f2)
	var rink: Dictionary = sv.terrain.pads[sv.target_pad_id]
	_check("sorvete_pista_larga", WorldConfig.px_to_m(float(rink["half_width"]) * 2.0) > 150.0)
	_check("sorvete_paga_a_plataforma_escolhida", sv.target_tier == "narrow" and sv._rings.size() == 5)   # gelo + 3 aneis + pino-fantasma
	sv.lander.state = Lander.State.FLYING
	sv.lander.global_position = Vector2(float(rink["x"]) - 60.0, float(rink["y"]) - 30.0)
	sv.lander.vel_m = Vector2(6.0, 2.0)
	sv._tick_minigame()
	_check("sorvete_fantasma_mostra_onde_para", sv._ghost.visible and sv._ghost.position.x > sv.lander.global_position.x)
	sv.lander.global_position.y = float(rink["y"]) - 200.0
	sv._tick_minigame()
	_check("sorvete_fantasma_some_no_alto", not sv._ghost.visible)
	sv.lander.state = Lander.State.LANDED
	var got: Array = []
	sv.delivery_finished.connect(func(r: Dictionary) -> void: got.append(r))
	sv.lander.global_position = Vector2(float(rink["x"]) - 120.0, float(rink["y"]) - 8.0)
	sv._on_lander_landed(rink, 0.9, {"vy": 1.0, "vx": 6.0, "tilt": 0.0, "gas_used": 5.0, "flight_time_m": 4.0})
	_check("sorvete_pousar_comeca_a_deslizar", sv.sliding and got.is_empty())
	var x0 := sv.lander.global_position.x
	for i in 3000:
		if not sv.sliding:
			break
		sv._tick_minigame()
	_check("sorvete_desliza_e_para", not sv.sliding and sv.lander.global_position.x > x0 and got.size() == 1)
	_check("sorvete_qualidade_pela_distancia", got.size() == 1 and float(got[0]["quality"]) >= 0.0
			and float(got[0]["quality"]) <= 1.0)
	_check("curling_centro_vale_mais", Minigames.curling_quality(2.0, 32.0) > Minigames.curling_quality(20.0, 32.0)
			and Minigames.curling_quality(40.0, 32.0) == 0.0)
	_check("verbo_do_sorvete", sv.minigame_verb() == "Deslize!")
	sv.queue_free()
	await get_tree().process_frame
	# Jardim: caules (Flappy Bird) + vento + mel pesado
	var h2 := {"kind": "heavy", "star": 2, "parts": [{"kind": "heavy", "star": 2}]}
	var j := _flight("jardim", h2, 900.0)
	_check("jardim_4_caules", j._stems.size() == 4)
	var st: Dictionary = j._stems[0]
	var mid := (float(st["gap_top"]) + float(st["gap_bot"])) * 0.5
	j.lander.global_position = Vector2(float(st["x"]) + float(st["half"]) + 3.0, mid)
	j._tick_minigame()
	_check("jardim_passar_pelo_vao_conta", st["passed"] and j.minigame_got == 1)
	var st2: Dictionary = j._stems[1]
	j.lander.vel_m = Vector2(10.0, 0.0)
	j.lander.global_position = Vector2(float(st2["x"]), float(st2["gap_top"]) - 20.0)
	j._tick_minigame()
	_check("jardim_bater_empurra_de_volta", j.lander.vel_m.x < 0.0 and st2["bumped"] and j.lander.state == Lander.State.FLYING)
	_check("jardim_vento_empurra_de_lado", absf(Minigames.wind_at(1.25, 2.0, 5.0)) > 1.9)
	j._judge_mission({"vy": 1.0}, 0.9)
	_check("jardim_faltou_vao_paga_menos", j.failed.has("heavy"))
	_check("verbo_do_jardim", j.minigame_verb() == "Passe!")
	j.queue_free()
	await get_tree().process_frame
	# Bolhas: garra do bau (maquina de garra) + mar + bolhas
	var t2 := {"kind": "tow", "star": 2, "parts": [{"kind": "tow", "star": 2}]}
	var bo := _flight("bolhas", t2, 900.0)
	_check("bolhas_bau_mar_e_bolhas", bo._chest_sprite != null and not bo._water.is_empty() and bo._bubbles.size() == 2)
	_check("bolhas_garra_comeca_leve", bo._tow.mass < 0.3)
	bo._tow.pos = bo._chest_pos
	bo._tick_minigame()
	_check("bolhas_garra_pega_o_bau", bo.chest_got and bo._tow.mass > 0.5 and bo.minigame_got == 1)
	bo._tow.pos = Vector2((float(bo._water["x0"]) + float(bo._water["x1"])) * 0.5, float(bo._water["y"]) + 20.0)
	for i in 90:                                               # wet_s da ★2 = 1,1 s
		bo._tow.pos.y = float(bo._water["y"]) + 20.0
		bo._tick_minigame()
	_check("bolhas_bau_no_mar_molha", bo.chest_wet and bo.failed.has("tow"))
	_check("bolhas_bau_molhado_paga_metade_do_que_falta", bo.minigame_partial() == {"tow": 0.5})
	var bx: float = float(bo._bubbles[0]["x"])
	bo.lander.global_position = Vector2(bx, float(bo._water["y"]) - 30.0)
	bo._tick_minigame()
	_check("bolhas_empurram_para_cima", bo.lander.env_accel.y < 0.0)
	bo.lander.global_position = Vector2(bx, float(bo._water["y"]) + 5.0)
	bo._tick_minigame()
	_check("bolhas_cair_no_mar_e_splash", bo.lander.state == Lander.State.CRASHED)
	_check("verbo_das_bolhas", bo.minigame_verb() == "Pesque!")
	bo.queue_free()
	print("MINIGAME_TEST " + ("OK" if _fails.is_empty() else "FALHOU " + "; ".join(_fails)))
	get_tree().quit(0 if _fails.is_empty() else 1)
