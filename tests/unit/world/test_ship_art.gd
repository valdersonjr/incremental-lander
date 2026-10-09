## Pecas que crescem por degrau (ShipArt): versao pelo nivel, animacoes do corpo/chama existem para toda combinacao,
## boca do bocal e recortes do poster dentro do atlas.
extends TestCase


func test_versao_pelo_degrau() -> void:
	for pair: Array in [[0, 0], [9, 0], [10, 1], [29, 1], [30, 2], [59, 2], [60, 3], [80, 3], [500, 3]]:
		assert_eq(ShipArt.tier("thrust", pair[0]), pair[1], "motor nivel %d" % pair[0])
		assert_eq(ShipArt.tier("tank", pair[0]), pair[1], "tanque nivel %d" % pair[0])
	for pair: Array in [[0, 0], [10, 1], [20, 2], [30, 3], [99, 3]]:
		assert_eq(ShipArt.tier("gear", pair[0]), pair[1], "pernas nivel %d" % pair[0])


func test_sem_niveis_e_tudo_de_serie() -> void:
	var t := ShipArt.tiers({})
	assert_eq(ShipArt.body_anim(t), &"b_000")
	assert_eq(ShipArt.flame_anim(t), &"flame_0")
	assert_eq(ShipArt.mouth(t), 21, "boca do bocal de serie = a da nave de sempre")


func test_toda_combinacao_tem_desenho() -> void:
	var body: SpriteFrames = load("res://assets/sprites/lander_body_frames.tres")
	var flame: SpriteFrames = load("res://assets/sprites/lander_flame_frames.tres")
	var atlas: Texture2D = load("res://assets/sprites/ship_poster.png")
	var fatlas: Texture2D = load("res://assets/sprites/ship_poster_flame.png")
	for a in 4:
		for b in 4:
			for c in 4:
				var t := {"tank": a, "efficiency": b, "gear": c, "thrust": c}
				assert_true(body.has_animation(ShipArt.body_anim(t)), "corpo %s" % ShipArt.body_anim(t))
				var r := ShipArt.poster_region(t)
				assert_true(Rect2(Vector2.ZERO, atlas.get_size()).encloses(r), "poster %s" % r)
		assert_true(flame.has_animation(ShipArt.flame_anim({"thrust": a})), "chama %d" % a)
		assert_true(Rect2(Vector2.ZERO, fatlas.get_size()).encloses(ShipArt.poster_flame_region({"thrust": a}, 3)))


func test_bocal_maior_empurra_a_chama_para_baixo() -> void:
	var last := 0
	for e in 4:
		var m := ShipArt.mouth({"efficiency": e})
		assert_true(m >= last, "boca nao sobe")
		last = m
		assert_true(ShipArt.mouth({"efficiency": e}, true) > 40, "poster: boca abaixo do disco")


func test_destaque_do_poster_tem_caixa() -> void:
	for p: String in ["tank", "efficiency", "gear"]:
		for v in 4:
			var boxes := ShipArt.poster_boxes(p, {p: v})
			assert_eq(boxes.size(), 1 if p == "efficiency" else 2, "%s: uma caixa por lado" % p)
			for box: Rect2 in boxes:
				assert_true(box.size.x > 0 and box.size.y > 0, "%s versao %d" % [p, v])
