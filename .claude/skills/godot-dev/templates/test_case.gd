## Base dos testes unitarios (skill godot-dev). Cada arquivo tests/unit/**/test_*.gd estende TestCase
## e define metodos test_*(). Opcional: before_each() / after_each(). Rodar: gdtool.py test
class_name TestCase
extends RefCounted

var tree: SceneTree
var _test_name := ""
var _messages: Array[String] = []


func begin(test_name: String) -> void:
	_test_name = test_name
	_messages.clear()


func current_failed() -> bool:
	return not _messages.is_empty()


func messages() -> Array[String]:
	return _messages


func fail(msg: String) -> void:
	_messages.append(msg)


func assert_true(cond: bool, msg: String = "") -> void:
	if not cond:
		fail("esperava true. " + msg)


func assert_false(cond: bool, msg: String = "") -> void:
	if cond:
		fail("esperava false. " + msg)


func assert_eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	if actual != expected:
		fail("esperava %s, veio %s. %s" % [str(expected), str(actual), msg])


func assert_almost(actual: float, expected: float, eps: float = 1e-6, msg: String = "") -> void:
	if absf(actual - expected) > eps * maxf(1.0, absf(expected)):
		fail("esperava ~%s, veio %s. %s" % [str(expected), str(actual), msg])


func assert_between(value: float, lo: float, hi: float, msg: String = "") -> void:
	if value < lo or value > hi:
		fail("esperava %s em [%s, %s]. %s" % [str(value), str(lo), str(hi), msg])
