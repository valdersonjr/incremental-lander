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
	_check("lua_placar_no_hud", f.minigame_text() == "queijinhos 3/%d" % f.minigame_total)
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
	var u: Dictionary = n._updrafts[0]
	n.lander.global_position = Vector2(float(u["x"]), TerrainGen.height_at(n.terrain.ridge, float(u["x"])) - 60.0)
	n._tick_minigame()
	_check("nuvens_corrente_empurra_para_cima", n.lander.env_accel.y < 0.0)
	n._judge_mission({"vy": 1.0}, 0.9)
	_check("nuvens_faltou_carneirinho_paga_menos", n.failed.has("passenger"))
	_check("verbo_das_nuvens", n.minigame_verb() == "Junte!")
	n.queue_free()
	print("MINIGAME_TEST " + ("OK" if _fails.is_empty() else "FALHOU " + "; ".join(_fails)))
	get_tree().quit(0 if _fails.is_empty() else 1)
