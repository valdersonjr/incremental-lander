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
