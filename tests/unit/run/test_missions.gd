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


func test_cada_mundo_oferece_so_o_pedido_dele() -> void:
	var un := EconMath.missions_unlocked(["heavy1", "soft1"])
	assert_eq(un, {"simple": 1, "heavy": 1, "soft": 1})
	var cog := RunState.create("cogumelos", EconMath.ship_stats({}), 3, un)
	assert_eq(cog.offers.size(), 3, "3 pedidos do sapinho (perto/medio/longe)")
	for m: Dictionary in cog.offer_mission:
		assert_eq(m["kind"], "soft", "Cogumelos = Pouso suave")
	var lua := RunState.create("luna", EconMath.ship_stats({}), 3, un)
	for m: Dictionary in lua.offer_mission:
		assert_eq(m["kind"], "simple", "na Lua so o mineiro, mesmo com outros liberados")


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
