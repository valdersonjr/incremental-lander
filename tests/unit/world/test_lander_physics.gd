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
