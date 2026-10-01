## Fundo em camadas (ceu, planeta, montanhas, planicie) em espaco de tela, atras do mundo.
## Cada camada rola com o proprio fator (data/world.json -> background.layers) via TerrainArt.layer_offset.
## Planeta sem arte (sem <planeta>_layers.json): fica vazio e o terreno usa o placeholder.
class_name Backdrop
extends CanvasLayer

const LAYERS: Array[String] = ["sky", "planet", "far", "mid", "plain"]

var _ref_y := 0.0
var _sprites: Dictionary = {}   # nome -> Sprite2D
var _base: Dictionary = {}      # nome -> Vector2 (posicao na tela com a camera no chao)
var _factors: Dictionary = {}   # nome -> Vector2


## Monta as camadas do planeta. ref_y = y da camera (mundo) quando o lander esta no chao da partida.
func setup(planet_id: String, ref_y: float) -> void:
	for c in get_children():
		c.queue_free()
	_sprites.clear()
	_ref_y = ref_y
	var meta := TerrainArt.load_meta(planet_id)
	if meta.is_empty():
		return
	var bg: Dictionary = WorldConfig.load_config()["background"]
	var shift := float(bg["horizon_screen"]) - float(meta["horizon"])
	var tops := {"sky": Vector2.ZERO, "planet": _vec(meta["planet_pos"]), "far": Vector2(0, meta["far_y"]),
		"mid": Vector2(0, meta["mid_y"]), "plain": Vector2(0, meta["plain_y"])}
	for layer_name in LAYERS:
		var tex := load("res://assets/bg/%s_%s.png" % [planet_id, layer_name]) as Texture2D
		var s := Sprite2D.new()
		s.name = layer_name.capitalize()
		s.texture = tex
		s.centered = false
		if layer_name in ["far", "mid", "plain"]:
			# laco horizontal: a regiao rola sobre a textura repetida
			s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			s.region_enabled = true
			s.region_rect = Rect2(0, 0, tex.get_width(), tex.get_height())
		add_child(s)
		_sprites[layer_name] = s
		# o ceu fica preso a tela; o resto acompanha o horizonte deslocado para perto do chao
		_base[layer_name] = tops[layer_name] + (Vector2.ZERO if layer_name == "sky" else Vector2(0, shift))
		_factors[layer_name] = _vec(bg["layers"][layer_name])
	follow(Vector2(0, ref_y))


## Atualiza as camadas para a camera centrada em cam (mundo).
func follow(cam: Vector2) -> void:
	for layer_name: String in _sprites:
		var s: Sprite2D = _sprites[layer_name]
		var off := TerrainArt.layer_offset(cam, _ref_y, _factors[layer_name])
		s.position = _base[layer_name] + Vector2(0, off.y)
		if s.region_enabled:
			s.region_rect.position.x = off.x


func _vec(a: Variant) -> Vector2:
	var arr: Array = a
	return Vector2(float(arr[0]), float(arr[1]))
