## Arvore de missoes (v12): regras da arvore, sorteio so do que esta liberado. O fluxo com o GameState (estrelas ->
## liberar -> destaque) fica na integracao release_fixes (autoloads nao existem nos testes unitarios).
extends TestCase


func before_each() -> void:
	EconMath.load_spec()


func _node(id: String) -> Dictionary:
	for n: Dictionary in EconMath.mission_spec()["nodes"]:
		if n["id"] == id:
			return n
	return {}


func test_arvore_pede_os_anteriores() -> void:
	assert_true(EconMath.mission_node_ok(_node("heavy1"), []), "estrela 1 de Pesada aberta desde o comeco")
	assert_false(EconMath.mission_node_ok(_node("heavy2"), []), "estrela 2 pede a 1")
	assert_true(EconMath.mission_node_ok(_node("heavy2"), ["heavy1"]))
	assert_false(EconMath.mission_node_ok(_node("passenger1"), ["heavy1"]), "passageiro pede 2 tipos de estrela 1")
	assert_true(EconMath.mission_node_ok(_node("passenger1"), ["heavy1", "fast1"]))
	assert_false(EconMath.mission_node_ok(_node("heavy1"), ["heavy1"]), "nao libera duas vezes")
	assert_false(EconMath.mission_node_ok(_node("double1"), ["heavy1", "heavy2", "heavy3"]), "dupla pede 2 tipos na 3")
	assert_eq(EconMath.mission_node_cost(_node("heavy1")), 3)


func test_liberadas_viram_pedidos() -> void:
	var un := EconMath.missions_unlocked(["heavy1"])
	assert_eq(un, {"simple": 1, "heavy": 1})
	var viu := false
	for s in 10:
		var run := RunState.create("luna", EconMath.ship_stats({}), s, un, {"heavy": 2})
		for m: Dictionary in run.offer_mission:
			viu = viu or m["kind"] == "heavy"
	assert_true(viu, "Pesada aparece nos pedidos depois de liberada")


func test_dupla_junta_duas_regras_diferentes() -> void:
	var un := EconMath.missions_unlocked(["heavy1", "soft1", "fast1", "heavy2", "heavy3", "soft2", "soft3", "double1"])
	var rng := RandomNumberGenerator.new()
	var viu := false
	for s in 80:
		rng.seed = s
		var m := EconMath.draw_mission("luna", un, {"double": 1}, EconMath.ship_stats({"thrust": 10}), rng)
		if m["kind"] == "double":
			viu = true
			assert_eq((m["parts"] as Array).size(), 2)
			assert_true(m["parts"][0]["kind"] != m["parts"][1]["kind"], "duas regras diferentes")
	assert_true(viu)


func test_pesada_que_nao_decola_nao_e_sorteada() -> void:
	# motor fraco demais para a Pesada 2-3 na gravidade: o sorteio pula essas estrelas (a nave nem sairia do chao)
	var weak := EconMath.ship_stats({})
	weak["thrust"] = 1.62 * 1.05 * 1.5
	var rng := RandomNumberGenerator.new()
	for s in 60:
		rng.seed = s
		var m := EconMath.draw_mission("luna", {"simple": 1, "heavy": 3}, {}, weak, rng)
		if m["kind"] == "heavy":
			assert_eq(int(m["star"]), 1, "so a estrela que decola (motor / 1,3) com este motor")
