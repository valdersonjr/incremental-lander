## Testes de sanidade do EconMath (a paridade completa com o Python fica em tests/test_econ_parity.py).
extends TestCase


func before_each() -> void:
	EconMath.load_spec()


func test_formatacao_de_numeros() -> void:
	assert_eq(EconMath.fmt(999), "999")
	assert_eq(EconMath.fmt(1234), "1,23K")
	assert_eq(EconMath.fmt(1.5e15), "1,50Qa")


func test_custo_cresce_com_nivel() -> void:
	var c0: float = EconMath.upgrade_cost("tank", 0)["credits"]
	var c10: float = EconMath.upgrade_cost("tank", 10)["credits"]
	assert_true(c10 > c0 * 3.0, "custo nivel 10 deveria ser bem maior que o nivel 0")


func test_peca_so_melhora_no_degrau() -> void:
	var s10 := EconMath.ship_stats({"thrust": 10, "tank": 10})
	var s15 := EconMath.ship_stats({"thrust": 15, "tank": 19})
	var s20 := EconMath.ship_stats({"thrust": 20})
	assert_almost(float(s15["thrust"]), float(s10["thrust"]), 1e-9, "bolinhas do meio nao mudam o Motor")
	assert_almost(float(s15["tank"]), float(s10["tank"]), 1e-9, "nem a Gasolina")
	assert_true(float(s20["thrust"]) > float(s10["thrust"]), "degrau novo melhora")
	assert_almost(float(EconMath.ship_stats({"thrust": 9})["thrust"]), float(EconMath.ship_stats({})["thrust"]), 1e-9)
