## Fisica do lander: gas = delta-v / eficiencia (contrato com a economy-balance).
extends TestCase

var params := {"gravity": 1.62, "thrust": 4.0, "efficiency": 3.0, "drag": 0.0}


func test_gas_gasto_igual_dv_sobre_eficiencia() -> void:
	var gas := 100.0
	var v := Vector2.ZERO
	var dv_total := 0.0
	for i in 60:
		var r := LanderPhysics.step(v, 0.0, true, gas, params, 1.0 / 60.0)
		v = r["velocity"]
		gas = r["gas"]
		dv_total += r["dv"]
	assert_almost(dv_total, 4.0, 1e-6, "1 s de propulsor a 4 m/s2 = 4 m/s")
	assert_almost(100.0 - gas, dv_total / 3.0, 1e-6)


func test_sem_propulsor_so_gravidade() -> void:
	var r := LanderPhysics.step(Vector2.ZERO, 0.0, false, 50.0, params, 1.0)
	assert_almost(r["velocity"].y, 1.62)
	assert_almost(r["gas"], 50.0)


func test_gas_acaba_no_meio_do_passo() -> void:
	var r := LanderPhysics.step(Vector2.ZERO, 0.0, true, 0.5, params, 1.0)
	assert_almost(r["gas"], 0.0)
	assert_almost(r["dv"], 1.5, 1e-6, "0.5 gas x 3 m/s por gas")


func test_propulsor_inclinado_empurra_de_lado() -> void:
	var r := LanderPhysics.step(Vector2.ZERO, PI / 2.0, true, 100.0, params, 1.0)
	assert_true(r["velocity"].x > 3.9, "nariz para a direita empurra para +x")


func test_ar_denso_perto_do_chao() -> void:
	var cfg := WorldConfig.load_config()
	var low := LanderPhysics.drag_at(0.3, 0.0, cfg)
	var high := LanderPhysics.drag_at(0.3, 2000.0, cfg)
	assert_true(low > high * 5.0, "rente ao chao o arrasto e bem maior")
	assert_almost(high, 0.3 * float(cfg["drag_scale"]), 1e-4, "no alto ~ o arrasto de sempre")
	assert_eq(LanderPhysics.drag_at(0.0, 0.0, cfg), 0.0, "sem ar (Lua) nao ha arrasto")


func test_giro_com_rampa_toque_fino() -> void:
	var rc: Dictionary = WorldConfig.load_config()["rotation"]
	assert_almost(Lander.rotation_speed(0.0, rc), float(rc["start_speed"]))
	assert_almost(Lander.rotation_speed(10.0, rc), float(rc["max_speed"]))
	# toque de 0,1 s gira menos que a tolerancia de inclinacao (antes: 0,4 rad > 0,35)
	var ang := 0.0
	var t := 0.0
	for i in 6:
		t += 1.0 / 60.0
		ang += Lander.rotation_speed(t, rc) / 60.0
	assert_true(ang < float(WorldConfig.load_config()["landing"]["max_tilt"]) * 0.75, "toque curto = ajuste fino")


func test_empuxo_sentido_tem_teto() -> void:
	var f: Dictionary = EconMath.spec["physics"]["feel"]
	assert_almost(EconMath.felt_thrust(4.0, 1.62), 4.0, 1e-9, "nave de serie igual")
	var big := EconMath.felt_thrust(50.0, 1.62) - 1.62
	assert_true(big <= float(f["max"]) + 1e-6 and big > float(f["knee"]), "motor forte sente no maximo max")
	assert_true(EconMath.felt_thrust(16.0, 1.62) > EconMath.felt_thrust(10.0, 1.62), "degrau maior ainda sente mais")
