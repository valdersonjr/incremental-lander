## Queijao rebocado (CargoTow) e Estabilizador (Lander.stabilize_input) — Lua, 2026-10-05.
extends TestCase

var ridge := PackedVector2Array([Vector2(-5000, 0), Vector2(5000, 0)])   # chao plano em y = 0


func test_comeca_no_chao_atras_da_nave() -> void:
	var t := CargoTow.create(Vector2(0, -8), ridge, 1)
	assert_true(t.pos.x < 0.0, "destino a direita: carga fica a esquerda")
	assert_almost(t.pos.y, -t.radius_px, 1e-3)
	assert_false(t.damaged)


func test_cabo_esticado_puxa_a_nave_para_baixo_e_ergue_a_carga() -> void:
	var t := CargoTow.create(Vector2(0, -8), ridge, 1)
	t.pos = Vector2(0, -t.radius_px)
	var anchor := Vector2(0, -8 - t.rope_px - 10.0)               # nave subiu alem do cabo
	var dv := t.step(anchor, Vector2(0, -5), 0.05, 1.62, ridge, true)
	assert_true(dv.y > 0.0, "o cabo puxa a nave para baixo (dv %s)" % dv)
	assert_true(t.vel.y < 0.0, "a carga sobe junto")
	assert_almost(t.pos.distance_to(anchor), t.rope_px, 1e-3)


func test_cabo_frouxo_nao_puxa() -> void:
	var t := CargoTow.create(Vector2(0, -8), ridge, 1)
	var dv := t.step(Vector2(t.pos.x + 2.0, t.pos.y - 3.0), Vector2.ZERO, 0.05, 1.62, ridge, true)
	assert_eq(dv, Vector2.ZERO)


func test_bater_forte_racha_e_devagar_nao() -> void:
	var t := CargoTow.create(Vector2(0, -8), ridge, 1)
	t.pos = Vector2(0, -20)
	t.vel = Vector2(0, 2.0)
	for i in 40:
		t.step(Vector2(0, -20 - t.rope_px * 0.5), Vector2.ZERO, 0.05, 1.62, ridge, false)
	assert_false(t.damaged, "pousar o queijo devagar nao racha")
	t.pos = Vector2(0, -40)
	t.vel = Vector2(0, float(WorldConfig.load_config()["missions"]["tow"]["break_speed"]) + 3.0)
	for i in 200:                                                  # cabo frouxo (ancora logo acima): cai livre
		t.step(Vector2(0, -30), Vector2.ZERO, 0.05, 1.62, ridge, false)
	assert_true(t.damaged, "bater rapido racha o queijo")


func test_estabilizador_gira_de_volta_para_cima() -> void:
	assert_true(Lander.stabilize_input(0.5, 4.0) < 0.0)
	assert_true(Lander.stabilize_input(-0.5, 4.0) > 0.0)
	assert_almost(Lander.stabilize_input(0.0, 4.0), 0.0)
	assert_almost(Lander.stabilize_input(2.0, 4.0), -1.0, 1e-6, "limitado a -1..1")
