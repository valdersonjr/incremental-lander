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
	assert_almost(t4["max_vy"], tol["max_vy"] * pow(4.0, float(landing["gear_exp"])), 1e-6, "gear^gear_exp")
	assert_true(t4["max_vy"] < tol["max_vy"] * 1.5, "Resistencia nao deixa o pouso impossivel de errar")


func test_pouso_perfeito_reto_e_macio() -> void:
	var land := {"max_vy": 7.0, "max_tilt": 0.35, "perfect": {"vy_frac": 0.4, "tilt_frac": 0.25}}
	assert_true(LandingRules.is_perfect(2.0, 0.05, land))
	assert_false(LandingRules.is_perfect(3.5, 0.0, land), "duro demais")
	assert_false(LandingRules.is_perfect(1.0, 0.2, land), "torto demais")
	assert_false(LandingRules.is_perfect(1.0, 0.0, {"max_vy": 7.0, "max_tilt": 0.35}), "sem regra = nunca")


func test_raspao_devagar_quica_e_sai_do_chao() -> void:
	var sc: Dictionary = landing["scrape"]
	var r := LandingRules.scrape_bounce(Vector2(3.0, 5.0), Vector2.UP, 1.0, 0, false, sc)
	assert_true(r["ok"])
	var v: Vector2 = r["velocity"]
	assert_true(v.y < 0.0, "quica para cima")
	assert_true(-v.y >= float(sc["min_out_mps"]) - 1e-6, "sai no minimo min_out")
	assert_almost(v.x, 3.0 * float(sc["friction"]), 1e-6, "atrito no tangente")


func test_raspao_forte_ou_amassados_esgotados_bate() -> void:
	var sc: Dictionary = landing["scrape"]
	var fast := Vector2(0.0, float(sc["max_mps"]) + 0.5)
	assert_false(LandingRules.scrape_bounce(fast, Vector2.UP, 1.0, 0, false, sc)["ok"], "forte demais")
	assert_true(LandingRules.scrape_bounce(fast, Vector2.UP, 2.0, 0, false, sc)["ok"], "Resistencia aguenta mais")
	var slow := Vector2(0.0, 3.0)
	assert_false(LandingRules.scrape_bounce(slow, Vector2.UP, 1.0, int(sc["per_hop"]), false, sc)["ok"], "sem amassado")
	assert_true(LandingRules.scrape_bounce(slow, Vector2.UP, 1.0, int(sc["per_hop"]), true, sc)["ok"], "carencia so quica")


func test_raspao_em_rampa_usa_a_normal() -> void:
	# deslizando rente a uma rampa de 45 graus: quase nada contra o chao -> quica mesmo rapido
	var n := Vector2(1.0, -1.0).normalized()
	var r := LandingRules.scrape_bounce(Vector2(20.0, 19.0), n, 1.0, 0, false, landing["scrape"])
	assert_true(r["ok"])
	assert_true((r["velocity"] as Vector2).dot(n) > 0.0, "sai da rampa")
