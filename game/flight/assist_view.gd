## Ajudas de voo desenhadas no mundo (arvore do Painel de bordo; quem tem cada uma: GameState.assist_on).
## Setinha (gratis) em volta da nave apontando a plataforma -> Setinha colorida (longe/perto/chegando) -> Rastro (arco
## ideal so a frente) -> Rota (arco inteiro). Sombra (marca no chao + tracejado) -> Nivelador (linha da inclinacao perto do
## chao) -> Onde vou cair (queda sem motor + X verde/amarelo/vermelho). Geometria pura em Assists; numeros em world.json.
## Placeholder em _draw com cores da Resurrect 64 e contorno escuro (estilo fofo: forma cheia + contorno ink).
class_name AssistView
extends Node2D

const INK := Color("#2e222f")
const MIST := Color("#c7dcd0")
const WHITE := Color("#ffffff")
const SHADOW := Color("#3e3546")
const GOLD := Color("#f9c22b")                  # pontos do caminho: dourados para nao parecerem estrelas
const HONEY := Color("#fbb954")
const TIER_COLOR := {"far": Color("#4d9be6"), "mid": Color("#f9c22b"), "near": Color("#1ebc73")}
const VERDICT_COLOR := {"good": Color("#1ebc73"), "hard": Color("#f9c22b"), "miss": Color("#e83b3b")}

var flight: Flight = null

var _arc: Array[Vector2] = []
var _arc_key := Vector2i(-1, -1)
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if flight == null or flight.target_pad_id < 0:
		return
	var l := flight.lander
	if l.state == Lander.State.CRASHED:
		return
	var flying := l.state == Lander.State.FLYING
	var cfg: Dictionary = WorldConfig.load_config()
	var ac: Dictionary = cfg["assists"]
	var target := flight.target_pad()
	var ground := TerrainGen.height_at(flight.terrain.ridge, l.global_position.x)
	var alt_m := WorldConfig.px_to_m(ground - l.global_position.y) - float(cfg["lander"]["feet_offset_m"])
	if GameState.assist_on("nav_route") or GameState.assist_on("nav_trail"):
		_draw_arc(GameState.assist_on("nav_route"), float(ac["trail_m"]))
	if flying and GameState.assist_on("land_shadow"):
		_draw_shadow(l.global_position, ground)
	if flying and GameState.assist_on("land_predict"):
		_draw_predict(target, cfg)
	if flying and GameState.assist_on("land_level") and alt_m < float(ac["level_alt_m"]):
		_draw_level(l, cfg)
	if GameState.assist_on(GameState.ASSIST_FREE):
		_draw_arrow(l.global_position, target, float(ac["arrow_r_px"]))


## Setinha: triangulo gordinho com contorno, a arrow_r_px do centro da nave, apontando o centro da plataforma.
## Some quando a nave ja esta em cima da plataforma.
func _draw_arrow(at: Vector2, target: Dictionary, r: float) -> void:
	var goal := Vector2(float(target["x"]), float(target["y"]) - 8.0)
	var to := goal - at
	if to.length() < r + 12.0:
		return
	var dir := to.normalized()
	var color := WHITE
	var size := 1.0
	if GameState.assist_on("nav_color"):
		var origin := flight.terrain.pads[flight.current_pad_id]
		var total := absf(float(target["x"]) - float(origin["x"]))
		var frac := absf(float(target["x"]) - at.x) / maxf(total, 1.0)
		var tier := Assists.arrow_tier(frac)
		color = TIER_COLOR[tier]
		if tier == "near":                                     # chegando: pulsa
			size = 1.0 + 0.18 * (0.5 + 0.5 * sin(_t * 9.0))
	var side := dir.orthogonal()
	var c := at + dir * r
	var tip := c + dir * 7.0 * size
	var base := c - dir * 3.0 * size
	var pts := PackedVector2Array([tip, base + side * 6.0 * size, base - side * 6.0 * size])
	var outline := PackedVector2Array([tip + dir * 2.0, base + side * 8.0 * size - dir * 1.5,
			base - side * 8.0 * size - dir * 1.5])
	draw_colored_polygon(outline, INK)
	draw_colored_polygon(pts, color)


## Rastro (so trail_m a frente da nave) ou Rota (o arco inteiro): pontinhos com contorno sobre o arco ideal.
func _draw_arc(full: bool, trail_m: float) -> void:
	var key := Vector2i(flight.current_pad_id, flight.target_pad_id)
	if key != _arc_key:
		_arc_key = key
		var n := int(WorldConfig.load_config()["assists"]["arc_points"])
		_arc = Assists.arc(flight.terrain.pads[key.x], flight.terrain.pads[key.y], n)
	var x := flight.lander.global_position.x
	var dir := signf(_arc[-1].x - _arc[0].x)
	var ahead := WorldConfig.m_to_px(trail_m)
	for i in range(1, _arc.size() - 1):
		var p := _arc[i]
		var fwd := (p.x - x) * dir
		if not full and (fwd < 0.0 or fwd > ahead):
			continue
		var q := p.round()
		draw_rect(Rect2(q - Vector2(2, 2), Vector2(4, 4)), INK)
		draw_rect(Rect2(q - Vector2(1, 1), Vector2(2, 2)), GOLD if full or fwd < ahead * 0.6 else HONEY)


## Sombra: marca no chao embaixo da nave + tracejado ate os pes (da para sentir a altura).
func _draw_shadow(at: Vector2, ground: float) -> void:
	var gx := roundf(at.x)
	var gy := roundf(ground)
	draw_rect(Rect2(gx - 7, gy - 1, 14, 2), SHADOW)
	draw_rect(Rect2(gx - 4, gy - 2, 8, 1), SHADOW)
	var feet := at.y + WorldConfig.m_to_px(float(WorldConfig.load_config()["lander"]["feet_offset_m"]))
	var y := feet + 4.0
	while y < gy - 6.0:
		draw_rect(Rect2(gx, roundf(y), 1, 3), MIST)
		y += 7.0


## Nivelador: linha na inclinacao da nave (verde = pode pousar, amarela = no limite, vermelha = vai bater) e uma regua
## horizontal apagada de referencia.
func _draw_level(l: Lander, cfg: Dictionary) -> void:
	var tol := LandingRules.tolerances(cfg["landing"], float(l.params.get("gear", 1.0)))
	var tilt := absf(wrapf(l.rotation, -PI, PI))
	var max_tilt := float(tol["max_tilt"])
	var color: Color = VERDICT_COLOR["good"] if tilt <= max_tilt * 0.6 else (VERDICT_COLOR["hard"]
			if tilt <= max_tilt else VERDICT_COLOR["miss"])
	var c := l.global_position + Vector2(0, WorldConfig.m_to_px(float(cfg["lander"]["feet_offset_m"])) + 4.0)
	for i in range(-5, 6):
		if i % 2 == 0:
			draw_rect(Rect2(c.round() + Vector2(i * 4 - 1, 0), Vector2(2, 1)), MIST)
	var d := Vector2.RIGHT.rotated(l.rotation) * 16.0
	draw_line(c - d, c + d, INK, 3.0)
	draw_line(c - d, c + d, color, 1.0)


## Onde vou cair: pontinhos da queda sem motor e um X no ponto de toque (cor do veredito).
func _draw_predict(target: Dictionary, cfg: Dictionary) -> void:
	var l := flight.lander
	var f := Assists.fall(l.global_position, l.vel_m, l.params, flight.terrain.ridge)
	var pts: Array[Vector2] = f["points"]
	var half := WorldConfig.m_to_px(float(cfg["lander"]["half_width_m"]))
	var tol := LandingRules.tolerances(cfg["landing"], float(l.params.get("gear", 1.0)))
	var v := Assists.verdict(f, target, half, tol)
	var color: Color = VERDICT_COLOR.get(v, MIST)
	var last := pts[0]
	for p in pts:
		if p.distance_to(last) < 12.0:
			continue
		last = p
		draw_rect(Rect2(p.round() - Vector2(2, 2), Vector2(4, 4)), INK)
		draw_rect(Rect2(p.round() - Vector2(1, 1), Vector2(2, 2)), color)
	if v != "":
		var e := pts[-1].round() + Vector2(0, -3)
		for s in [Vector2(1, 1), Vector2(1, -1)]:
			draw_line(e - s * 4.0, e + s * 4.0, INK, 3.0)
		for s in [Vector2(1, 1), Vector2(1, -1)]:
			draw_line(e - s * 3.0, e + s * 3.0, color, 1.0)
