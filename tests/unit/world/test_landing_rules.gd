## Regras de pouso e qualidade q.
extends TestCase

var landing: Dictionary
var tol: Dictionary


func before_each() -> void:
	landing = WorldConfig.load_config()["landing"]
	tol = LandingRules.tolerances(landing, 1.0)


func test_pouso_perfeito_q_1() -> void:
	assert_almost(LandingRules.quality(0.0, 0.0, 0.0, 0.0, tol, landing["weights"]), 1.0)


func test_pouso_no_limite_q_baixo() -> void:
	var q := LandingRules.quality(tol["max_vy"], tol["max_vx"], tol["max_tilt"], 1.0, tol, landing["weights"])
	assert_almost(q, 0.0)


func test_batidas() -> void:
	assert_eq(LandingRules.crash_reason(0.5, 0.0, 0.0, false, tol), "fora_da_plataforma")
	assert_eq(LandingRules.crash_reason(tol["max_vy"] + 0.1, 0.0, 0.0, true, tol), "vertical_rapido")
	assert_eq(LandingRules.crash_reason(0.5, tol["max_vx"] + 0.1, 0.0, true, tol), "horizontal_rapido")
	assert_eq(LandingRules.crash_reason(0.5, 0.0, tol["max_tilt"] + 0.05, true, tol), "inclinado")
	assert_eq(LandingRules.crash_reason(0.5, 0.2, 0.05, true, tol), "")


func test_trem_de_pouso_amplia_tolerancia() -> void:
	var t4 := LandingRules.tolerances(landing, 4.0)
	assert_almost(t4["max_vy"], tol["max_vy"] * 2.0, 1e-6, "gear 4 com expoente 0.5 = x2")
