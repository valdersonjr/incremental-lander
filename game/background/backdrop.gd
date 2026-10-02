## Fundo em camadas (ceu, planeta, montanhas, planicie) em espaco de tela, atras do mundo.
## Cada camada rola com o proprio fator (data/world.json -> background.layers) via TerrainArt.layer_offset.
## Planeta sem arte (sem <planeta>_layers.json): fica vazio e o terreno usa o placeholder.
class_name Backdrop
extends CanvasLayer

const LAYERS: Array[String] = ["sky", "clouds", "planet", "far", "mid", "plain"]
const REPEATING: Array[String] = ["clouds", "far", "mid", "plain"]

var _ref_y := 0.0
var _sprites: Dictionary = {}   # nome -> Sprite2D
var _base: Dictionary = {}      # nome -> Vector2 (posicao na tela com a camera no chao)
var _factors: Dictionary = {}   # nome -> Vector2
var _min_y := -INF              # limites do deslocamento vertical (ver setup)
var _max_y := INF
var _anim: Dictionary = {}      # nome -> {"frames": int, "ms": float, "h": float} (quadros empilhados na vertical)
var _scroll: Dictionary = {}    # nome -> px/s de rolagem propria (nuvens)
var _time := 0.0
var _war: WarFx = null          # guerra no fundo (opcional: meta "war"), acompanha a camada mid


## Monta as camadas do planeta. ref_y = y da camera (mundo) quando o lander esta no chao da partida.
func setup(planet_id: String, ref_y: float) -> void:
	for c in get_children():
		c.queue_free()
	_sprites.clear()
	_war = null
	_anim.clear()
	_scroll.clear()
	_ref_y = ref_y
	var meta := TerrainArt.load_meta(planet_id)
	if meta.is_empty():
		return
	var bg: Dictionary = WorldConfig.load_config()["background"]
	var shift := float(bg["horizon_screen"]) - float(meta["horizon"])
	var clouds: Dictionary = meta.get("clouds", {})
	# wall_mode (ex.: o quarto): parede e janela fazem parte do mesmo espaco dos moveis -> acompanham o horizonte
	var wall_mode := bool(meta.get("wall_mode", false))
	var tops := {"sky": Vector2(0, float(meta.get("sky_y", 0.0))), "planet": _vec(meta["planet_pos"]), "far": Vector2(0, meta["far_y"]),
		"mid": Vector2(0, meta["mid_y"]), "plain": Vector2(0, meta["plain_y"]),
		"clouds": Vector2(0, float(clouds.get("y", 0.0)))}
	var anim: Dictionary = meta.get("anim", {})
	for layer_name in LAYERS:
		var path := "res://assets/bg/%s_%s.png" % [planet_id, layer_name]
		if layer_name == "clouds" and (clouds.is_empty() or not ResourceLoader.exists(path)):
			continue                                          # camada opcional
		var tex := load(path) as Texture2D
		var frames := int(anim.get(layer_name, {}).get("frames", 1))
		var frame_h := float(tex.get_height()) / frames
		var s := Sprite2D.new()
		s.name = layer_name.capitalize()
		s.texture = tex
		s.centered = false
		s.region_enabled = true                                # regiao: quadro da animacao (y) e rolagem (x)
		s.region_rect = Rect2(0, 0, tex.get_width(), frame_h)
		if layer_name in REPEATING:
			s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED   # laco horizontal
		add_child(s)
		_sprites[layer_name] = s
		if frames > 1:
			_anim[layer_name] = {"frames": frames, "ms": float(anim[layer_name]["ms"]), "h": frame_h}
		if layer_name == "clouds":
			_scroll[layer_name] = float(clouds.get("speed", 0.0))
		# ceu e nuvens ficam presos a tela; o resto acompanha o horizonte deslocado para perto do chao
		var screen_fixed := layer_name in ["sky", "clouds"] and not wall_mode
		_base[layer_name] = tops[layer_name] + (Vector2.ZERO if screen_fixed else Vector2(0, shift))
		_factors[layer_name] = _vec(bg["layers"][layer_name])
		if wall_mode and layer_name in ["sky", "planet"]:
			_factors[layer_name] = Vector2(0.0, _vec(bg["layers"]["far"]).y)   # sobe/desce junto com os moveis
	if meta.has("war") and _sprites.has("mid"):
		_war = WarFx.new()
		_war.name = "War"
		add_child(_war)
		move_child(_war, (_sprites["mid"] as Sprite2D).get_index() + 1)   # na frente das montanhas do meio
		_war.setup(meta["war"], hash(planet_id))
	# a planicie (camada mais baixa) precisa sempre cobrir o pe da tela: o fundo desce no maximo ate sobrar
	# ground_margin px de planicie, e sobe no maximo ate o fim da textura da planicie
	var view_h := float(ProjectSettings.get_setting("display/window/size/viewport_height"))
	var plain_top: float = _base["plain"].y
	var plain_h := (_sprites["plain"] as Sprite2D).region_rect.size.y
	_max_y = view_h - float(bg["ground_margin"]) - plain_top
	_min_y = view_h - (plain_top + plain_h)
	follow(Vector2(0, ref_y))


## Atualiza as camadas para a camera centrada em cam (mundo).
func follow(cam: Vector2) -> void:
	for layer_name: String in _sprites:
		var s: Sprite2D = _sprites[layer_name]
		var off := TerrainArt.layer_offset(cam, _ref_y, _factors[layer_name], _min_y, _max_y)
		if layer_name == "clouds":
			off.y = 0.0                                          # nuvens: so rolam em x (presas ao ceu)
		s.position = _base[layer_name] + Vector2(0, off.y)
		if layer_name in REPEATING:
			s.region_rect.position.x = off.x + roundf(_time * float(_scroll.get(layer_name, 0.0)))
	if _war != null:
		var mid: Sprite2D = _sprites["mid"]
		_war.position = mid.position
		_war.scroll_x = mid.region_rect.position.x


func _process(delta: float) -> void:
	_time += delta
	for layer_name: String in _anim:
		var a: Dictionary = _anim[layer_name]
		var s: Sprite2D = _sprites[layer_name]
		s.region_rect.position.y = TerrainArt.anim_frame(_time, a["ms"], a["frames"]) * float(a["h"])


func _vec(a: Variant) -> Vector2:
	var arr: Array = a
	return Vector2(float(arr[0]), float(arr[1]))
