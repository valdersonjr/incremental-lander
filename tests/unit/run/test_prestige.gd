## Prestigio: ganho da spec, requisito de Ares, reset, loja e itens que mudam o recomeco.
extends TestCase


func _state(credits_cycle: float) -> Dictionary:
	return {"resources": {"credits": 5e6, "ore": 10.0, "stardust": 0.0}, "levels": {"tank": 10, "exp1_station": 1},
			"shop": {}, "unlocked": ["luna", "ares"], "current_planet": "ares", "prestige_points": 0.0,
			"cycle_earned": {"credits": credits_cycle}}


func before_each() -> void:
	EconMath.load_spec()


func test_ganho_igual_formula_da_spec() -> void:
	var st := _state(1e9)
	assert_almost(Prestige.gain(st), EconMath.prestige_gain(1e9))


func test_exige_ares_e_ganho_minimo() -> void:
	var st := _state(1e12)
	st["unlocked"] = ["luna"]
	assert_false(Prestige.can_prestige(st))
	assert_false(Prestige.can_prestige(_state(10.0)), "ganho abaixo do minimo")
	assert_true(Prestige.can_prestige(_state(1e12)))


func test_reset_mantem_poeira_e_etapas() -> void:
	var st := _state(1e12)
	var g := Prestige.apply(st)
	assert_true(g >= 20.0)
	assert_almost(st["resources"]["stardust"], g)
	assert_almost(st["prestige_points"], g)
	assert_almost(st["resources"]["credits"], 0.0)
	assert_false(st["levels"].has("tank"), "upgrades comuns resetam")
	assert_eq(st["levels"].get("exp1_station", 0), 1, "etapa da Expedicao e persistente")
	assert_eq(st["unlocked"], ["luna"])
	assert_eq(st["cycle_earned"], {})


func test_loja_muda_o_recomeco() -> void:
	var st := _state(1e12)
	st["resources"]["stardust"] = 1000.0
	assert_true(Prestige.buy_shop(st, "capital"))
	assert_true(Prestige.buy_shop(st, "pilot_file"))
	assert_true(Prestige.buy_shop(st, "star_charts"))
	Prestige.apply(st)
	assert_almost(st["resources"]["credits"], 20000.0, 1e-6, "capital inicial nv1")
	assert_eq(st["levels"]["thrust"], 3, "ficha de piloto nv1")
	assert_eq(st["unlocked"], ["luna", "ares"], "cartas de navegacao mantem planetas")


func test_loja_respeita_nivel_maximo() -> void:
	var st := _state(0.0)
	st["resources"]["stardust"] = 1e6
	assert_true(Prestige.buy_shop(st, "star_charts"))
	assert_false(Prestige.buy_shop(st, "star_charts"), "max_level 1")


func test_coletar_comprar_e_resetar() -> void:
	var st := _state(1e12)
	var g := Prestige.collect(st)
	assert_true(g >= 20.0)
	assert_eq(st["levels"].get("tank", 0), 10, "coletar nao reseta ainda")
	assert_true(Prestige.buy_shop(st, "capital"))
	Prestige.reset(st)
	assert_almost(st["resources"]["credits"], 20000.0, 1e-6, "loja comprada entre coletar e resetar vale ja")
	assert_almost(Prestige.collect(st), 0.0, 1e-9, "ciclo zerado: nao coleta de novo")
